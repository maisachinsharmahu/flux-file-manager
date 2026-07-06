package com.example.flux.viewer

import android.graphics.Bitmap
import android.util.LruCache
import java.util.concurrent.Executors

/**
 * TileEngine — universal 512×512 tile management.
 *
 * Every format — PDF pages, spreadsheet grids, long text files, large images —
 * is decomposed into tiles. Only tiles intersecting the current viewport are rendered.
 *
 * Rules (doc2, Ch. 2):
 *   - NEVER create Bitmap > 2048×2048 in a single allocation — always tile
 *   - NEVER use ARGB_8888 for photos/PDF tiles — use RGB_565 (50% RAM saving)
 *   - NEVER do tile generation on the main thread — always on Dispatchers.Default
 *
 * Source: doc2, Ch. 2, TileEngine listing.
 */
class TileEngine(
    val tileW: Int = 512,
    val tileH: Int = 512,
    maxCacheMB: Int = 40,
) {
    // ── Tile types ────────────────────────────────────────────────────────────

    data class TileKey(
        val row: Int,
        val col: Int,
        val zoomLevel: Int,  // 0=thumb 0.5x, 1=fit 1x, 2=zoom 2x, 3=zoom 4x
    )

    data class Tile(
        val key: TileKey,
        val bitmap: Bitmap,
        val renderedAt: Long = System.currentTimeMillis(),
    )

    data class Viewport(
        val left: Float,
        val top: Float,
        val right: Float,
        val bottom: Float,
    ) {
        val width: Float get() = right - left
        val height: Float get() = bottom - top
    }

    // ── Interface every format implements ─────────────────────────────────────

    interface TileRenderer {
        /** Render one tile. MUST run on background thread. Returns RGB_565 bitmap. */
        fun renderTile(key: TileKey, tileW: Int, tileH: Int): Bitmap

        /** Total content width in pixels at zoom level 1 */
        val contentWidth: Int

        /** Total content height in pixels at zoom level 1 */
        val contentHeight: Int
    }

    // ── LRU cache keyed by TileKey ────────────────────────────────────────────

    private val cache = object : LruCache<TileKey, Tile>(maxCacheMB * 1024 * 1024) {
        override fun sizeOf(key: TileKey, value: Tile): Int = value.bitmap.byteCount
    }

    // ── Background render thread pool ─────────────────────────────────────────

    private val renderPool = Executors.newFixedThreadPool(
        (Runtime.getRuntime().availableProcessors()).coerceIn(2, 4)
    )

    // Track in-flight renders to avoid duplicate work
    private val inFlight = java.util.Collections.newSetFromMap(
        java.util.concurrent.ConcurrentHashMap<TileKey, Boolean>()
    )

    /** Called when a tile is ready — implementor should invalidate the view region */
    var onTileReady: ((Tile) -> Unit)? = null

    // ── Public API ────────────────────────────────────────────────────────────

    /**
     * Request a tile. Returns cached tile immediately, or null (triggers async render).
     * Caller should show a placeholder when null is returned.
     */
    fun getTile(key: TileKey, renderer: TileRenderer): Tile? {
        cache.get(key)?.let { return it }  // cache hit O(1)

        // Cache miss: submit to background pool (avoid duplicate submits)
        if (inFlight.add(key)) {
            renderPool.submit {
                try {
                    val bitmap = renderer.renderTile(key, tileW, tileH)
                    val tile   = Tile(key, bitmap)
                    cache.put(key, tile)
                    onTileReady?.invoke(tile)
                } catch (e: OutOfMemoryError) {
                    // Graceful OOM: evict half the cache and retry next frame
                    cache.trimToSize(cache.maxSize() / 2)
                    android.util.Log.w("TileEngine", "OOM while rendering tile $key, cache trimmed")
                } catch (e: Exception) {
                    android.util.Log.e("TileEngine", "Tile render error for $key: ${e.message}")
                } finally {
                    inFlight.remove(key)
                }
            }
        }
        return null
    }

    /**
     * Returns all TileKeys that intersect the given viewport.
     * O(visible_tiles) — typically a small constant.
     */
    fun tilesForViewport(viewport: Viewport, zoomLevel: Int): List<TileKey> {
        val scaledTileW = tileW.toFloat()
        val scaledTileH = tileH.toFloat()

        val startCol = (viewport.left / scaledTileW).toInt().coerceAtLeast(0)
        val endCol   = (viewport.right / scaledTileW).toInt()
        val startRow = (viewport.top / scaledTileH).toInt().coerceAtLeast(0)
        val endRow   = (viewport.bottom / scaledTileH).toInt()

        val keys = mutableListOf<TileKey>()
        for (row in startRow..endRow) {
            for (col in startCol..endCol) {
                keys.add(TileKey(row, col, zoomLevel))
            }
        }
        return keys
    }

    /**
     * Prefetch tiles around the current viewport (one tile border).
     * Call after tilesForViewport() — extends prefetch window.
     */
    fun prefetchAround(visibleKeys: List<TileKey>, renderer: TileRenderer) {
        val extended = mutableSetOf<TileKey>()
        for (key in visibleKeys) {
            // One tile in each direction
            extended.add(key.copy(row = key.row - 1))
            extended.add(key.copy(row = key.row + 1))
            extended.add(key.copy(col = key.col - 1))
            extended.add(key.copy(col = key.col + 1))
        }
        // Request without blocking — cache miss silently triggers background render
        for (key in extended - visibleKeys.toSet()) {
            if (key.row >= 0 && key.col >= 0) {
                getTile(key, renderer)
            }
        }
    }

    /** Evict all tiles for a specific zoom level (e.g., when zoom changes) */
    fun evictZoomLevel(zoomLevel: Int) {
        // LruCache doesn't support batch eviction by predicate, so we track manually
        // For now, we rely on LRU to evict old zoom tiles naturally
        // A more efficient approach would maintain a zoom→keySet index
    }

    /** Evict entire cache (e.g., when file changes or renderer is released) */
    fun evictAll() {
        cache.evictAll()
    }

    /**
     * Compute the pixel boundaries of a tile within the content space.
     * Returns (left, top, right, bottom) in content pixels.
     */
    fun tileBounds(key: TileKey): FloatArray {
        val left   = key.col * tileW.toFloat()
        val top    = key.row * tileH.toFloat()
        val right  = left + tileW
        val bottom = top  + tileH
        return floatArrayOf(left, top, right, bottom)
    }

    fun shutdown() {
        renderPool.shutdown()
    }

    // ── Zoom level utilities ──────────────────────────────────────────────────

    companion object {
        const val ZOOM_THUMBNAIL = 0  // 0.5x
        const val ZOOM_FIT       = 1  // 1.0x (fit-width)
        const val ZOOM_2X        = 2  // 2.0x
        const val ZOOM_4X        = 3  // 4.0x

        fun zoomScale(level: Int): Float = when (level) {
            ZOOM_THUMBNAIL -> 0.5f
            ZOOM_FIT       -> 1.0f
            ZOOM_2X        -> 2.0f
            ZOOM_4X        -> 4.0f
            else           -> 1.0f
        }
    }
}
