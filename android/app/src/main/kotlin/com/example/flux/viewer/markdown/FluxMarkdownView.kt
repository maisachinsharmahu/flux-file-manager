package com.example.flux.viewer.markdown

import android.content.Context
import android.view.View
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.plugin.platform.PlatformView
import java.io.File
import java.nio.charset.StandardCharsets

class FluxMarkdownView(
    context: Context,
    creationParams: Map<String, Any>?
) : PlatformView {

    private val webView: WebView = WebView(context)
    private val filePath = creationParams?.get("path") as? String
        ?: throw IllegalArgumentException("Missing file path")
    private val isDark = creationParams?.get("isDark") as? Boolean ?: true

    init {
        webView.settings.apply {
            javaScriptEnabled = false // sandboxed, no scripts
            allowFileAccess = true
            allowContentAccess = true
            domStorageEnabled = true
        }
        webView.webViewClient = WebViewClient()

        loadMarkdownFile()
    }

    private fun loadMarkdownFile() {
        try {
            val file = File(filePath)
            if (!file.exists()) {
                webView.loadData("File not found: $filePath", "text/plain", "UTF-8")
                return
            }
            val content = file.readText(StandardCharsets.UTF_8)
            val htmlBody = MarkdownParser.toHtml(content)
            val fullHtml = buildHtmlDocument(htmlBody)
            webView.loadDataWithBaseURL(null, fullHtml, "text/html", "UTF-8", null)
        } catch (e: Exception) {
            webView.loadData("Failed to load file: ${e.message}", "text/plain", "UTF-8")
        }
    }

    private fun buildHtmlDocument(bodyHtml: String): String {
        val themeClass = if (isDark) "dark-mode" else "light-mode"
        return """
            <!DOCTYPE html>
            <html>
            <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                    line-height: 1.6;
                    padding: 20px;
                    margin: 0;
                    font-size: 15px;
                }
                /* Dark Theme Styles */
                body.dark-mode {
                    background-color: #0F0F0F;
                    color: #E0E0E0;
                }
                .dark-mode h1, .dark-mode h2, .dark-mode h3, .dark-mode h4, .dark-mode h5, .dark-mode h6 {
                    color: #FFFFFF;
                }
                .dark-mode a {
                    color: #00E5FF;
                    text-decoration: none;
                }
                .dark-mode a:hover {
                    text-decoration: underline;
                }
                .dark-mode code {
                    background-color: #1E1E1E;
                    color: #00E5FF;
                    padding: 2px 6px;
                    border-radius: 4px;
                    font-family: "Courier New", Courier, monospace;
                    font-size: 85%;
                }
                .dark-mode pre {
                    background-color: #161616;
                    padding: 14px;
                    border-radius: 8px;
                    overflow-x: auto;
                    border: 1px solid #2B2B2B;
                }
                .dark-mode pre code {
                    background-color: transparent;
                    color: #A8D8A8;
                    padding: 0;
                    border-radius: 0;
                    font-size: 90%;
                }
                .dark-mode blockquote {
                    border-left: 4px solid #00E5FF;
                    margin: 0 0 16px 0;
                    padding-left: 16px;
                    color: #888888;
                }
                .dark-mode hr {
                    border: 0;
                    border-top: 1px solid #2B2B2B;
                    margin: 24px 0;
                }
                /* Light Theme Styles */
                body.light-mode {
                    background-color: #FFFFFF;
                    color: #212121;
                }
                .light-mode h1, .light-mode h2, .light-mode h3, .light-mode h4, .light-mode h5, .light-mode h6 {
                    color: #000000;
                }
                .light-mode a {
                    color: #00838F;
                    text-decoration: none;
                }
                .light-mode a:hover {
                    text-decoration: underline;
                }
                .light-mode code {
                    background-color: #F5F5F5;
                    color: #00838F;
                    padding: 2px 6px;
                    border-radius: 4px;
                    font-family: "Courier New", Courier, monospace;
                    font-size: 85%;
                }
                .light-mode pre {
                    background-color: #F9F9F9;
                    padding: 14px;
                    border-radius: 8px;
                    overflow-x: auto;
                    border: 1px solid #E0E0E0;
                }
                .light-mode pre code {
                    background-color: transparent;
                    color: #2E7D32;
                    padding: 0;
                    border-radius: 0;
                    font-size: 90%;
                }
                .light-mode blockquote {
                    border-left: 4px solid #00838F;
                    margin: 0 0 16px 0;
                    padding-left: 16px;
                    color: #666666;
                }
                .light-mode hr {
                    border: 0;
                    border-top: 1px solid #E0E0E0;
                    margin: 24px 0;
                }
            </style>
            </head>
            <body class="$themeClass">
                $bodyHtml
            </body>
            </html>
        """.trimIndent()
    }

    override fun getView(): View = webView

    override fun dispose() {
        webView.stopLoading()
        webView.destroy()
    }
}

object MarkdownParser {
    fun toHtml(markdown: String): String {
        val lines = markdown.split("\n")
        val html = StringBuilder()
        var inList = false
        var inCodeBlock = false
        val codeContent = StringBuilder()
        var inQuote = false

        for (line in lines) {
            val trimmed = line.trim()

            // Code block handling
            if (trimmed.startsWith("```")) {
                if (inCodeBlock) {
                    inCodeBlock = false
                    html.append("<pre><code>")
                        .append(escapeHtml(codeContent.toString()))
                        .append("</code></pre>\n")
                    codeContent.setLength(0)
                } else {
                    inCodeBlock = true
                }
                continue
            }

            if (inCodeBlock) {
                codeContent.append(line).append("\n")
                continue
            }

            // List handling
            val isBullet = trimmed.startsWith("- ") || trimmed.startsWith("* ") || trimmed.startsWith("+ ")
            if (isBullet) {
                if (!inList) {
                    html.append("<ul>\n")
                    inList = true
                }
                val content = trimmed.substring(2)
                html.append("<li>").append(parseInline(content)).append("</li>\n")
                continue
            } else {
                if (inList) {
                    html.append("</ul>\n")
                    inList = false
                }
            }

            // Blockquote handling
            val isQuote = trimmed.startsWith(">")
            if (isQuote) {
                if (!inQuote) {
                    html.append("<blockquote>\n")
                    inQuote = true
                }
                val content = if (trimmed.length > 1) trimmed.substring(1).trim() else ""
                html.append("<p>").append(parseInline(content)).append("</p>\n")
                continue
            } else {
                if (inQuote) {
                    html.append("</blockquote>\n")
                    inQuote = false
                }
            }

            // Empty line
            if (trimmed.isEmpty()) {
                continue
            }

            // Heading handling
            if (trimmed.startsWith("#")) {
                var level = 0
                while (level < trimmed.length && trimmed[level] == '#') {
                    level++
                }
                if (level in 1..6 && level < trimmed.length && trimmed[level] == ' ') {
                    val content = trimmed.substring(level + 1).trim()
                    html.append("<h").append(level).append(">")
                        .append(parseInline(content))
                        .append("</h").append(level).append(">\n")
                    continue
                }
            }

            // Horizontal rule
            if (trimmed == "---" || trimmed == "***" || trimmed == "___") {
                html.append("<hr/>\n")
                continue
            }

            // Paragraph
            html.append("<p>").append(parseInline(line)).append("</p>\n")
        }

        // Clean up unclosed structures
        if (inList) html.append("</ul>\n")
        if (inQuote) html.append("</blockquote>\n")
        if (inCodeBlock) {
            html.append("<pre><code>").append(escapeHtml(codeContent.toString())).append("</code></pre>\n")
        }

        return html.toString()
    }

    private fun parseInline(text: String): String {
        var escaped = escapeHtml(text)
        // Inline code `code`
        escaped = escaped.replace(Regex("`([^`]+)`"), "<code>$1</code>")
        // Bold **bold** or __bold__
        escaped = escaped.replace(Regex("\\*\\*([^\\*]+)\\*\\*"), "<strong>$1</strong>")
        escaped = escaped.replace(Regex("__([^_]+)__"), "<strong>$1</strong>")
        // Italic *italic* or _italic_
        escaped = escaped.replace(Regex("\\*([^\\*]+)\\*"), "<em>$1</em>")
        escaped = escaped.replace(Regex("_([^_]+)_"), "<em>$1</em>")
        // Links [text](url)
        escaped = escaped.replace(Regex("\\[([^\\]]+)\\]\\(([^\\)]+)\\)"), "<a href=\"$2\">$1</a>")
        return escaped
    }

    private fun escapeHtml(text: String): String {
        return text.replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")
            .replace("'", "&#39;")
    }
}
