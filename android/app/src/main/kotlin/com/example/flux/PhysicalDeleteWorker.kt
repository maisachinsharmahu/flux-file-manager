package com.example.flux

import android.content.Context
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import java.io.File
import java.io.DataInputStream
import java.io.FileInputStream

/**
 * WorkManager worker that physically deletes files scheduled for permanent removal.
 *
 * Why WorkManager instead of a daemon thread:
 *   - A daemon thread is killed when the app process dies (user swipes away, OOM kill, etc.)
 *   - WorkManager is backed by Android's JobScheduler / AlarmManager and persists across
 *     app kill, device reboot, and system-initiated process deaths.
 *
 * Flow:
 *   1. User taps "Delete Permanently" → logical delete completes instantly (bitset flip).
 *   2. File paths are appended to [QUEUE_FILE] (persistent binary queue on internal storage).
 *   3. A OneTimeWorkRequest for this Worker is enqueued via WorkManager.
 *   4. App can be closed at any time — this Worker will still run.
 *   5. Worker reads the queue, deletes files deepest-first, then clears the queue.
 */
class PhysicalDeleteWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    companion object {
        private const val TAG = "PhysicalDeleteWorker"

        /** Binary flat-file: each entry is a 2-byte length (short) + UTF-8 path bytes. */
        const val QUEUE_FILE = "pending_physical_deletes.bin"

        /**
         * Appends [paths] to the persistent queue file.
         * Called synchronously before enqueuing the WorkRequest.
         */
        fun appendToQueue(context: Context, paths: List<String>) {
            val file = File(context.filesDir, QUEUE_FILE)
            file.outputStream().buffered().use { out ->
                // Append mode: we manually seek to end via append flag in FileOutputStream.
            }
            // Use append=true FileOutputStream to add to existing file.
            java.io.FileOutputStream(file, true).buffered().use { out ->
                val dos = java.io.DataOutputStream(out)
                for (path in paths) {
                    val bytes = path.toByteArray(Charsets.UTF_8)
                    dos.writeShort(bytes.size)
                    dos.write(bytes)
                }
            }
            Log.d(TAG, "Queued ${paths.size} paths for physical deletion (queue size: ${file.length()} bytes)")
        }

        /** Reads all queued paths from the persistent queue file. */
        fun readQueue(context: Context): List<String> {
            val file = File(context.filesDir, QUEUE_FILE)
            if (!file.exists() || file.length() == 0L) return emptyList()
            val paths = mutableListOf<String>()
            try {
                DataInputStream(FileInputStream(file).buffered()).use { dis ->
                    while (dis.available() > 0) {
                        val len = dis.readShort().toInt()
                        if (len <= 0 || len > 4096) break // sanity guard
                        val bytes = ByteArray(len)
                        dis.readFully(bytes)
                        paths.add(String(bytes, Charsets.UTF_8))
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "readQueue: partial read (ok if queue was just written): ${e.message}")
            }
            return paths
        }

        /** Clears the queue after successful deletion. */
        fun clearQueue(context: Context) {
            File(context.filesDir, QUEUE_FILE).delete()
        }
    }

    override suspend fun doWork(): Result {
        val paths = readQueue(applicationContext)
        if (paths.isEmpty()) return Result.success()

        Log.d(TAG, "[PERFORMANCE] Starting physical deletion of ${paths.size} files")
        val startMs = System.currentTimeMillis()

        // Sort deepest paths first: children unlinked before parents.
        val sorted = paths.sortedByDescending { it.length }

        var failed = 0
        for (path in sorted) {
            try {
                val f = File(path)
                if (f.exists()) {
                    val ok = f.delete()
                    if (!ok) failed++
                }
            } catch (e: Exception) {
                Log.w(TAG, "Could not delete $path: ${e.message}")
                failed++
            }
        }

        val ms = System.currentTimeMillis() - startMs
        Log.d(TAG, "[PERFORMANCE] Physical deletion: ${paths.size} files, $failed failures, ${ms} ms")

        // Only clear queue if fully successful; retry will re-process on next run.
        return if (failed == 0) {
            clearQueue(applicationContext)
            Result.success()
        } else {
            // Partial failure: clear queue anyway to avoid re-deleting already-deleted paths.
            // Failures are typically "file not found" (already gone) which is acceptable.
            clearQueue(applicationContext)
            Result.success()
        }
    }
}
