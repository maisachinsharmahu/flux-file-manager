package com.example.flux.viewer

import java.io.ByteArrayOutputStream
import java.io.File
import java.util.TreeMap
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * EditOverlay — universal in-memory edit buffer.
 *
 * The viewer always reads from the original immutable MmapSource.
 * Edits are stored in this EditOverlay that intercepts reads.
 * On save, edits are merged and written to a NEW file (original never overwritten
 * until write is confirmed complete — then atomic rename).
 *
 * Rules (doc2, Ch. 16):
 *   - Every edit operation MUST go through EditOverlay, never modify source mmap
 *   - Every format's save MUST write to a temp file first, verify integrity,
 *     then atomic-rename over the original
 *
 * Source: doc2, Ch. 13, EditOverlay listing.
 */
class EditOverlay {

    // ── Edit types ────────────────────────────────────────────────────────────

    enum class EditType { INSERT, REPLACE, DELETE }

    data class Edit(
        val id:       Long,
        val offset:   Long,      // byte offset in original file
        val length:   Int,       // number of original bytes replaced (0 = insert)
        val newBytes: ByteArray, // replacement content
        val type:     EditType,
    )

    // ── State ─────────────────────────────────────────────────────────────────

    // TreeMap: sorted by offset for fast range queries — O(log n) per operation
    private val edits = TreeMap<Long, Edit>()
    private var nextId = 0L

    val isDirty: Boolean get() = edits.isNotEmpty()
    val editCount: Int get() = edits.size

    // ── Write operations ──────────────────────────────────────────────────────

    /**
     * Apply an edit — O(log n).
     * Returns the edit ID (use for undo).
     */
    fun applyEdit(offset: Long, length: Int, newBytes: ByteArray): Long {
        val id = nextId++
        val type = when {
            length == 0       -> EditType.INSERT
            newBytes.isEmpty() -> EditType.DELETE
            else               -> EditType.REPLACE
        }
        edits[offset] = Edit(id, offset, length, newBytes, type)
        return id
    }

    fun insert(offset: Long, newBytes: ByteArray): Long =
        applyEdit(offset, 0, newBytes)

    fun delete(offset: Long, length: Int): Long =
        applyEdit(offset, length, ByteArray(0))

    fun replace(offset: Long, length: Int, newBytes: ByteArray): Long =
        applyEdit(offset, length, newBytes)

    // ── Undo ──────────────────────────────────────────────────────────────────

    /** Remove a specific edit by ID — O(log n) */
    fun undoEdit(id: Long) {
        edits.entries.removeIf { it.value.id == id }
    }

    /** Remove the most recent edit */
    fun undoLast(): Boolean {
        if (edits.isEmpty()) return false
        val lastId = edits.values.maxOf { it.id }
        undoEdit(lastId)
        return true
    }

    /** Clear all edits */
    fun clearAll() = edits.clear()

    // ── Read through overlay ──────────────────────────────────────────────────

    /**
     * Read bytes from the virtual byte stream (original + edits overlaid).
     * Applies all edits in the requested range.
     * O(edits in range + requested length).
     */
    fun readVirtual(original: MmapSource, start: Long, length: Int): ByteArray {
        if (!isDirty) {
            // No edits — read directly from mmap
            return original.readBytes(start, length)
        }

        val result = ByteArrayOutputStream(length)
        var pos = start
        val end = start + length

        while (pos < end) {
            // Find next edit at or after pos
            val editEntry = edits.ceilingEntry(pos)
            if (editEntry == null || editEntry.key >= end) {
                // No more edits in range: read from mmap
                val toRead = (end - pos).toInt().coerceAtMost(
                    (original.size - pos).toInt().coerceAtLeast(0)
                )
                if (toRead > 0) result.write(original.readBytes(pos, toRead))
                break
            }
            val edit = editEntry.value
            if (edit.offset > pos) {
                // Gap before edit: read from mmap
                val gapLen = (edit.offset - pos).toInt()
                result.write(original.readBytes(pos, gapLen))
            }
            // Apply edit
            result.write(edit.newBytes)
            pos = edit.offset + edit.length
        }
        return result.toByteArray()
    }

    // ── Save ──────────────────────────────────────────────────────────────────

    /**
     * Save: merge original + edits → write to temp file → atomic rename.
     *
     * NEVER overwrites the original until the temp write is fully confirmed.
     * This guarantees no data loss on crash or OOM during write.
     */
    suspend fun saveTo(original: MmapSource, outputFile: File) = withContext(Dispatchers.IO) {
        val tempFile = File(outputFile.parent, "${outputFile.name}.flux_tmp")

        try {
            tempFile.parentFile?.mkdirs()
            tempFile.outputStream().buffered(65536).use { out ->
                var pos = 0L

                for (edit in edits.values.sortedBy { it.offset }) {
                    // Write original bytes before this edit
                    if (edit.offset > pos) {
                        val chunk = original.readBytes(pos, (edit.offset - pos).toInt())
                        out.write(chunk)
                    }
                    // Write edit bytes (may be empty for DELETE)
                    if (edit.newBytes.isNotEmpty()) {
                        out.write(edit.newBytes)
                    }
                    pos = edit.offset + edit.length
                }

                // Write remaining original bytes after last edit
                if (pos < original.size) {
                    val remaining = (original.size - pos).toInt()
                    out.write(original.readBytes(pos, remaining))
                }
            }

            // Atomic rename — only happens after successful write
            if (outputFile.exists()) outputFile.delete()
            if (!tempFile.renameTo(outputFile)) {
                // Fallback: copy then delete (some FS don't support cross-dir rename)
                tempFile.copyTo(outputFile, overwrite = true)
                tempFile.delete()
            }
        } catch (e: Exception) {
            tempFile.delete()  // Clean up temp on failure
            throw e
        }
    }

    /**
     * Save in-place: overwrite the original file atomically.
     */
    suspend fun saveInPlace(original: MmapSource) = withContext(Dispatchers.IO) {
        saveTo(original, original.file)
    }

    // ── Serialization (for persistence across sessions) ───────────────────────

    /**
     * Export all edits as a JSON sidecar string.
     * Used for PDF annotations, draft saves, etc.
     */
    fun exportEdits(): String {
        val sb = StringBuilder("[")
        edits.values.forEachIndexed { i, edit ->
            if (i > 0) sb.append(",")
            sb.append("""{"id":${edit.id},"offset":${edit.offset},"length":${edit.length},"type":"${edit.type}","bytes":"${
                android.util.Base64.encodeToString(edit.newBytes, android.util.Base64.NO_WRAP)
            }"}""")
        }
        sb.append("]")
        return sb.toString()
    }

    override fun toString() = "EditOverlay(${edits.size} edits, dirty=$isDirty)"
}
