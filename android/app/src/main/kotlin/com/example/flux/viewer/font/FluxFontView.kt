package com.example.flux.viewer.font

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import android.view.View
import io.flutter.plugin.platform.PlatformView
import java.io.File

class FluxFontView(context: Context, filePath: String) : PlatformView {

    private val view: View = FontPreviewCanvasView(context, filePath)

    override fun getView(): View {
        return view
    }

    override fun dispose() {}

    private class FontPreviewCanvasView(context: Context, filePath: String) : View(context) {

        private var typeface: Typeface? = null

        init {
            val file = File(filePath)
            if (file.exists()) {
                try {
                    typeface = Typeface.createFromFile(file)
                } catch (e: Exception) {
                    // Fail gracefully
                }
            }
        }

        override fun onDraw(canvas: Canvas) {
            super.onDraw(canvas)
            val tf = typeface ?: return

            val paint = Paint().apply {
                isAntiAlias = true
                this.typeface = tf
            }

            val previews = listOf(
                Pair(44f, "Aa Bb Cc"),
                Pair(26f, "ABCDEFGHIJKLMNOPQRSTUVWXYZ"),
                Pair(22f, "abcdefghijklmnopqrstuvwxyz"),
                Pair(20f, "0123456789 !@#\$%^&*()"),
                Pair(16f, "The quick brown fox jumps over the lazy dog.")
            )

            var y = 80f
            // We use standard light colors for texts and dark background context
            canvas.drawColor(0xFF0F0F0F.toInt())

            for ((size, text) in previews) {
                paint.textSize = size
                paint.color = 0xFFEEEEEE.toInt()
                canvas.drawText(text, 36f, y, paint)
                y += size * 1.8f
            }
        }
    }
}
