package com.example.flux.viewer.text

import com.example.flux.viewer.MmapSource
import java.nio.charset.StandardCharsets

/**
 * LineIndex — maps newline byte offsets to support O(1) line bounds retrieval.
 *
 * Pre-computes all line starts inside a single-pass scan.
 * Extracts line text using zero-copy memory slices (no full file loading, Rule 2).
 */
class LineIndex(private val source: MmapSource) {

    // Store line byte start offsets
    private val offsets = source.scanNewlines()

    /** Total count of lines in the file */
    val lineCount: Int
        get() = offsets.size

    /**
     * Fetch line string by decoding mapped buffer bytes.
     * Keeps memory footprint close to zero by only slicing the requested range.
     */
    fun getLineText(lineNum: Int): String {
        if (lineNum < 0 || lineNum >= offsets.size) return ""

        val start = offsets[lineNum].toLong()
        val end = if (lineNum + 1 < offsets.size) {
            offsets[lineNum + 1].toLong()
        } else {
            source.size
        }

        // Calculate size without trailing newline characters (\r or \n)
        var length = (end - start).toInt()
        if (length <= 0) return ""

        // Slice the buffer region
        val sliceBuffer = source.slice(start, length)
        val bytes = ByteArray(length)
        sliceBuffer.get(bytes)

        // Trim carriage return or trailing newline
        var actualLength = length
        while (actualLength > 0 && (bytes[actualLength - 1] == '\n'.code.toByte() || bytes[actualLength - 1] == '\r'.code.toByte())) {
            actualLength--
        }

        return String(bytes, 0, actualLength, StandardCharsets.UTF_8)
    }
}
