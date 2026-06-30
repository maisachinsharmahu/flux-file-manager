package com.example.flux

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.flux.channel/methods"
    private val EVENT_CHANNEL = "com.flux.channel/search_stream"
    
    private lateinit var fluxIndex: FluxIndex

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        fluxIndex = FluxIndex(applicationContext)

        // Set up MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeIndex" -> {
                    fluxIndex.initialize()
                    result.success(true)
                }
                "getAllFiles" -> {
                    result.success(fluxIndex.getAllFiles())
                }
                "getDirectoryContents" -> {
                    val parentPath = call.argument<String>("parentPath") ?: "/"
                    result.success(fluxIndex.getDirectoryContents(parentPath))
                }
                "executeBatchDelete" -> {
                    val fids = call.argument<List<Number>>("fids")?.map { it.toLong() } ?: listOf()
                    result.success(fluxIndex.deleteBatch(fids))
                }
                "restoreTombstones" -> {
                    val fids = call.argument<List<Number>>("fids")?.map { it.toLong() } ?: listOf()
                    result.success(fluxIndex.restoreBatch(fids))
                }
                "getStorageStatistics" -> {
                    result.success(fluxIndex.getStorageStatistics())
                }
                "getAppStorageUsage" -> {
                    result.success(listOf(
                        mapOf("packageName" to "com.android.chrome", "appName" to "Google Chrome", "size" to 512 * 1024 * 1024L, "sizeString" to "512 MB"),
                        mapOf("packageName" to "com.whatsapp", "appName" to "WhatsApp", "size" to 1024 * 1024 * 1024L, "sizeString" to "1.0 GB"),
                        mapOf("packageName" to "com.google.android.youtube", "appName" to "YouTube", "size" to 800 * 1024 * 1024L, "sizeString" to "800 MB"),
                        mapOf("packageName" to "com.instagram.android", "appName" to "Instagram", "size" to 600 * 1024 * 1024L, "sizeString" to "600 MB")
                    ))
                }
                "scanJunkFiles" -> {
                    result.success(fluxIndex.scanJunkFiles())
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
                    val args = arguments as? Map<String, Any>
                    val query = args?.get("query") as? String ?: ""
                    val limit = (args?.get("limit") as? Number)?.toInt() ?: 50
                    
                    val results = fluxIndex.search(query, limit)
                    events?.success(results)
                    events?.endOfStream()
                }

                override fun onCancel(arguments: Any?) {}
            }
        )
    }

    override fun onTrimMemory(level: Int) {
        super.onTrimMemory(level)
        when (level) {
            TRIM_MEMORY_RUNNING_MODERATE -> {
                fluxIndex.evictChecksumMap()
            }
            TRIM_MEMORY_RUNNING_CRITICAL -> {
                fluxIndex.evictWarmStore()
            }
            TRIM_MEMORY_BACKGROUND -> {
                // Pause background threads
            }
            TRIM_MEMORY_COMPLETE -> {
                fluxIndex.emergencyFlush()
            }
        }
    }
}
