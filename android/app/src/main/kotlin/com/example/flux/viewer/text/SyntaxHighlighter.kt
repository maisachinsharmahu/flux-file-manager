package com.example.flux.viewer.text

import android.graphics.Color
import java.util.regex.Pattern

/**
 * SyntaxHighlighter — fast line-by-line syntax highlight regex tokenizer.
 *
 * Designed to process code snippets a line at a time to remain highly performant.
 * Fits Rule 3 (Zero external libraries) by using Kotlin's standard regex features.
 */
object SyntaxHighlighter {

    class HighlightRun(val text: String, val color: Int)

    // Token color constants matching standard dark theme palettes
    private const val COLOR_NORMAL = 0xFFD4D4D4.toInt()    // Light grey
    private const val COLOR_KEYWORD = 0xFF569CD6.toInt()   // Blue
    private const val COLOR_TYPE = 0xFF4EC9B0.toInt()      // Teal
    private const val COLOR_STRING = 0xFFCE9178.toInt()    // Orange/Red
    private const val COLOR_COMMENT = 0xFF6A9955.toInt()   // Green
    private const val COLOR_NUMBER = 0xFFB5CEA8.toInt()    // Light Green/Yellow

    // Keyword pattern databases per language type group
    private val jvmKeywords = setOf(
        "package", "import", "class", "interface", "object", "fun", "val", "var",
        "private", "protected", "public", "internal", "if", "else", "when", "for",
        "while", "return", "throw", "try", "catch", "finally", "null", "true", "false",
        "this", "super", "new", "class", "void", "static", "final", "abstract", "extends",
        "implements", "volatile", "synchronized", "throw", "instanceof", "enum"
    )

    private val scriptKeywords = setOf(
        "def", "class", "if", "elif", "else", "for", "while", "return", "import",
        "from", "as", "try", "except", "finally", "raise", "None", "True", "False",
        "and", "or", "not", "in", "is", "lambda", "global", "nonlocal", "pass", "break",
        "continue", "with", "assert"
    )

    private val webKeywords = setOf(
        "const", "let", "var", "function", "class", "constructor", "extends", "super",
        "import", "export", "from", "default", "if", "else", "for", "while", "do",
        "switch", "case", "break", "continue", "return", "try", "catch", "finally",
        "throw", "typeof", "instanceof", "in", "of", "new", "this", "null", "undefined",
        "true", "false", "await", "async", "yield", "debugger"
    )

    private val nativeKeywords = setOf(
        "fn", "let", "mut", "struct", "enum", "impl", "trait", "pub", "use", "mod",
        "match", "if", "else", "for", "loop", "while", "return", "break", "continue",
        "true", "false", "type", "const", "static", "unsafe", "where", "ref", "self",
        "Self", "as", "extern", "crate"
    )

    private val sqlKeywords = setOf(
        "select", "insert", "update", "delete", "from", "where", "join", "inner", "left",
        "right", "outer", "on", "group", "by", "order", "having", "limit", "offset",
        "and", "or", "not", "null", "true", "false", "create", "table", "drop", "alter",
        "index", "view", "primary", "key", "foreign", "into", "values", "set", "as"
    )

    // Token boundary marker
    private class TokenMatch(val start: Int, val end: Int, val color: Int) : Comparable<TokenMatch> {
        override fun compareTo(other: TokenMatch): Int {
            return start.compareTo(other.start)
        }
    }

    /**
     * Parse code file line into styled segments.
     * Uses greedy regex matches and compiles them to a linear list of runs.
     */
    fun highlight(line: String, formatName: String): List<HighlightRun> {
        if (line.isEmpty()) return emptyList()

        val format = formatName.lowercase()

        // 1. Identify keywords database
        val keywords = when {
            format.contains("kotlin") || format.contains("java") || format.contains("dart") || format.contains("swift") -> jvmKeywords
            format.contains("python") || format.contains("ruby") || format.contains("bash") || format.contains("sh") -> scriptKeywords
            format.contains("javascript") || format.contains("typescript") || format.contains("js") || format.contains("ts") || format.contains("html") || format.contains("css") -> webKeywords
            format.contains("rust") || format.contains("go") || format.contains("cpp") || format.contains("c") -> nativeKeywords
            format.contains("sql") -> sqlKeywords
            else -> null
        }

        // Plain text formats bypass highlighting completely
        if (keywords == null) {
            return listOf(HighlightRun(line, COLOR_NORMAL))
        }

        val matches = ArrayList<TokenMatch>()

        // 2. Extract Comments
        val commentPattern = if (format.contains("python") || format.contains("ruby") || format.contains("bash") || format.contains("sh") || format.contains("yaml") || format.contains("toml")) {
            Pattern.compile("#.*")
        } else {
            Pattern.compile("//.*|/\\*.*?\\*/")
        }
        val commentMatcher = commentPattern.matcher(line)
        while (commentMatcher.find()) {
            matches.add(TokenMatch(commentMatcher.start(), commentMatcher.end(), COLOR_COMMENT))
        }

        // 3. Extract String Literals
        val stringPattern = Pattern.compile("\".*?\"|'.*?'")
        val stringMatcher = stringPattern.matcher(line)
        while (stringMatcher.find()) {
            matches.add(TokenMatch(stringMatcher.start(), stringMatcher.end(), COLOR_STRING))
        }

        // 4. Extract Numbers
        val numberPattern = Pattern.compile("\\b\\d+(\\.\\d+)?\\b")
        val numberMatcher = numberPattern.matcher(line)
        while (numberMatcher.find()) {
            matches.add(TokenMatch(numberMatcher.start(), numberMatcher.end(), COLOR_NUMBER))
        }

        // 5. Extract Keywords
        val wordPattern = Pattern.compile("\\b[a-zA-Z_][a-zA-Z0-9_]*\\b")
        val wordMatcher = wordPattern.matcher(line)
        while (wordMatcher.find()) {
            val word = wordMatcher.group()
            // Check if SQL keywords (case-insensitive) or other language keywords
            val isMatch = if (format.contains("sql")) {
                keywords.contains(word.lowercase())
            } else {
                keywords.contains(word)
            }
            if (isMatch) {
                matches.add(TokenMatch(wordMatcher.start(), wordMatcher.end(), COLOR_KEYWORD))
            }
        }

        // Sort matches by start index
        matches.sort()

        // 6. Segment Partitioning (filter out overlaps)
        val runs = ArrayList<HighlightRun>()
        var lastIdx = 0

        for (match in matches) {
            // Check if this match overlaps with already highlighted range
            if (match.start < lastIdx) continue

            // Add normal text before this highlighted token
            if (match.start > lastIdx) {
                runs.add(HighlightRun(line.substring(lastIdx, match.start), COLOR_NORMAL))
            }

            // Add the token highlight run
            runs.add(HighlightRun(line.substring(match.start, match.end), match.color))
            lastIdx = match.end
        }

        // Add remaining trailing normal text
        if (lastIdx < line.length) {
            runs.add(HighlightRun(line.substring(lastIdx), COLOR_NORMAL))
        }

        return runs
    }
}
