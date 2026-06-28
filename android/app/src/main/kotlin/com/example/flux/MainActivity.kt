package com.example.flux

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.flux.channel/methods"
    private val EVENT_CHANNEL = "com.flux.channel/search_stream"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Set up MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeIndex" -> {
                    result.success(true)
                }
                "getDirectoryContents" -> {
                    result.success(listOf<Any>())
                }
                "executeBatchDelete" -> {
                    result.success(true)
                }
                "restoreTombstones" -> {
                    result.success(true)
                }
                "getStorageStatistics" -> {
                    result.success(mapOf<Any, Any>())
                }
                "getAppStorageUsage" -> {
                    result.success(listOf<Any>())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Set up EventChannel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    events?.endOfStream()
                }

                override fun onCancel(arguments: Any?) {}
            }
        )
    }
}
