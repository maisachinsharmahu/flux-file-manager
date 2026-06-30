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
import java.net.HttpURLConnection
import java.net.URL

/**
 * Background Foreground Service for resumable ONNX model download.
 *
 * Design:
 *  - Runs as Android foreground service (persistent notification) so Android OS
 *    does NOT kill this when app is minimized.
 *  - Uses HTTP Range headers: "Range: bytes=<startByte>-" to resume from
 *    the exact byte where the previous download was interrupted.
 *  - Progress is reported via callbacks to ModelSyncBridge.
 *  - On success/failure, posts result back to Flutter via MethodChannel.
 */
class ModelDownloadService : Service() {

    companion object {
        const val TAG = "ModelDownloadService"
        const val CHANNEL_ID = "flux_model_download"
        const val NOTIFICATION_ID = 8001
        const val ACTION_START = "com.example.flux.START_DOWNLOAD"
        const val ACTION_CANCEL = "com.example.flux.CANCEL_DOWNLOAD"
        const val MODEL_URL =
            "https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2/resolve/main/onnx/model.onnx"

        // Callback interface — set by MainActivity to relay progress to Flutter
        var onProgress: ((Int, Long, Long) -> Unit)? = null  // (percent, received, total)
        var onComplete: (() -> Unit)? = null
        var onError: ((String) -> Unit)? = null
    }

    private val binder = LocalBinder()
    private var downloadJob: Job? = null
    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    inner class LocalBinder : Binder() {
        fun getService(): ModelDownloadService = this@ModelDownloadService
    }

    override fun onBind(intent: Intent?): IBinder = binder

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                Log.d(TAG, "Download command received — starting foreground service")
                startForeground(NOTIFICATION_ID, buildNotification("Preparing download...", 0))
                startResumableDownload()
            }
            ACTION_CANCEL -> {
                Log.d(TAG, "Cancel command received")
                downloadJob?.cancel()
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    /**
     * Core download logic.
     * HTTP Range header allows resuming from any byte offset.
     * Partial file preserved on disk so restart picks up where it left off.
     */
    private fun startResumableDownload() {
        downloadJob?.cancel()
        downloadJob = serviceScope.launch {
            try {
                val modelFile = getModelFile()
                val startByte = if (modelFile.exists()) modelFile.length() else 0L

                Log.d(TAG, "Resume download from byte $startByte (${startByte / 1_048_576} MB already downloaded)")

                val connection = (URL(MODEL_URL).openConnection() as HttpURLConnection).apply {
                    connectTimeout = 30_000
                    readTimeout = 60_000
                    requestMethod = "GET"
                    if (startByte > 0) {
                        // HTTP Range header: continue from byte N
                        setRequestProperty("Range", "bytes=$startByte-")
                    }
                    setRequestProperty("User-Agent", "FluxApp/1.0 (Android)")
                }

                connection.connect()

                val responseCode = connection.responseCode
                Log.d(TAG, "HTTP Response: $responseCode")

                // 200 = full response, 206 = partial content (resume supported)
                if (responseCode != HttpURLConnection.HTTP_OK &&
                    responseCode != HttpURLConnection.HTTP_PARTIAL) {
                    throw Exception("HTTP error $responseCode")
                }

                // If server returned 200 but we expected 206, reset startByte
                val actualStart = if (responseCode == HttpURLConnection.HTTP_OK) 0L else startByte
                val contentLength = connection.contentLengthLong
                val totalBytes = if (contentLength > 0) contentLength + actualStart else 86_000_000L

                Log.d(TAG, "Total size: $totalBytes bytes. Starting from byte $actualStart")

                // Open file in append mode if resuming, write mode if fresh start
                val fos = FileOutputStream(modelFile, actualStart > 0)
                val inputStream = connection.inputStream
                val buffer = ByteArray(8 * 1024) // 8 KB buffer

                var received = actualStart
                var lastNotifyMs = System.currentTimeMillis()
                var bytesRead: Int

                while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                    if (!isActive) {
                        // Service cancelled
                        fos.flush()
                        fos.close()
                        inputStream.close()
                        Log.d(TAG, "Download cancelled at $received bytes")
                        return@launch
                    }

                    fos.write(buffer, 0, bytesRead)
                    received += bytesRead

                    // Notify progress every 300ms to avoid flooding the main thread
                    val now = System.currentTimeMillis()
                    if (now - lastNotifyMs > 300) {
                        lastNotifyMs = now
                        val percent = ((received.toDouble() / totalBytes) * 100).toInt().coerceIn(0, 99)
                        updateNotification("Downloading FLUX model: $percent%", percent)
                        onProgress?.invoke(percent, received, totalBytes)
                        Log.d(TAG, "Download: $percent% (${received / 1_048_576} MB / ${totalBytes / 1_048_576} MB)")
                    }
                }

                fos.flush()
                fos.close()
                inputStream.close()
                connection.disconnect()

                Log.d(TAG, "Download complete! File size: ${modelFile.length()} bytes")
                updateNotification("FLUX model downloaded ✓", 100)
                onComplete?.invoke()
                stopSelf()

            } catch (e: Exception) {
                if (e is CancellationException) return@launch
                Log.e(TAG, "Download error: ${e.message}")
                // Partial file preserved — next start will resume from this offset
                val partialBytes = getModelFile().let { if (it.exists()) it.length() else 0L }
                Log.d(TAG, "Partial file preserved: $partialBytes bytes. Next start will resume.")
                onError?.invoke(e.message ?: "Unknown error")
                updateNotification("Download failed — will resume on retry", 0)
                stopSelf()
            }
        }
    }

    fun getModelFile(): File {
        val dir = filesDir  // App-internal storage (no permission needed)
        return File(dir, "minilm_l6.onnx")
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "FLUX Model Download",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows progress while downloading the on-device AI model"
                setShowBadge(false)
            }
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(text: String, progress: Int): Notification {
        val cancelIntent = Intent(this, ModelDownloadService::class.java).apply {
            action = ACTION_CANCEL
        }
        val cancelPI = PendingIntent.getService(
            this, 0, cancelIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        return builder
            .setContentTitle("FLUX — Downloading AI Model")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setProgress(100, progress, progress == 0)
            .setOngoing(true)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Cancel", cancelPI)
            .build()
    }

    private fun updateNotification(text: String, progress: Int) {
        val nm = getSystemService(NotificationManager::class.java)
        nm.notify(NOTIFICATION_ID, buildNotification(text, progress))
    }

    override fun onDestroy() {
        serviceScope.cancel()
        super.onDestroy()
    }
}
