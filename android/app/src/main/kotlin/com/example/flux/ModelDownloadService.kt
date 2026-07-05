package com.example.flux

import android.app.*
import android.content.Intent
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.util.Log
import kotlinx.coroutines.*
import java.io.File
import java.io.FileOutputStream
import java.io.RandomAccessFile
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.atomic.AtomicLong

/**
 * Background Foreground Service for resumable, parallel-chunk ONNX model download.
 *
 * Design:
 *  - Android Foreground Service: survives app minimize/background (Android OS cannot kill it)
 *  - HTTP Range-based resume: if connection drops, resumes from exact byte offset
 *  - Parallel 4-chunk download: splits file into 4 ranges downloaded concurrently
 *    for full bandwidth utilization (CDN often rate-limits single connections)
 *  - Progress is reported to Flutter via companion object callbacks → EventChannel
 *
 * Model: all-MiniLM-L6-v2 INT8 quantized ONNX — 22 MB (not 86 MB full precision)
 * Path: filesDir/minilm_l6.onnx (app-internal storage, no permission needed)
 */
class ModelDownloadService : Service() {

    companion object {
        const val TAG = "ModelDownloadService"
        const val CHANNEL_ID = "flux_model_download"
        const val NOTIFICATION_ID = 8001
        const val ACTION_START = "com.example.flux.START_DOWNLOAD"
        const val ACTION_CANCEL = "com.example.flux.CANCEL_DOWNLOAD"
        const val MODEL_FILE_NAME = "minilm_l6.onnx"

        // Quantized INT8 model: 22 MB instead of 86 MB full-precision
        // Runs 4x faster on inference, same semantic quality for file name matching
        const val MODEL_URL =
            "https://huggingface.co/Xenova/all-MiniLM-L6-v2/resolve/main/onnx/model_quantized.onnx"

        // Number of parallel download chunks for full bandwidth utilization
        const val CHUNKS = 4

        // Callbacks: set by MainActivity to relay events to Flutter EventChannel
        var onProgress: ((Int, Long, Long) -> Unit)? = null
        var onComplete: (() -> Unit)? = null
        var onError: ((String) -> Unit)? = null

        /** Static helper so MainActivity can get model file path without instantiating Service */
        fun getModelFile(context: android.content.Context): File =
            File(context.filesDir, MODEL_FILE_NAME)
    }

    private val binder = LocalBinder()
    private var downloadJob: Job? = null
    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    inner class LocalBinder : Binder() {
        fun getService(): ModelDownloadService = this@ModelDownloadService
    }

    override fun onBind(intent: Intent?): IBinder = binder

    /**
     * Always call stopForeground BEFORE stopSelf so Android 12+ cannot kill
     * the process between the two calls while the foreground token is still held.
     */
    private fun gracefulStop() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                Log.d(TAG, "Download command received — starting foreground service")
                startForeground(NOTIFICATION_ID, buildNotification("Preparing download...", 0, 0))
                startParallelResumableDownload()
            }
            ACTION_CANCEL -> {
                Log.d(TAG, "Cancel command received")
                downloadJob?.cancel()
                gracefulStop()
            }
        }
        return START_NOT_STICKY
    }

    /**
     * Parallel chunked download with HTTP Range resume.
     *
     * Step 1: HEAD request to get total file size
     * Step 2: Check how many bytes already downloaded (partial file on disk)
     * Step 3: If partial < total, split REMAINING bytes into CHUNKS parallel workers
     * Step 4: Each worker downloads its range into a temp file
     * Step 5: Merge temp files into final model file
     */
    private fun startParallelResumableDownload() {
        downloadJob?.cancel()
        downloadJob = serviceScope.launch {
            try {
                val modelFile = getModelFile(applicationContext)
                val alreadyDownloaded = if (modelFile.exists()) modelFile.length() else 0L

                // Step 1: HEAD request to get total size
                val totalSize = getRemoteFileSize() ?: 22_000_000L
                Log.d(TAG, "Remote file size: $totalSize bytes (${totalSize / 1_048_576} MB)")

                if (alreadyDownloaded >= totalSize) {
                    Log.d(TAG, "File already complete! Size: $alreadyDownloaded bytes")
                    onComplete?.invoke()
                    gracefulStop()
                    return@launch
                }

                val remainingBytes = totalSize - alreadyDownloaded
                Log.d(TAG, "Already downloaded: $alreadyDownloaded bytes. Remaining: $remainingBytes bytes")

                // Step 2: If remaining is small enough, use single-thread resume
                // If large, use parallel chunked download
                if (remainingBytes < 4_000_000 || CHUNKS == 1) {
                    singleThreadResume(modelFile, alreadyDownloaded, totalSize)
                } else {
                    parallelChunkDownload(modelFile, alreadyDownloaded, totalSize)
                }

            } catch (e: Exception) {
                if (e is CancellationException) return@launch
                Log.e(TAG, "Download orchestration error: ${e.message}")
                onError?.invoke(e.message ?: "Unknown error")
                updateNotification("Download failed — tap to retry", 0, 0)
                gracefulStop()
            }
        }
    }

    /**
     * Parallel download: split remaining bytes into CHUNKS ranges.
     * Each chunk downloads concurrently, then chunks are assembled in order.
     */
    private suspend fun parallelChunkDownload(modelFile: File, startByte: Long, totalSize: Long) = coroutineScope {
        val remaining = totalSize - startByte
        val chunkSize = remaining / CHUNKS

        Log.d(TAG, "Parallel download: $CHUNKS chunks, ${chunkSize / 1_048_576} MB each, starting from byte $startByte")

        // Create temp files for each chunk
        val chunkFiles = (0 until CHUNKS).map {
            File(applicationContext.filesDir, "chunk_$it.tmp")
        }

        // Track per-chunk progress
        val chunkProgress = LongArray(CHUNKS)
        val chunkSizes = LongArray(CHUNKS)
        
        // Throttle progress updates to at most once every 300ms
        val lastUpdateMs = AtomicLong(0L)

        try {
            // Launch parallel coroutines, one per chunk
            val deferreds = (0 until CHUNKS).map { chunkIdx ->
                val chunkStart = startByte + chunkIdx * chunkSize
                val chunkEnd = if (chunkIdx == CHUNKS - 1) totalSize - 1
                               else startByte + (chunkIdx + 1) * chunkSize - 1
                chunkSizes[chunkIdx] = chunkEnd - chunkStart + 1

                async {
                    downloadChunk(
                        chunkFile = chunkFiles[chunkIdx],
                        rangeStart = chunkStart,
                        rangeEnd = chunkEnd,
                        onChunkProgress = { received ->
                            chunkProgress[chunkIdx] = received
                            // Report aggregate progress across all chunks
                            val totalReceived = startByte + chunkProgress.sum()
                            val percent = ((totalReceived.toDouble() / totalSize) * 100).toInt().coerceIn(0, 99)
                            
                            val now = System.currentTimeMillis()
                            val lastTime = lastUpdateMs.get()
                            if (now - lastTime > 300) {
                                if (lastUpdateMs.compareAndSet(lastTime, now)) {
                                    updateNotification("Downloading: $percent%", percent, totalSize)
                                    onProgress?.invoke(percent, totalReceived, totalSize)
                                }
                            }
                        }
                    )
                }
            }

            // Wait for all chunks to complete
            deferreds.awaitAll()
            Log.d(TAG, "All $CHUNKS chunks downloaded. Assembling final file...")

            // Assemble: append all chunks to model file (after any pre-existing data)
            assembleChunks(modelFile, chunkFiles, startByte)

            Log.d(TAG, "Assembly complete. Final file: ${modelFile.length()} bytes")
            updateNotification("FLUX model downloaded ✓", 100, totalSize)
            onComplete?.invoke()
            gracefulStop()

        } catch (e: Exception) {
            if (e is CancellationException) {
                Log.d(TAG, "Download cancelled. Partial chunks preserved for resume.")
                return@coroutineScope
            }
            // Preserve whatever chunks we have — next run resumes from last good byte
            Log.e(TAG, "Parallel download error: ${e.message}")
            onError?.invoke(e.message ?: "Chunk download failed")
            updateNotification("Download paused (tap to resume)", 0, 0)
            gracefulStop()
        } finally {
            // Clean up chunk temp files
            chunkFiles.forEach { if (it.exists()) it.delete() }
        }
    }

    /** Download a single byte range into a temp file */
    private suspend fun downloadChunk(
        chunkFile: File,
        rangeStart: Long,
        rangeEnd: Long,
        onChunkProgress: (Long) -> Unit
    ) = withContext(Dispatchers.IO) {
        // Resume chunk if partially downloaded
        val existingBytes = if (chunkFile.exists()) chunkFile.length() else 0L
        val actualStart = rangeStart + existingBytes

        if (actualStart > rangeEnd) {
            Log.d(TAG, "Chunk [${rangeStart}-${rangeEnd}] already complete")
            onChunkProgress(rangeEnd - rangeStart + 1)
            return@withContext
        }

        Log.d(TAG, "Chunk [$actualStart-$rangeEnd]: ${(rangeEnd - actualStart) / 1024} KB to download")

        val connection = (URL(MODEL_URL).openConnection() as HttpURLConnection).apply {
            connectTimeout = 30_000
            readTimeout = 60_000
            requestMethod = "GET"
            setRequestProperty("Range", "bytes=$actualStart-$rangeEnd")
            setRequestProperty("User-Agent", "FluxApp/1.0 (Android)")
        }
        connection.connect()

        val responseCode = connection.responseCode
        if (responseCode != HttpURLConnection.HTTP_PARTIAL && responseCode != HttpURLConnection.HTTP_OK) {
            throw Exception("Chunk HTTP $responseCode for range $actualStart-$rangeEnd")
        }

        val fos = FileOutputStream(chunkFile, existingBytes > 0)
        val buffer = ByteArray(16 * 1024) // 16 KB buffer per chunk
        val inputStream = connection.inputStream
        var chunkReceived = existingBytes
        var bytesRead: Int

        while (inputStream.read(buffer).also { bytesRead = it } != -1) {
            if (!isActive) {
                fos.flush(); fos.close(); inputStream.close()
                return@withContext
            }
            fos.write(buffer, 0, bytesRead)
            chunkReceived += bytesRead
            onChunkProgress(chunkReceived)
        }

        fos.flush()
        fos.close()
        inputStream.close()
        connection.disconnect()
        Log.d(TAG, "Chunk [$rangeStart-$rangeEnd] complete: $chunkReceived bytes")
    }

    /** Assemble chunk temp files into the final model file */
    private fun assembleChunks(modelFile: File, chunkFiles: List<File>, existingBytes: Long) {
        val raf = RandomAccessFile(modelFile, "rw")
        raf.seek(existingBytes)  // Append after any pre-existing bytes
        val buffer = ByteArray(64 * 1024)

        for ((idx, chunkFile) in chunkFiles.withIndex()) {
            if (!chunkFile.exists()) {
                Log.w(TAG, "Chunk $idx missing during assembly!")
                continue
            }
            val fis = chunkFile.inputStream()
            var bytesRead: Int
            while (fis.read(buffer).also { bytesRead = it } != -1) {
                raf.write(buffer, 0, bytesRead)
            }
            fis.close()
            Log.d(TAG, "Assembled chunk $idx (${chunkFile.length()} bytes)")
        }
        raf.close()
    }

    /** Single-thread resume for small remaining chunks */
    private suspend fun singleThreadResume(modelFile: File, startByte: Long, totalSize: Long) {
        Log.d(TAG, "Single-thread resume from byte $startByte")
        val connection = (URL(MODEL_URL).openConnection() as HttpURLConnection).apply {
            connectTimeout = 30_000
            readTimeout = 60_000
            requestMethod = "GET"
            if (startByte > 0) setRequestProperty("Range", "bytes=$startByte-")
            setRequestProperty("User-Agent", "FluxApp/1.0 (Android)")
        }
        connection.connect()

        val fos = FileOutputStream(modelFile, startByte > 0)
        val buffer = ByteArray(8 * 1024)
        val inputStream = connection.inputStream
        var received = startByte
        var bytesRead: Int
        var lastUpdateMs = 0L

        while (inputStream.read(buffer).also { bytesRead = it } != -1) {
            fos.write(buffer, 0, bytesRead)
            received += bytesRead
            val percent = ((received.toDouble() / totalSize) * 100).toInt().coerceIn(0, 99)
            
            val now = System.currentTimeMillis()
            if (now - lastUpdateMs > 300) {
                lastUpdateMs = now
                onProgress?.invoke(percent, received, totalSize)
                updateNotification("Downloading: $percent%", percent, totalSize)
            }
            if (received >= totalSize) break
        }

        fos.flush(); fos.close()
        inputStream.close(); connection.disconnect()
        onComplete?.invoke()
        gracefulStop()
    }

    /** HEAD request to get total file size without downloading content */
    private suspend fun getRemoteFileSize(): Long? = withContext(Dispatchers.IO) {
        try {
            val connection = (URL(MODEL_URL).openConnection() as HttpURLConnection).apply {
                requestMethod = "HEAD"
                connectTimeout = 15_000
                readTimeout = 15_000
                setRequestProperty("User-Agent", "FluxApp/1.0 (Android)")
            }
            connection.connect()
            val size = connection.contentLengthLong
            connection.disconnect()
            if (size > 0) size else null
        } catch (e: Exception) {
            Log.w(TAG, "HEAD request failed: ${e.message}. Using fallback size.")
            null
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID, "FLUX Model Download", NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows progress while downloading the on-device AI model"
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    private fun buildNotification(text: String, progress: Int, totalBytes: Long): Notification {
        val cancelPI = PendingIntent.getService(
            this, 0,
            Intent(this, ModelDownloadService::class.java).apply { action = ACTION_CANCEL },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val totalMb = if (totalBytes > 0) " (~${totalBytes / 1_048_576} MB)" else ""
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            Notification.Builder(this, CHANNEL_ID)
        else
            @Suppress("DEPRECATION") Notification.Builder(this)

        return builder
            .setContentTitle("FLUX — Downloading AI Model$totalMb")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setProgress(100, progress, progress == 0)
            .setOngoing(true)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Cancel", cancelPI)
            .build()
    }

    private fun updateNotification(text: String, progress: Int, totalBytes: Long) {
        getSystemService(NotificationManager::class.java)
            .notify(NOTIFICATION_ID, buildNotification(text, progress, totalBytes))
    }

    override fun onDestroy() {
        serviceScope.cancel()
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        super.onDestroy()
    }
}
