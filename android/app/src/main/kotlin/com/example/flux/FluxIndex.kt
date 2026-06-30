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

    // The Master Record Map (FIDs to records)
    val masterIndex = ConcurrentHashMap<Long, FileRecord>()

    // Index 1: Path Map (Path string -> FID)
    val pathMap = ConcurrentHashMap<String, Long>()

    // Index 2: Name Trie
    val nameTrie = RadixTrie()

    // Index 3: Token Index
    val tokenIndex = ConcurrentHashMap<String, BitSet>()

    // Index 4: Directory Index (parent FID -> children FIDs)
    val directoryIndex = ConcurrentHashMap<Long, MutableList<Long>>()

    // Index 5: Type Buckets
    val typeBuckets = ConcurrentHashMap<String, BitSet>()

    // Index 8: Checksum Map (Checksum -> list of matching FIDs)
    val checksumMap = ConcurrentHashMap<Long, MutableList<Long>>()

    // The Deletion BitSet (O(1) logical deletion)
    val deletionSet = BitSet()

    // Root directory FID definition
    val rootFid = 1L

    init {
        // Pre-reserve FID 1 for Root Directory "/"
        val rootDir = FileRecord(
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
        masterIndex[rootFid] = rootDir
        pathMap["/"] = rootFid
        nextFid.set(2L)
    }

    /**
     * Initializes the indexing engine. Reads WAL logs, scans real filesystem,
     * and seeds mock files if no files were found.
     */
    @Synchronized
    fun initialize() {
        Log.d(TAG, "Initializing FluxIndex...")
        
        // 1. Clear existing in-memory structures (keep root)
        val root = masterIndex[rootFid]
        masterIndex.clear()
        pathMap.clear()
        tokenIndex.clear()
        directoryIndex.clear()
        typeBuckets.clear()
        checksumMap.clear()
        deletionSet.clear()

        if (root != null) {
            masterIndex[rootFid] = root
            pathMap["/"] = rootFid
        }

        // 2. Scan standard storage paths
        scanStorage()

        // 3. If standard storage is empty or denied, generate simulated/mock files
        if (masterIndex.size <= 1) {
            Log.d(TAG, "Storage empty or permissions missing, seeding premium mockup files.")
            seedMockFiles()
        }

        // 4. Recover tombstones from WAL
        applyWalLogs()

        // 5. Update duplicate flags
        detectDuplicates()

        Log.d(TAG, "FluxIndex initialized successfully with ${masterIndex.size} entries.")
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
            
            val record = FileRecord(
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
        masterIndex[record.fid] = record
        pathMap[record.path] = record.fid
        pathMap[record.path.lowercase()] = record.fid

        // Index 2: Name Trie
        nameTrie.insert(record.name, record.fid)

        // Index 3: Token Index
        val tokens = tokenize(record.name)
        for (token in tokens) {
            tokenIndex.getOrPut(token) { BitSet() }.set(record.fid.toInt())
        }

        // Index 4: Directory Index
        directoryIndex.getOrPut(record.parentDirFid) { mutableListOf() }.add(record.fid)

        // Index 5: Type Buckets
        typeBuckets.getOrPut(record.mimeType) { BitSet() }.set(record.fid.toInt())
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
            val record = FileRecord(
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
                else -> "application/octet-stream"
            }

            // Assign identical checksums to some files to simulate duplicates
            val checksum = if (name.startsWith("resume") || name.startsWith("tax")) 9999L else (fid * 17L)

            val record = FileRecord(
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
                    val record = masterIndex[fid] ?: continue
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
                    val record = masterIndex[fid] ?: continue
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
                    val record = masterIndex[fid] ?: return@forEachLine
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
        for (record in masterIndex.values) {
            if (record.isDeleted || record.isDirectory || record.checksum == 0L) continue
            checksumMap.getOrPut(record.checksum) { mutableListOf() }.add(record.fid)
        }

        // Set FLAG_DUPLICATE if there is more than 1 file with matching checksum
        for ((_, fids) in checksumMap) {
            if (fids.size > 1) {
                // The first file is considered the original, others are duplicates
                for (i in 1 until fids.size) {
                    val record = masterIndex[fids[i]] ?: continue
                    record.flags = record.flags or FileRecord.FLAG_DUPLICATE
                }
            }
        }
    }

    /**
     * Returns list of children maps for a parent directory path.
     */
    fun getDirectoryContents(parentPath: String): List<Map<String, Any>> {
        val parentFid = pathMap[parentPath.lowercase()] ?: return emptyList()
        val childrenFids = directoryIndex[parentFid] ?: return emptyList()
        
        val results = mutableListOf<Map<String, Any>>()
        for (fid in childrenFids) {
            if (deletionSet.get(fid.toInt())) continue
            val record = masterIndex[fid] ?: continue
            results.add(record.toMap())
        }
        return results
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

        for (record in masterIndex.values) {
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
            val record = masterIndex[fid] ?: continue
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
        for (record in masterIndex.values) {
            if (record.isDeleted || record.isDirectory) continue
            results.add(record.toMap())
        }
        return results
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
