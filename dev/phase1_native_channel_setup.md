# Phase 1 — Native Channel Setup & Foundation
**Weeks 1–4 | Sprint S1 (W1–2) + S2 (W3–4)**

> **Gate:** Browse any real device folder from the Flutter UI with zero crashes. FileObserver fires correctly on manual delete. WAL writes and recovers across cold restart.

---

## Overview

Phase 1 establishes the entire native Kotlin foundation that every subsequent phase builds on top of. No user-facing features ship here — only the structural bedrock. The goal is a Flutter screen that can navigate real on-device directories by end of Week 4, driven by native Kotlin data structures over the MethodChannel bridge.

**Central invariant:** The bridge carries ONLY integer FIDs, never strings or raw bytes. This is established here and never violated.

---

## 1. Project Setup & Gradle Configuration (Week 1, Days 1–2)

### Android Module Structure

```
android/app/src/main/kotlin/com/flux/
├── FluxPlugin.kt            # MethodChannel + EventChannel bridge entry point
├── index/
│   ├── FluxIndex.kt         # Facade — single public API for all 9 indexes
│   ├── FileRecord.kt        # 64-byte file metadata struct
│   └── StringPool.kt        # Shared mmap string pool
├── persistence/
│   └── WalManager.kt        # Write-Ahead Log: write, read-back, crash recovery
├── sync/
│   └── FileObserverHub.kt   # inotify-backed directory watcher (Layer 1)
└── thermal/
    └── ThermalGovernor.kt   # Thermal state reader (stub in P1, real in P4)
```

### build.gradle.kts Dependencies

```kotlin
dependencies {
    implementation("org.roaringbitmap:RoaringBitmap:0.9.49")
    implementation("net.openhft:zero-allocation-hashing:0.16")
    implementation("com.microsoft.onnxruntime:onnxruntime-android:1.17.0")
    implementation("androidx.work:work-runtime-ktx:2.9.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
}
```

### Flutter Plugin Skeleton (lib/bridge/flux_bridge.dart)

```dart
const _methodChannel = MethodChannel('com.flux.channel/methods');
const _searchChannel = EventChannel('com.flux.channel/search_stream');
const _syncChannel   = EventChannel('com.flux.channel/sync_events');
```

---

## 2. FileRecord — The 64-Byte Struct (Week 1, Days 3–5)

Every file = exactly one FileRecord. Deliberately packed to fit in CPU cache lines.

```
Layout (64 bytes total):
  fid          Long   8B  — unique monotonic file identifier
  parentDirFid Long   8B  — FID of containing directory
  nameOffset   Int    4B  — byte offset into StringPool.namePool
  nameLen      Short  2B  — byte length of filename
  pathOffset   Int    4B  — byte offset into StringPool.pathPool
  pathLen      Short  2B  — byte length of full path
  size         Long   8B  — file size in bytes
  mtime        Int    4B  — modified time (seconds since 2020-01-01 epoch)
  atime        Int    4B  — accessed time
  ctime        Int    4B  — created time
  mimeType     Short  2B  — index into global MIME type table
  flags        Int    4B  — FLAG_DELETED, FLAG_HIDDEN, FLAG_PINNED, FLAG_STARRED
  vectorSlot   Int    4B  — slot in HNSW vector store (-1 if not embedded)
  accessCount  Short  2B  — open count capped at 65,535
  checksum     Long   8B  — xxHash64 of file content (0 if not computed)
  [padding]    2B         — alignment to 64 bytes
```

Flag constants:
- FLAG_DELETED  = 1 shl 0
- FLAG_HIDDEN   = 1 shl 1
- FLAG_PINNED   = 1 shl 2
- FLAG_INDEXED  = 1 shl 3 (content tokenized)
- FLAG_STARRED  = 1 shl 4

FID 0 = reserved null sentinel. Never return or store FID 0.

### Master Index Array (in FluxIndex.kt)

```kotlin
// Complexity: O(1) — single array index operation
// RAM: 100k files = 6.4 MB; 500k files = 32 MB
val masterIndex = arrayOfNulls<FileRecord>(2_000_000)
private val fidCounter = AtomicLong(1L)
fun allocateFid(): Long = fidCounter.incrementAndGet()
```

---

## 3. StringPool — Shared String Storage (Week 2, Days 1–2)

FileRecord stores (offset, length) pairs into flat byte arrays, NOT String references.
This eliminates per-string object overhead and enables mmap recovery.

```kotlin
class StringPool {
    private val namePool = ByteArray(32 * 1024 * 1024)  // 32 MB
    private val pathPool = ByteArray(64 * 1024 * 1024)  // 64 MB
    private var nameHead = 0
    private var pathHead = 0

    @Synchronized
    fun internName(name: String): Pair<Int, Short> {
        val bytes = name.toByteArray(Charsets.UTF_8)
        val offset = nameHead
        bytes.copyInto(namePool, nameHead)
        nameHead += bytes.size
        return Pair(offset, bytes.size.toShort())
    }

    fun resolveName(offset: Int, len: Short): String =
        String(namePool, offset, len.toInt(), Charsets.UTF_8)
}
```

---

## 4. WalManager — Write-Ahead Log (Week 2, Days 3–5)

WAL guarantees zero data loss on crash. Every insert/delete/update writes a 32-byte
WAL entry BEFORE modifying the in-memory index.

### WAL Entry Format (32 bytes exactly)

```
magic     4B UInt  — 0x464C5558 ("FLUX") — corrupt entries rejected
sequence  8B Long  — monotonic, verified on recovery
timestamp 8B Long  — Unix epoch milliseconds
opCode    1B Byte  — INSERT=1, DELETE=2, UPDATE=3, RENAME=4
fid       4B Int   — target file FID
payload   2B Short — op-specific metadata
checksum  4B Int   — CRC32 of bytes 0..27
padding   1B       — pad to 32 bytes
```

### Key Methods

```kotlin
// Complexity: O(1) — sequential append, no seeks
fun append(opCode: Byte, fid: Int, payload: Short = 0)

// Replay WAL from beginning. Corrupt entries (bad magic/CRC) are skipped.
fun replay(): List<WalEntry>

// Checkpoint: flush to master.bin, truncate WAL
fun checkpoint()
```

### Test requirements (min 95% coverage)
- Write 1 entry → replay → verify all fields match
- Write 1000 entries → truncate mid-entry → replay recovers all complete entries
- Write entry → corrupt CRC byte → replay skips corrupt entry
- Checkpoint → verify WAL file size = 0

---

## 5. PathMap — Index 1: O(1) Exact Path Lookup (Week 3, Days 1–2)

```kotlin
// HashMap<xxHash64(path), FID>
// Complexity: O(1) — hash ~5ns + HashMap get ~10ns + deletionSet check ~10ns
// Total: ~25 nanoseconds for any path in any size index

private val pathMap = HashMap<Long, Int>(1_000_000)
private val hasher = LongHashFunction.xx()  // net.openhft zero-allocation-hashing

fun lookupByPath(path: String): FileRecord? {
    val hash = hasher.hashChars(path.lowercase())
    val fid  = pathMap[hash] ?: return null
    if (deletionSet.contains(fid)) return null
    return masterIndex[fid]
}

@Synchronized
fun insertPath(fid: Int, path: String) {
    pathMap[hasher.hashChars(path.lowercase())] = fid
    wal.append(WalOpCode.INSERT, fid)
}
```

---

## 6. DirIndex — Index 4: O(1) Folder Listing (Week 3, Days 3–5)

```kotlin
// HashMap<parentFid, sorted IntArray of child FIDs>
// Complexity: O(1) — single HashMap get

private val dirIndex = HashMap<Int, IntArray>(500_000)

fun getChildren(parentFid: Int): IntArray =
    dirIndex[parentFid] ?: IntArray(0)

@Synchronized
fun insertChild(parentFid: Int, childFid: Int) {
    val existing = dirIndex[parentFid]
    if (existing == null) {
        dirIndex[parentFid] = intArrayOf(childFid)
        return
    }
    val pos = existing.binarySearch(childFid)
    if (pos >= 0) return  // already present
    val insertAt = -(pos + 1)
    val newArr = IntArray(existing.size + 1)
    existing.copyInto(newArr, 0, 0, insertAt)
    newArr[insertAt] = childFid
    existing.copyInto(newArr, insertAt + 1, insertAt)
    dirIndex[parentFid] = newArr
}
```

---

## 7. BFS Directory Scanner (Week 4, Days 1–3)

Runs on Dispatchers.IO — NEVER on main thread. Thermal check every batch.

```kotlin
suspend fun buildInitialIndex(rootPath: String) = withContext(Dispatchers.IO) {
    val queue = ArrayDeque<File>()
    queue.add(File(rootPath))

    while (queue.isNotEmpty()) {
        val dir = queue.removeFirst()
        val dirFid = getOrCreateFid(dir.absolutePath)
        val children = dir.listFiles() ?: continue

        for (child in children) {
            val childFid = getOrCreateFid(child.absolutePath)
            val record = FileRecord().apply {
                fid = childFid.toLong()
                parentDirFid = dirFid.toLong()
                val (no, nl) = stringPool.internName(child.name)
                nameOffset = no; nameLen = nl
                val (po, pl) = stringPool.internPath(child.absolutePath)
                pathOffset = po; pathLen = pl
                size  = if (child.isFile) child.length() else 0L
                mtime = ((child.lastModified() / 1000L) - FileRecord.EPOCH_OFFSET).toInt()
                mimeType = MimeTable.lookup(child.extension).toShort()
            }
            masterIndex[childFid] = record
            insertPath(childFid, child.absolutePath)
            insertChild(dirFid, childFid)
            if (child.isDirectory) queue.add(child)
        }

        if (thermalGovernor.currentState() == ThermalState.CRITICAL) delay(5_000)
    }
    wal.checkpoint()
}
```

---

## 8. FileObserverHub — Layer 1 inotify (Week 4, Days 3–5)

Layer 1 of the 4-layer cross-app deletion sync system. Delivers events in < 1 ms.
Max Android inotify watchers: 8,192. FLUX watches dirs at depth 1–2 only.

```kotlin
class FileObserverHub(private val fluxIndex: FluxIndex) {
    private val activeObservers = ConcurrentHashMap<String, FileObserver>()
    private val EVENTS = CREATE or DELETE or MOVED_FROM or MOVED_TO or CLOSE_WRITE

    fun register(dirPath: String, depth: Int = 0) {
        if (depth > 2) return  // inotify limit guard
        if (activeObservers.containsKey(dirPath)) return

        val observer = object : FileObserver(dirPath, EVENTS) {
            override fun onEvent(event: Int, filename: String?) {
                filename ?: return
                val fullPath = "$dirPath/$filename"
                when (event and ALL_EVENTS) {
                    CREATE      -> { if (File(fullPath).isDirectory) {
                                       register(fullPath, depth + 1)
                                       fluxIndex.scanDirAsync(fullPath)
                                   } else fluxIndex.insertAsync(fullPath) }
                    DELETE,
                    MOVED_FROM  -> { fluxIndex.logicalDelete(fullPath)
                                     activeObservers.remove(fullPath)?.stopWatching() }
                    MOVED_TO    -> fluxIndex.insertAsync(fullPath)
                    CLOSE_WRITE -> fluxIndex.invalidateChecksumAndThumb(fullPath)
                }
            }
        }
        observer.startWatching()
        activeObservers[dirPath] = observer
    }
}
```

### Coverage requirements (min 85%)
- CREATE file → insertAsync called
- DELETE → logicalDelete within 5 ms
- CREATE subdir → auto-registers
- depth > 2 → silently ignored, no crash

---

## 9. MethodChannel Bridge — Phase 1 (Week 4)

### Flutter side (lib/bridge/flux_bridge.dart)

```dart
class FluxBridge {
  static const _ch = MethodChannel('com.flux.channel/methods');

  static Future<bool> initializeIndex() async =>
      await _ch.invokeMethod('initializeIndex');

  // Returns List<Map> each with: fid(int), name(String), size(int),
  //                               mtime(int), isDir(bool), mimeType(int)
  // Max 500 items per call — use EventChannel pagination for large dirs
  static Future<List<Map>> getDirectoryContents(String path) async =>
      await _ch.invokeMethod('getDirectoryContents', {'parentPath': path});
}
```

### Native side (FluxPlugin.kt)

```kotlin
override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
        "initializeIndex" -> scope.launch(Dispatchers.IO) {
            try {
                val loaded = fluxIndex.initialize(context)
                withContext(Dispatchers.Main) { result.success(loaded) }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) { result.error("INIT_FAILED", e.message, null) }
            }
        }
        "getDirectoryContents" -> {
            val path = call.argument<String>("parentPath")
                ?: return result.error("INVALID_ARG", "parentPath required", null)
            scope.launch(Dispatchers.IO) {
                try {
                    val contents = fluxIndex.getDirectoryContents(path)
                    withContext(Dispatchers.Main) { result.success(contents) }
                } catch (e: Exception) {
                    withContext(Dispatchers.Main) { result.error("DIR_FAILED", e.message, null) }
                }
            }
        }
        else -> result.notImplemented()
    }
}
```

**Bridge rules (enforced from Day 1, never relaxed):**
1. All bridge methods: Dispatchers.IO — NEVER main thread
2. All bridge methods: try/catch → result.error() — NEVER unhandled exceptions
3. No path strings in response — only `name` for display, `fid` as identifier
4. No response > 500 items — EventChannel for larger

---

## 10. Permissions (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="28" />
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"
    tools:ignore="ScopedStorage" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

---

## Sprint Acceptance Criteria

### S1 (Weeks 1–2)
- [ ] flutter run compiles on physical Android device
- [ ] FluxPlugin registered, no crash on startup
- [ ] MethodChannel ping/pong roundtrip works
- [ ] WAL writes 1000 entries, replays all 1000 correctly
- [ ] Corrupt WAL entry (bad CRC) skipped without crash
- [ ] FileRecord verified as 64 bytes

### S2 (Weeks 3–4)
- [ ] BFS scan of /sdcard completes without ANR on real device
- [ ] getDirectoryContents("/sdcard/DCIM") returns correct children
- [ ] FileObserver fires within 5 ms on adb shell touch
- [ ] Logical delete removes file from Flutter view without UI freeze
- [ ] 100k files indexed, memory increase < 15 MB RSS

## Gate 1
> Browse /sdcard/DCIM/Camera in Flutter. Tap subfolder — loads. ADB touch newfile → appears within 2s. ADB rm file → disappears within 2s. No crashes in 30-min soak.

---

## Phase 1 File Checklist

| File | Contents |
|------|----------|
| android/.../FluxPlugin.kt | MethodChannel + EventChannel bridge |
| android/.../index/FluxIndex.kt | PathMap + DirIndex + Master Array + BFS scanner |
| android/.../index/FileRecord.kt | 64-byte struct + flag constants |
| android/.../index/StringPool.kt | Name + path byte pools |
| android/.../persistence/WalManager.kt | Write, replay, checkpoint |
| android/.../sync/FileObserverHub.kt | inotify Layer 1 |
| android/.../thermal/ThermalGovernor.kt | Stub (real in Phase 4) |
| lib/bridge/flux_bridge.dart | Channel constants + method wrappers |
| lib/main.dart | Permission request + initializeIndex |
| lib/features/browser/presentation/browser_screen.dart | Phase 1 basic directory list |
