package com.example.flux.viewer

/**
 * FileFormat — all formats supported by FLUX Viewer Engine.
 *
 * Detected from magic bytes (not file extension) via FormatDetector.
 * Source: doc2, Ch. 2 FormatDetector + doc1 Appendix (50+ types).
 */
enum class FileFormat {
    // Documents
    PDF,
    DOCX, DOC,
    XLSX, XLS,
    PPTX, PPT,
    ODT, ODS,
    RTF,

    // Images
    JPEG, PNG, WEBP, GIF, HEIC, HEIF, BMP, SVG, AVIF, DNG,

    // Video
    VIDEO_MP4, VIDEO_MKV, VIDEO_AVI, VIDEO_MOV, VIDEO_WEBM, VIDEO_3GP,

    // Audio
    AUDIO_MP3, AUDIO_FLAC, AUDIO_AAC, AUDIO_OGG, AUDIO_WAV, AUDIO_OPUS, AUDIO_M4A,

    // Text / Code
    PLAIN_TEXT,
    MARKDOWN,
    HTML,
    CODE_KOTLIN, CODE_JAVA, CODE_PYTHON, CODE_JS, CODE_TS, CODE_DART,
    CODE_C, CODE_CPP, CODE_RUST, CODE_GO, CODE_SWIFT, CODE_PHP, CODE_RUBY, CODE_BASH,
    CODE_CSS, CODE_R,

    // Data
    JSON, XML, YAML, CSV, TSV, TOML, INI, ENV, LOG, SQL,

    // Database
    SQLITE,

    // Archives
    ZIP, JAR, APK, AAR, EPUB, RAR, SEVEN_ZIP,

    // Fonts
    FONT_TTF, FONT_OTF, FONT_WOFF, FONT_WOFF2,

    // Fallback
    BINARY,
    UNKNOWN;

    fun isImage() = this in setOf(JPEG, PNG, WEBP, GIF, HEIC, HEIF, BMP, SVG, AVIF, DNG)
    fun isVideo() = this in setOf(VIDEO_MP4, VIDEO_MKV, VIDEO_AVI, VIDEO_MOV, VIDEO_WEBM, VIDEO_3GP)
    fun isAudio() = this in setOf(AUDIO_MP3, AUDIO_FLAC, AUDIO_AAC, AUDIO_OGG, AUDIO_WAV, AUDIO_OPUS, AUDIO_M4A)
    fun isOffice() = this in setOf(DOCX, DOC, XLSX, XLS, PPTX, PPT, ODT, ODS, RTF)
    fun isCode()   = name.startsWith("CODE_")
    fun isArchive()= this in setOf(ZIP, JAR, APK, AAR, EPUB, RAR, SEVEN_ZIP)
    fun isFont()   = name.startsWith("FONT_")
    fun isText()   = this in setOf(PLAIN_TEXT, MARKDOWN, HTML, JSON, XML, YAML, CSV, TSV, TOML, INI, ENV, LOG, SQL) || isCode()
}
