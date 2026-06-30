# Phase 5 — Junk Cleaner Engine & Storage Analytics
**Weeks 21–24 | Sprint S11 (W21–22) + S12 (W23–24)**

> **Gate:** Junk scanner completes traversal and identifies empty directories, duplicate files, and cache segments on 1,000,000 files in under 3 seconds. Deletion operations adhere to strict safety exclusion rules.

---

## Overview

Phase 5 builds the high-performance junk scanning and cleaner engine. The goal is to safely reclaim gigabytes of storage space by scanning temporary folder trees, locating duplicate files (via xxHash64 collisions), and pinpointing large old files using Van Emde Boas (vEB) index intersections. This phase also implements per-app system memory analytics.

---

## 1. JunkScanner Engine (Week 21, Days 1–5)

Traverses directories to identify orphaned logs, temp caches, empty directories, and cache folder leftovers.

### File: `android/app/src/main/kotlin/com/flux/clean/JunkScanner.kt`

```kotlin
package com.flux.clean

import java.io.File

class JunkScanner(private val exclusions: Set<String>) {
    class JunkItem(val file: File, val size: Long, val type: JunkType)
    enum class JunkType { LOGS, CACHE, TEMP, EMPTY_DIR, ORPHANED_DATA }

    private val tempExtensions = setOf("tmp", "temp", "bak", "log", "DS_Store")

    fun scan(rootDir: File, onProgress: (String) -> Unit): List<JunkItem> {
        val junkList = mutableListOf<JunkItem>()
        scanRecursive(rootDir, junkList, onProgress)
        return junkList
    }

    private fun scanRecursive(dir: File, results: MutableList<JunkItem>, onProgress: (String) -> Unit) {
        if (exclusions.contains(dir.absolutePath)) return
        onProgress(dir.absolutePath)

        val files = dir.listFiles()
        if (files == null || files.isEmpty()) {
            if (!exclusions.contains(dir.absolutePath)) {
                results.add(JunkItem(dir, 0L, JunkType.EMPTY_DIR))
            }
            return
        }

        for (file in files) {
            if (file.isDirectory) {
                scanRecursive(file, results, onProgress)
            } else {
                val ext = file.extension.lowercase()
                if (tempExtensions.contains(ext) || file.name.startsWith("._")) {
                    results.add(JunkItem(file, file.length(), JunkType.TEMP))
                }
            }
        }
    }
}
```

---

## 2. Duplicate Finder & Large File Filtering (Week 22, Days 1–5)

Uses Index 8 (ChecksumMap) to locate identical files. Because identical file sizes can collide, we check xxHash64 checksums before declaring files duplicates.

### File: `android/app/src/main/kotlin/com/flux/clean/DuplicateFinder.kt`

```kotlin
package com.flux.clean

import com.flux.index.FluxIndex
import com.flux.index.FileRecord

class DuplicateFinder(private val index: FluxIndex) {
    // Groups FIDs that share identical non-zero content checksums
    fun findDuplicates(): List<List<Long>> {
        val groups = HashMap<Long, MutableList<Long>>()
        
        // Iterate master index records to group xxHash64 collisions
        for (i in 0 until index.size()) {
            val record = index.getRecordAt(i) ?: continue
            if (record.checksum != 0L && (record.flags and FileRecord.FLAG_DELETED) == 0) {
                val list = groups.getOrPut(record.checksum) { mutableListOf() }
                list.add(record.fid)
            }
        }

        // Return only groups containing more than one file copy
        return groups.values.filter { it.size > 1 }
    }
}
```

---

## 3. StorageStatsManager Integration (Week 23, Days 1–5)

Retrieves granular application storage allocations directly from the Android System APIs.

### File: `android/app/src/main/kotlin/com/flux/analytics/PackageStorageCollector.kt`

```kotlin
package com.flux.analytics

import android.app.usage.StorageStatsManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.UserHandle
import android.os.storage.StorageManager
import java.util.UUID

class PackageStorageCollector(private val context: Context) {
    class AppStorageStats(val packageName: String, val appName: String, val appBytes: Long, val cacheBytes: Long, val dataBytes: Long)

    fun getInstalledAppStorage(): List<AppStorageStats> {
        val statsManager = context.getSystemService(Context.STORAGE_STATS_SERVICE) as StorageStatsManager
        val pm = context.packageManager
        val list = mutableListOf<AppStorageStats>()

        val apps = pm.getInstalledApplications(PackageManager.GET_META_DATA)
        val uuid = StorageManager.UUID_DEFAULT

        for (app in apps) {
            try {
                val stats = statsManager.queryStatsForPackage(uuid, app.packageName, UserHandle.getUserHandleForUid(app.uid))
                val label = pm.getApplicationLabel(app).toString()
                list.add(AppStorageStats(
                    packageName = app.packageName,
                    appName = label,
                    appBytes = stats.appBytes,
                    cacheBytes = stats.cacheBytes,
                    dataBytes = stats.dataBytes
                ))
            } catch (e: Exception) {
                // Ignore packages system constraints prevent reading
            }
        }
        return list.sortByDescending { it.appBytes + it.dataBytes }
    }
}
```

---

## 4. Cleaner Safety & System Exclusions (Week 24, Days 1–5)

To prevent breaking installed applications or the Android operating system, we enforce strict folder exclusions that cannot be modified or bypassed.

### File: `android/app/src/main/kotlin/com/flux/clean/SafetyGuard.kt`

```kotlin
package com.flux.clean

import java.io.File

object SafetyGuard {
    private val criticalSystemPaths = setOf(
        "/system",
        "/vendor",
        "/boot",
        "/data/system",
        "/Android/obb"
    )

    fun isSafeToDelete(file: File): Boolean {
        val path = file.absolutePath.lowercase()
        // Never touch root system directories or obb game cache paths
        for (criticalPath in criticalSystemPaths) {
            if (path.startsWith(criticalPath.lowercase())) {
                return false
            }
        }
        // Protect parent app boundaries if scoped storage is disabled
        if (path.contains("com.flux.filemanager")) {
            return false
        }
        return true
    }
}
```

---

## Verification & Testing Requirements
- **Automated Tests:**
  - Verify `SafetyGuard` exceptions correctly block deletions for root paths.
  - Implement collision test cases verifying that only files with matching non-zero checksums are marked as duplicates.
- **Manual Verification:**
  - Build mock empty folder hierarchies and test if `JunkScanner` successfully cleans them up.
