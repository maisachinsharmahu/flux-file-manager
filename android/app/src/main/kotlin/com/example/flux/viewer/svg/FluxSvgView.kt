package com.example.flux.viewer.svg

import android.content.Context
import android.graphics.*
import android.view.View
import androidx.core.graphics.PathParser
import io.flutter.plugin.platform.PlatformView
import org.xmlpull.v1.XmlPullParser
import org.xmlpull.v1.XmlPullParserFactory
import java.io.File
import java.io.FileInputStream

class FluxSvgView(context: Context, filePath: String) : PlatformView {

    private val view: View = SvgCanvasView(context, filePath)

    override fun getView(): View {
        return view
    }

    override fun dispose() {}

    private class SvgCanvasView(context: Context, filePath: String) : View(context) {

        private val paths = ArrayList<SvgPath>()
        private var viewBox = RectF(0f, 0f, 100f, 100f)

        data class SvgPath(
            val path: Path,
            val fill: Int?,
            val stroke: Int?,
            val strokeWidth: Float
        )

        init {
            parseSvg(filePath)
        }

        private fun parseSvg(path: String) {
            val file = File(path)
            if (!file.exists()) return

            try {
                val factory = XmlPullParserFactory.newInstance()
                val parser = factory.newPullParser()
                FileInputStream(file).use { stream ->
                    parser.setInput(stream, "UTF-8")
                    var event = parser.eventType
                    while (event != XmlPullParser.END_DOCUMENT) {
                        if (event == XmlPullParser.START_TAG) {
                            when (parser.name) {
                                "svg" -> {
                                    parser.getAttributeValue(null, "viewBox")?.let { vb ->
                                        val parts = vb.trim().split(Regex("\\s+"))
                                        if (parts.size == 4) {
                                            viewBox = RectF(
                                                parts[0].toFloatOrNull() ?: 0f,
                                                parts[1].toFloatOrNull() ?: 0f,
                                                parts[2].toFloatOrNull() ?: 100f,
                                                parts[3].toFloatOrNull() ?: 100f
                                            )
                                        }
                                    }
                                }
                                "rect" -> {
                                    val x = parser.getAttributeValue(null, "x")?.toFloatOrNull() ?: 0f
                                    val y = parser.getAttributeValue(null, "y")?.toFloatOrNull() ?: 0f
                                    val w = parser.getAttributeValue(null, "width")?.toFloatOrNull() ?: 0f
                                    val h = parser.getAttributeValue(null, "height")?.toFloatOrNull() ?: 0f
                                    val rx = parser.getAttributeValue(null, "rx")?.toFloatOrNull() ?: 0f
                                    
                                    val fill = parseColor(parser.getAttributeValue(null, "fill"))
                                    val stroke = parseColor(parser.getAttributeValue(null, "stroke"))
                                    val sw = parser.getAttributeValue(null, "stroke-width")?.toFloatOrNull() ?: 1f

                                    val p = Path().apply {
                                        addRoundRect(RectF(x, y, x + w, y + h), rx, rx, Path.Direction.CW)
                                    }
                                    paths.add(SvgPath(p, fill, stroke, sw))
                                }
                                "circle" -> {
                                    val cx = parser.getAttributeValue(null, "cx")?.toFloatOrNull() ?: 0f
                                    val cy = parser.getAttributeValue(null, "cy")?.toFloatOrNull() ?: 0f
                                    val r = parser.getAttributeValue(null, "r")?.toFloatOrNull() ?: 0f
                                    
                                    val fill = parseColor(parser.getAttributeValue(null, "fill"))
                                    val stroke = parseColor(parser.getAttributeValue(null, "stroke"))
                                    val sw = parser.getAttributeValue(null, "stroke-width")?.toFloatOrNull() ?: 1f

                                    val p = Path().apply {
                                        addCircle(cx, cy, r, Path.Direction.CW)
                                    }
                                    paths.add(SvgPath(p, fill, stroke, sw))
                                }
                                "path" -> {
                                    val d = parser.getAttributeValue(null, "d") ?: ""
                                    val fill = parseColor(parser.getAttributeValue(null, "fill"))
                                    val stroke = parseColor(parser.getAttributeValue(null, "stroke"))
                                    val sw = parser.getAttributeValue(null, "stroke-width")?.toFloatOrNull() ?: 1f

                                    try {
                                        val p = PathParser.createPathFromPathData(d)
                                        paths.add(SvgPath(p, fill, stroke, sw))
                                    } catch (e: Exception) {
                                        // Ignore malformed path syntax
                                    }
                                }
                            }
                        }
                        event = parser.next()
                    }
                }
            } catch (e: Exception) {
                // Ignore parse errors, will draw whatever was loaded
            }
        }

        private fun parseColor(colorStr: String?): Int? {
            if (colorStr == null || colorStr == "none" || colorStr.isEmpty()) return null
            if (colorStr.startsWith("#")) {
                return try {
                    Color.parseColor(colorStr)
                } catch (e: Exception) {
                    null
                }
            }
            // Basic colors map helper
            return when (colorStr.lowercase()) {
                "red" -> Color.RED
                "blue" -> Color.BLUE
                "green" -> Color.GREEN
                "black" -> Color.BLACK
                "white" -> Color.WHITE
                "yellow" -> Color.YELLOW
                "cyan" -> Color.CYAN
                "magenta" -> Color.MAGENTA
                "gray" -> Color.GRAY
                else -> null
            }
        }

        override fun onDraw(canvas: Canvas) {
            super.onDraw(canvas)
            if (paths.isEmpty()) return

            val scaleX = width.toFloat() / viewBox.width()
            val scaleY = height.toFloat() / viewBox.height()
            val scale = Math.min(scaleX, scaleY)

            val matrix = Matrix().apply {
                setScale(scale, scale)
                postTranslate(
                    (width - viewBox.width() * scale) / 2f - viewBox.left * scale,
                    (height - viewBox.height() * scale) / 2f - viewBox.top * scale
                )
            }

            val paint = Paint().apply {
                isAntiAlias = true
            }

            for (sp in paths) {
                val mapped = Path().apply {
                    sp.path.transform(matrix, this)
                }
                if (sp.fill != null) {
                    paint.style = Paint.Style.FILL
                    paint.color = sp.fill
                    canvas.drawPath(mapped, paint)
                }
                if (sp.stroke != null) {
                    paint.style = Paint.Style.STROKE
                    paint.color = sp.stroke
                    paint.strokeWidth = sp.strokeWidth * scale
                    canvas.drawPath(mapped, paint)
                }
            }
        }
    }
}
