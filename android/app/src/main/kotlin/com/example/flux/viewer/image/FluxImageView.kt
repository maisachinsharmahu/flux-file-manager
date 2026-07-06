package com.example.flux.viewer.image

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Paint
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.ScaleGestureDetector
import android.view.View
import com.example.flux.viewer.MmapSource
import com.example.flux.viewer.TileEngine
import io.flutter.plugin.platform.PlatformView

/**
 * FluxImageView — native zoomable progressive tiled image view.
 *
 * Implements PlatformView so Flutter embeds it.
 * Uses custom matrices for pan & zoom and queries TileEngine for visible segments.
 *
 * Rules (doc2, Ch. 2):
 *   - Hardware-accelerated drawing.
 *   - Fast responsive gestures.
 */
class FluxImageView(
    context: Context,
    viewId: Int,
    creationParams: Map<String, Any>?
) : PlatformView, View(context), GestureDetector.OnGestureListener, GestureDetector.OnDoubleTapListener {

    private val sourcePath = creationParams?.get("path") as? String
        ?: throw IllegalArgumentException("Missing path parameter")

    private val mmapSource = MmapSource(java.io.File(sourcePath))
    private val renderer = ImageTileRenderer(mmapSource)
    private val tileEngine = TileEngine()

    // ── Gesture state ─────────────────────────────────────────────────────────

    private val transformMatrix = Matrix()
    private val inverseMatrix = Matrix()
    private val matrixValues = FloatArray(9)

    private val scaleGestureDetector = ScaleGestureDetector(context, ScaleListener())
    private val gestureDetector = GestureDetector(context, this)

    private val tilePaint = Paint(Paint.FILTER_BITMAP_FLAG)
    private val bgPaint = Paint().apply { color = Color.parseColor("#0F0F0F") }

    private var viewW = 0
    private var viewH = 0

    init {
        // Wire tile ready callback to repaint the view
        tileEngine.onTileReady = {
            postInvalidate()
        }
        gestureDetector.setOnDoubleTapListener(this)
    }

    // ── PlatformView implementation ──────────────────────────────────────────

    override fun getView(): View = this

    override fun dispose() {
        tileEngine.shutdown()
        tileEngine.evictAll()
        renderer.close()
        mmapSource.close()
    }

    // ── Layout & Drawing ─────────────────────────────────────────────────────

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        viewW = w
        viewH = h
        if (w > 0 && h > 0) {
            resetFitTranslation()
        }
    }

    /** Center the image and fit it inside screen dimensions initially */
    private fun resetFitTranslation() {
        val imgW = renderer.contentWidth.toFloat()
        val imgH = renderer.contentHeight.toFloat()
        if (imgW <= 0 || imgH <= 0) return

        val scaleX = viewW / imgW
        val scaleY = viewH / imgH
        val fitScale = minOf(scaleX, scaleY).coerceAtMost(1.0f)

        transformMatrix.reset()
        transformMatrix.postScale(fitScale, fitScale)

        val tx = (viewW - imgW * fitScale) / 2f
        val ty = (viewH - imgH * fitScale) / 2f
        transformMatrix.postTranslate(tx, ty)

        postInvalidate()
    }

    override fun onDraw(canvas: Canvas) {
        // Clear background
        canvas.drawRect(0f, 0f, viewW.toFloat(), viewH.toFloat(), bgPaint)

        val imgW = renderer.contentWidth
        val imgH = renderer.contentHeight
        if (imgW <= 0 || imgH <= 0) return

        canvas.save()
        // Apply zoom & pan translation to the canvas drawing operations
        canvas.concat(transformMatrix)

        // Calculate inverse matrix to project screen coordinates to image space
        transformMatrix.invert(inverseMatrix)

        // Get current scale factor
        transformMatrix.getValues(matrixValues)
        val currentScale = matrixValues[Matrix.MSCALE_X]

        // Map zoom level to TileEngine presets based on scale
        val zoomLevel = when {
            currentScale < 0.7f  -> TileEngine.ZOOM_THUMBNAIL
            currentScale < 1.5f  -> TileEngine.ZOOM_FIT
            currentScale < 3.0f  -> TileEngine.ZOOM_2X
            else                 -> TileEngine.ZOOM_4X
        }

        // Get viewport rect in screen pixels projected to image coordinates
        val screenPoints = floatArrayOf(
            0f, 0f,
            viewW.toFloat(), viewH.toFloat()
        )
        inverseMatrix.mapPoints(screenPoints)

        val left = screenPoints[0].coerceAtLeast(0f)
        val top = screenPoints[1].coerceAtLeast(0f)
        val right = screenPoints[2].coerceAtMost(imgW.toFloat())
        val bottom = screenPoints[3].coerceAtMost(imgH.toFloat())

        val viewport = TileEngine.Viewport(left, top, right, bottom)

        // Draw visible tiles
        val visibleKeys = tileEngine.tilesForViewport(viewport, zoomLevel)
        for (key in visibleKeys) {
            val tile = tileEngine.getTile(key, renderer)
            val bounds = tileEngine.tileBounds(key) // left, top, right, bottom

            if (tile != null) {
                // Draw tile at its bounds
                canvas.drawBitmap(tile.bitmap, bounds[0], bounds[1], tilePaint)
            } else {
                // Draw a simple grey loader placeholder while decoding
                canvas.drawRect(bounds[0], bounds[1], bounds[2], bounds[3], Paint().apply {
                    color = Color.parseColor("#1C1C1C")
                })
            }
        }

        // Trigger prefetch around current viewports asynchronously
        tileEngine.prefetchAround(visibleKeys, renderer)

        canvas.restore()
    }

    // ── Input Gestures ───────────────────────────────────────────────────────

    override fun onTouchEvent(event: MotionEvent): Boolean {
        var handled = scaleGestureDetector.onTouchEvent(event)
        handled = gestureDetector.onTouchEvent(event) || handled
        return handled || super.onTouchEvent(event)
    }

    private inner class ScaleListener : ScaleGestureDetector.SimpleOnScaleGestureListener() {
        override fun onScale(detector: ScaleGestureDetector): Boolean {
            val scaleFactor = detector.scaleFactor
            transformMatrix.postScale(scaleFactor, scaleFactor, detector.focusX, detector.focusY)
            constrainBounds()
            invalidate()
            return true
        }
    }

    override fun onDown(e: MotionEvent): Boolean = true

    override fun onShowPress(e: MotionEvent) {}

    override fun onSingleTapUp(e: MotionEvent): Boolean = false

    override fun onScroll(
        e1: MotionEvent?,
        e2: MotionEvent,
        distanceX: Float,
        distanceY: Float
    ): Boolean {
        // Drag-to-pan: translate by drag delta distance
        transformMatrix.postTranslate(-distanceX, -distanceY)
        constrainBounds()
        invalidate()
        return true
    }

    override fun onLongPress(e: MotionEvent) {}

    override fun onFling(
        e1: MotionEvent?,
        e2: MotionEvent,
        velocityX: Float,
        velocityY: Float
    ): Boolean = false

    override fun onSingleTapConfirmed(e: MotionEvent): Boolean = false

    override fun onDoubleTap(e: MotionEvent): Boolean {
        // Double tap zooms into 2x scale or resets back to fit view
        transformMatrix.getValues(matrixValues)
        val currentScale = matrixValues[Matrix.MSCALE_X]

        if (currentScale > 1.2f) {
            resetFitTranslation()
        } else {
            transformMatrix.postScale(2.5f / currentScale, 2.5f / currentScale, e.x, e.y)
            constrainBounds()
            invalidate()
        }
        return true
    }

    override fun onDoubleTapEvent(e: MotionEvent): Boolean = false

    /** Limit scale factor and keep image from being dragged off the viewport */
    private fun constrainBounds() {
        transformMatrix.getValues(matrixValues)
        val scale = matrixValues[Matrix.MSCALE_X]
        val tx = matrixValues[Matrix.MTRANS_X]
        val ty = matrixValues[Matrix.MTRANS_Y]

        val imgW = renderer.contentWidth * scale
        val imgH = renderer.contentHeight * scale

        // Max zoom 5.0x, min zoom 0.5x
        if (scale > 5.0f) {
            val s = 5.0f / scale
            transformMatrix.postScale(s, s)
        } else if (scale < 0.2f) {
            val s = 0.2f / scale
            transformMatrix.postScale(s, s)
        }

        // Limit translation coordinates
        var newTx = tx
        var newTy = ty

        if (imgW < viewW) {
            // Keep centered horizontally
            newTx = (viewW - imgW) / 2f
        } else {
            if (tx > 0) newTx = 0f
            if (tx < viewW - imgW) newTx = viewW - imgW
        }

        if (imgH < viewH) {
            // Keep centered vertically
            newTy = (viewH - imgH) / 2f
        } else {
            if (ty > 0) newTy = 0f
            if (ty < viewH - imgH) newTy = viewH - imgH
        }

        // Update translate delta directly
        matrixValues[Matrix.MTRANS_X] = newTx
        matrixValues[Matrix.MTRANS_Y] = newTy
        transformMatrix.setValues(matrixValues)
    }
}
