package com.example.flux.viewer.video

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * FluxVideoViewFactory — registers com.flux/video_viewer PlatformView.
 */
class FluxVideoViewFactory(
    private val messenger: BinaryMessenger
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val params = args as? Map<String, Any>
        
        // Dynamic MethodChannel configured for each view instance
        val channel = MethodChannel(messenger, "com.flux.channel/video_player_$viewId")
        return FluxVideoView(context, viewId, params, channel)
    }
}
