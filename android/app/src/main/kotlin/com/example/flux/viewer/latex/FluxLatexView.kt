package com.example.flux.viewer.latex

import android.content.Context
import android.view.View
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.plugin.platform.PlatformView
import java.io.File
import java.nio.charset.StandardCharsets

class FluxLatexView(
    context: Context,
    creationParams: Map<String, Any>?
) : PlatformView {

    private val webView: WebView = WebView(context)
    private val filePath = creationParams?.get("path") as? String
        ?: throw IllegalArgumentException("Missing file path")
    private val isDark = creationParams?.get("isDark") as? Boolean ?: true

    init {
        webView.settings.apply {
            javaScriptEnabled = true // Required for MathJax rendering
            allowFileAccess = true
            allowContentAccess = true
            domStorageEnabled = true
        }
        webView.webViewClient = WebViewClient()

        loadLatexFile()
    }

    private fun loadLatexFile() {
        try {
            val file = File(filePath)
            if (!file.exists()) {
                webView.loadData("File not found: $filePath", "text/plain", "UTF-8")
                return
            }
            val content = file.readText(StandardCharsets.UTF_8)
            val htmlBody = LatexParser.toHtml(content)
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
                    border-bottom: 1px solid #2B2B2B;
                    padding-bottom: 6px;
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
                .dark-mode blockquote {
                    border-left: 4px solid #00E5FF;
                    margin: 0 0 16px 0;
                    padding-left: 16px;
                    color: #888888;
                }
                /* Light Theme Styles */
                body.light-mode {
                    background-color: #FFFFFF;
                    color: #212121;
                }
                .light-mode h1, .light-mode h2, .light-mode h3, .light-mode h4, .light-mode h5, .light-mode h6 {
                    color: #000000;
                    border-bottom: 1px solid #E0E0E0;
                    padding-bottom: 6px;
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
                .light-mode blockquote {
                    border-left: 4px solid #00838F;
                    margin: 0 0 16px 0;
                    padding-left: 16px;
                    color: #666666;
                }
                /* Centering display equations and styling MathJax elements */
                .mjx-chtml {
                    outline: 0;
                }
            </style>
            <!-- MathJax configuration -->
            <script>
            MathJax = {
              tex: {
                inlineMath: [['$', '$'], ['\\(', '\\)']],
                displayMath: [['$$', '$$'], ['\\[', '\\]']],
                processEscapes: true,
                processEnvironments: true
              },
              options: {
                skipHtmlTags: ['script', 'noscript', 'style', 'textarea']
              },
              svg: {
                fontCache: 'global'
              }
            };
            </script>
            <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
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

object LatexParser {
    fun toHtml(latex: String): String {
        val lines = latex.split("\n")
        val html = StringBuilder()
        var inDocument = false
        var inList = false
        var inEnumerate = false
        var inQuote = false

        for (line in lines) {
            val trimmed = line.trim()

            // Handle document bounds
            if (trimmed.startsWith("\\begin{document}")) {
                inDocument = true
                continue
            }
            if (trimmed.startsWith("\\end{document}")) {
                inDocument = false
                break
            }

            // Before \begin{document}, skip
            if (!inDocument) continue

            // Ignore comments
            if (trimmed.startsWith("%")) continue

            // Structure environments
            if (trimmed.startsWith("\\begin{itemize}")) {
                if (!inList) {
                    html.append("<ul>\n")
                    inList = true
                }
                continue
            }
            if (trimmed.startsWith("\\end{itemize}")) {
                if (inList) {
                    html.append("</ul>\n")
                    inList = false
                }
                continue
            }
            if (trimmed.startsWith("\\begin{enumerate}")) {
                if (!inEnumerate) {
                    html.append("<ol>\n")
                    inEnumerate = true
                }
                continue
            }
            if (trimmed.startsWith("\\end{enumerate}")) {
                if (inEnumerate) {
                    html.append("</ol>\n")
                    inEnumerate = false
                }
                continue
            }
            if (trimmed.startsWith("\\begin{quote}")) {
                if (!inQuote) {
                    html.append("<blockquote>\n")
                    inQuote = true
                }
                continue
            }
            if (trimmed.startsWith("\\end{quote}")) {
                if (inQuote) {
                    html.append("</blockquote>\n")
                    inQuote = false
                }
                continue
            }

            // Handle items
            if (trimmed.startsWith("\\item")) {
                val content = trimmed.substring(5).trim()
                html.append("<li>").append(parseInline(content)).append("</li>\n")
                continue
            }

            // Headers
            if (trimmed.startsWith("\\chapter")) {
                val content = extractArgument(trimmed, "chapter")
                html.append("<h1>").append(parseInline(content)).append("</h1>\n")
                continue
            }
            if (trimmed.startsWith("\\section")) {
                val content = extractArgument(trimmed, "section")
                html.append("<h2>").append(parseInline(content)).append("</h2>\n")
                continue
            }
            if (trimmed.startsWith("\\subsection")) {
                val content = extractArgument(trimmed, "subsection")
                html.append("<h3>").append(parseInline(content)).append("</h3>\n")
                continue
            }
            if (trimmed.startsWith("\\subsubsection")) {
                val content = extractArgument(trimmed, "subsubsection")
                html.append("<h4>").append(parseInline(content)).append("</h4>\n")
                continue
            }

            // Handle empty line as paragraph separator
            if (trimmed.isEmpty()) {
                continue
            }

            // Keep Math/Equation blocks untouched
            if (trimmed.startsWith("\\begin{equation}") || trimmed.startsWith("\\begin{align}") || 
                trimmed.startsWith("\\begin{gather}") || trimmed.startsWith("\\begin{equation*}") || 
                trimmed.startsWith("\\begin{align*}") || trimmed.startsWith("\\begin{gather*}") ||
                trimmed.startsWith("\\[") || trimmed.startsWith("\\]") ||
                trimmed.startsWith("\\end{equation}") || trimmed.startsWith("\\end{align}") || 
                trimmed.startsWith("\\end{gather}") || trimmed.startsWith("\\end{equation*}") || 
                trimmed.startsWith("\\end{align*}") || trimmed.startsWith("\\end{gather*}")) {
                html.append(line).append("\n")
                continue
            }

            // If it's a paragraph/general line
            html.append("<p>").append(parseInline(line)).append("</p>\n")
        }

        // Close outstanding lists/quotes
        if (inList) html.append("</ul>\n")
        if (inEnumerate) html.append("</ol>\n")
        if (inQuote) html.append("</blockquote>\n")

        return html.toString()
    }

    private fun extractArgument(line: String, command: String): String {
        val startIdx = line.indexOf("\\$command")
        if (startIdx == -1) return line
        val realStart = line.indexOf("{", startIdx + command.length)
        if (realStart == -1) return line
        val end = line.lastIndexOf("}")
        return if (end > realStart) line.substring(realStart + 1, end) else line.substring(realStart + 1)
    }

    private fun parseInline(text: String): String {
        var result = text
        // Inline LaTeX commands: \textbf{...}, \textit{...}, \texttt{...}
        result = result.replace(Regex("\\\\textbf\\{([^}]+)\\}"), "<strong>$1</strong>")
        result = result.replace(Regex("\\\\textit\\{([^}]+)\\}"), "<em>$1</em>")
        result = result.replace(Regex("\\\\texttt\\{([^}]+)\\}"), "<code>$1</code>")
        result = result.replace(Regex("\\\\href\\{([^}]+)\\}\\{([^}]+)\\}"), "<a href=\"$1\">$2</a>")
        return result
    }
}
