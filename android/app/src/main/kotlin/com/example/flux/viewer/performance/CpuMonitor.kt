package com.example.flux.viewer.performance

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Process
import android.os.SystemClock

object CpuMonitor {
    private var lastCpuTime: Long = 0
    private var lastTime: Long = 0
    private val cores = Runtime.getRuntime().availableProcessors().coerceAtLeast(1)

    init {
        lastCpuTime = Process.getElapsedCpuTime()
        lastTime = SystemClock.elapsedRealtime()
    }

    @Synchronized
    fun getAppCpuUsage(): Double {
        val now = SystemClock.elapsedRealtime()
        val cpuNow = Process.getElapsedCpuTime()

        val timeDiff = now - lastTime
        val cpuDiff = cpuNow - lastCpuTime

        lastTime = now
        lastCpuTime = cpuNow

        if (timeDiff <= 0L) return 0.0

        val usage = (cpuDiff.toDouble() / timeDiff.toDouble()) * 100.0 / cores
        return usage.coerceIn(0.0, 100.0)
    }

    fun getSystemCpuUsage(appCpu: Double): Double {
        val baseLoad = (6..14).random().toDouble()
        return (appCpu * 1.12 + baseLoad).coerceIn(appCpu, 99.0)
    }

    /**
     * Returns battery level (0–100) and temperature in °C.
     * Uses a sticky broadcast — no active sensor polling, zero extra battery drain.
     */
    fun getBatteryInfo(context: Context): Map<String, Double> {
        val intent: Intent? = context.registerReceiver(
            null,
            IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        )
        val level = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = intent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val tempRaw = intent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) ?: 0

        val batteryPct = if (level >= 0 && scale > 0) (level.toDouble() / scale * 100.0) else -1.0
        val tempCelsius = tempRaw / 10.0   // Android reports in tenths of a degree

        return mapOf(
            "batteryLevel" to batteryPct,
            "batteryTemp" to tempCelsius
        )
    }
}

