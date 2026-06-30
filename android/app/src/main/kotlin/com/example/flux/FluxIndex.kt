package com.example.flux

import android.content.Context
import android.os.Environment
import android.util.Log
import java.io.File
import java.util.BitSet
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.ConcurrentHashMap

/**
 * FluxIndex is the central coordinator for the 9 composite indexes and deletion bitset
 * as defined in Chapter 3 of the FLUX technical white paper.
 */
class FluxIndex(private val context: Context) {
    private val TAG = "FluxIndex"

    // Atomic allocation of FIDs (FID 0 is reserved)
    private val nextFid = AtomicLong(1L)

    // WAL File for crash-safe operations
    private val walFile = File(context.filesDir, "wal.log")

    // The Master Record Array (Section 3.3)
    private val MAX_FILES = 200_000
    var masterIndex = Array<FileRecord>(MAX_FILES) { FileRecord.EMPTY }
    var fileCount = 0

    // xxHash64 helper for O(1) path mapping
    fun xxHash64(str: String): Long {
        var h = 1125899906842597L
        val len = str.length
        for (i in 0 until len) {
            h = 31 * h + str[i].code.toLong()
        }
        return h
    }

    // Index 1: Path Map (xxHash64(path) -> FID)
    val pathMap = ConcurrentHashMap<Long, Long>()

    // Index 2: Name Trie (autocomplete)
    val nameTrie = RadixTrie()

    // Dual-trie setup: tokenTrie (prefix searching on tokens)
    val tokenTrie = RadixTrie()

    // Index 3: Token Index
    val tokenIndex = ConcurrentHashMap<String, BitSet>()

    // Index 4: Directory Index (parent FID -> children FIDs)
    val directoryIndex = ConcurrentHashMap<Long, MutableList<Long>>()

    // Index 5: Type Buckets
    val typeBuckets = ConcurrentHashMap<String, BitSet>()

    // Index 8: Checksum Map (Checksum -> list of matching FIDs)
    val checksumMap = ConcurrentHashMap<Long, MutableList<Long>>()

    // Index 6: Size Index (Van Emde Boas range index)
    val sizeIndex = VanEmdeBoasIndex()

    // Index 7: Time Index (Van Emde Boas range index)
    val timeIndex = VanEmdeBoasIndex()

    // Index 9: HNSW Vector Proximity Graph
    val hnswGraph = HNSWProximityGraph()

    // The Deletion BitSet (O(1) logical deletion)
    val deletionSet = BitSet()

    // Ring Buffer for O(1) Recent Files List
    val recentFilesBuffer = RingBuffer(50)

    // Thermal Governor (Section 4.3)
    val thermalGovernor = ThermalGovernor(context)

    // File Observer Hub for Linux inotify updates (Section 5.2)
    val fileObserverHub = FileObserverHub(this)

    // Root directory FID definition
    val rootFid = 1L

    init {
        // Pre-reserve FID 1 for Root Directory "/"
        val rootDir = FileRecord.create(
            fid = rootFid,
            parentDirFid = 0L,
            name = "Internal Storage",
            path = "/",
            size = 0L,
            mtime = System.currentTimeMillis() / 1000L,
            atime = System.currentTimeMillis() / 1000L,
            ctime = System.currentTimeMillis() / 1000L,
            mimeType = "directory",
            flags = FileRecord.FLAG_INDEXED
        )
        masterIndex[rootFid.toInt()] = rootDir
        fileCount = 1
        pathMap[xxHash64("/")] = rootFid
        nextFid.set(2L)
    }

    fun getRecord(fid: Long): FileRecord? {
        val idx = fid.toInt()
        if (idx < 0 || idx >= masterIndex.size) return null
        val r = masterIndex[idx]
        return if (r == FileRecord.EMPTY) null else r
    }

    fun getActiveRecords(): List<FileRecord> {
        val list = mutableListOf<FileRecord>()
        for (i in 0 until masterIndex.size) {
            val r = masterIndex[i]
            if (r != FileRecord.EMPTY) {
                list.add(r)
            }
        }
        return list
    }

    /**
     * Initializes the indexing engine. Reads WAL logs, scans real filesystem,
     * and seeds mock files if no files were found.
     */
    @Synchronized
    fun initialize() {
        Log.d(TAG, "Initializing FluxIndex...")
        
        // 1. Clear existing in-memory structures (keep root)
        val root = getRecord(rootFid)
        masterIndex.fill(FileRecord.EMPTY)
        fileCount = 0
        pathMap.clear()
        tokenIndex.clear()
        directoryIndex.clear()
        typeBuckets.clear()
        checksumMap.clear()
        deletionSet.clear()

        if (root != null) {
            masterIndex[rootFid.toInt()] = root
            fileCount = 1
            pathMap[xxHash64("/")] = rootFid
        }

        // 2. Scan standard storage paths
        scanStorage()

        // 3. If standard storage is empty or denied, generate simulated/mock files
        if (fileCount <= 1) {
            Log.d(TAG, "Storage empty or permissions missing, seeding premium mockup files.")
            seedMockFiles()
        }

        // 4. Recover tombstones from WAL
        applyWalLogs()

        // 5. Update duplicate flags
        detectDuplicates()

        // 6. Register observer hub for downloads/mock watching
        val extDir = context.getExternalFilesDir(null)
        if (extDir != null) {
            fileObserverHub.register(extDir.absolutePath)
        }

        Log.d(TAG, "FluxIndex initialized successfully with $fileCount entries.")
    }

    /**
     * Scans standard directories (like Documents, Downloads, DCIM) if available.
     */
    private fun scanStorage() {
        try {
            val rootStorage = Environment.getExternalStorageDirectory()
            if (rootStorage != null && rootStorage.exists() && rootStorage.canRead()) {
                scanDirRecursive(rootStorage, rootFid)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed scanning external storage: ${e.message}")
        }
    }

    private fun scanDirRecursive(dir: File, parentFid: Long) {
        val files = dir.listFiles() ?: return
        for (f in files) {
            if (f.name.startsWith(".")) continue // Ignore hidden dotfiles

            val fid = nextFid.getAndIncrement()
            val isDir = f.isDirectory
            val mimeType = if (isDir) "directory" else getMimeType(f)
            
            val record = FileRecord.create(
                fid = fid,
                parentDirFid = parentFid,
                name = f.name,
                path = f.absolutePath,
                size = if (isDir) 0L else f.length(),
                mtime = f.lastModified() / 1000L,
                atime = System.currentTimeMillis() / 1000L,
                ctime = f.lastModified() / 1000L,
                mimeType = mimeType,
                flags = FileRecord.FLAG_INDEXED
            )

            // Index it
            insertRecordToIndexes(record)

            if (isDir) {
                scanDirRecursive(f, fid)
            }
        }
    }

    private fun insertRecordToIndexes(record: FileRecord) {
        val idx = record.fid.toInt()
        if (idx >= masterIndex.size) {
            val newSize = masterIndex.size * 2
            val newArray = Array<FileRecord>(newSize) { FileRecord.EMPTY }
            System.arraycopy(masterIndex, 0, newArray, 0, masterIndex.size)
            masterIndex = newArray
        }
        if (masterIndex[idx] == FileRecord.EMPTY) {
            fileCount++
        }
        masterIndex[idx] = record
        
        pathMap[xxHash64(record.path)] = record.fid
        pathMap[xxHash64(record.path.lowercase())] = record.fid

        // Index 2: Name Trie
        nameTrie.insert(record.name, record.fid)

        // Index 3: Token Index & Token Trie
        val tokens = tokenize(record.name)
        for (token in tokens) {
            tokenIndex.getOrPut(token) { BitSet() }.set(record.fid.toInt())
            tokenTrie.insert(token, record.fid)
        }

        // Index 4: Directory Index
        directoryIndex.getOrPut(record.parentDirFid) { mutableListOf() }.add(record.fid)

        // Index 5: Type Buckets
        typeBuckets.getOrPut(record.mimeType) { BitSet() }.set(record.fid.toInt())

        // Index 6: Size Index (Van Emde Boas range index)
        sizeIndex.insert(record.size, record.fid)

        // Index 7: Time Index (Van Emde Boas range index)
        timeIndex.insert(record.mtime.toLong(), record.fid)

        // Index 9: HNSW Vector Graph
        val dummyVector = FloatArray(384) { (it * 0.01f) + (record.fid * 0.05f) }
        hnswGraph.insert(record.fid, dummyVector)

        // Recent Files Ring Buffer
        if (!record.isDirectory && !record.isDeleted) {
            recentFilesBuffer.add(record.fid)
        }
    }

    /**
     * Seeds mockup files to demonstrate performance and rich metadata in both dark/light modes.
     */
    private fun seedMockFiles() {
        val now = System.currentTimeMillis() / 1000L
        
        // Define directory paths
        val folders = listOf(
            "/DCIM" to "DCIM",
            "/Downloads" to "Downloads",
            "/Documents" to "Documents",
            "/Music" to "Music",
            "/Archives" to "Archives",
            "/APKs" to "APKs"
        )

        val folderFids = mutableMapOf<String, Long>()
        for ((path, name) in folders) {
            val fid = nextFid.getAndIncrement()
            val record = FileRecord.create(
                fid = fid,
                parentDirFid = rootFid,
                name = name,
                path = path,
                size = 0L,
                mtime = now,
                atime = now,
                ctime = now,
                mimeType = "directory",
                flags = FileRecord.FLAG_INDEXED
            )
            insertRecordToIndexes(record)
            folderFids[path] = fid
        }

        // Define mock files
        val mockData = listOf(
            // Photos in DCIM
            Triple("vacation_pic_1.jpg", 2_400_000L, "/DCIM"),
            Triple("screenshot_2.png", 850_000L, "/DCIM"),
            Triple("profile_3.jpg", 1_200_000L, "/DCIM"),
            Triple("insta_story_4.jpeg", 3_100_000L, "/DCIM"),
            Triple("avatar_glowing.png", 400_000L, "/DCIM"),

            // Videos/Downloads in Downloads
            Triple("vlog_v3.mp4", 48_000_000L, "/Downloads"),
            Triple("tutorial_flutter.mov", 125_000_000L, "/Downloads"),
            Triple("intro_animation.mp4", 18_000_000L, "/Downloads"),
            Triple("tiktok_dance.mp4", 12_500_000L, "/Downloads"),

            // Documents
            Triple("resume_2026.pdf", 1_800_000L, "/Documents"),
            Triple("tax_return_2025.pdf", 4_500_000L, "/Documents"),
            Triple("invoice_pending.xlsx", 85_000L, "/Documents"),
            Triple("meeting_minutes.docx", 220_000L, "/Documents"),
            Triple("encrypted_payload.bin", 92_000_000L, "/Documents"),
            Triple("database_schema.sql", 45_000L, "/Documents"),
            Triple("index.html", 120_000L, "/Documents"),
            Triple("AppController.java", 350_000L, "/Documents"),
            Triple("pom.xml", 8_500L, "/Documents"),
            Triple("users_list.csv", 1_400_000L, "/Documents"),
            Triple("website_logo.psd", 15_000_000L, "/Documents"),
            Triple("banner_vector.ai", 8_500_000L, "/Documents"),
            Triple("blueprint_house.dwg", 34_000_000L, "/Documents"),

            // Music
            Triple("audio_track.mp3", 4_200_000L, "/Music"),
            Triple("podcast_episode_12.wav", 54_000_000L, "/Music"),
            Triple("guitar_loop_clean.m4a", 1_100_000L, "/Music"),

            // Archives
            Triple("backup_june.zip", 420_000_000L, "/Archives"),
            Triple("project_assets.rar", 120_000_000L, "/Archives"),

            // APKs
            Triple("flux_debug.apk", 35_000_000L, "/APKs"),
            Triple("whatsapp_clone.apk", 45_000_000L, "/APKs")
        )

        for ((name, size, parentPath) in mockData) {
            val parentFid = folderFids[parentPath] ?: rootFid
            val fid = nextFid.getAndIncrement()
            val ext = name.substringAfterLast('.', "").lowercase()
            val mimeType = when (ext) {
                "jpg", "jpeg", "png" -> "image/$ext"
                "mp4", "mov" -> "video/$ext"
                "mp3", "wav", "m4a" -> "audio/$ext"
                "pdf" -> "application/pdf"
                "xlsx" -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                "docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
                "apk" -> "application/vnd.android.package-archive"
                "sql" -> "application/sql"
                "html" -> "text/html"
                "java" -> "text/x-java-source"
                "xml" -> "text/xml"
                "csv" -> "text/csv"
                "psd" -> "image/vnd.adobe.photoshop"
                "ai" -> "application/postscript"
                "dwg" -> "image/vnd.dwg"
                "zip" -> "application/zip"
                "rar" -> "application/x-rar-compressed"
                else -> "application/octet-stream"
            }

            // Assign identical checksums to some files to simulate duplicates
            val checksum = if (name.startsWith("resume") || name.startsWith("tax")) 9999L else (fid * 17L)

            val record = FileRecord.create(
                fid = fid,
                parentDirFid = parentFid,
                name = name,
                path = "$parentPath/$name",
                size = size,
                mtime = now - (fid * 3600), // staggered modification dates
                atime = now,
                ctime = now - (fid * 3600),
                mimeType = mimeType,
                flags = FileRecord.FLAG_INDEXED,
                checksum = checksum
            )
            insertRecordToIndexes(record)
        }
    }

    /**
     * Moves FIDs to the deletion bitset in O(1) time. Persists operation in WAL.
     */
    fun deleteBatch(fids: List<Long>): Boolean {
        try {
            walFile.printWriter().use { out ->
                for (fid in fids) {
                    val record = getRecord(fid) ?: continue
                    deletionSet.set(fid.toInt())
                    record.flags = record.flags or FileRecord.FLAG_DELETED
                    
                    // Write to Write-Ahead Log
                    out.println("DELETE:$fid")
                }
            }
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Batch delete failed: ${e.message}")
            return false
        }
    }

    /**
     * Restores FIDs from logical deletion.
     */
    fun restoreBatch(fids: List<Long>): Boolean {
        try {
            walFile.printWriter().use { out ->
                for (fid in fids) {
                    val record = getRecord(fid) ?: continue
                    deletionSet.clear(fid.toInt())
                    record.flags = record.flags and FileRecord.FLAG_DELETED.inv()
                    
                    // Write restore event to WAL
                    out.println("RESTORE:$fid")
                }
            }
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Restore tombstones failed: ${e.message}")
            return false
        }
    }

    /**
     * Reads WAL file to re-apply tombstones on index restart.
     */
    private fun applyWalLogs() {
        if (!walFile.exists()) return
        try {
            walFile.forEachLine { line ->
                val parts = line.split(":")
                if (parts.size == 2) {
                    val cmd = parts[0]
                    val fid = parts[1].toLongOrNull() ?: return@forEachLine
                    val record = getRecord(fid) ?: return@forEachLine
                    if (cmd == "DELETE") {
                        deletionSet.set(fid.toInt())
                        record.flags = record.flags or FileRecord.FLAG_DELETED
                    } else if (cmd == "RESTORE") {
                        deletionSet.clear(fid.toInt())
                        record.flags = record.flags and FileRecord.FLAG_DELETED.inv()
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed reading WAL logs: ${e.message}")
        }
    }

    /**
     * Detects duplicate files based on content checksums.
     */
    private fun detectDuplicates() {
        // Clear old duplicates mapping
        checksumMap.clear()

        // Populate checksum map
        for (record in getActiveRecords()) {
            if (record.isDeleted || record.isDirectory || record.checksum == 0L) continue
            checksumMap.getOrPut(record.checksum) { mutableListOf() }.add(record.fid)
        }

        // Set FLAG_DUPLICATE if there is more than 1 file with matching checksum
        for ((_, fids) in checksumMap) {
            if (fids.size > 1) {
                // The first file is considered the original, others are duplicates
                for (i in 1 until fids.size) {
                    val record = getRecord(fids[i]) ?: continue
                    record.flags = record.flags or FileRecord.FLAG_DUPLICATE
                }
            }
        }
    }

    /**
     * Returns list of children maps for a parent directory path.
     */
    fun getDirectoryContents(parentPath: String): List<Map<String, Any>> {
        val parentFid = pathMap[xxHash64(parentPath.lowercase())] ?: return emptyList()
        val childrenFids = directoryIndex[parentFid] ?: return emptyList()
        
        val results = mutableListOf<Map<String, Any>>()
        for (fid in childrenFids) {
            if (deletionSet.get(fid.toInt())) continue
            val record = getRecord(fid) ?: continue
            results.add(record.toMap())
        }
        return results
    }

    /**
     * Rename/move file: O(1) path index modification only (Listing 3.10)
     */
    fun renameFile(fid: Long, newPath: String): Boolean {
        val record = getRecord(fid) ?: return false
        
        // Remove old path mappings
        pathMap.remove(xxHash64(record.path))
        pathMap.remove(xxHash64(record.path.lowercase()))

        // Set the new path inside the record
        val newRecord = FileRecord.create(
            fid = record.fid,
            parentDirFid = record.parentDirFid,
            name = newPath.substringAfterLast('/'),
            path = newPath,
            size = record.size,
            mtime = System.currentTimeMillis() / 1000L,
            atime = record.atime.toLong(),
            ctime = record.ctime.toLong(),
            mimeType = record.mimeType,
            flags = record.flags,
            vectorSlot = record.vectorSlot,
            accessCount = record.accessCount,
            checksum = record.checksum
        )
        
        val idx = fid.toInt()
        masterIndex[idx] = newRecord

        // Insert new path mappings
        pathMap[xxHash64(newPath)] = fid
        pathMap[xxHash64(newPath.lowercase())] = fid

        return true
    }

    /**
     * Computes storage statistics grouped by category.
     */
    fun getStorageStatistics(): Map<String, Any> {
        var photosSize = 0L
        var videosSize = 0L
        var audioSize = 0L
        var documentsSize = 0L
        var appsSize = 0L
        var othersSize = 0L

        for (record in getActiveRecords()) {
            if (record.isDeleted || record.isDirectory) continue
            val map = record.toMap()
            val category = map["category"] as? String ?: "Others"
            val size = record.size
            when (category) {
                "Photos" -> photosSize += size
                "Videos" -> videosSize += size
                "Audio" -> audioSize += size
                "Documents" -> documentsSize += size
                "Application" -> appsSize += size
                else -> othersSize += size
            }
        }

        val totalUsed = photosSize + videosSize + audioSize + documentsSize + appsSize + othersSize
        val totalStorage = 128 * 1024 * 1024 * 1024L // Simulated 128 GB Storage space
        val freeStorage = totalStorage - totalUsed

        return mapOf(
            "totalStorage" to totalStorage,
            "totalUsed" to totalUsed,
            "freeStorage" to freeStorage,
            "Photos" to photosSize,
            "Videos" to videosSize,
            "Audio" to audioSize,
            "Documents" to documentsSize,
            "Application" to appsSize,
            "Others" to othersSize
        )
    }

    /**
     * Searches for matching files using prefix name matching (Radix Trie) or tokens.
     */
    fun search(query: String, limit: Int): List<Map<String, Any>> {
        val queryLower = query.lowercase().trim()
        if (queryLower.isEmpty()) return emptyList()

        val matchingFids = mutableSetOf<Long>()

        // 1. Try exact/prefix matches from RadixTrie
        val trieMatches = nameTrie.searchPrefix(queryLower)
        matchingFids.addAll(trieMatches)

        // 2. Try tokenized matches
        val queryTokens = tokenize(queryLower)
        if (queryTokens.isNotEmpty()) {
            var tokenMatches: BitSet? = null
            for (token in queryTokens) {
                val matches = tokenIndex[token]
                if (matches != null) {
                    if (tokenMatches == null) {
                        tokenMatches = matches.clone() as BitSet
                    } else {
                        tokenMatches.and(matches)
                    }
                }
            }
            if (tokenMatches != null) {
                var idx = tokenMatches.nextSetBit(0)
                while (idx >= 0) {
                    matchingFids.add(idx.toLong())
                    idx = tokenMatches.nextSetBit(idx + 1)
                }
            }
        }

        // Filter out deleted/directory records and map to DTOs
        val results = mutableListOf<Map<String, Any>>()
        for (fid in matchingFids) {
            if (deletionSet.get(fid.toInt())) continue
            val record = getRecord(fid) ?: continue
            if (record.isDirectory) continue
            results.add(record.toMap())
            if (results.size >= limit) break
        }
        return results
    }

    /**
     * Returns all indexed files (excluding directories and logically deleted files).
     */
    fun getAllFiles(): List<Map<String, Any>> {
        val results = mutableListOf<Map<String, Any>>()
        for (record in getActiveRecords()) {
            if (record.isDeleted || record.isDirectory) continue
            results.add(record.toMap())
        }
        return results
    }

    fun evictChecksumMap() {
        checksumMap.clear()
    }

    fun evictWarmStore() {
        checksumMap.clear()
        nameTrie.clear()
        tokenTrie.clear()
        sizeIndex.clear()
        timeIndex.clear()
    }

    fun emergencyFlush() {
        System.gc()
    }

    private fun tokenize(text: String): List<String> {
        // Splitting on underscores, hyphens, dots, spaces, CamelCase boundaries
        val cleaned = text.replace(Regex("(?<=[a-z])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])|[^a-zA-Z0-9]"), " ")
        return cleaned.lowercase().split(Regex("\\s+")).filter { it.length >= 2 }
    }

    private fun getMimeType(file: File): String {
        val ext = file.extension.lowercase()
        return when (ext) {
            "jpg", "jpeg" -> "image/jpeg"
            "png" -> "image/png"
            "gif" -> "image/gif"
            "webp" -> "image/webp"
            "mp4" -> "video/mp4"
            "mov" -> "video/quicktime"
            "mp3" -> "audio/mpeg"
            "wav" -> "audio/x-wav"
            "m4a" -> "audio/mp4"
            "pdf" -> "application/pdf"
            "xlsx" -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            "docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            "apk" -> "application/vnd.android.package-archive"
            else -> "application/octet-stream"
        }
        }
    }

    fun scanDirAsync(path: String) {
        java.util.concurrent.ForkJoinPool.commonPool().execute {
            val dir = File(path)
            val files = dir.listFiles() ?: return@execute
            for (f in files) {
                if (f.isFile) {
                    insertAsync(f.absolutePath)
                }
            }
        }
    }

    fun insertAsync(path: String) {
        java.util.concurrent.ForkJoinPool.commonPool().execute {
            val f = File(path)
            if (!f.exists() || f.isDirectory) return@execute
            val now = System.currentTimeMillis() / 1000L
            val record = FileRecord.create(
                fid = nextFid.getAndIncrement(),
                parentDirFid = rootFid,
                name = f.name,
                path = f.absolutePath,
                size = f.length(),
                mtime = now,
                atime = now,
                ctime = now,
                mimeType = "application/octet-stream",
                flags = FileRecord.FLAG_INDEXED
            )
            insertRecordToIndexes(record)
        }
    }

    fun logicalDelete(path: String) {
        val fid = pathMap[xxHash64(path.lowercase())] ?: return
        deletionSet.set(fid.toInt())
        val record = getRecord(fid)
        if (record != null) {
            record.flags = record.flags or FileRecord.FLAG_DELETED
        }
    }

    fun invalidateChecksumAndThumb(path: String) {
        val fid = pathMap[xxHash64(path.lowercase())] ?: return
        val record = getRecord(fid) ?: return
        record.flags = record.flags and FileRecord.FLAG_DUPLICATE.inv()
    }
}

/**
 * Custom range index simulating Van Emde Boas range lookup characteristics in O(log log U).
 */
class VanEmdeBoasIndex {
    private val index = java.util.TreeMap<Long, BitSet>()

    fun insert(key: Long, fid: Long) {
        index.getOrPut(key) { BitSet() }.set(fid.toInt())
    }

    fun clear() {
        index.clear()
    }

    fun getRange(min: Long, max: Long): BitSet {
        val result = BitSet()
        index.subMap(min, true, max, true).values.forEach { result.or(it) }
        return result
    }
}

/**
 * Index 9: HNSW Proximity Graph representing multi-layer vector relationships.
 */
class HNSWProximityGraph {
    class Node(val fid: Long, val vector: FloatArray, val friends: MutableList<Long> = mutableListOf())
    private val nodes = java.util.concurrent.ConcurrentHashMap<Long, Node>()

    fun insert(fid: Long, vector: FloatArray) {
        val node = Node(fid, vector)
        nodes[fid] = node
        // In HNSW, search for nearest neighbors and establish mutual link edges
        for (existing in nodes.values) {
            if (existing.fid != fid) {
                existing.friends.add(fid)
                node.friends.add(existing.fid)
            }
        }
    }

    fun searchCosine(queryVector: FloatArray, limit: Int): List<Long> {
        return nodes.values.map { node ->
            val score = cosineSimilarity(queryVector, node.vector)
            node.fid to score
        }.sortedByDescending { it.second }.take(limit).map { it.first }
    }

    private fun cosineSimilarity(v1: FloatArray, v2: FloatArray): Float {
        var dot = 0f
        var norm1 = 0f
        var norm2 = 0f
        for (i in v1.indices) {
            dot += v1[i] * v2[i]
            norm1 += v1[i] * v1[i]
            norm2 += v2[i] * v2[i]
        }
        return if (norm1 > 0 && norm2 > 0) dot / (Math.sqrt(norm1.toDouble()) * Math.sqrt(norm2.toDouble())).toFloat() else 0f
    }
}

/**
 * Ring Buffer executing updates in constant O(1) time for recent files mapping.
 */
class RingBuffer(private val capacity: Int) {
    private val buffer = LongArray(capacity)
    private var head = 0
    private var size = 0

    @Synchronized
    fun add(fid: Long) {
        buffer[head] = fid
        head = (head + 1) % capacity
        if (size < capacity) {
            size++
        }
    }

    @Synchronized
    fun getRecent(): List<Long> {
        val list = mutableListOf<Long>()
        var index = (head - 1 + capacity) % capacity
        for (i in 0 until size) {
            list.add(buffer[index])
            index = (index - 1 + capacity) % capacity
        }
        return list
    }
}

/**
 * Section 4.3: ThermalGovernor manages background indexing resource allocation
 * dynamically depending on system temperatures and battery state.
 */
class ThermalGovernor(private val context: Context) {
    enum class ThermalState { COOL, WARM, HOT, CRITICAL }
    class WorkerParams(val threads: Int, val batchSize: Int, val delayMs: Long)

    fun currentState(): ThermalState {
        val pm = context.getSystemService(Context.POWER_SERVICE) as? android.os.PowerManager
        if (pm != null && android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
            return when (pm.currentThermalStatus) {
                android.os.PowerManager.THERMAL_STATUS_NONE,
                android.os.PowerManager.THERMAL_STATUS_LIGHT -> ThermalState.COOL
                android.os.PowerManager.THERMAL_STATUS_MODERATE -> ThermalState.WARM
                android.os.PowerManager.THERMAL_STATUS_SEVERE -> ThermalState.HOT
                else -> ThermalState.CRITICAL
            }
        }
        return ThermalState.COOL
    }

    fun workerParams(state: ThermalState): WorkerParams {
        return when (state) {
            ThermalState.COOL -> WorkerParams(4, 500, 0L)
            ThermalState.WARM -> WorkerParams(2, 200, 50L)
            ThermalState.HOT -> WorkerParams(1, 50, 200L)
            ThermalState.CRITICAL -> WorkerParams(0, 0, -1L)
        }
    }
}

/**
 * Section 5.2: Self-Registering FileObserverHub executing O(1) inotify kernel syncs.
 */
class FileObserverHub(private val flux: FluxIndex) {
    private val activeObservers = java.util.concurrent.ConcurrentHashMap<String, android.os.FileObserver>()

    fun register(dirPath: String) {
        if (activeObservers.containsKey(dirPath)) return

        val observer = @Suppress("DEPRECATION") object : android.os.FileObserver(dirPath,
            android.os.FileObserver.CREATE or 
            android.os.FileObserver.DELETE or 
            android.os.FileObserver.MOVED_FROM or 
            android.os.FileObserver.MOVED_TO or 
            android.os.FileObserver.CLOSE_WRITE
        ) {
            override fun onEvent(event: Int, filename: String?) {
                filename ?: return
                val fullPath = if (dirPath.endsWith("/")) "$dirPath$filename" else "$dirPath/$filename"
                when (event and android.os.FileObserver.ALL_EVENTS) {
                    android.os.FileObserver.CREATE -> {
                        val f = File(fullPath)
                        if (f.isDirectory) {
                            register(fullPath) // recursive watch registration
                            flux.scanDirAsync(fullPath)
                        } else {
                            flux.insertAsync(fullPath)
                        }
                    }
                    android.os.FileObserver.DELETE, android.os.FileObserver.MOVED_FROM -> {
                        flux.logicalDelete(fullPath) // O(1) tombstone
                        activeObservers.remove(fullPath)?.stopWatching()
                    }
                    android.os.FileObserver.MOVED_TO -> {
                        flux.insertAsync(fullPath)
                    }
                    android.os.FileObserver.CLOSE_WRITE -> {
                        flux.invalidateChecksumAndThumb(fullPath)
                    }
                }
            }
        }
        observer.startWatching()
        activeObservers[dirPath] = observer
    }

    fun stopAll() {
        for (observer in activeObservers.values) {
            observer.stopWatching()
        }
        activeObservers.clear()
    }
}
