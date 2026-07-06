package com.example.flux.viewer.image

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.BitmapRegionDecoder
import android.graphics.Rect
import android.os.Build
import com.example.flux.viewer.MmapSource
import com.example.flux.viewer.TileEngine
import java.io.InputStream

/**
 * ImageTileRenderer — decodes image regions on-demand into RGB_565 bitmaps.
 *
 * Implements TileEngine.TileRenderer.
 * Uses Android's built-in BitmapRegionDecoder to stream regions without loading the full image.
 *
 * Rules (doc2, Ch. 16):
 *   - NEVER use ARGB_8888 for photos/PDF tiles — use RGB_565 (50% RAM saving)
 *   - NEVER load the full image into memory if it is large — always tile
 */
class ImageTileRenderer(private val source: MmapSource) : TileEngine.TileRenderer, AutoCloseable {

    private var decoder: BitmapRegionDecoder? = null

    override var contentWidth: Int = 0
        private set

    override var contentHeight: Int = 0
        private set

    init {
        // Initialize BitmapRegionDecoder using a parcel file descriptor or stream
        val pfd = android.os.ParcelFileDescriptor.open(
            source.file,
            android.os.ParcelFileDescriptor.MODE_READ_ONLY
        )
        decoder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            BitmapRegionDecoder.newInstance(pfd)
        } else {
            @Suppress("DEPRECATION")
            BitmapRegionDecoder.newInstance(source.file.absolutePath, false)
        }
        pfd.close()

        contentWidth = decoder?.width ?: 0
        contentHeight = decoder?.height ?: 0
    }

    override fun renderTile(key: TileEngine.TileKey, tileW: Int, tileH: Int): Bitmap {
        val dec = decoder ?: throw IllegalStateException("Decoder recycled or not initialized")

        // Map tile key to source image coordinate rect
        val scale = TileEngine.zoomScale(key.zoomLevel)
        
        // Rect in content space at 1x scale
        val left = (key.col * tileW / scale).toInt()
        val top = (key.row * tileH / scale).toInt()
        val right = (((key.col + 1) * tileW) / scale).toInt().coerceAtMost(contentWidth)
        val bottom = (((key.row + 1) * tileH) / scale).toInt().coerceAtMost(contentHeight)

        val regionRect = Rect(left, top, right, bottom)

        val options = BitmapFactory.Options().apply {
            // Force RGB_565 to save 50% RAM (no transparency support, which photos don't need)
            inPreferredConfig = Bitmap.Config.RGB_565
            
            // Set scale factor
            // inSampleSize must be a power of 2
            val sampleSize = (1 / scale).toInt()
            inSampleSize = if (sampleSize > 1) {
                // Find next power of 2
                var p = 1
                while (p < sampleSize) p = p shl 1
                p
            } else {
                1
            }
        }

        return dec.decodeRegion(regionRect, options)
            ?: throw RuntimeException("Failed to decode region $regionRect")
    }

    override fun close() {
        decoder?.recycle()
        decoder = null
    }
}
