package com.example.flux

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import java.io.File
import java.io.FileOutputStream
import kotlin.concurrent.thread

class FileGenerationService : Service() {

    companion object {
        const val TAG = "FileGenerationService"
        const val CHANNEL_ID = "flux_file_generation"
        const val NOTIFICATION_ID = 8002
        const val ACTION_START = "com.example.flux.START_GENERATION"
        const val ACTION_CANCEL = "com.example.flux.CANCEL_GENERATION"

        // Global status flags so MainActivity/Flutter can check if it is active
        @Volatile var isGenerating = false
        @Volatile var progressPercent = 0
        @Volatile var filesCreated = 0
        @Volatile var totalCount = 1000000
    }

    private var activeThread: Thread? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val count = intent.getIntExtra("count", 1000000)
                val targetSizeGb = intent.getDoubleExtra("targetSizeGb", 25.0)
                totalCount = count
                Log.d(TAG, "Start generation command received: count=$count, size=$targetSizeGb GB")
                
                // Show notification and start foreground immediately
                startForeground(NOTIFICATION_ID, buildNotification("Preparing test files...", 0))
                
                startGenerationThread(count, targetSizeGb)
            }
            ACTION_CANCEL -> {
                Log.d(TAG, "Cancel command received")
                cancelGeneration()
            }
        }
        return START_NOT_STICKY
    }

    private fun startGenerationThread(count: Int, targetSizeGb: Double) {
        if (isGenerating) return
        isGenerating = true
        progressPercent = 0
        filesCreated = 0

        activeThread = thread(start = true) {
            try {
                val filesDir = File(android.os.Environment.getExternalStorageDirectory(), "flux_test_files")
                if (!filesDir.exists()) {
                    filesDir.mkdirs()
                }

                val start = System.currentTimeMillis()
                val targetBytes = (targetSizeGb * 1024 * 1024 * 1024).toLong()
                val avgFileBytes = targetBytes / count
                val buffer = ByteArray(avgFileBytes.toInt().coerceAtLeast(16))

                val extensions = listOf("jpg", "png", "mp4", "mp3", "pdf", "docx", "txt", "zip", "apk")
                val folders = listOf("Photos", "Videos", "Documents", "Audio", "Downloads", "Others", "Games", "System")

                for (folder in folders) {
                    File(filesDir, folder).mkdirs()
                }

                Log.d(TAG, "Directory structure pre-created. Beginning file generation loop...")
                updateNotification("Generating 1M test files...", 0)

                var bytesWritten = 0L

                for (i in 1..count) {
                    if (Thread.currentThread().isInterrupted) {
                        Log.d(TAG, "Generation interrupted by cancel request.")
                        break
                    }

                    val folder = folders[i % folders.size]
                    val ext = extensions[i % extensions.size]
                    val subDir = File(filesDir, folder)
                    val file = File(subDir, "test_file_${i}.${ext}")

                    val fileIndexBytes = i.toString().toByteArray()
                    FileOutputStream(file).use { fos ->
                        fos.write(fileIndexBytes)
                        if (buffer.size > fileIndexBytes.size) {
                            fos.write(buffer, 0, buffer.size - fileIndexBytes.size)
                        }
                    }
                    bytesWritten += buffer.size
                    filesCreated++

                    if (filesCreated % 5000 == 0) {
                        val elapsed = (System.currentTimeMillis() - start) / 1000.0
                        progressPercent = ((filesCreated.toDouble() / count) * 100).toInt()
                        Log.d(TAG, "Progress: Generated $filesCreated files (${bytesWritten / (1024*1024)} MB written) in ${String.format("%.1f", elapsed)}s ($progressPercent%)")
                        updateNotification("Generating files: $filesCreated / $count ($progressPercent%)", progressPercent)
                    }
                }

                val totalDuration = (System.currentTimeMillis() - start) / 1000.0
                Log.d(TAG, "=== Success: Generated $filesCreated files (${bytesWritten / (1024*1024)} MB) in ${String.format("%.1f", totalDuration)}s ===")
                
                showCompletionNotification("FLUX Generator", "Successfully generated $filesCreated files ($totalDuration s)")
            } catch (e: Exception) {
                Log.e(TAG, "Generation failed: ${e.message}")
            } finally {
                isGenerating = false
                stopSelf()
            }
        }
    }

    private fun cancelGeneration() {
        activeThread?.interrupt()
        isGenerating = false
        stopSelf()
    }

    private fun buildNotification(contentText: String, progress: Int): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("FLUX Test File Generator")
            .setContentText(contentText)
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setContentIntent(pendingIntent)
            .setOngoing(true)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            builder.setChannelId(CHANNEL_ID)
        }

        builder.setProgress(100, progress, false)
        return builder.build()
    }

    private fun updateNotification(contentText: String, progress: Int) {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        nm.notify(NOTIFICATION_ID, buildNotification(contentText, progress))
    }

    private fun showCompletionNotification(title: String, text: String) {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        val builder = Notification.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(android.R.drawable.stat_sys_download_done)
            .setAutoCancel(true)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            builder.setChannelId(CHANNEL_ID)
        }
        nm.notify(NOTIFICATION_ID + 10, builder.build())
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
            val channel = NotificationChannel(
                CHANNEL_ID,
                "FLUX File Generator",
                NotificationManager.IMPORTANCE_LOW
            )
            nm.createNotificationChannel(channel)
        }
    }
}
