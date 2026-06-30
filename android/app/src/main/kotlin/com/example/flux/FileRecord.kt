package com.example.flux

import java.io.File

/**
 * FileRecord represents the compact 64-byte structural metadata of a file
 * as described in Chapter 3.3 of the FLUX technical white paper.
 */
data class FileRecord(
    val fid: Long,
    val parentDirFid: Long,
    val name: String,
    val path: String,
    val size: Long,
    val mtime: Long,
    val atime: Long,
    val ctime: Long,
    val mimeType: String,
    var flags: Int,
    val vectorSlot: Int = 0,
    val accessCount: Int = 0,
    val checksum: Long = 0L
) {
    companion object {
        const val FLAG_DELETED = 1 shl 0
        const val FLAG_HIDDEN = 1 shl 1
        const val FLAG_PINNED = 1 shl 2
        const val FLAG_INDEXED = 1 shl 3
        const val FLAG_STARRED = 1 shl 4
        const val FLAG_VAULT = 1 shl 5
        const val FLAG_DUPLICATE = 1 shl 6

        val EMPTY = FileRecord(0L, 0L, "", "", 0L, 0L, 0L, 0L, "", 0)
    }

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
            "modifiedDate" to mtime * 1000L, // Convert to milliseconds for Dart DateTime
            "isDuplicate" to isDuplicate,
            "isVault" to isVault,
            "location" to "Local"
        )
    }

    private fun formatSize(bytes: Long): String {
        if (bytes < 1024) return "$bytes B"
        val exp = (Math.log(bytes.toDouble()) / Math.log(1024.0)).toInt()
        val pre = "KMGTPE"[exp - 1]
        return String.format("%.1f %sB", bytes / Math.pow(1024.0, exp.toDouble()), pre)
    }

    private fun getCategoryFromMime(mime: String, filename: String): String {
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
