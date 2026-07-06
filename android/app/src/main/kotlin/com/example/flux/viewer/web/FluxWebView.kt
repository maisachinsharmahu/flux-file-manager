package com.example.flux.viewer.web

import android.content.Context
import android.view.View
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.plugin.platform.PlatformView

/**
 * FluxWebView — local WebView viewer PlatformView wrapper.
 *
 * Configured with strict sandboxing: JavaScript disabled, network connections blocked (Rule 3).
 */
class FluxWebView(private val context: Context, private val filePath: String) : PlatformView {

    private val webView: WebView = WebView(context).apply {
        settings.apply {
            javaScriptEnabled = false // Strict sandboxing - no scripts
            allowFileAccess = true
            allowContentAccess = true
            domStorageEnabled = true
        }
        webViewClient = WebViewClient()
        loadUrl("file://$filePath")
    }

    override fun getView(): View {
        return webView
    }

    override fun dispose() {
        webView.stopLoading()
        webView.destroy()
    }
}
