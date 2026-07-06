package com.example.flux.viewer.office

import android.util.Xml
import org.xmlpull.v1.XmlPullParser
import java.io.InputStream
import java.util.zip.ZipFile
import java.util.zip.ZipEntry

/**
 * OfficeParser — lightweight zero-dependency XML parser for DOCX, XLSX, and PPTX formats.
 *
 * Directly unzips OpenXML packages and streams content through Android's fast native XmlPullParser.
 * Avoids 20MB+ library overhead of Apache POI/Docx4j to prevent application bloat (Rule 3).
 */
object OfficeParser {

    /**
     * Parse DOCX paragraphs and tables.
     * Returns a JSON representation: [ {"type":"p", "align":"...", "runs":[ {"text":"...", "b":true...} ]}, {"type":"table", "rows":[ [ {"runs":[]} ] ]} ]
     */
    fun parseDocx(filePath: String): String {
        val zip = ZipFile(filePath)
        val entry = zip.getEntry("word/document.xml") ?: return "[]"
        
        val list = ArrayList<String>()
        val parser = Xml.newPullParser()
        parser.setInput(zip.getInputStream(entry), "UTF-8")

        var eventType = parser.eventType
        var currentParagraphRuns = ArrayList<String>()
        var currentParagraphAlign: String? = null
        var inTable = false
        var currentTableRow = ArrayList<String>()
        var currentTableCell = ArrayList<String>()

        while (eventType != XmlPullParser.END_DOCUMENT) {
            val name = parser.name
            when (eventType) {
                XmlPullParser.START_TAG -> {
                    when (name) {
                        "tbl" -> {
                            inTable = true
                            currentTableRow.clear()
                        }
                        "tr" -> {
                            currentTableCell.clear()
                        }
                        "tc" -> {
                            currentParagraphRuns.clear()
                        }
                        "p" -> {
                            currentParagraphRuns.clear()
                            currentParagraphAlign = null
                        }
                        "jc" -> {
                            currentParagraphAlign = parser.getAttributeValue(null, "val")
                        }
                        "r" -> {
                            // Parse run properties (bold, italic, color)
                            var bold = false
                            var italic = false
                            var underline = false
                            var color: String? = null
                            var text = ""

                            // Loop run elements
                            var depth = parser.depth
                            while (parser.next() != XmlPullParser.END_TAG || parser.depth > depth) {
                                val runName = parser.name ?: continue
                                if (parser.eventType == XmlPullParser.START_TAG) {
                                    when (runName) {
                                        "b" -> bold = true
                                        "i" -> italic = true
                                        "u" -> underline = true
                                        "color" -> color = parser.getAttributeValue(null, "val")
                                        "t" -> {
                                            if (parser.next() == XmlPullParser.TEXT) {
                                                text = parser.text
                                            }
                                        }
                                    }
                                }
                            }

                            if (text.isNotEmpty()) {
                                val cleanText = escapeJson(text)
                                val runJson = """{"text":"$cleanText","b":$bold,"i":$italic,"u":$underline,"color":${if (color != null) "\"#$color\"" else "null"}}"""
                                currentParagraphRuns.add(runJson)
                            }
                        }
                    }
                }
                XmlPullParser.END_TAG -> {
                    when (name) {
                        "p" -> {
                            val runsStr = currentParagraphRuns.joinToString(",")
                            val pJson = """{"type":"p","align":${if (currentParagraphAlign != null) "\"$currentParagraphAlign\"" else "null"},"runs":[$runsStr]}"""
                            if (inTable) {
                                currentTableCell.add(pJson)
                            } else {
                                list.add(pJson)
                            }
                        }
                        "tc" -> {
                            val cellsStr = currentTableCell.joinToString(",")
                            currentTableRow.add("[$cellsStr]")
                            currentTableCell.clear()
                        }
                        "tr" -> {
                            val rowStr = currentTableRow.joinToString(",")
                            currentTableCell.add("[$rowStr]") // Borrow table cells container for holding completed row string temporary
                            currentTableRow.clear()
                        }
                        "tbl" -> {
                            inTable = false
                            val rowsStr = currentTableCell.joinToString(",")
                            val tableJson = """{"type":"table","rows":[$rowsStr]}"""
                            list.add(tableJson)
                            currentTableCell.clear()
                        }
                    }
                }
            }
            eventType = parser.next()
        }

        zip.close()
        return "[${list.joinToString(",")}]"
    }

    /**
     * Parse XLSX Sheets and SharedStrings.
     * Returns: {"sharedStrings":["..."], "cells":{"A1":"val1", "B1":"val2"}}
     */
    fun parseXlsx(filePath: String): String {
        val zip = ZipFile(filePath)
        
        // 1. Parse Shared Strings table
        val sharedStrings = ArrayList<String>()
        val stringsEntry = zip.getEntry("xl/sharedStrings.xml")
        if (stringsEntry != null) {
            val parser = Xml.newPullParser()
            parser.setInput(zip.getInputStream(stringsEntry), "UTF-8")
            var eventType = parser.eventType
            while (eventType != XmlPullParser.END_DOCUMENT) {
                if (eventType == XmlPullParser.START_TAG && parser.name == "t") {
                    if (parser.next() == XmlPullParser.TEXT) {
                        sharedStrings.add(parser.text)
                    }
                }
                eventType = parser.next()
            }
        }

        // 2. Parse Sheet1 grid cells
        val sheetEntry = zip.getEntry("xl/worksheets/sheet1.xml") ?: return "{}"
        val parser = Xml.newPullParser()
        parser.setInput(zip.getInputStream(sheetEntry), "UTF-8")
        
        var eventType = parser.eventType
        val cellsList = ArrayList<String>()
        var maxRow = 0
        var maxCol = 0

        while (eventType != XmlPullParser.END_DOCUMENT) {
            if (eventType == XmlPullParser.START_TAG && parser.name == "c") {
                val ref = parser.getAttributeValue(null, "r") ?: "" // e.g. "A1", "C12"
                val type = parser.getAttributeValue(null, "t") ?: "" // "s" for shared string
                
                // Parse col index (A -> 0, B -> 1) & row index
                val (col, row) = parseCellRef(ref)
                if (row > maxRow) maxRow = row
                if (col > maxCol) maxCol = col

                var value = ""
                val depth = parser.depth
                while (parser.next() != XmlPullParser.END_TAG || parser.depth > depth) {
                    if (parser.eventType == XmlPullParser.START_TAG && parser.name == "v") {
                        if (parser.next() == XmlPullParser.TEXT) {
                            val rawVal = parser.text ?: ""
                            value = if (type == "s") {
                                val idx = rawVal.toIntOrNull() ?: -1
                                if (idx in sharedStrings.indices) sharedStrings[idx] else ""
                            } else {
                                rawVal
                            }
                        }
                    }
                }

                if (value.isNotEmpty()) {
                    val cleanValue = escapeJson(value)
                    cellsList.add("\"$ref\":\"$cleanValue\"")
                }
            }
            eventType = parser.next()
        }

        zip.close()
        val cellsStr = cellsList.joinToString(",")
        return """{"maxRow":$maxRow,"maxCol":$maxCol,"cells":{$cellsStr}}"""
    }

    /**
     * Parse PPTX slide previews.
     * Returns: [ {"page":1, "texts":["...", "..."]} ]
     */
    fun parsePptx(filePath: String): String {
        val zip = ZipFile(filePath)
        val slidesList = ArrayList<String>()

        var slideIndex = 1
        while (true) {
            val entryName = "ppt/slides/slide$slideIndex.xml"
            val entry = zip.getEntry(entryName) ?: break

            val slideTexts = ArrayList<String>()
            val parser = Xml.newPullParser()
            parser.setInput(zip.getInputStream(entry), "UTF-8")
            
            var eventType = parser.eventType
            while (eventType != XmlPullParser.END_DOCUMENT) {
                if (eventType == XmlPullParser.START_TAG && parser.name == "t") {
                    if (parser.next() == XmlPullParser.TEXT) {
                        val txt = parser.text ?: ""
                        if (txt.trim().isNotEmpty()) {
                            slideTexts.add("\"${escapeJson(txt)}\"")
                        }
                    }
                }
                eventType = parser.next()
            }

            val textsStr = slideTexts.joinToString(",")
            slidesList.add("""{"slide":$slideIndex,"texts":[$textsStr]}""")
            slideIndex++
        }

        zip.close()
        return "[${slidesList.joinToString(",")}]"
    }

    // ── Helper parsing methods ───────────────────────────────────────────────

    private fun parseCellRef(ref: String): Pair<Int, Int> {
        var col = 0
        var row = 0
        for (char in ref) {
            if (char.isLetter()) {
                col = col * 26 + (char.uppercaseChar() - 'A' + 1)
            } else if (char.isDigit()) {
                row = row * 10 + (char - '0')
            }
        }
        return Pair(col - 1, row - 1)
    }

    private fun escapeJson(str: String): String {
        return str.replace("\\", "\\\\")
            .replace("\"", "\\\"")
            .replace("\n", "\\n")
            .replace("\r", "\\r")
            .replace("\t", "\\t")
    }
}
