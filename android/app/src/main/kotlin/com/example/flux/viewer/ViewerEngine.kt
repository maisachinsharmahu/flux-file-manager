package com.example.flux.viewer

import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns
import java.io.File
import java.io.FileOutputStream

/**
 * ViewerSession — manages lifecycle of an open file viewer.
 *
 * Holds MmapSource, TileEngine, EditOverlay for one file.
 * Must be closed when the viewer screen is disposed.
 *
 * Source: doc1, Ch. UFE Integration.
 */
class ViewerSession(
    val filePath: String,
    val format: FileFormat,
    val source: MmapSource,
    val tileEngine: TileEngine = TileEngine(),
    val editOverlay: EditOverlay = EditOverlay(),
) : AutoCloseable {

    val isDirty: Boolean get() = editOverlay.isDirty

    override fun close() {
        try {
            tileEngine.shutdown()
            tileEngine.evictAll()
            source.close()
        } catch (_: Exception) { /* best-effort */ }
    }

    override fun toString() = "ViewerSession(${File(filePath).name}, $format)"
}

/**
 * ViewerEngine — entry point for opening any file.
 *
 * O(1) dispatch — no Intent, no IPC, no cold start.
 * Identical to doc1's UniversalFileEngine.open() concept.
 */
object ViewerEngine {

    /**
     * Open a file by absolute path.
     * Detects format from magic bytes, returns a ViewerSession.
     * Caller is responsible for closing the session.
     */
    fun open(filePath: String): ViewerSession {
        val file = File(filePath)
        require(file.exists()) { "File not found: $filePath" }
        require(file.isFile)   { "Not a file: $filePath" }

        val source = MmapSource(file)
        val format = FormatDetector.detect(source)

        return ViewerSession(
            filePath    = filePath,
            format      = format,
            source      = source,
        )
    }

    /**
     * Resolve a content:// URI to an absolute file path.
     * Copies to cache dir if direct path not available.
     * Required for files received via ACTION_VIEW intent from other apps.
     */
    fun resolveUri(context: Context, uri: Uri): String? {
        return try {
            when (uri.scheme?.lowercase()) {
                "file" -> uri.path

                "content" -> {
                    // Try to get direct path via cursor (works for file:// backed content URIs)
                    val directPath = tryGetContentPath(context, uri)
                    if (directPath != null && File(directPath).exists()) {
                        directPath
                    } else {
                        // Copy to cache — streaming, no full-file RAM allocation
                        copyToCache(context, uri)
                    }
                }

                else -> null
            }
        } catch (e: Exception) {
            android.util.Log.e("ViewerEngine", "URI resolve failed: ${e.message}")
            null
        }
    }

    private fun tryGetContentPath(context: Context, uri: Uri): String? {
        return try {
            context.contentResolver.query(uri, arrayOf("_data"), null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val col = cursor.getColumnIndex("_data")
                    if (col >= 0) cursor.getString(col) else null
                } else null
            }
        } catch (_: Exception) { null }
    }

    private fun copyToCache(context: Context, uri: Uri): String? {
        val fileName = getFileName(context, uri) ?: "flux_temp_${System.currentTimeMillis()}"
        val cacheFile = File(context.cacheDir, "viewer/$fileName")
        cacheFile.parentFile?.mkdirs()

        context.contentResolver.openInputStream(uri)?.use { input ->
            FileOutputStream(cacheFile).use { output ->
                input.copyTo(output, bufferSize = 65536)
            }
        } ?: return null

        return cacheFile.absolutePath
    }

    private fun getFileName(context: Context, uri: Uri): String? {
        return try {
            context.contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val col = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (col >= 0) cursor.getString(col) else null
                } else null
            }
        } catch (_: Exception) { null }
    }
}
