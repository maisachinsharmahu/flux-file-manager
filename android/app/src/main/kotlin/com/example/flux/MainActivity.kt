package com.example.flux

import android.content.Intent
import android.net.Uri
import android.util.Log
import com.example.flux.viewer.ViewerEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.flux.channel/methods"
    private val EVENT_CHANNEL = "com.flux.channel/search_stream"
    private val DOWNLOAD_EVENT_CHANNEL = "com.flux.channel/download_progress"
    private val COPY_PROGRESS_CHANNEL = "com.flux.channel/copy_progress"

    private lateinit var fluxIndex: FluxIndex
    private var downloadProgressSink: EventChannel.EventSink? = null
    private var copyProgressChannel: MethodChannel? = null
    private var bridgeChannel: MethodChannel? = null

    // Pending file intent from ACTION_VIEW — delivered to Flutter once bridge is ready
    private var pendingIntentFilePath: String? = null
    private var audioMediaPlayer: android.media.MediaPlayer? = null

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        checkAndRequestStoragePermissions()
        // Handle file intent if app was opened via ACTION_VIEW
        handleIncomingIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // App already running — handle new ACTION_VIEW intent
        handleIncomingIntent(intent)
        // Notify Flutter immediately if bridge is already set up
        pendingIntentFilePath?.let { path ->
            bridgeChannel?.invokeMethod("onIntentFile", path)
        }
    }

    /**
     * Handle ACTION_VIEW intent from external apps (file managers, email, etc.).
     * Resolves the URI to an absolute path and stores for Flutter retrieval.
     */
    private fun handleIncomingIntent(intent: Intent?) {
        if (intent?.action != Intent.ACTION_VIEW) return
        val uri: Uri = intent.data ?: return

        // Resolve on background thread — content:// URIs may require IO
        java.util.concurrent.ForkJoinPool.commonPool().execute {
            try {
                val path = ViewerEngine.resolveUri(applicationContext, uri)
                if (path != null) {
                    pendingIntentFilePath = path
                    Log.d("FLUX_VIEWER", "Intent file resolved: $path")
                    // Notify Flutter (may be null if bridge not set up yet — Flutter polls via getIntentFilePath)
                    runOnUiThread {
                        bridgeChannel?.invokeMethod("onIntentFile", path)
                    }
                } else {
                    Log.w("FLUX_VIEWER", "Could not resolve intent URI: $uri")
                }
            } catch (e: Exception) {
                Log.e("FLUX_VIEWER", "Intent handling error: ${e.message}")
            }
        }
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

    private fun checkAndRequestUsageStatsPermission() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            try {
                val appOps = getSystemService(android.content.Context.APP_OPS_SERVICE) as? android.app.AppOpsManager
                if (appOps != null) {
                    val mode = appOps.unsafeCheckOpNoThrow(
                        android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                        android.os.Process.myUid(),
                        packageName
                    )
                    if (mode != android.app.AppOpsManager.MODE_ALLOWED) {
                        val intent = android.content.Intent(android.provider.Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                            data = android.net.Uri.parse("package:${packageName}")
                        }
                        startActivity(intent)
                    }
                }
            } catch (e: Exception) {
                try {
                    val intent = android.content.Intent(android.provider.Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    startActivity(intent)
                } catch (ex: Exception) {
                    android.util.Log.e("MainActivity", "Failed to open usage access settings: ${ex.message}")
                }
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

        // MethodChannel for copy progress — Kotlin pushes Double (0.0→1.0) via invokeMethod.
        copyProgressChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, COPY_PROGRESS_CHANNEL)

        // Set up MethodChannel
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
        bridgeChannel = channel
        
        fluxIndex.onIndexChanged = {
            runOnUiThread {
                bridgeChannel?.invokeMethod("onIndexChanged", null)
            }
        }

        // Register native platform views
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "com.flux/image_viewer",
            com.example.flux.viewer.image.FluxImageViewFactory()
        )
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "com.flux/video_viewer",
            com.example.flux.viewer.video.FluxVideoViewFactory(flutterEngine.dartExecutor.binaryMessenger)
        )
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "com.flux/text_viewer",
            com.example.flux.viewer.text.FluxTextViewFactory()
        )
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "com.flux/pdf_page_view",
            com.example.flux.viewer.pdf.FluxPdfPageViewFactory()
        )
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "com.flux/web_view",
            com.example.flux.viewer.web.FluxWebViewFactory()
        )
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "com.flux/svg_view",
            com.example.flux.viewer.svg.FluxSvgViewFactory()
        )
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "com.flux/font_view",
            com.example.flux.viewer.font.FluxFontViewFactory()
        )

        channel.setMethodCallHandler { call, result ->
            java.util.concurrent.ForkJoinPool.commonPool().execute {
                try {
                    when (call.method) {
                        "initializeIndex" -> {
                            val force = call.argument<Boolean>("force") ?: false
                            fluxIndex.initialize(force)
                            runOnUiThread { result.success(true) }
                        }
                        "getAllFiles" -> {
                            val files = fluxIndex.getAllFiles()
                            runOnUiThread { result.success(files) }
                        }
                        "getFileCount" -> {
                            runOnUiThread { result.success(fluxIndex.fileCount) }
                        }
                        "getDirectoryContents" -> {
                            val parentPath = call.argument<String>("parentPath") ?: "/"
                            val contents = fluxIndex.getDirectoryContents(parentPath)
                            runOnUiThread { result.success(contents) }
                        }
                        "executeBatchDelete" -> {
                            val fids = call.argument<List<Number>>("fids")?.map { it.toLong() } ?: listOf()
                            val recursive = call.argument<Boolean>("recursive") ?: true
                            val success = fluxIndex.deleteBatch(fids, recursive)
                            runOnUiThread { result.success(success) }
                        }
                        "restoreTombstones" -> {
                            val fids = call.argument<List<Number>>("fids")?.map { it.toLong() } ?: listOf()
                            val recursive = call.argument<Boolean>("recursive") ?: true
                            val success = fluxIndex.restoreBatch(fids, recursive)
                            runOnUiThread { result.success(success) }
                        }
                        "getTombstones" -> {
                            val tombstones = fluxIndex.getTombstones()
                            runOnUiThread { result.success(tombstones) }
                        }
                        "deletePermanently" -> {
                            val fids = call.argument<List<Number>>("fids")?.map { it.toLong() } ?: listOf()
                            val recursive = call.argument<Boolean>("recursive") ?: true
                            val success = fluxIndex.deletePermanently(fids, recursive)
                            runOnUiThread { result.success(success) }
                        }
                        "schedulePhysicalDelete" -> {
                            // Fire-and-forget: logical delete already done, schedule disk cleanup.
                            val fids = call.argument<List<Number>>("fids")?.map { it.toLong() } ?: listOf()
                            fluxIndex.schedulePhysicalDelete(applicationContext, fids)
                            runOnUiThread { result.success(true) } // returns immediately
                        }
                        "moveFiles" -> {
                            val fids = call.argument<List<Number>>("fids")?.map { it.toLong() } ?: listOf()
                            val destinationPath = call.argument<String>("destinationPath") ?: ""
                            // Move is O(1) per file (rename syscall), safe to run on background thread.
                            Thread {
                                val success = fluxIndex.moveFiles(fids, destinationPath)
                                runOnUiThread { result.success(success) }
                            }.apply { isDaemon = true }.start()
                        }
                        "copyFilesWithProgress" -> {
                            val fids = call.argument<List<Number>>("fids")?.map { it.toLong() } ?: listOf()
                            val destinationPath = call.argument<String>("destinationPath") ?: ""
                            // Copy runs on IO thread; progress is reported via a side-channel EventChannel
                            // but for simplicity we stream chunk-level progress through the result channel.
                            // Dart receives a final true/false; progress is polled via getLastCopyProgress.
                            Thread {
                                val success = fluxIndex.copyFilesWithProgress(fids, destinationPath) { progress ->
                                    runOnUiThread {
                                        copyProgressChannel?.invokeMethod("onProgress", progress)
                                    }
                                }
                                runOnUiThread { result.success(success) }
                            }.apply { isDaemon = true }.start()
                        }
                        "createDirectory" -> {
                            val parentPath = call.argument<String>("parentPath") ?: ""
                            val name = call.argument<String>("name") ?: ""
                            val success = fluxIndex.createDirectory(parentPath, name)
                            runOnUiThread { result.success(success) }
                        }
                        "getAllDirectoryFids" -> {
                            val parentPath = call.argument<String>("parentPath") ?: ""
                            val fids = fluxIndex.getAllDirectoryFids(parentPath)
                            runOnUiThread { result.success(fids) }
                        }
                        "expandFolderFids" -> {
                            val fids = call.argument<List<Number>>("fids")?.map { it.toLong() } ?: listOf()
                            val expanded = fluxIndex.expandFolderFids(fids)
                            runOnUiThread { result.success(expanded) }
                        }
                        "getTotalBytes" -> {
                            val fids = call.argument<List<Number>>("fids")?.map { it.toLong() } ?: listOf()
                            val totalBytes = fluxIndex.getTotalBytes(fids)
                            runOnUiThread { result.success(totalBytes) }
                        }
                        "requestUsageStatsPermission" -> {
                            checkAndRequestUsageStatsPermission()
                            runOnUiThread { result.success(true) }
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
                        "generateTestFiles" -> {
                             val count = call.argument<Int>("count") ?: 1000000
                             val targetSizeGb = call.argument<Double>("targetSizeGb") ?: 25.0
                             try {
                                 val intent = Intent(this@MainActivity, FileGenerationService::class.java).apply {
                                     action = FileGenerationService.ACTION_START
                                     putExtra("count", count)
                                     putExtra("targetSizeGb", targetSizeGb)
                                 }
                                 startForegroundService(intent)
                                 runOnUiThread { result.success(true) }
                             } catch (e: Exception) {
                                 Log.e("FLUX_TEST", "Failed starting generation service: ${e.message}")
                                 runOnUiThread { result.error("ERROR", e.message, null) }
                             }
                         }
                         "getFileGenerationStatus" -> {
                             runOnUiThread {
                                 result.success(mapOf(
                                     "isGenerating" to FileGenerationService.isGenerating,
                                     "progressPercent" to FileGenerationService.progressPercent,
                                     "filesCreated" to FileGenerationService.filesCreated,
                                     "totalCount" to FileGenerationService.totalCount
                                 ))
                             }
                         }
                         "cancelFileGeneration" -> {
                             try {
                                 val intent = Intent(this@MainActivity, FileGenerationService::class.java).apply {
                                     action = FileGenerationService.ACTION_CANCEL
                                 }
                                 startService(intent)
                                 runOnUiThread { result.success(true) }
                             } catch (e: Exception) {
                                 runOnUiThread { result.error("ERROR", e.message, null) }
                             }
                         }
                        "clearTestFiles" -> {
                             java.util.concurrent.ForkJoinPool.commonPool().execute {
                                 try {
                                     val filesDir = java.io.File(android.os.Environment.getExternalStorageDirectory(), "flux_test_files")
                                     Log.d("FLUX_TEST", "=== Clearing test files ===")
                                     val folders = listOf("Photos", "Videos", "Documents", "Audio", "Downloads", "Others", "Games", "System")
                                     var countDeleted = 0
                                     for (folderName in folders) {
                                         val folder = java.io.File(filesDir, folderName)
                                         if (folder.exists() && folder.isDirectory) {
                                             val files = folder.listFiles() ?: continue
                                             for (file in files) {
                                                 if (file.name.startsWith("test_file_")) {
                                                     file.delete()
                                                     countDeleted++
                                                 }
                                             }
                                         }
                                     }
                                     Log.d("FLUX_TEST", "=== Success: Deleted $countDeleted test files ===")
                                     fluxIndex.initialize(force = true)
                                     runOnUiThread { result.success(countDeleted) }
                                 } catch (e: Exception) {
                                     Log.e("FLUX_TEST", "Failed clearing test files: ${e.message}")
                                     runOnUiThread { result.error("ERROR", e.message, null) }
                                 }
                             }
                         }
                        "scanJunkFiles" -> {
                            val junk = fluxIndex.scanJunkFiles()
                            runOnUiThread { result.success(junk) }
                        }
                        "getDuplicateGroups" -> {
                            val groups = fluxIndex.getDuplicateGroups()
                            runOnUiThread { result.success(groups) }
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
                        "shareFiles" -> {
                            val paths = call.argument<List<String>>("paths") ?: listOf()
                            if (paths.isNotEmpty()) {
                                shareFilesNative(paths)
                            }
                            runOnUiThread { result.success(true) }
                        }
                        // ─── FLUX Viewer Engine ──────────────────────────────
                        "getIntentFilePath" -> {
                            // Flutter polls this on startup to check if we were opened via intent
                            val path = pendingIntentFilePath
                            pendingIntentFilePath = null  // consume once delivered
                            runOnUiThread { result.success(path) }
                        }
                        "resolveContentUri" -> {
                            val uriString = call.argument<String>("uri") ?: ""
                            try {
                                val uri = Uri.parse(uriString)
                                val path = ViewerEngine.resolveUri(applicationContext, uri)
                                runOnUiThread { result.success(path) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("URI_ERROR", e.message, null) }
                            }
                        }
                        "extractAudioWaveform" -> {
                            val filePath = call.argument<String>("path") ?: ""
                            val bars = call.argument<Int>("bars") ?: 256
                            try {
                                val points = com.example.flux.viewer.audio.AudioWaveformExtractor.extract(filePath, bars)
                                val list = points.toList()
                                runOnUiThread { result.success(list) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("WAVEFORM_ERROR", e.message, null) }
                            }
                        }
                        "getFileContent" -> {
                            val filePath = call.argument<String>("path") ?: ""
                            try {
                                val mmap = com.example.flux.viewer.MmapSource(java.io.File(filePath))
                                val size = mmap.size.toInt().coerceAtMost(10 * 1024 * 1024) // 10MB limit safety
                                val slice = mmap.slice(0, size)
                                val bytes = ByteArray(size)
                                slice.get(bytes)
                                mmap.close()
                                val content = String(bytes, java.nio.charset.StandardCharsets.UTF_8)
                                runOnUiThread { result.success(content) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("READ_ERROR", e.message, null) }
                            }
                        }
                        "getFileLines" -> {
                            val filePath = call.argument<String>("path") ?: ""
                            val start = call.argument<Int>("start") ?: 0
                            val count = call.argument<Int>("count") ?: 50
                            try {
                                val mmap = com.example.flux.viewer.MmapSource(java.io.File(filePath))
                                val index = com.example.flux.viewer.text.LineIndex(mmap)
                                val lines = ArrayList<String>()
                                val end = (start + count).coerceAtMost(index.lineCount)
                                for (i in start until end) {
                                    lines.add(index.getLineText(i))
                                }
                                mmap.close()
                                runOnUiThread { result.success(lines) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("READ_ERROR", e.message, null) }
                            }
                        }
                        "getPdfPageCount" -> {
                            val filePath = call.argument<String>("path") ?: ""
                            try {
                                val count = com.example.flux.viewer.pdf.PdfRenderService.getPageCount(filePath)
                                runOnUiThread { result.success(count) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("PDF_ERROR", e.message, null) }
                            }
                        }
                        "closePdf" -> {
                            val filePath = call.argument<String>("path") ?: ""
                            try {
                                com.example.flux.viewer.pdf.PdfRenderService.closePdf(filePath)
                                runOnUiThread { result.success(true) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("PDF_ERROR", e.message, null) }
                            }
                        }
                        "parseDocx" -> {
                            val filePath = call.argument<String>("path") ?: ""
                            try {
                                val json = com.example.flux.viewer.office.OfficeParser.parseDocx(filePath)
                                runOnUiThread { result.success(json) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("OFFICE_ERROR", e.message, null) }
                            }
                        }
                        "parseXlsx" -> {
                            val filePath = call.argument<String>("path") ?: ""
                            try {
                                val json = com.example.flux.viewer.office.OfficeParser.parseXlsx(filePath)
                                runOnUiThread { result.success(json) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("OFFICE_ERROR", e.message, null) }
                            }
                        }
                        "parsePptx" -> {
                            val filePath = call.argument<String>("path") ?: ""
                            try {
                                val json = com.example.flux.viewer.office.OfficeParser.parsePptx(filePath)
                                runOnUiThread { result.success(json) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("OFFICE_ERROR", e.message, null) }
                            }
                        }
                        "getSqliteTables" -> {
                            val filePath = call.argument<String>("path") ?: ""
                            try {
                                val json = com.example.flux.viewer.data.SqliteParser.getSqliteTables(filePath)
                                runOnUiThread { result.success(json) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("SQLITE_ERROR", e.message, null) }
                            }
                        }
                        "getSqliteTableSchema" -> {
                            val filePath = call.argument<String>("path") ?: ""
                            val tableName = call.argument<String>("table") ?: ""
                            try {
                                val json = com.example.flux.viewer.data.SqliteParser.getSqliteTableSchema(filePath, tableName)
                                runOnUiThread { result.success(json) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("SQLITE_ERROR", e.message, null) }
                            }
                        }
                        "getSqliteTableRows" -> {
                            val filePath = call.argument<String>("path") ?: ""
                            val tableName = call.argument<String>("table") ?: ""
                            val offset = call.argument<Int>("offset") ?: 0
                            val limit = call.argument<Int>("limit") ?: 50
                            try {
                                val json = com.example.flux.viewer.data.SqliteParser.getSqliteTableRows(filePath, tableName, offset, limit)
                                runOnUiThread { result.success(json) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("SQLITE_ERROR", e.message, null) }
                            }
                        }
                        "closeCsv" -> {
                            val filePath = call.argument<String>("path") ?: ""
                            try {
                                com.example.flux.viewer.data.CsvParser.closeCsv(filePath)
                                runOnUiThread { result.success(true) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("CSV_ERROR", e.message, null) }
                            }
                        }
                        "getCsvMetadata" -> {
                            val filePath = call.argument<String>("path") ?: ""
                            try {
                                val json = com.example.flux.viewer.data.CsvParser.getCsvMetadata(filePath)
                                runOnUiThread { result.success(json) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("CSV_ERROR", e.message, null) }
                            }
                        }
                        "getCsvRows" -> {
                            val filePath = call.argument<String>("path") ?: ""
                            val offset = call.argument<Int>("offset") ?: 0
                            val limit = call.argument<Int>("limit") ?: 50
                            try {
                                val json = com.example.flux.viewer.data.CsvParser.getCsvRows(filePath, offset, limit)
                                runOnUiThread { result.success(json) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("CSV_ERROR", e.message, null) }
                            }
                        }
                        "getArchiveEntries" -> {
                            val filePath = call.argument<String>("path") ?: ""
                            try {
                                val json = com.example.flux.viewer.archive.ArchiveParser.getArchiveEntries(filePath)
                                runOnUiThread { result.success(json) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("ARCHIVE_ERROR", e.message, null) }
                            }
                        }
                        "extractArchiveEntry" -> {
                            val filePath = call.argument<String>("path") ?: ""
                            val entryName = call.argument<String>("entry") ?: ""
                            val destPath = call.argument<String>("dest") ?: ""
                            try {
                                val ok = com.example.flux.viewer.archive.ArchiveParser.extractArchiveEntry(filePath, entryName, destPath)
                                runOnUiThread { result.success(ok) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("ARCHIVE_ERROR", e.message, null) }
                            }
                        }
                        "getApkMetadata" -> {
                            val filePath = call.argument<String>("path") ?: ""
                            try {
                                val json = com.example.flux.viewer.archive.ApkInfoReader.getApkMetadata(applicationContext, filePath)
                                runOnUiThread { result.success(json) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("APK_ERROR", e.message, null) }
                            }
                        }
                        "getEpubChapters" -> {
                            val filePath = call.argument<String>("path") ?: ""
                            try {
                                val json = com.example.flux.viewer.archive.EpubManifestParser.getEpubChapters(filePath)
                                runOnUiThread { result.success(json) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("EPUB_ERROR", e.message, null) }
                            }
                        }
                        "playAudio" -> {
                            val filePath = call.argument<String>("path") ?: ""
                            try {
                                if (audioMediaPlayer == null) {
                                    audioMediaPlayer = android.media.MediaPlayer().apply {
                                        setDataSource(filePath)
                                        prepare()
                                    }
                                }
                                audioMediaPlayer?.start()
                                runOnUiThread { result.success(true) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("PLAY_ERROR", e.message, null) }
                            }
                        }
                        "pauseAudio" -> {
                            try {
                                audioMediaPlayer?.pause()
                                runOnUiThread { result.success(true) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("PAUSE_ERROR", e.message, null) }
                            }
                        }
                        "seekAudio" -> {
                            val position = call.argument<Int>("position") ?: 0
                            try {
                                audioMediaPlayer?.seekTo(position)
                                runOnUiThread { result.success(true) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("SEEK_ERROR", e.message, null) }
                            }
                        }
                        "getAudioPosition" -> {
                            runOnUiThread { result.success(audioMediaPlayer?.currentPosition ?: 0) }
                        }
                        "getAudioDuration" -> {
                            runOnUiThread { result.success(audioMediaPlayer?.duration ?: 0) }
                        }
                        "stopAudio" -> {
                            try {
                                audioMediaPlayer?.stop()
                                audioMediaPlayer?.release()
                                audioMediaPlayer = null
                                runOnUiThread { result.success(true) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("STOP_ERROR", e.message, null) }
                            }
                        }
                        "detectFileFormat" -> {
                            val filePath = call.argument<String>("path") ?: ""
                            try {
                                val session = ViewerEngine.open(filePath)
                                val formatName = session.format.name
                                session.close()
                                runOnUiThread { result.success(formatName) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("FORMAT_ERROR", e.message, null) }
                            }
                        }
                        "getModelFilePath" -> {
                            // FIXED: Do NOT instantiate Service directly (no Context available)
                            // Use applicationContext.filesDir directly instead
                            val file = java.io.File(applicationContext.filesDir, "minilm_l6.onnx")
                            runOnUiThread { result.success(if (file.exists() && file.length() > 1_000_000) file.absolutePath else null) }
                        }
                        else -> {
                            runOnUiThread { result.notImplemented() }
                        }
                    }
                } catch (e: Throwable) {
                    android.util.Log.e("MainActivity", "KOTLIN_BRIDGE_ERROR inside method execution", e)
                    runOnUiThread { result.error("KOTLIN_BRIDGE_ERROR", e.toString(), null) }
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

    private fun shareFilesNative(paths: List<String>) {
        try {
            val uris = ArrayList<android.net.Uri>()
            for (path in paths) {
                val file = java.io.File(path)
                if (file.exists()) {
                    val uri = androidx.core.content.FileProvider.getUriForFile(
                        applicationContext,
                        "${packageName}.fileprovider",
                        file
                    )
                    uris.add(uri)
                }
            }

            if (uris.isEmpty()) return

            val intent = if (uris.size == 1) {
                Intent(Intent.ACTION_SEND).apply {
                    putExtra(Intent.EXTRA_STREAM, uris[0])
                    type = getMimeTypeFromPath(paths[0])
                }
            } else {
                Intent(Intent.ACTION_SEND_MULTIPLE).apply {
                    putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
                    type = "*/*"
                }
            }

            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            val chooser = Intent.createChooser(intent, "Share Files")
            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(chooser)
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Failed to share files: ${e.message}", e)
        }
    }

    private fun getMimeTypeFromPath(path: String): String {
        val extension = path.substringAfterLast('.', "").lowercase()
        return android.webkit.MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension) ?: "*/*"
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
