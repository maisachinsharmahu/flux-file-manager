package com.example.flux.viewer.pdf

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.view.View
import io.flutter.plugin.platform.PlatformView

/**
 * FluxPdfPageView — custom view rendering a single PDF page bitmap.
 *
 * Implements PlatformView and triggers PdfRenderService background decoder.
 * Uses hardware accelerated rendering paths.
 */
class FluxPdfPageView(
    context: Context,
    viewId: Int,
    creationParams: Map<String, Any>?
) : PlatformView, View(context) {

    private val sourcePath = creationParams?.get("path") as? String
        ?: throw IllegalArgumentException("Missing path parameter")
    private val pageIndex = creationParams?.get("pageIndex") as? Int ?: 0
    private val scale = (creationParams?.get("scale") as? Double ?: 1.0).toFloat()

    private var pageBitmap: Bitmap? = null
    private val bitmapPaint = Paint(Paint.FILTER_BITMAP_FLAG)

    init {
        // Trigger pre-render / render
        loadPageBitmap()
    }

    private fun loadPageBitmap() {
        // Run rendering asynchronously to avoid blocking UI thread
        java.util.concurrent.ForkJoinPool.commonPool().execute {
            val bitmap = PdfRenderService.renderPage(sourcePath, pageIndex, scale)
            if (bitmap != null) {
                pageBitmap = bitmap
                postInvalidate()
            }
        }
    }

    // ── PlatformView ──────────────────────────────────────────────────────────

    override fun getView(): View = this

    override fun dispose() {
        // Note: do not close PDF immediately here, since sibling page views 
        // may still be active. Let PdfRenderService handle release on complete dismiss.
        pageBitmap = null
    }

    // ── Layout & Drawing ─────────────────────────────────────────────────────

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val bitmap = pageBitmap
        if (bitmap != null) {
            // Draw centered bitmap on the view surface
            val left = (width - bitmap.width) / 2f
            val top = (height - bitmap.height) / 2f
            canvas.drawBitmap(bitmap, left, top, bitmapPaint)
        } else {
            // Loading placeholder background
            canvas.drawColor(android.graphics.Color.WHITE)
        }
    }
}
