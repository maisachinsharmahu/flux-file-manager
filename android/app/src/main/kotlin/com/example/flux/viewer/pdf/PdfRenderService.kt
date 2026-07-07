package com.example.flux.viewer.pdf

import android.graphics.Bitmap
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import android.util.LruCache
import java.io.File
import java.util.concurrent.Executors

/**
 * PdfRenderService — thread-safe synchronized manager around Android's native PdfRenderer.
 *
 * Implements a memory-based Bitmap LruCache to cache rendered pages for smooth scrolling.
 * Employs a single-threaded executor to guarantee sequential, thread-safe PDF page rendering (Rule 3).
 */
object PdfRenderService {

    // Cache size set to 30MB of bitmap allocation
    private val memoryCache = object : LruCache<String, Bitmap>(30 * 1024 * 1024) {
        override fun sizeOf(key: String, value: Bitmap): Int {
            return value.byteCount
        }
    }

    private val singleThreadExecutor = Executors.newSingleThreadExecutor()

    // File descriptors & renderers cache
    private val openRenderers = HashMap<String, Pair<ParcelFileDescriptor, PdfRenderer>>()

    /**
     * Get total page count of a PDF file.
     */
    fun getPageCount(filePath: String): Int {
        return synchronized(openRenderers) {
            try {
                val (fd, renderer) = getOrCreateRenderer(filePath)
                renderer.pageCount
            } catch (e: Exception) {
                0
            }
        }
    }

    /**
     * Render page safely onto a Bitmap at the given scale factor, or fetch from LruCache.
     */
    fun renderPage(filePath: String, pageIndex: Int, scale: Float): Bitmap? {
        val cacheKey = "$filePath-$pageIndex-$scale"
        val cachedBitmap = memoryCache.get(cacheKey)
        if (cachedBitmap != null) {
            return cachedBitmap
        }

        // Run rendering on a single thread to guarantee safety
        val future = singleThreadExecutor.submit<Bitmap> {
            synchronized(openRenderers) {
                val (_, renderer) = getOrCreateRenderer(filePath)
                if (pageIndex < 0 || pageIndex >= renderer.pageCount) {
                    throw IllegalArgumentException("Invalid PDF page index: $pageIndex")
                }

                val page = renderer.openPage(pageIndex)
                val destW = (page.width * scale).toInt().coerceAtLeast(1)
                val destH = (page.height * scale).toInt().coerceAtLeast(1)

                val bitmap = Bitmap.createBitmap(destW, destH, Bitmap.Config.ARGB_8888)
                // Fill white background before rendering to avoid dark transparency overlaps
                bitmap.eraseColor(android.graphics.Color.WHITE)

                page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                page.close()

                memoryCache.put(cacheKey, bitmap)
                bitmap
            }
        }

        return try {
            future.get()
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Render page safely and compress to JPEG bytes.
     */
    fun getPageBytes(filePath: String, pageIndex: Int, scale: Float): ByteArray? {
        val bitmap = renderPage(filePath, pageIndex, scale) ?: return null
        val stream = java.io.ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 85, stream)
        return stream.toByteArray()
    }

    /**
     * Close a PDF and release all descriptors. Called on dispose/close.
     */
    fun closePdf(filePath: String) {
        synchronized(openRenderers) {
            val pair = openRenderers.remove(filePath)
            if (pair != null) {
                try {
                    pair.second.close()
                    pair.first.close()
                } catch (e: Exception) {
                    // Ignore release errors
                }
            }
        }
    }

    private fun getOrCreateRenderer(filePath: String): Pair<ParcelFileDescriptor, PdfRenderer> {
        val cached = openRenderers[filePath]
        if (cached != null) return cached

        val file = File(filePath)
        if (!file.exists()) {
            throw java.io.FileNotFoundException("PDF file not found: $filePath")
        }

        val fd = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
        val renderer = PdfRenderer(fd)
        val pair = Pair(fd, renderer)
        openRenderers[filePath] = pair
        return pair
    }
}
