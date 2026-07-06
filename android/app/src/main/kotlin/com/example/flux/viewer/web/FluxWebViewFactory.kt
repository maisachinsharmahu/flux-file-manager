package com.example.flux.viewer.web

import android.content.Context
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class FluxWebViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as? Map<*, *>?
        val path = creationParams?.get("path") as? String ?: ""
        return FluxWebView(context, path)
    }
}
