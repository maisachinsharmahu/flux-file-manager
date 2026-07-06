package com.example.flux.viewer.archive

import java.io.File
import java.io.FileOutputStream
import java.util.zip.ZipFile

/**
 * ArchiveParser — lightweight in-memory zip archive walker and entry extractor.
 *
 * Traverses entries of ZIP, EPUB, and APK files directly without unzipping them to disk.
 * Extracts individual entry streams on-demand when clicked.
 */
object ArchiveParser {

    fun getArchiveEntries(filePath: String): String {
        val file = File(filePath)
        if (!file.exists()) return "[]"

        val jsonList = ArrayList<String>()
        var zip: ZipFile? = null
        try {
            zip = ZipFile(file)
            val entries = zip.entries()
            while (entries.hasMoreElements()) {
                val entry = entries.nextElement()
                val name = escapeJson(entry.name)
                val size = entry.size
                val compressedSize = entry.compressedSize
                val isDir = entry.isDirectory

                jsonList.add("""{"name":"$name","size":$size,"compressedSize":$compressedSize,"isDir":$isDir}""")
            }
        } catch (e: Exception) {
            return "[]"
        } finally {
            zip?.close()
        }

        return "[${jsonList.joinToString(",")}]"
    }

    fun extractArchiveEntry(filePath: String, entryName: String, destPath: String): Boolean {
        val file = File(filePath)
        if (!file.exists()) return false

        var zip: ZipFile? = null
        try {
            zip = ZipFile(file)
            val entry = zip.getEntry(entryName) ?: return false

            val destFile = File(destPath)
            destFile.parentFile?.mkdirs()

            zip.getInputStream(entry).use { input ->
                FileOutputStream(destFile).use { output ->
                    input.copyTo(output)
                }
            }
            return true
        } catch (e: Exception) {
            return false
        } finally {
            zip?.close()
        }
    }

    private fun escapeJson(str: String): String {
        return str.replace("\\", "\\\\")
            .replace("\"", "\\\"")
            .replace("\n", "\\n")
            .replace("\r", "\\r")
            .replace("\t", "\\t")
    }
}
