package com.example.flux.viewer.pdf

import android.content.Context
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * FluxPdfPageViewFactory — factory mapping com.flux/pdf_page_view.
 */
class FluxPdfPageViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val params = args as? Map<String, Any>
        return FluxPdfPageView(context, viewId, params)
    }
}
