package com.example.flux.viewer

import java.io.File
import java.io.FileInputStream
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel

/**
 * MmapSource — zero-copy memory-mapped file access.
 *
 * The OS loads pages on demand — we never read the whole file.
 * Every format parser in FLUX reads through this single abstraction.
 *
 * Rules (doc2, Ch. 16):
 *  - NEVER call File.readBytes() for files > 1MB — always use MmapSource
 *  - NEVER create a ByteArray of the full file
 *
 * Thread-safe for concurrent reads (MappedByteBuffer.duplicate() creates independent positions).
 */
class MmapSource(val file: File) : AutoCloseable {

    private val channel: FileChannel = FileInputStream(file).channel

    // Memory-map entire file — OS loads pages on demand
    private val buffer: MappedByteBuffer =
        channel.map(FileChannel.MapMode.READ_ONLY, 0, file.length())

    val size: Long = file.length()

    val path: String get() = file.absolutePath

    // ── Read primitives ─────────────────────────────────────────────────────

    /** Read bytes at absolute offset — O(1), zero-copy into new array */
    fun readBytes(offset: Long, length: Int): ByteArray {
        require(offset >= 0 && length >= 0 && offset + length <= size) {
            "readBytes out of bounds: offset=$offset length=$length size=$size"
        }
        val buf = ByteArray(length)
        val view = buffer.duplicate()  // independent position, same data
        view.position(offset.toInt())
        view.get(buf)
        return buf
    }

    /** Read a single byte — O(1) */
    fun readByte(offset: Long): Byte {
        require(offset in 0 until size)
        return buffer.get(offset.toInt())
    }

    /** Read little-endian Int32 at offset — O(1) */
    fun readInt32LE(offset: Long): Int {
        require(offset + 4 <= size)
        val b = buffer
        return (b.get(offset.toInt()).toInt() and 0xFF) or
               ((b.get((offset + 1).toInt()).toInt() and 0xFF) shl 8) or
               ((b.get((offset + 2).toInt()).toInt() and 0xFF) shl 16) or
               ((b.get((offset + 3).toInt()).toInt() and 0xFF) shl 24)
    }

    /** Read big-endian Int32 at offset — O(1) */
    fun readInt32BE(offset: Long): Int {
        require(offset + 4 <= size)
        val b = buffer
        return ((b.get(offset.toInt()).toInt() and 0xFF) shl 24) or
               ((b.get((offset + 1).toInt()).toInt() and 0xFF) shl 16) or
               ((b.get((offset + 2).toInt()).toInt() and 0xFF) shl 8) or
               (b.get((offset + 3).toInt()).toInt() and 0xFF)
    }

    /** Read bytes as ASCII string — for magic byte comparisons */
    fun readAscii(offset: Long, length: Int): String =
        String(readBytes(offset, length), Charsets.US_ASCII)

    /** Check if bytes at offset match the given ASCII prefix */
    fun startsWith(offset: Long, prefix: String): Boolean {
        if (offset + prefix.length > size) return false
        return prefix.indices.all { i ->
            buffer.get((offset + i).toInt()) == prefix[i].code.toByte()
        }
    }

    // ── Slicing ──────────────────────────────────────────────────────────────

    /**
     * Slice a region as an independent view — O(1), no copy.
     * Returns a new MappedByteBuffer positioned at offset with limit=length.
     */
    fun slice(offset: Long, length: Int): java.nio.ByteBuffer {
        require(offset >= 0 && length >= 0 && offset + length <= size)
        val view = buffer.duplicate()
        view.position(offset.toInt())
        val sliced = view.slice()
        sliced.limit(length)
        return sliced
    }

    // ── Scanning ─────────────────────────────────────────────────────────────

    /**
     * Scan for newline positions — returns IntArray of line-start byte offsets.
     * Used by LineIndex for text/code files.
     * Scans entire file in a single sequential pass.
     */
    fun scanNewlines(): IntArray {
        val estimated = (size / 40).toInt().coerceAtLeast(16)
        val offsets = ArrayList<Int>(estimated)
        offsets.add(0)  // line 0 starts at byte 0
        val view = buffer.duplicate()
        view.rewind()
        var i = 0
        while (view.hasRemaining()) {
            if (view.get() == '\n'.code.toByte()) {
                val next = i + 1
                if (next < size) offsets.add(next)
            }
            i++
        }
        return offsets.toIntArray()
    }

    /**
     * Find last occurrence of a byte sequence, scanning backward from the end.
     * Used by PDF engine to find startxref keyword.
     */
    fun findBackward(sequence: ByteArray, fromEnd: Int = 1024): Long {
        val scanStart = maxOf(0L, size - fromEnd)
        val view = buffer.duplicate()
        for (pos in (size - sequence.size) downTo scanStart) {
            var match = true
            for (j in sequence.indices) {
                if (buffer.get((pos + j).toInt()) != sequence[j]) {
                    match = false
                    break
                }
            }
            if (match) return pos
        }
        return -1L
    }

    // ── Lifecycle ────────────────────────────────────────────────────────────

    override fun close() {
        try {
            channel.close()
        } catch (_: Exception) { /* best-effort */ }
    }

    override fun toString() = "MmapSource(${file.name}, ${size}B)"
}
