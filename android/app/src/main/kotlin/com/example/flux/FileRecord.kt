package com.example.flux

import java.io.File
import java.nio.charset.StandardCharsets

/**
 * Shared Monolithic String Pool to avoid storing JVM String instances per file,
 * strictly matching the nameOffset/pathOffset spec.
 */
object StringPool {
    private var buffer = ByteArray(16 * 1024 * 1024) // 16 MB pre-allocated
    private var offset = 0

    @Synchronized
    fun put(str: String): Pair<Int, Short> {
        val bytes = str.toByteArray(StandardCharsets.UTF_8)
        val len = bytes.size
        if (offset + len > buffer.size) {
            val newBuffer = ByteArray(buffer.size * 2)
            System.arraycopy(buffer, 0, newBuffer, 0, buffer.size)
            buffer = newBuffer
        }
        val startOffset = offset
        System.arraycopy(bytes, 0, buffer, startOffset, len)
        offset += len
        return Pair(startOffset, len.toShort())
    }

    @Synchronized
    fun get(startOffset: Int, len: Short): String {
        if (len <= 0) return ""
        return String(buffer, startOffset, len.toInt(), StandardCharsets.UTF_8)
    }

    @Synchronized
    fun writeTo(dos: java.io.DataOutputStream) {
        dos.writeInt(offset)
        dos.write(buffer, 0, offset)
    }

    @Synchronized
    fun readFrom(dis: java.io.DataInputStream) {
        offset = dis.readInt()
        if (offset > buffer.size) {
            buffer = ByteArray(offset * 2)
        }
        dis.readFully(buffer, 0, offset)
    }

    @Synchronized
    fun clear() {
        offset = 0
    }
}

/**
 * Global MIME Type Lookup Table, mapping MIME strings to uint16 indices.
 */
object MimeTable {
    private val mimeList = mutableListOf<String>()
    private val mimeMap = mutableMapOf<String, Short>()

    init {
        // Pre-populate standard MIMEs
        getIndex("directory")
        getIndex("application/octet-stream")
    }

    @Synchronized
    fun getIndex(mime: String): Short {
        return mimeMap.getOrPut(mime) {
            val idx = mimeList.size.toShort()
            mimeList.add(mime)
            idx
        }
    }

    @Synchronized
    fun getMime(idx: Short): String {
        if (idx < 0 || idx >= mimeList.size) return "application/octet-stream"
        return mimeList[idx.toInt()]
    }

    @Synchronized
    fun writeTo(dos: java.io.DataOutputStream) {
        dos.writeInt(mimeList.size)
        for (mime in mimeList) {
            dos.writeUTF(mime)
        }
    }

    @Synchronized
    fun readFrom(dis: java.io.DataInputStream) {
        mimeList.clear()
        mimeMap.clear()
        val size = dis.readInt()
        for (i in 0 until size) {
            val mime = dis.readUTF()
            mimeList.add(mime)
            mimeMap[mime] = i.toShort()
        }
    }

    @Synchronized
    fun clear() {
        mimeList.clear()
        mimeMap.clear()
        getIndex("directory")
        getIndex("application/octet-stream")
    }
}

/**
 * FileRecord representing the precise 64-byte structural metadata
 * optimized for cache lines and memory compaction.
 */
data class FileRecord(
    val fid: Long,               // 8 B (uint64)
    val parentDirFid: Long,      // 8 B (uint64)
    val nameOffset: Int,         // 3 B (uint24 - mapped to Int)
    val nameLen: Short,          // 2 B (uint16)
    val pathOffset: Int,         // 3 B (uint24 - mapped to Int)
    val pathLen: Short,          // 2 B (uint16)
    val size: Long,              // 8 B (uint64)
    val mtime: Int,              // 4 B (uint32 - modified time since epoch / 2020)
    val atime: Int,              // 4 B (uint32)
    val ctime: Int,              // 4 B (uint32)
    val mimeTypeIdx: Short,      // 2 B (uint16)
    var flags: Int,              // 4 B (uint32)
    val vectorSlot: Int,         // 3 B (uint24 - mapped to Int)
    val accessCount: Short,      // 2 B (uint16)
    val checksum: Long           // 8 B (uint64)
) {
    companion object {
        const val FLAG_DELETED = 1 shl 0
        const val FLAG_HIDDEN = 1 shl 1
        const val FLAG_PINNED = 1 shl 2
        const val FLAG_INDEXED = 1 shl 3
        const val FLAG_STARRED = 1 shl 4
        const val FLAG_VAULT = 1 shl 5
        const val FLAG_DUPLICATE = 1 shl 6

        // Reserved sentinel
        val EMPTY = FileRecord(
            fid = 0L, parentDirFid = 0L,
            nameOffset = 0, nameLen = 0,
            pathOffset = 0, pathLen = 0,
            size = 0L, mtime = 0, atime = 0, ctime = 0,
            mimeTypeIdx = 0, flags = 0,
            vectorSlot = 0, accessCount = 0, checksum = 0L
        )

        /**
         * Builder to assign pools automatically when constructing a record.
         */
        fun create(
            fid: Long,
            parentDirFid: Long,
            name: String,
            path: String,
            size: Long,
            mtime: Long,
            atime: Long,
            ctime: Long,
            mimeType: String,
            flags: Int,
            vectorSlot: Int = 0,
            accessCount: Short = 0,
            checksum: Long = 0L
        ): FileRecord {
            val namePool = StringPool.put(name)
            val pathPool = StringPool.put(path)
            val mimeIdx = MimeTable.getIndex(mimeType)
            
            return FileRecord(
                fid = fid,
                parentDirFid = parentDirFid,
                nameOffset = namePool.first,
                nameLen = namePool.second,
                pathOffset = pathPool.first,
                pathLen = pathPool.second,
                size = size,
                mtime = mtime.toInt(),
                atime = atime.toInt(),
                ctime = ctime.toInt(),
                mimeTypeIdx = mimeIdx,
                flags = flags,
                vectorSlot = vectorSlot,
                accessCount = accessCount,
                checksum = checksum
            )
        }
    }

    // Computed string getters from StringPool
    val name: String
        get() = StringPool.get(nameOffset, nameLen)

    val path: String
        get() = StringPool.get(pathOffset, pathLen)

    val mimeType: String
        get() = MimeTable.getMime(mimeTypeIdx)

    val isDeleted: Boolean
        get() = (flags and FLAG_DELETED) != 0

    val isVault: Boolean
        get() = (flags and FLAG_VAULT) != 0

    val isDuplicate: Boolean
        get() = (flags and FLAG_DUPLICATE) != 0

    val isDirectory: Boolean
        get() = mimeType == "directory"

    fun toMap(): Map<String, Any> {
        val category = getCategoryFromMime(mimeType, name)
        return mapOf(
            "fid" to fid,
            "parentDirFid" to parentDirFid,
            "name" to name,
            "path" to path,
            "category" to category,
            "size" to size,
            "sizeString" to formatSize(size),
            "sizeInMb" to size.toDouble() / (1024.0 * 1024.0),
            "modifiedDate" to mtime.toLong() * 1000L,
            "isDuplicate" to isDuplicate,
            "isVault" to isVault,
            "location" to "Local"
        )
    }

    private fun formatSize(bytes: Long): String {
        if (bytes < 1000) return "$bytes B"
        val exp = (Math.log(bytes.toDouble()) / Math.log(1000.0)).toInt()
        val pre = "KMGTPE"[exp - 1]
        return String.format("%.1f %sB", bytes / Math.pow(1000.0, exp.toDouble()), pre)
    }

    val category: String
        get() = getCategoryFromMime(mimeType, name)

    fun getCategoryFromMime(mime: String, filename: String): String {
        if (mime == "directory") return "Directory"
        val ext = filename.substringAfterLast('.', "").lowercase()
        return when {
            mime.startsWith("image/") || ext in listOf("jpg", "jpeg", "png", "gif", "webp", "bmp", "svg") -> "Photos"
            mime.startsWith("video/") || ext in listOf("mp4", "mkv", "mov", "avi", "webm", "flv", "3gp") -> "Videos"
            mime.startsWith("audio/") || ext in listOf("mp3", "wav", "ogg", "m4a", "flac", "aac", "wma") -> "Audio"
            mime.startsWith("text/") || mime.contains("pdf") || mime.contains("document") || mime.contains("sheet") || mime.contains("presentation") || ext in listOf("pdf", "docx", "doc", "txt", "xlsx", "xls", "pptx", "ppt", "epub") -> "Documents"
            mime == "application/vnd.android.package-archive" || ext == "apk" -> "Application"
            ext in listOf("zip", "rar", "7z", "tar", "gz") -> "Archives"
            else -> "Others"
        }
    }
}

/**
 * Section 9.2: WAL Entry Schema - 32 Bytes aligned structure
 */
data class WalEntry(
    val magic: Int = 0x464C5558, // 4B - 'FLUX'
    val sequence: Long,          // 8B - monotonic sequence number
    val timestamp: Long,         // 8B - epoch milliseconds
    val opCode: Byte,            // 1B - INSERT=1, DELETE=2, UPDATE=3, RENAME=4
    val fid: Int,                // 4B - target file ID
    val payload: Short = 0,      // 2B - operation-specific data
    val checksum: Int = 0        // 4B - CRC32 corruption detection
) {
    fun toBytes(): ByteArray {
        val buffer = java.nio.ByteBuffer.allocate(32)
        buffer.putInt(magic)
        buffer.putLong(sequence)
        buffer.putLong(timestamp)
        buffer.put(opCode)
        buffer.putInt(fid)
        buffer.putShort(payload)
        buffer.putInt(checksum)
        buffer.put(0.toByte()) // 1B padding for 32B alignment
        return buffer.array()
    }

    companion object {
        fun fromBytes(bytes: ByteArray): WalEntry {
            val buffer = java.nio.ByteBuffer.wrap(bytes)
            val magic = buffer.getInt()
            val sequence = buffer.getLong()
            val timestamp = buffer.getLong()
            val opCode = buffer.get()
            val fid = buffer.getInt()
            val payload = buffer.getShort()
            val checksum = buffer.getInt()
            return WalEntry(magic, sequence, timestamp, opCode, fid, payload, checksum)
        }
    }
}
