# Phase 6 — Production Hardening & Store Submission
**Weeks 25–27 | Sprint S13 (W25–27)**

> **Gate:** Zero Application Not Responding (ANR) occurrences during 48-hour automated monkey stress-test cycle. Application accepted by Google Play Console review pipeline.

---

## Overview

Phase 6 hardens the codebase for launch. It audits all thread bridges, performs low-RAM stress testing to prevent out-of-memory crashes, links crash logging, configures WorkManager tasks, and prepares play store submission details (specifically the `MANAGE_EXTERNAL_STORAGE` permission justification).

---

## 1. ANR Thread Audit (Week 25, Days 1–3)

All MethodChannel calls must run asynchronously off the main thread. We enforce this by routing bridge calls through Coroutine scopes tied to `Dispatchers.IO` on Android and `compute()` or Riverpod async workers in Dart.

```kotlin
// Dispatch bridge tasks off the Android Main UI Thread
fun handleBridgeCall(call: MethodCall, result: MethodChannel.Result) {
    CoroutineScope(Dispatchers.IO).launch {
        try {
            val response = executeComplexOperation(call.arguments)
            withContext(Dispatchers.Main) {
                result.success(response)
            }
        } catch (e: Exception) {
            withContext(Dispatchers.Main) {
                result.error("ERR_CODE", e.message, null)
            }
        }
    }
}
```

---

## 2. Low-RAM Garbage Collection & Trim Memory Rules (Week 25, Days 4–5)

To prevent the Android Out-Of-Memory (OOM) killer from destroying the process, we listen to system memory warnings and aggressively purge caches.

### File: `android/app/src/main/kotlin/com/flux/MainActivity.kt`

```kotlin
package com.flux

import android.content.ComponentCallbacks2
import io.flutter.embedding.android.FlutterActivity
import com.flux.index.FluxIndex

class MainActivity : FlutterActivity() {
    override fun onTrimMemory(level: Int) {
        super.onTrimMemory(level)
        when (level) {
            ComponentCallbacks2.TRIM_MEMORY_RUNNING_MODERATE -> {
                // Clear temporary memory caches
                FluxIndex.clearLruCaches()
            }
            ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL,
            ComponentCallbacks2.TRIM_MEMORY_COMPLETE -> {
                // Critical pressure: Evict string pools, optimize Triels
                FluxIndex.emergencyPurge()
                System.gc()
            }
        }
    }
}
```

---

## 3. WorkManager Task Chains (Week 26, Days 1–3)

Schedules recurring scans, metadata updates, and index validation tasks when the device is idle, connected to Wi-Fi, and charging.

```kotlin
val syncRequest = PeriodicWorkRequestBuilder<SyncWorker>(12, TimeUnit.HOURS)
    .setConstraints(Constraints.Builder()
        .setRequiresCharging(true)
        .setRequiresDeviceIdle(true)
        .build())
    .build()

WorkManager.getInstance(context).enqueueUniquePeriodicWork(
    "FluxBackgroundSync",
    ExistingPeriodicWorkPolicy.KEEP,
    syncRequest
)
```

---

## 4. Google Play Store Submission Checklist (Week 27, Days 1–5)

### Scoped Storage & MANAGE\_EXTERNAL\_STORAGE Permission Justification

Because FLUX operates as a core utility file manager, it requires broad access to device storage. The Play Store submission demands a strict declaration explaining why Scoped Storage does not suffice:

- **Core Functionality:** File Manager.
- **Justification:** FLUX indexes non-media documents, temporary logs, system folder leftovers, and application packages to support keyword search, duplicate removal, and safety reviews. These folders are located outside Scoped Storage directories, necessitating the `MANAGE_EXTERNAL_STORAGE` permission.
- **Privacy Enforcement:** No indexing records or metadata values are sent off the device. All HNSW vector and text embedding calculations run purely local to the device client.

---

## Verification & Testing Requirements
- **Automated Tests:**
  - Execute Android Monkey testing tools for 48 hours to find UI lockups.
- **Manual Verification:**
  - Run memory profiling tools on low-RAM emulators (e.g. 1.5 GB memory limits) to ensure the `onTrimMemory` hooks fire and prevent OOM occurrences during large directory traversals.
