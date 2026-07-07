package com.example.flux.viewer

/**
 * FormatDetector — identifies file format from magic bytes, NOT from extension.
 *
 * "Extensions lie; magic bytes don't." — doc2, Ch. 2
 *
 * Detection order:
 *   1. Magic bytes from first 16 bytes of file
 *   2. For ZIP-family: inspect ZIP central directory for internal structure
 *   3. For text-like: heuristic (<2% non-printable) → detect sub-type by extension + shebang
 *
 * Source: doc2, Ch. 2, FormatDetector listing.
 */
object FormatDetector {

    fun detect(source: MmapSource): FileFormat {
        if (source.size < 4) return FileFormat.BINARY

        val magic = source.readBytes(0, minOf(16, source.size.toInt()))

        return when {
            // ── Documents ────────────────────────────────────────────────────
            // PDF: starts with '%PDF-'
            magic.startsWith("%PDF-") ->
                FileFormat.PDF

            // ZIP-based: DOCX, XLSX, PPTX, EPUB, APK, ODT, ODS, JAR — all start with PK (0x50 0x4B)
            magic[0] == 0x50.toByte() && magic[1] == 0x4B.toByte() ->
                detectZipBased(source)

            // RTF: starts with '{\rtf'
            magic.startsWith("{\\rtf") ->
                FileFormat.RTF

            // ── Images ────────────────────────────────────────────────────────
            // JPEG: FF D8 FF
            magic[0] == 0xFF.toByte() && magic[1] == 0xD8.toByte() && magic[2] == 0xFF.toByte() ->
                FileFormat.JPEG

            // PNG: 89 50 4E 47 0D 0A 1A 0A
            magic[0] == 0x89.toByte() && magic.startsWith("\u0089PNG") ->
                FileFormat.PNG

            // WebP: RIFF....WEBP
            magic.startsWith("RIFF") && source.size >= 12 &&
                source.readAscii(8, 4) == "WEBP" ->
                FileFormat.WEBP

            // GIF: GIF87a or GIF89a
            magic.startsWith("GIF8") ->
                FileFormat.GIF

            // BMP: BM
            magic[0] == 0x42.toByte() && magic[1] == 0x4D.toByte() ->
                FileFormat.BMP

            // HEIC/HEIF: ftyp box at offset 4 (check major brand)
            source.size >= 12 && source.readAscii(4, 4) == "ftyp" ->
                detectHeicOrVideo(source)

            // SVG: starts with '<svg' or '<?xml' + contains 'svg'
            magic.startsWith("<?xm") || magic.startsWith("<svg") ->
                detectXmlOrSvg(source)

            // ── Audio ─────────────────────────────────────────────────────────
            // MP3: ID3 header or FF FB / FF FA / FF F3 sync word
            magic.startsWith("ID3") ||
                (magic[0] == 0xFF.toByte() && (magic[1].toInt() and 0xE0) == 0xE0) ->
                FileFormat.AUDIO_MP3

            // FLAC: fLaC
            magic.startsWith("fLaC") ->
                FileFormat.AUDIO_FLAC

            // OGG: OggS
            magic.startsWith("OggS") ->
                FileFormat.AUDIO_OGG

            // WAV: RIFF....WAVE
            magic.startsWith("RIFF") && source.size >= 12 &&
                source.readAscii(8, 4) == "WAVE" ->
                FileFormat.AUDIO_WAV

            // ── Database ──────────────────────────────────────────────────────
            // SQLite: 'SQLite format 3\000'
            magic.startsWith("SQLite format 3") ->
                FileFormat.SQLITE

            // ── Text heuristic ────────────────────────────────────────────────
            isLikelyText(source) ->
                detectTextSubtype(source)

            else ->
                FileFormat.BINARY
        }
    }

    // ── ZIP-family disambiguation ────────────────────────────────────────────

    private fun detectZipBased(source: MmapSource): FileFormat {
        // Scan ZIP central directory for indicator files
        return try {
            val zipEntries = peekZipEntries(source, maxEntries = 10)
            when {
                // DOCX: contains word/document.xml
                zipEntries.any { it.startsWith("word/") }             -> FileFormat.DOCX
                // XLSX: contains xl/workbook.xml
                zipEntries.any { it.startsWith("xl/") }               -> FileFormat.XLSX
                // PPTX: contains ppt/presentation.xml
                zipEntries.any { it.startsWith("ppt/") }              -> FileFormat.PPTX
                // EPUB: contains META-INF/container.xml
                zipEntries.any { it == "META-INF/container.xml" }     -> FileFormat.EPUB
                // APK: contains AndroidManifest.xml
                zipEntries.any { it == "AndroidManifest.xml" }        -> FileFormat.APK
                // ODT
                zipEntries.any { it.startsWith("content.xml") &&
                    zipEntries.any { e -> e.contains("odt") } }       -> FileFormat.ODT
                // ODS
                zipEntries.any { it == "mimetype" }                   -> detectOdfMime(source)
                // JAR: contains META-INF/MANIFEST.MF
                zipEntries.any { it.startsWith("META-INF/MANIFEST") } -> FileFormat.JAR
                else                                                   -> FileFormat.ZIP
            }
        } catch (_: Exception) {
            FileFormat.ZIP
        }
    }

    /**
     * Read first N local file header names from a ZIP without fully parsing.
     * We use java.util.zip.ZipFile through a helper to avoid byte-level ZIP parsing here.
     */
    private fun peekZipEntries(source: MmapSource, maxEntries: Int): List<String> {
        return try {
            val zipFile = java.util.zip.ZipFile(source.file)
            val entries = mutableListOf<String>()
            val iter = zipFile.entries()
            var count = 0
            while (iter.hasMoreElements() && count < maxEntries) {
                entries.add(iter.nextElement().name)
                count++
            }
            zipFile.close()
            entries
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun detectOdfMime(source: MmapSource): FileFormat {
        return try {
            val zipFile = java.util.zip.ZipFile(source.file)
            val mime = zipFile.getEntry("mimetype")?.let { entry ->
                zipFile.getInputStream(entry).bufferedReader().readText()
            } ?: ""
            zipFile.close()
            when {
                mime.contains("spreadsheet") -> FileFormat.ODS
                mime.contains("presentation") -> FileFormat.PPTX
                else -> FileFormat.ODT
            }
        } catch (_: Exception) {
            FileFormat.ODT
        }
    }

    // ── HEIC / Video disambiguation ──────────────────────────────────────────

    private fun detectHeicOrVideo(source: MmapSource): FileFormat {
        return try {
            val brand = source.readAscii(8, 4)
            when (brand) {
                "heic", "heics", "heis", "heim", "hevm" -> FileFormat.HEIC
                "mif1", "msf1" -> FileFormat.HEIF
                "mp42", "mp41", "isom", "M4V ", "M4A " -> FileFormat.VIDEO_MP4
                "qt  " -> FileFormat.VIDEO_MOV
                "3gp5", "3gp6" -> FileFormat.VIDEO_3GP
                "M4A ", "m4a " -> FileFormat.AUDIO_M4A
                else -> {
                    // Check for moov box in first 32 bytes
                    if (source.size >= 8 && source.readAscii(4, 4) == "moov") FileFormat.VIDEO_MP4
                    else FileFormat.VIDEO_MP4 // Default ftyp = MP4
                }
            }
        } catch (_: Exception) {
            FileFormat.VIDEO_MP4
        }
    }

    // ── XML / SVG disambiguation ─────────────────────────────────────────────

    private fun detectXmlOrSvg(source: MmapSource): FileFormat {
        // Read first 512 bytes to check for SVG namespace
        val header = try {
            String(source.readBytes(0, minOf(512, source.size.toInt())), Charsets.UTF_8)
        } catch (_: Exception) { "" }
        return when {
            header.contains("svg", ignoreCase = true) -> FileFormat.SVG
            else -> FileFormat.XML
        }
    }

    // ── Text heuristic ───────────────────────────────────────────────────────

    private fun isLikelyText(source: MmapSource): Boolean {
        val sample = source.readBytes(0, minOf(512, source.size.toInt()))
        val nonPrintable = sample.count { b ->
            val i = b.toInt() and 0xFF
            i < 9 || (i in 14..31 && i != 27)  // not tab/LF/CR/ESC
        }
        return nonPrintable.toDouble() / sample.size < 0.02  // <2% non-printable
    }

    private fun detectTextSubtype(source: MmapSource): FileFormat {
        // Step 1: extension-based detection
        val ext = source.file.extension.lowercase()
        extensionMap[ext]?.let { return it }

        // Step 2: shebang line for extensionless scripts
        return try {
            val header = String(source.readBytes(0, minOf(128, source.size.toInt())), Charsets.UTF_8)
            when {
                header.startsWith("#!/usr/bin/env python") || header.startsWith("#!/usr/bin/python") ->
                    FileFormat.CODE_PYTHON
                header.startsWith("#!/bin/bash") || header.startsWith("#!/usr/bin/bash") ->
                    FileFormat.CODE_BASH
                header.startsWith("#!/usr/bin/node") || header.startsWith("#!/usr/bin/env node") ->
                    FileFormat.CODE_JS
                header.startsWith("<?xml") ->
                    detectXmlOrSvg(source)
                header.trimStart().startsWith("{") || header.trimStart().startsWith("[") ->
                    FileFormat.JSON
                else ->
                    FileFormat.PLAIN_TEXT
            }
        } catch (_: Exception) {
            FileFormat.PLAIN_TEXT
        }
    }

    // ── Extension map — O(1) lookup ──────────────────────────────────────────

    val extensionMap: Map<String, FileFormat> = mapOf(
        // Documents
        "pdf"   to FileFormat.PDF,
        "docx"  to FileFormat.DOCX, "doc" to FileFormat.DOC,
        "xlsx"  to FileFormat.XLSX, "xls" to FileFormat.XLS,
        "pptx"  to FileFormat.PPTX, "ppt" to FileFormat.PPT,
        "odt"   to FileFormat.ODT,  "ods" to FileFormat.ODS,
        "rtf"   to FileFormat.RTF,
        "tex"   to FileFormat.LATEX, "ltx" to FileFormat.LATEX, "latex" to FileFormat.LATEX,
        // Images
        "jpg"   to FileFormat.JPEG, "jpeg" to FileFormat.JPEG,
        "png"   to FileFormat.PNG,
        "webp"  to FileFormat.WEBP,
        "gif"   to FileFormat.GIF,
        "bmp"   to FileFormat.BMP,
        "heic"  to FileFormat.HEIC, "heif" to FileFormat.HEIF,
        "svg"   to FileFormat.SVG,
        "avif"  to FileFormat.AVIF,
        "dng"   to FileFormat.DNG,  "raw" to FileFormat.DNG,
        // Video
        "mp4"   to FileFormat.VIDEO_MP4, "m4v" to FileFormat.VIDEO_MP4,
        "mkv"   to FileFormat.VIDEO_MKV,
        "avi"   to FileFormat.VIDEO_AVI,
        "mov"   to FileFormat.VIDEO_MOV,
        "webm"  to FileFormat.VIDEO_WEBM,
        "3gp"   to FileFormat.VIDEO_3GP,
        // Audio
        "mp3"   to FileFormat.AUDIO_MP3,
        "flac"  to FileFormat.AUDIO_FLAC,
        "aac"   to FileFormat.AUDIO_AAC,
        "ogg"   to FileFormat.AUDIO_OGG,
        "wav"   to FileFormat.AUDIO_WAV,
        "opus"  to FileFormat.AUDIO_OPUS,
        "m4a"   to FileFormat.AUDIO_M4A,
        // Text / Code
        "txt"   to FileFormat.PLAIN_TEXT,
        "log"   to FileFormat.LOG,
        "md"    to FileFormat.MARKDOWN, "markdown" to FileFormat.MARKDOWN,
        "html"  to FileFormat.HTML, "htm" to FileFormat.HTML,
        "kt"    to FileFormat.CODE_KOTLIN,
        "java"  to FileFormat.CODE_JAVA,
        "py"    to FileFormat.CODE_PYTHON,
        "js"    to FileFormat.CODE_JS,
        "ts"    to FileFormat.CODE_TS,
        "dart"  to FileFormat.CODE_DART,
        "c"     to FileFormat.CODE_C,
        "cpp"   to FileFormat.CODE_CPP, "cc" to FileFormat.CODE_CPP, "cxx" to FileFormat.CODE_CPP,
        "h"     to FileFormat.CODE_C, "hpp" to FileFormat.CODE_CPP,
        "rs"    to FileFormat.CODE_RUST,
        "go"    to FileFormat.CODE_GO,
        "swift" to FileFormat.CODE_SWIFT,
        "php"   to FileFormat.CODE_PHP,
        "rb"    to FileFormat.CODE_RUBY,
        "sh"    to FileFormat.CODE_BASH, "bash" to FileFormat.CODE_BASH,
        "css"   to FileFormat.CODE_CSS,
        "r"     to FileFormat.CODE_R,
        // Data
        "json"  to FileFormat.JSON,
        "xml"   to FileFormat.XML,
        "yaml"  to FileFormat.YAML, "yml" to FileFormat.YAML,
        "csv"   to FileFormat.CSV,
        "tsv"   to FileFormat.TSV,
        "toml"  to FileFormat.TOML,
        "ini"   to FileFormat.INI, "conf" to FileFormat.INI,
        "env"   to FileFormat.ENV,
        "sql"   to FileFormat.SQL,
        // Database
        "db"    to FileFormat.SQLITE, "sqlite" to FileFormat.SQLITE, "sqlite3" to FileFormat.SQLITE,
        // Archives
        "zip"   to FileFormat.ZIP,
        "jar"   to FileFormat.JAR,
        "apk"   to FileFormat.APK,
        "aar"   to FileFormat.AAR,
        "epub"  to FileFormat.EPUB,
        "rar"   to FileFormat.RAR,
        "7z"    to FileFormat.SEVEN_ZIP,
        // Fonts
        "ttf"   to FileFormat.FONT_TTF,
        "otf"   to FileFormat.FONT_OTF,
        "woff"  to FileFormat.FONT_WOFF,
        "woff2" to FileFormat.FONT_WOFF2,
    )

    // ── MIME type → FileFormat ───────────────────────────────────────────────

    fun fromMimeType(mimeType: String?): FileFormat? = when (mimeType?.lowercase()) {
        "application/pdf" -> FileFormat.PDF
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" -> FileFormat.DOCX
        "application/msword" -> FileFormat.DOC
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" -> FileFormat.XLSX
        "application/vnd.ms-excel" -> FileFormat.XLS
        "application/vnd.openxmlformats-officedocument.presentationml.presentation" -> FileFormat.PPTX
        "application/vnd.ms-powerpoint" -> FileFormat.PPT
        "image/jpeg" -> FileFormat.JPEG
        "image/png" -> FileFormat.PNG
        "image/webp" -> FileFormat.WEBP
        "image/gif" -> FileFormat.GIF
        "image/heic", "image/heif" -> FileFormat.HEIC
        "image/bmp" -> FileFormat.BMP
        "image/svg+xml" -> FileFormat.SVG
        "image/avif" -> FileFormat.AVIF
        "video/mp4" -> FileFormat.VIDEO_MP4
        "video/x-matroska" -> FileFormat.VIDEO_MKV
        "video/x-msvideo" -> FileFormat.VIDEO_AVI
        "video/quicktime" -> FileFormat.VIDEO_MOV
        "video/webm" -> FileFormat.VIDEO_WEBM
        "video/3gpp" -> FileFormat.VIDEO_3GP
        "audio/mpeg" -> FileFormat.AUDIO_MP3
        "audio/flac" -> FileFormat.AUDIO_FLAC
        "audio/aac" -> FileFormat.AUDIO_AAC
        "audio/ogg" -> FileFormat.AUDIO_OGG
        "audio/wav", "audio/x-wav" -> FileFormat.AUDIO_WAV
        "audio/opus" -> FileFormat.AUDIO_OPUS
        "audio/mp4" -> FileFormat.AUDIO_M4A
        "text/plain" -> FileFormat.PLAIN_TEXT
        "text/html" -> FileFormat.HTML
        "text/markdown" -> FileFormat.MARKDOWN
        "text/x-tex", "application/x-tex" -> FileFormat.LATEX
        "text/csv" -> FileFormat.CSV
        "application/json" -> FileFormat.JSON
        "text/xml", "application/xml" -> FileFormat.XML
        "application/zip", "application/x-zip-compressed" -> FileFormat.ZIP
        "application/vnd.android.package-archive" -> FileFormat.APK
        "application/epub+zip" -> FileFormat.EPUB
        "font/ttf", "application/x-font-ttf" -> FileFormat.FONT_TTF
        "font/otf", "application/x-font-otf" -> FileFormat.FONT_OTF
        "font/woff" -> FileFormat.FONT_WOFF
        "font/woff2" -> FileFormat.FONT_WOFF2
        else -> null
    }
}

// ── Extension helper ─────────────────────────────────────────────────────────

private fun ByteArray.startsWith(prefix: String): Boolean {
    if (size < prefix.length) return false
    return prefix.indices.all { i -> this[i] == prefix[i].code.toByte() }
}
