package com.example.flux

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.flux.channel/methods"
    private val EVENT_CHANNEL = "com.flux.channel/search_stream"
    private val DOWNLOAD_EVENT_CHANNEL = "com.flux.channel/download_progress"

    private lateinit var fluxIndex: FluxIndex
    private var downloadProgressSink: EventChannel.EventSink? = null

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        checkAndRequestStoragePermissions()
    }

    private fun checkAndRequestStoragePermissions() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
            if (!android.os.Environment.isExternalStorageManager()) {
                try {
                    val intent = android.content.Intent(android.provider.Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION).apply {
                        data = android.net.Uri.parse("package:${packageName}")
                    }
                    startActivity(intent)
                } catch (e: Exception) {
                    val intent = android.content.Intent(android.provider.Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
                    startActivity(intent)
                }
            }
        } else {
            val permissions = arrayOf(
                android.Manifest.permission.READ_EXTERNAL_STORAGE,
                android.Manifest.permission.WRITE_EXTERNAL_STORAGE
            )
            val needed = permissions.filter {
                androidx.core.content.ContextCompat.checkSelfPermission(this, it) != android.content.pm.PackageManager.PERMISSION_GRANTED
            }
            if (needed.isNotEmpty()) {
                androidx.core.app.ActivityCompat.requestPermissions(this, needed.toTypedArray(), 1001)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        fluxIndex = FluxIndex(applicationContext)

        // Wire ModelDownloadService callbacks → Flutter EventChannel
        ModelDownloadService.onProgress = { percent, received, total ->
            runOnUiThread {
                downloadProgressSink?.success(mapOf(
                    "type" to "progress",
                    "percent" to percent,
                    "received" to received,
                    "total" to total
                ))
            }
        }
        ModelDownloadService.onComplete = {
            runOnUiThread {
                downloadProgressSink?.success(mapOf("type" to "complete"))
            }
        }
        ModelDownloadService.onError = { error ->
            runOnUiThread {
                downloadProgressSink?.success(mapOf("type" to "error", "message" to error))
            }
        }

        // EventChannel for real-time download progress (works even when app is minimized)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, DOWNLOAD_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    downloadProgressSink = events
                }
                override fun onCancel(arguments: Any?) {
                    downloadProgressSink = null
                }
            })
        // Set up MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            java.util.concurrent.ForkJoinPool.commonPool().execute {
                try {
                    when (call.method) {
                        "initializeIndex" -> {
                            fluxIndex.initialize()
                            runOnUiThread { result.success(true) }
                        }
                        "getAllFiles" -> {
                            val files = fluxIndex.getAllFiles()
                            runOnUiThread { result.success(files) }
                        }
                        "getDirectoryContents" -> {
                            val parentPath = call.argument<String>("parentPath") ?: "/"
                            val contents = fluxIndex.getDirectoryContents(parentPath)
                            runOnUiThread { result.success(contents) }
                        }
                        "executeBatchDelete" -> {
                            val fids = call.argument<List<Number>>("fids")?.map { it.toLong() } ?: listOf()
                            val success = fluxIndex.deleteBatch(fids)
                            runOnUiThread { result.success(success) }
                        }
                        "restoreTombstones" -> {
                            val fids = call.argument<List<Number>>("fids")?.map { it.toLong() } ?: listOf()
                            val success = fluxIndex.restoreBatch(fids)
                            runOnUiThread { result.success(success) }
                        }
                        "getStorageStatistics" -> {
                            val stats = fluxIndex.getStorageStatistics()
                            runOnUiThread { result.success(stats) }
                        }
                        "getAppStorageUsage" -> {
                            val usage = listOf(
                                mapOf("packageName" to "com.android.chrome", "appName" to "Google Chrome", "size" to 512 * 1024 * 1024L, "sizeString" to "512 MB"),
                                mapOf("packageName" to "com.whatsapp", "appName" to "WhatsApp", "size" to 1024 * 1024 * 1024L, "sizeString" to "1.0 GB"),
                                mapOf("packageName" to "com.google.android.youtube", "appName" to "YouTube", "size" to 800 * 1024 * 1024L, "sizeString" to "800 MB"),
                                mapOf("packageName" to "com.instagram.android", "appName" to "Instagram", "size" to 600 * 1024 * 1024L, "sizeString" to "600 MB")
                            )
                            runOnUiThread { result.success(usage) }
                        }
                        "searchAndFilter" -> {
                            val query = call.argument<String>("query") ?: ""
                            val categories = call.argument<List<String>>("categories") ?: listOf()
                            val location = call.argument<String>("location") ?: "All"
                            val showVaultOnly = call.argument<Boolean>("showVaultOnly") ?: false
                            val showDuplicatesOnly = call.argument<Boolean>("showDuplicatesOnly") ?: false
                            val sizeRange = call.argument<String>("sizeRange") ?: "All"
                            val dateRange = call.argument<String>("dateRange") ?: "All"
                            val nameSort = call.argument<String>("nameSort") ?: "Off"
                            val dateSort = call.argument<String>("dateSort") ?: "Off"
                            val sizeSort = call.argument<String>("sizeSort") ?: "Off"
                            val limit = call.argument<Int>("limit") ?: 1000

                            val resultsList = fluxIndex.searchAndFilter(
                                query = query,
                                categories = categories,
                                location = location,
                                showVaultOnly = showVaultOnly,
                                showDuplicatesOnly = showDuplicatesOnly,
                                sizeRange = sizeRange,
                                dateRange = dateRange,
                                nameSort = nameSort,
                                dateSort = dateSort,
                                sizeSort = sizeSort,
                                limit = limit
                            )
                            runOnUiThread { result.success(resultsList) }
                        }
                        "scanJunkFiles" -> {
                            val junk = fluxIndex.scanJunkFiles()
                            runOnUiThread { result.success(junk) }
                        }
                        "startModelDownload" -> {
                            // Start foreground download service — survives app minimize
                            val intent = Intent(this@MainActivity, ModelDownloadService::class.java).apply {
                                action = ModelDownloadService.ACTION_START
                            }
                            startForegroundService(intent)
                            runOnUiThread { result.success(true) }
                        }
                        "cancelModelDownload" -> {
                            val intent = Intent(this@MainActivity, ModelDownloadService::class.java).apply {
                                action = ModelDownloadService.ACTION_CANCEL
                            }
                            startService(intent)
                            runOnUiThread { result.success(true) }
                        }
                        "getModelFilePath" -> {
                            // Return model path so ONNX runtime can load it
                            val service = ModelDownloadService()
                            val file = service.getModelFile()
                            runOnUiThread { result.success(if (file.exists()) file.absolutePath else null) }
                        }
                        else -> {
                            runOnUiThread { result.notImplemented() }
                        }
                    }
                } catch (e: Exception) {
                    runOnUiThread { result.error("KOTLIN_BRIDGE_ERROR", e.message, null) }
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
