package com.example.flux.viewer.data

import com.example.flux.viewer.MmapSource
import com.example.flux.viewer.text.LineIndex
import java.io.File

/**
 * CsvParser — high performance line-indexed CSV browser.
 *
 * Reuses MmapSource and LineIndex to scan and read CSV row lines instantly
 * with zero-copy region slicing (no full file loading, Rule 2).
 */
object CsvParser {

    private val sourceCache = HashMap<String, MmapSource>()
    private val indexCache = HashMap<String, LineIndex>()

    private fun getOrCreateSource(filePath: String): Pair<MmapSource, LineIndex> {
        val cachedIndex = indexCache[filePath]
        val cachedSource = sourceCache[filePath]
        if (cachedIndex != null && cachedSource != null) {
            return Pair(cachedSource, cachedIndex)
        }

        val source = MmapSource(File(filePath))
        val index = LineIndex(source)
        sourceCache[filePath] = source
        indexCache[filePath] = index
        return Pair(source, index)
    }

    /**
     * Clear index and source cache of a CSV file to release mapped byte buffers.
     */
    fun closeCsv(filePath: String) {
        indexCache.remove(filePath)
        sourceCache.remove(filePath)?.close()
    }

    /**
     * Retrieve CSV headers and row count.
     * Returns: {"rowCount": 100, "headers":["col1", "col2"]}
     */
    fun getCsvMetadata(filePath: String): String {
        val file = File(filePath)
        if (!file.exists()) return "{}"

        val (_, index) = getOrCreateSource(filePath)
        val rowCount = index.lineCount
        if (rowCount == 0) return """{"rowCount":0,"headers":[]}"""

        // Load row 0 (headers)
        val headerCells = getCsvRowCells(filePath, 0)
        val headersStr = headerCells.joinToString(",") { "\"${escapeJson(it)}\"" }

        return """{"rowCount":$rowCount,"headers":[$headersStr]}"""
    }

    /**
     * Get paginated CSV row data list.
     * Returns: [ ["cell1", "cell2"], ["cell1", "cell2"] ]
     */
    fun getCsvRows(filePath: String, offset: Int, limit: Int): String {
        val (_, index) = getOrCreateSource(filePath)
        val rowCount = index.lineCount
        val end = Math.min(offset + limit, rowCount)

        val rowsJson = ArrayList<String>()
        for (i in offset until end) {
            val cells = getCsvRowCells(filePath, i)
            val cellsStr = cells.joinToString(",") { "\"${escapeJson(it)}\"" }
            rowsJson.add("[$cellsStr]")
        }

        return "[${rowsJson.joinToString(",")}]"
    }

    private fun getCsvRowCells(filePath: String, rowIndex: Int): List<String> {
        val (_, index) = getOrCreateSource(filePath)
        val rawLine = index.getLineText(rowIndex)
        if (rawLine.isEmpty()) return emptyList()

        val cells = ArrayList<String>()
        // Parse columns respecting double quotes RFC 4180
        var inQuotes = false
        var sb = StringBuilder()
        var idx = 0
        while (idx < rawLine.length) {
            val c = rawLine[idx]
            if (c == '"') {
                // Check double quotes escape: "" inside quotes -> literal double quote character
                if (inQuotes && idx + 1 < rawLine.length && rawLine[idx + 1] == '"') {
                    sb.append('"')
                    idx++ // Skip escaped quote
                } else {
                    inQuotes = !inQuotes // Toggle quote state
                }
            } else if (c == ',' && !inQuotes) {
                cells.add(sb.toString())
                sb = StringBuilder()
            } else {
                sb.append(c)
            }
            idx++
        }
        cells.add(sb.toString())

        return cells
    }

    private fun escapeJson(str: String): String {
        return str.replace("\\", "\\\\")
            .replace("\"", "\\\"")
            .replace("\n", "\\n")
            .replace("\r", "\\r")
            .replace("\t", "\\t")
    }
}
