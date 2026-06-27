# FLUX: File Lookup & Unified eXperience Index

A publication-grade, sub-millisecond, on-device AI-powered, thermally-safe native Android file management index and application framework.

---

## Executive Summary

Every Android smartphone today ships with a file management application (such as Google Files or Samsung My Files). Yet despite billions of users and decades of operating system updates, these utility applications share one fundamental architectural flaw: they rely directly on Android's MediaStore, an SQLite database designed in the early 2000s. MediaStore requires full table scans for substring searches, causing high execution latency, index staleness, UI freezes during batch file operations, and a lack of relationship awareness between local files.

FLUX (File Lookup & Unified experience Index) is a complete, ground-up redesign of mobile filesystem indexes. It replaces the MediaStore SQLite query path with a 9-layer composite index where every search, folder listing, and filtering operation executes in O(1) or O(log n) time. FLUX introduces on-device AI semantic search for local Android file management, powered by an HNSW vector index and a 22 MB sentence embedding model running locally. Furthermore, it eliminates stale entries through a 4-layer synchronization system anchored directly to the Linux kernel's inotify subsystem.

This project is structured as a native Android performance library (written in Kotlin) bridged to a modern cross-platform user interface (written in Flutter/Dart).

---

## Technical Problem Statements

The standard file explorer ecosystem on Android experiences five core architectural bottlenecks:

### 1. Substring Search is an O(n) Full Scan
Standard Android file managers search filenames by executing SQL LIKE queries with wildcards (e.g., `LIKE '%query%'`) against the MediaStore database. Because B-tree indexes cannot optimize wildcards, the database engine must execute a full table scan. On a device with 50,000 files, this requires 50,000 string comparisons. On flagship devices with 1,000,000 files, search latency increases to 200–600 ms, causing noticeable frame drops and UI input delays.

### 2. Lack of Semantic Understanding
Substring matching is syntax-bound. If a file is named `Q3_Final_Report_v2.pdf` and a user searches for "quarterly report", the query returns zero results. Existing applications lack local synonym mapping, semantic context extraction, or natural language retrieval capabilities.

### 3. Asynchronous Staleness (Ghost Files)
Android's MediaStore database updates asynchronously via background media scans. When a third-party application (such as WhatsApp, a browser, or an image editor) creates or deletes a file, the MediaStore index does not update immediately. This delay leads to "ghost files" — search results pointing to files that have already been deleted, or newly downloaded files failing to appear in listings for minutes or hours.

### 4. UI Freezes on Batch Operations
Deleting, moving, or copying large batches of files (e.g., 1,000 files) triggers a sequence of individual filesystem notifications. In legacy applications, this forces the main UI thread to re-query the database and redraw the interface 1,000 consecutive times, freezing the application for 30–60 seconds or causing Application Not Responding (ANR) crashes.

### 5. Zero Relationship Awareness
Files are treated as isolated objects. Traditional file explorers have no awareness that `Project_Budget.xlsx`, `Project_Kickoff.pptx`, and `Project_Notes.docx` belong to the same project container. Users are forced to manually organize directories rather than relying on automated relationship grouping.

---

## Technical Architecture

FLUX splits operations between native Android code and a Flutter user interface, communicating via a low-overhead MethodChannel and EventChannel bridge.

```
FLUX Application Architecture
+-------------------------------------------------------------+
|                       FLUTTER UI LAYER                      |
|  - Riverpod State    - GoRouter Routing   - 60fps Lists     |
+-------------------------------------------------------------+
                               |
                   FIDs & Metadata Only (Bridge)
                               |
                               v
+-------------------------------------------------------------+
|                      NATIVE KOTLIN CORE                     |
|  - 9-Layer Composite Index             - Write-Ahead Log    |
|  - inotify FileObservers               - Thermal Governor   |
|  - ONNX Embedding Engine               - Memory trim hooks  |
+-------------------------------------------------------------+
                               |
                               v
+-------------------------------------------------------------+
|                     ANDROID KERNEL LAYER                    |
|                ext4 filesystem  /  Linux inode              |
+-------------------------------------------------------------+
```

### The Bridge Rule
Native Kotlin owns all logic that interacts with hardware, filesystem observers, CPU scheduling, and binary index allocations. Flutter owns only presentation and gesture logic. The MethodChannel bridge carries only integer File IDs (FIDs) and compact metadata. Raw bytes and long path strings are never passed across the bridge.

---

## The FLUX 9-Layer Composite Index

Every local query, filter, sort, or folder listing is resolved in O(1) or O(log n) time by routing the query through one or more of the nine specialized memory-mapped indexes.

### The File ID (FID) System
To minimize memory usage and avoid cascading updates during file renames, all indexes store a unique 64-bit integer FID instead of full path strings. 
* Renaming or moving a file updates only the path map index. The remaining eight indexes retain the FID, preventing cascading updates.
* FIDs enable high-performance set intersections via 64-bit CPU word operations (AND, OR, NOT).
* Accessing a file's master metadata record requires an O(1) array index operation.

```kotlin
// In-memory master index mapping FIDs to structures
val masterIndex = Array<FileRecord>(MAX_FILES) { FileRecord.EMPTY }

// O(1) metadata lookup
val record: FileRecord = masterIndex[fid]
```

### The FileRecord Struct (64 Bytes)
The Master Record Array is packed into a 64-byte aligned structure to optimize L1/L2 CPU cache utilization and minimize memory usage:

| Field | Type | Size | Description |
| :--- | :--- | :--- | :--- |
| `fid` | uint64 | 8 B | Monotonically increasing unique file identifier |
| `parentDirFid` | uint64 | 8 B | FID of the parent directory |
| `nameOffset` | uint24 | 3 B | Byte offset in the shared filename string pool |
| `nameLen` | uint16 | 2 B | Length of the filename |
| `pathOffset` | uint24 | 3 B | Byte offset in the shared path string pool |
| `pathLen` | uint16 | 2 B | Length of the full path |
| `size` | uint64 | 8 B | File size in bytes |
| `mtime` | uint32 | 4 B | Modification timestamp (epoch seconds offset) |
| `atime` | uint32 | 4 B | Access timestamp |
| `ctime` | uint32 | 4 B | Creation timestamp |
| `mimeType` | uint16 | 2 B | Reference in the MIME type lookup table |
| `flags` | uint32 | 4 B | Binary flags (deleted, hidden, starred, etc.) |
| `vectorSlot` | uint24 | 3 B | Slot index within the HNSW vector database |
| `accessCount` | uint16 | 2 B | Dynamic access count tracker |
| `checksum` | uint64 | 8 B | xxHash64 of content blocks (for deduplication) |

At scale, 100,000 files consume only 6.4 MB of memory in the active cache.

---

### Index Detailed Breakdown

#### 1. Path Map (O(1))
A HashMap storing `xxHash64(lowercase(path)) -> FID`. This index resolves exact path lookups (e.g., verifying if a file exists before an operation) in ~25 nanoseconds.

#### 2. Name Trie (O(k))
A Radix Trie (compressed prefix tree) indexing all filenames. Searching for files starting with a prefix of length $k$ completes in O(k) steps, completely independent of the total number of files in the system.

#### 3. Token Index (O(1) / O(N/64))
A HashMap mapping extracted tokens (e.g., words split by spaces, casing boundaries, dashes, or CamelCase) to a `RoaringBitmap` of matching FIDs. Multi-keyword searches (e.g., "budget xlsx 2025") execute via bitwise AND intersections of the bitmaps.

#### 4. Directory Index (O(1))
A HashMap mapping a directory FID to a sorted `IntArray` of child FIDs. This index resolves folder listings instantly, bypassing filesystem directory scans.

#### 5. Type Buckets (O(1))
A HashMap mapping major MIME classes (e.g., `image/*`, `video/*`, `application/pdf`) to a `RoaringBitmap` of matching FIDs. This resolves category-wide filtering in constant time.

#### 6. Size Index (O(log log U))
A Van Emde Boas (VEB) tree mapping file sizes to FIDs. For a universe size of $U = 2^{40}$ (1 TB range), range queries (e.g., "find files between 10 MB and 100 MB") execute in a maximum of 13 operations.

#### 7. Time Index (O(log log U))
A matching VEB tree mapping modification timestamps to FIDs, resolving chronological range queries and sorting operations.

#### 8. Checksum Map (O(1))
A HashMap mapping `xxHash64(content)` to `IntArray` collections of matching FIDs, resolving duplicate file detection in constant time.

#### 9. HNSW Vector Graph (O(log n))
A hierarchical navigable small world proximity graph containing 384-dimensional sentence embeddings generated from filenames, parent paths, and document contents. It resolves natural language queries (e.g., "tax documents from last year") using approximate nearest neighbor retrieval.

---

### Deletion and Compaction Model
FLUX implements O(1) logical deletion to prevent blocking the main UI thread during batch delete operations.

```kotlin
// Logic to tombstone files instantly
fun logicalDelete(fid: Int) {
    deletionSet.add(fid) // Add to RoaringBitmap ( O(1) bit flip )
    masterIndex[fid].flags = masterIndex[fid].flags or FLAG_DELETED
    wal.append(WAL_DELETE, fid) // Write-Ahead Log append
}

// Every search query filters out deleted files in O(N/64) time:
val filteredResults = queryResult.andNot(deletionSet)
```

The system defer physical index cleanups (removing deleted items from the Radix Trie, VEB trees, and HNSW graph) to an asynchronous background coroutine that runs when the device is idle.

---

### Performance Latency Table

| Operation | Standard MediaStore | FLUX Index Layer | Time Complexity | Latency (1M Files) |
| :--- | :--- | :--- | :--- | :--- |
| **Exact Path Lookup** | Database Query | Path Map | O(1) | < 25 ns |
| **Prefix / Autocomplete** | LIKE '%term%' | Name Trie | O(k) | < 0.5 ms |
| **Multi-Keyword Search** | Multiple LIKE scans | Token Index AND | O(N/64) | < 2.0 ms |
| **Folder Listing** | Directory Walk | Directory Index | O(1) | < 1.0 ms |
| **Filter by MIME Type** | SQLite Index Scan | Type Buckets | O(1) | < 1.0 ms |
| **Size Range Query** | SQLite Index Scan | Size VEB Tree | O(log log U) | < 1.0 ms |
| **Duplicate File Check** | Full Hash Scan | Checksum Map | O(1) | < 1.0 ms |
| **Semantic AI Search** | Not Supported | HNSW Vector Graph | O(log n) | < 10.0 ms |
| **Batch Deletion (1k files)** | UI Thread Block | Deletion BitSet | O(N/64) | < 2.0 ms |
| **App Cold Start** | SQLite Initialize | mmap WAL restore | Sequential Read | < 800.0 ms |

---

## Memory and Resource Control

FLUX is designed to operate on memory-constrained mobile hardware without causing system lag or CPU thermal throttling.

### Memory (RAM) Tiering

* **Tier 1: Hot Cache (50–80 MB):** Contains the `masterIndex`, `pathMap`, `dirIndex`, `deletionSet`, and type bitmaps. These structures remain pinned in JVM heap memory while the application is in the foreground.
* **Tier 2: Warm Store (80–150 MB):** Contains the size and time VEB trees, the `checksumMap`, and the full `nameTrie`. These structures are automatically cleared from memory when the OS triggers low-memory warnings (`onTrimMemory`).
* **Tier 3: Cold Disk (600 MB+):** Contains the HNSW vector graph, string pool blocks, and content index tokens. These files are mapped using virtual memory (`mmap`), allowing the operating system to load and evict pages dynamically without inflating the app's active RAM footprint.

```kotlin
// Android system memory pressure handler implementation
override fun onTrimMemory(level: Int) {
    when (level) {
        TRIM_MEMORY_RUNNING_MODERATE -> {
            checksumMap.evictLRU(keepCount = 50_000)
        }
        TRIM_MEMORY_RUNNING_CRITICAL -> {
            warmStore.evictAll()
            tokenIndex.values.forEach { it.runOptimize() }
        }
        TRIM_MEMORY_BACKGROUND -> {
            wal.flush()
            indexingJob.pause()
        }
        TRIM_MEMORY_COMPLETE -> {
            fluxIndex.emergencyFlush()
        }
    }
}
```

### Thermal Governor
To prevent background indexing tasks from overheating the CPU and draining the battery, the `ThermalGovernor` regulates execution thread allocations and batch sizes:

```kotlin
class ThermalGovernor(private val pm: PowerManager) {
    enum class ThermalState { COOL, WARM, HOT, CRITICAL }

    fun currentState(): ThermalState = when {
        Build.VERSION.SDK_INT >= 29 -> when (pm.currentThermalStatus) {
            PowerManager.THERMAL_STATUS_NONE,
            PowerManager.THERMAL_STATUS_LIGHT    -> ThermalState.COOL
            PowerManager.THERMAL_STATUS_MODERATE -> ThermalState.WARM
            PowerManager.THERMAL_STATUS_SEVERE   -> ThermalState.HOT
            else                                 -> ThermalState.CRITICAL
        }
        else -> readCpuTempFallback()
    }

    fun getWorkerParams(state: ThermalState): WorkerParams = when (state) {
        ThermalState.COOL     -> WorkerParams(threads = 4, batchSize = 500, delayMs = 0)
        ThermalState.WARM     -> WorkerParams(threads = 2, batchSize = 200, delayMs = 50)
        ThermalState.HOT      -> WorkerParams(threads = 1, batchSize = 50,  delayMs = 200)
        ThermalState.CRITICAL -> WorkerParams(threads = 0, batchSize = 0,   delayMs = -1) // Paused
    }
}
```

### Progressive Thumbnail Pipeline
To prevent out-of-memory (OOM) crashes in grid views containing large images, FLUX restricts image decodes to a maximum resolution of 256x256 using RGB_565 (2 bytes per pixel) instead of ARGB_8888 (4 bytes per pixel). 

```dart
// Optimized thumbnail loader inside Flutter list components
Image.memory(
  thumbnailBytes,
  cacheWidth: 256, // Constraints Flutter memory footprint
  cacheHeight: 256,
  fit: BoxFit.cover,
  filterQuality: FilterQuality.low,
)
```

This reduces the memory consumed by a single thumbnail from **1.76 MB** to **128 KB** ($13.7\times$ memory savings).

---

## Synchronization System

To eliminate stale indices and ghost files, FLUX implements a 4-layer synchronization system that monitors filesystem changes in real time.

```
+-------------------------------------------------------------+
|                     4-LAYER SYNC SYSTEM                     |
|                                                             |
|  Layer 1: Linux inotify FileObservers (< 1 ms latency)       |
|  Layer 2: Android MediaStore ContentObserver (100 ms - 2 s) |
|  Layer 3: sdcard Root Directory Observer (< 1 ms latency)   |
|  Layer 4: Delta Reconciliation Worker (15 min intervals)    |
+-------------------------------------------------------------+
```

### Layer 1: inotify FileObservers
Wraps the Linux kernel's inotify subsystem to monitor file actions in watched directories. When a file is created or deleted, an event is fired in less than 1 ms.

```kotlin
class FileObserverHub(private val flux: FluxIndex) {
    private val activeObservers = ConcurrentHashMap<String, FileObserver>()

    fun register(dirPath: String) {
        if (activeObservers.containsKey(dirPath)) return

        val observer = object : FileObserver(dirPath,
            CREATE or DELETE or MOVED_FROM or MOVED_TO or CLOSE_WRITE) {
            override fun onEvent(event: Int, filename: String?) {
                filename ?: return
                val fullPath = "$dirPath/$filename"
                when (event and ALL_EVENTS) {
                    CREATE -> {
                        val f = File(fullPath)
                        if (f.isDirectory) {
                            register(fullPath)
                            flux.scanDirAsync(fullPath)
                        } else {
                            flux.insertAsync(fullPath)
                        }
                    }
                    DELETE, MOVED_FROM -> {
                        flux.logicalDelete(fullPath)
                        activeObservers.remove(fullPath)?.stopWatching()
                    }
                    MOVED_TO  -> flux.insertAsync(fullPath)
                    CLOSE_WRITE -> flux.invalidateChecksumAndThumb(fullPath)
                }
            }
        }
        observer.startWatching()
        activeObservers[dirPath] = observer
    }
}
```

### Layer 2: MediaStore ContentObserver
Receives broadcasts from Android's ContentResolver when media databases are updated, ensuring synchronization for background writes.

### Layer 3: sdcard Root Observer
Listens for changes to root directories, automatically attaching Layer 1 watchers to new folders.

### Layer 4: Delta Reconciliation Worker
A background job running at 15-minute intervals. It performs local, non-blocking check scans against the index to reconcile any missed change events.

---

## Data Schema & Persistence

FLUX ensures durability and fast startup recovery by combining a Write-Ahead Log (WAL) with memory-mapped data structures.

### WAL Entry Binary Layout (32 Bytes)
All index mutations are serialized to a binary log file (`flux.wal`) before updating the in-memory index.

```kotlin
data class WalEntry(
    val magic:     UInt,   // 4B -- Sentinel verification value (0xFLUX)
    val sequence:  Long,   // 8B -- Monotonically increasing sequence ID
    val timestamp: Long,   // 8B -- Epoch milliseconds timestamp
    val opCode:    Byte,   // 1B -- Operation Code (INSERT=1, DELETE=2, UPDATE=3, RENAME=4)
    val fid:       Int,    // 4B -- Target File ID
    val payload:   Short,  // 2B -- Operation-specific metadata flags
    val checksum:  Int,    // 4B -- CRC32 validation checksum
    // Padding:    1B      -- Standard padding to ensure 32-byte alignment
)
```

On app cold start, the system restores the index state in less than 800 ms by reading the memory-mapped master table and replaying any outstanding WAL entries.

---

## AI Agent Development Rules

All AI coding assistants contributing to the FLUX codebase must adhere to these rules:

### The Prime Directives
1. **Never** loop over the `masterIndex` array on the main thread or in response to a UI gesture. All O(n) calculations must be offloaded to background threads (`Dispatchers.IO`).
2. **Never** execute MediaStore ContentResolver queries for search operations. All search requests must be routed through the FLUX index.
3. **Never** pass raw file data or lists of strings across the MethodChannel bridge. Use FIDs to query file metadata.
4. **Always** document the expected time complexity of a function in a comment block before implementation.

### Forbidden Patterns
* Do not call `Thread.sleep()` in native Kotlin. Use coroutine `delay()`.
* Do not use standard `ArrayList` lists for integer FID collections. Use `IntArray` or `RoaringBitmap`.
* Do not use String keys in hot path HashMaps. Use `Long` hashes (xxHash64) of strings.
* Do not scale bitmap files via `Bitmap.createScaledBitmap()`. Use `ThumbnailUtils` with explicit dimensions.
* Do not let exceptions escape across the MethodChannel bridge. Catch exceptions and propagate them using `result.error()`.
* Do not mutate files without writing corresponding Write-Ahead Log (WAL) records.

### Test Coverage Targets

| Module | Min Coverage | Required Test Cases |
| :--- | :---: | :--- |
| **PathMap** | 95% | Hit, miss, collision, delete, rename |
| **NameTrie** | 90% | Prefix match, CamelCase split, missing search term |
| **TokenIndex** | 90% | Keyword query, Roaring AND/OR, empty set checks |
| **DirIndex** | 90% | Empty directory, single child, 10k directories, delete node |
| **TypeBuckets** | 85% | 11 categories check, MIME mismatch fallback |
| **ChecksumMap** | 90% | Duplicate checksum matches, size difference misses |
| **HnswGraph** | 80% | $\ge$95% vector retrieval recall rate on synthetic embeddings |
| **FileObserverHub** | 85% | Directory creation, directory removal, watcher bounds exceeded |
| **WAL Engine** | 95% | Serialization, file recovery checkpoints, corruption recovery |

---

## Project Structure & Setup

```
flux/
|-- docs/                      # Architectural and requirements documentation
|   |-- fm.tex                 # Unified Master TeX Document
|   |-- tex/                   # Standalone LaTeX files (preamble, prd, trd, design, plan)
|   `-- md/                    # Standalone Markdown translations (prd, trd, design, plan)
|-- android/                   # Native Android codebase (Kotlin, NDK)
|-- ios/                       # iOS runner shell configuration
|-- lib/                       # Flutter codebase (Dart)
|-- test/                      # Flutter UI integration test suites
`-- pubspec.yaml               # Flutter package configuration
```

### Prerequisites
* Flutter SDK (v3.19.0 or higher)
* Android SDK (API level 33 or higher)
* Android NDK (for native HNSW vector calculations)
* Kotlin (v1.9.0 or higher)

### Build and Run
1. Clone the repository and navigate to the project directory:
   ```bash
   git clone https://github.com/maisachinsharmahu/flux-file-manager.git
   cd flux
   ```
2. Retrieve packages and initialize build tasks:
   ```bash
   flutter pub get
   ```
3. Compile and execute the application on a connected device:
   ```bash
   flutter run --release
   ```
4. Execute unit test suites:
   ```bash
   flutter test
   ```
