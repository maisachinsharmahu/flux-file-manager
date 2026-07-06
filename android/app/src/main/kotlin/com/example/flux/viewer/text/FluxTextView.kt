package com.example.flux.viewer.text

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.View
import com.example.flux.viewer.MmapSource
import io.flutter.plugin.platform.PlatformView

/**
 * FluxTextView — high performance native canvas-based text and code renderer.
 *
 * Renders lines on-demand using LineIndex offsets and draws syntax highlighted text runs.
 * Prevents memory overflows (OOM) on massive files by only processing the viewport lines.
 *
 * Rules (doc2, Ch. 2):
 *   - Fast responsive scrolling via custom canvas offset matrices.
 *   - Hardware-accelerated drawing.
 */
class FluxTextView(
    context: Context,
    viewId: Int,
    creationParams: Map<String, Any>?
) : PlatformView, View(context), GestureDetector.OnGestureListener {

    private val sourcePath = creationParams?.get("path") as? String
        ?: throw IllegalArgumentException("Missing file path parameter")
    private val formatName = creationParams?.get("format") as? String ?: "plain_text"

    private val mmapSource = MmapSource(java.io.File(sourcePath))
    private val lineIndex = LineIndex(mmapSource)

    // ── Drawing Paint parameters ─────────────────────────────────────────────

    private val textPaint = Paint().apply {
        color = Color.parseColor("#D4D4D4")
        textSize = spToPx(14f)
        isAntiAlias = true
        typeface = android.graphics.Typeface.MONOSPACE
    }

    private val gutterPaint = Paint().apply {
        color = Color.parseColor("#858585")
        textSize = spToPx(12f)
        isAntiAlias = true
        typeface = android.graphics.Typeface.MONOSPACE
        textAlign = Paint.Align.RIGHT
    }

    private val dividerPaint = Paint().apply {
        color = Color.parseColor("#2B2B2B")
        strokeWidth = dpToPx(1f)
    }

    private val bgPaint = Paint().apply { color = Color.parseColor("#1E1E1E") }
    private val gutterBgPaint = Paint().apply { color = Color.parseColor("#181818") }

    // Line heights calculations
    private val fontMetrics = textPaint.fontMetrics
    private val lineHeight = fontMetrics.bottom - fontMetrics.top + dpToPx(4f)
    private val textBaselineOffset = -fontMetrics.top

    // Scroll Coordinates
    private var scrollYOffset = 0f
    private var scrollXOffset = 0f

    private val gestureDetector = GestureDetector(context, this)

    private var viewW = 0
    private var viewH = 0

    // Gutter column width parameters
    private val gutterPadding = dpToPx(8f)
    private var gutterWidth = dpToPx(44f)

    init {
        // Adapt gutter width to fit line counts
        val maxDigits = lineIndex.lineCount.toString().length
        val digitWidth = gutterPaint.measureText("9")
        gutterWidth = maxDigits * digitWidth + gutterPadding * 2f
    }

    // ── PlatformView implementation ──────────────────────────────────────────

    override fun getView(): View = this

    override fun dispose() {
        mmapSource.close()
    }

    // ── Layout & Drawing ─────────────────────────────────────────────────────

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        viewW = w
        viewH = h
    }

    override fun onDraw(canvas: Canvas) {
        // Draw main editor background
        canvas.drawRect(0f, 0f, viewW.toFloat(), viewH.toFloat(), bgPaint)

        val totalLines = lineIndex.lineCount
        if (totalLines <= 0) return

        // 1. Calculate visible range boundaries
        val firstLine = (scrollYOffset / lineHeight).toInt().coerceIn(0, totalLines - 1)
        val lastLine = ((scrollYOffset + viewH) / lineHeight).toInt().coerceIn(0, totalLines - 1)

        val startY = firstLine * lineHeight - scrollYOffset

        // 2. Render Gutter backgrounds
        canvas.drawRect(0f, 0f, gutterWidth, viewH.toFloat(), gutterBgPaint)
        canvas.drawLine(gutterWidth, 0f, gutterWidth, viewH.toFloat(), dividerPaint)

        // 3. Draw text and line numbers gutter loop
        for (i in firstLine..lastLine) {
            val lineY = startY + (i - firstLine) * lineHeight
            val baseline = lineY + textBaselineOffset

            // Draw line numbers
            val lineNumStr = (i + 1).toString()
            canvas.drawText(lineNumStr, gutterWidth - gutterPadding, baseline, gutterPaint)

            // Draw line text segments
            canvas.save()
            // Clip drawing to avoid overlapping the gutter divider column
            canvas.clipRect(gutterWidth + dpToPx(4f), 0f, viewW.toFloat(), viewH.toFloat())
            
            val lineText = lineIndex.getLineText(i)
            val highlightedRuns = SyntaxHighlighter.highlight(lineText, formatName)

            var currentX = gutterWidth + dpToPx(8f) - scrollXOffset
            for (run in highlightedRuns) {
                textPaint.color = run.color
                canvas.drawText(run.text, currentX, baseline, textPaint)
                currentX += textPaint.measureText(run.text)
            }
            canvas.restore()
        }
    }

    // ── Touch Gestures ───────────────────────────────────────────────────────

    override fun onTouchEvent(event: MotionEvent): Boolean {
        return gestureDetector.onTouchEvent(event) || super.onTouchEvent(event)
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
        // Drag scrolling: update offsets
        scrollYOffset += distanceY
        scrollXOffset += distanceX

        // Limit scrolling bounds
        val maxScrollY = (lineIndex.lineCount * lineHeight - viewH).coerceAtLeast(0f)
        scrollYOffset = scrollYOffset.coerceIn(0f, maxScrollY)

        // Horizontal scroll boundaries
        scrollXOffset = scrollXOffset.coerceAtLeast(0f)
        // Set dynamic limit for horizontal scrolling if needed
        val maxScrollX = dpToPx(1000f) // arbitrary ceiling for long code lines
        scrollXOffset = scrollXOffset.coerceAtMost(maxScrollX)

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

    // ── Helper Dimensions Converter ──────────────────────────────────────────

    private fun dpToPx(dp: Float): Float {
        return dp * resources.displayMetrics.density
    }

    private fun spToPx(sp: Float): Float {
        return sp * resources.displayMetrics.scaledDensity
    }
}
