# Technical Requirements Document (TRD) - FLUX

## Research: Existing File System Architecture

### The Android Filesystem Foundation
Android runs on the Linux kernel and uses a hierarchical tree structure for all files. Every file and directory is represented internally by an **inode** (index node) — a 256-byte on-disk structure containing all metadata about a file except its name.

* **The inode:** Stores file size, owner UID and GID, permissions, three timestamps (created, accessed, modified), and a pointer to where the file's content blocks reside on disk. The file's name is stored separately in a directory entry mapping name to inode. Renaming is instantaneous at the OS level.
* **ext4 (Extent B-Tree):** Inside every inode, a 60-byte field called `i_block` holds the root of an Extent B-Tree mapping logical offsets to physical disk blocks. Small files fit entirely inside the inode (inline data). B-tree search, insert, and delete execute in $\mathcal{O}(\log n)$.
* **Directory Indexing (HTree):** Small directories use a linear linked list of entries ($\mathcal{O}(n)$). Large directories use an HTree (Hashed B-Tree), enabling $\mathcal{O}(\log n)$ directory lookup.

> **Critical Observation:** Even at the kernel level, large directories use B-trees. Yet file explorer applications sitting above this foundation perform linear scans across thousands of files. The inefficiency is entirely in the application layer, not the kernel.

### Android MediaStore
File explorer apps cannot access ext4 directly due to Android's permission model. Instead, they query **MediaStore** — an SQLite database maintained by the OS. MediaStore has tables for `Images`, `Video`, `Audio`, and `Files`. Substring searches issue SQL `LIKE '%query%'` statements, which cannot use B-tree indexes, degrading to a full table scan $\mathcal{O}(n)$.

* **The Staleness Problem:** MediaStore is updated asynchronously by the Media Scanner. Files deleted by another app may continue to appear as ghost files. Vendor overlays (like Samsung My Files) compound this by keeping their own SQLite databases at `/data/data/.../myfiles.db` — creating dual stale caches.

| App | Primary Index | Search Method | Critical Weakness |
| :--- | :--- | :--- | :--- |
| **Google Files** | MediaStore SQLite | SQL `LIKE` full scan | No substring index; stale data |
| **Samsung My Files** | MediaStore + `myfiles.db` | SQL `LIKE` + dir scan | Dual stale caches; permission gaps |
| **Google Photos** | Cloud Vector DB + SQLite | Semantic vector similarity | Cloud-dependent; photos only |
| **Windows Explorer** | NTFS MFT + inverted index | Inverted word index | Slow first-run indexing |

---

## The FLUX Index Architecture

### Design Manifesto
> **THE FLUX LAW:** Every operation a user can trigger — lookup, delete, search, insert, filter, list — must execute in $\mathcal{O}(1)$ or $\mathcal{O}(\log n)$ time. No full scans. No exceptions. If a data structure cannot guarantee this, we use a different one.

### The File ID (FID) System
Every file is assigned a unique 64-bit integer FID at discovery. All indexes reference the FID, never the path string:
* **Rename safety:** Renaming/moving updates only the path index. Other indexes hold FIDs — zero cascading updates.
* **Memory efficiency:** FIDs are 8 bytes. String paths are 60–120 bytes. FID-based posting lists save 87–93% memory.
* **Bitset operations:** Integer FIDs enable set intersections via 64-bit CPU word operations (AND, OR, NOT).
* **$\mathcal{O}(1)$ record access:** Master record lookup is a single array index operation.

FIDs are thread-safely allocated by `AtomicLong.incrementAndGet()`. FID 0 is a null sentinel. Deleted FIDs enter a free pool during compaction.

```kotlin
// Master Record Array
val masterIndex = Array<FileRecord>(MAX_FILES) { FileRecord.EMPTY }

// O(1) lookup -- always, regardless of total file count
val record: FileRecord = masterIndex[fid]
```

### The FileRecord Structure (64 Bytes)
Optimized for mobile RAM constraints:

| Field | Type | Size | Purpose |
| :--- | :--- | :--- | :--- |
| `fid` | uint64 | 8 B | Unique file identifier |
| `parentDirFid` | uint64 | 8 B | FID of parent directory |
| `nameOffset` | uint24 | 3 B | Offset into shared name string pool |
| `nameLen` | uint16 | 2 B | Byte length of filename |
| `pathOffset` | uint24 | 3 B | Offset into shared path string pool |
| `pathLen` | uint16 | 2 B | Byte length of full path |
| `size` | uint64 | 8 B | File size in bytes |
| `mtime` | uint32 | 4 B | Modified time (seconds since 2020-01-01) |
| `atime` | uint32 | 4 B | Accessed time |
| `ctime` | uint32 | 4 B | Created time |
| `mimeType` | uint16 | 2 B | Index into global MIME type table |
| `flags` | uint32 | 4 B | Deleted, hidden, pinned, indexed, starred |
| `vectorSlot` | uint24 | 3 B | Slot in HNSW vector store |
| `accessCount` | uint16 | 2 B | Open count (capped at 65,535) |
| `checksum` | uint64 | 8 B | xxHash64 of content (deduplication) |

**RAM footprint at scale:**
* 100,000 files = 6.4 MB
* 500,000 files = 32 MB (Fits easily in the 50–80 MB HOT cache tier).

### The Nine Indexes

| # | Name | Structure | Primary Query | Complexity |
| :-: | :--- | :--- | :--- | :--- |
| 1 | **Path Map** | HashMap (xxHash64) | Exact path lookup | $\mathcal{O}(1)$ |
| 2 | **Name Trie** | Radix Trie | Prefix / autocomplete | $\mathcal{O}(k)$ |
| 3 | **Token Index** | HashMap + RoaringBitmap | Keyword search, AND/OR | $\mathcal{O}(1)$ / $\mathcal{O}(N/64)$ |
| 4 | **Directory Index** | HashMap + sorted int[] | Folder listing | $\mathcal{O}(1)$ |
| 5 | **Type Buckets** | HashMap + RoaringBitmap | Filter by MIME type | $\mathcal{O}(1)$ |
| 6 | **Size Index** | Van Emde Boas Tree | Range by file size | $\mathcal{O}(\log \log U)$ |
| 7 | **Time Index** | Van Emde Boas Tree | Range by date | $\mathcal{O}(\log \log U)$ |
| 8 | **Checksum Map** | HashMap (xxHash64) | Duplicate detection | $\mathcal{O}(1)$ |
| 9 | **HNSW Vector Graph** | Multi-layer proximity graph | Semantic AI search | $\mathcal{O}(\log n)$ |

#### The Deletion BitSet (O(1) logical deletion)
```kotlin
// User deletes N files -- O(1) per file for user-perceived latency
fun logicalDelete(fid: Int) {
    deletionSet.add(fid)                   // flip one bit
    masterIndex[fid].flags = masterIndex[fid].flags or FLAG_DELETED
    wal.append(WAL_DELETE, fid)            // crash-safe write-ahead log
}

// Every query result is filtered through:
val result = queryResult.andNot(deletionSet)   // O(N/64)

// Physical cleanup runs asynchronously during idle
fun backgroundCompaction() {
    deletionSet.forEach { fid -> physicallyRemoveFromAllIndexes(fid) }
    deletionSet.clear()
}
```
Deleting 10,000 files requires 156 bitmap operations, taking less than 2 ms. The interface never freezes.

#### Index 1 — Path HashMap: $\mathcal{O}(1)$ Exact Lookup
```kotlin
val pathMap = HashMap<Long, Int>()   // xxHash64(path) -> FID

fun lookup(path: String): FileRecord? {
    val hash = xxHash64(path.lowercase())       // ~5 nanoseconds
    val fid  = pathMap[hash] ?: return null    // ~10 nanoseconds
    return if (deletionSet.contains(fid)) null else masterIndex[fid]  // ~10 ns
}
```

#### Index 2 — Radix Trie: $\mathcal{O}(k)$ Prefix Search
Enables autocomplete in $\mathcal{O}(k)$ time, where $k$ is query prefix length, independent of total files.
* `nameTrie`: complete filenames (autocomplete).
* `tokenTrie`: extracted tokens (mid-word search).
* *Tokenisation:* `Q3_Budget_2025_FINAL_v2.xlsx` $\rightarrow$ `[q3, budget, 2025, final, v2, xlsx]` (split on underscores, hyphens, dots, CamelCase, letter-number transitions).

#### Index 3 — Token Index + RoaringBitmap: Keyword Search
```kotlin
val tokenIndex = HashMap<String, RoaringBitmap>()

// Multi-keyword AND: O(N/64) via bitmap intersection
fun searchAll(vararg tokens: String): RoaringBitmap {
    var result = tokenIndex[tokens[0]] ?: return RoaringBitmap()
    for (i in 1 until tokens.size) {
        val bitmap = tokenIndex[tokens[i]] ?: return RoaringBitmap()
        result = RoaringBitmap.and(result, bitmap)
    }
    return result.andNot(deletionSet)
}
```

| Property | Plain Bitset | RoaringBitmap | Winner |
| :--- | :--- | :--- | :--- |
| **Memory (1M files, 1% density)** | 125 KB fixed | $\approx$5 KB | Roaring ($25\times$) |
| **AND speed** | $\mathcal{O}(N/64)$ | $\mathcal{O}(N/64)$ + skip zeros | Roaring ($2\text{--}5\times$) |
| **Sparse tokens** | 125 KB wasted | ArrayContainer: tiny | Roaring |
| **Serialisation** | Large | Compressed | Roaring |

Content indexing maps in a `content:` namespace in the same `tokenIndex` (first 10,000 characters).

#### Index 4 — Directory Index: Folder Listing
`HashMap<Int, IntArray>` mapping parent FID to sorted children FIDs. Folder listing executes in $\mathcal{O}(1)$.

#### Index 5 — Type Buckets: MIME Filtering
`HashMap<String, RoaringBitmap>` mapped by MIME type. Filtering images: `typeBuckets["image/*"]` ($\mathcal{O}(1)$).

#### Index 6 — Size Index: VEB Tree
Van Emde Boas Tree with universe size $U = 2^{40}$ (1 TB max). Range queries (e.g. "files 10 MB to 100 MB") run in $\mathcal{O}(\log \log U)$ ($\sim$13 operations, independent of file count).

#### Index 7 — Time Index: VEB Tree
VEB tree on timestamps for range queries ("files from last week") in $\mathcal{O}(\log \log U)$.

#### Index 8 — Checksum Map: Duplicate Detection
`HashMap<Long, IntArray>` keyed on `xxHash64(content)`. Duplicate check is $\mathcal{O}(1)$. xxHash64 computes a 10 MB file in 8 ms on modern Android SoCs.

#### Index 9 — HNSW Vector Graph: Semantic AI Search
Natural language search is performed using HNSW (Hierarchical Navigable Small World) structures.
* **Vector Embeddings:** Filename, path context, and document previews are mapped to a 384-dimensional numeric vector using on-device MiniLM-L6 (22 MB).
* **HNSW Graph:** Multi-layer navigable graph reduces brute-force nearest-neighbour searches from $\mathcal{O}(n)$ to $\mathcal{O}(\log n)$.
* **Model Choices:**
  * `MiniLM-L6`: 384 dimensions, 22 MB, $\sim$15 ms latency (Default).
  * `all-MiniLM-L3-v2`: 384 dimensions, 17 MB, $\sim$8 ms latency.
  * `BERT-tiny`: 128 dimensions, 5 MB, $\sim$3 ms latency.

---

## Mobile-First Architecture: Flutter + Native

### The Split: Flutter vs Native Kotlin
> **THE BRIDGE RULE:** Native owns everything that touches hardware, the filesystem, or the OS scheduler. Flutter owns everything the user sees and touches. The bridge carries only FIDs and small metadata — never raw bytes, never large strings.

| Responsibility | Layer | Language | Rationale |
| :--- | :--- | :--- | :--- |
| **FLUX Index (9 structures)** | Native | Kotlin | Direct JVM memory, no Dart GC pressure |
| **FileObserver / inotify** | Native | Kotlin | OS API unavailable from Dart |
| **Background indexing service** | Native | Kotlin | WorkManager system, survives backgrounding |
| **Thumbnail generation** | Native | Kotlin | Hardware-accelerated JPEG decoder |
| **HNSW vector computation** | Native | Kotlin/C++ | ONNX Runtime NDK inference |
| **File CRUD** | Native | Kotlin | Direct POSIX filesystem calls |
| **UI screens** | Flutter | Dart | Single codebase, unified layouts |
| **State management** | Flutter | Dart | Riverpod reactive provider tree |

### RAM Tiering
* **Tier 1 (HOT CACHE):** `masterIndex`, `pathMap`, `dirIndex`, `tokenIndex`, `deletionSet`. Max RAM: 50–80 MB. Never evicted in foreground.
* **Tier 2 (WARM STORE):** `sizeVEB`, `timeVEB`, `checksumMap`, full `nameTrie`. Max RAM: 80–150 MB. Evicted on low memory.
* **Tier 3 (COLD DISK):** HNSW graph, content tokens, string pool. Max RAM: 600 MB+ on disk. OS-managed `mmap`.

```kotlin
// Memory pressure response
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

### Thermal Management
Background indexing can overheat mobile CPUs. The `ThermalGovernor` regulates threads based on thermal state:
* **COOL:** 4 threads, batch size 500, delay 0 ms.
* **WARM:** 2 threads, batch size 200, delay 50 ms.
* **HOT:** 1 thread, batch size 50, delay 200 ms.
* **CRITICAL:** Indexing paused (0 threads).

HNSW embedding generation runs exclusively when the device is charging and the screen is off.

---

## Cross-Application Deletion Sync

### 4-Layer Defence System
* **Layer 1 — FileObserver (`inotify`):** Kernel-level event (<1 ms) covering watched directories.
* **Layer 2 — MediaStore ContentObserver:** OS broadcast (100 ms–2 s) covering media tables.
* **Layer 3 — sdcard Root Observer:** Directory listener (<1 ms) catching newly created directories.
* **Layer 4 — Delta Reconciliation:** 15-minute background idle scan resolving residual differences.

```kotlin
// FileObserverHub snippet
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

---

## Complete Data Schema

### Persistence Files
* `flux.wal`: Binary sequential log of recent mutations (writes).
* `master.bin`: Serialised `FileRecord[]` (memory-mapped).
* `pathmap.bin`: Serialised hash map (xxHash64 to FID).
* `deletion.bin`: Serialised deletion `RoaringBitmap`.
* `hnsw.bin`: Memory-mapped HNSW graph structure (600 MB+).
* `strings.pool`: Shared string pool byte array.

```kotlin
// WAL Entry Format (32 Bytes)
data class WalEntry(
    val magic:     UInt,   // 4B -- 0xFLUX sentinel
    val sequence:  Long,   // 8B -- monotonic sequence number
    val timestamp: Long,   // 8B -- epoch milliseconds
    val opCode:    Byte,   // 1B -- INSERT=1, DELETE=2, UPDATE=3, RENAME=4
    val fid:       Int,    // 4B -- target file ID
    val payload:   Short,  // 2B -- operation metadata
    val checksum:  Int,    // 4B -- CRC32 checksum
    // padding    1B       -- alignment to 32 bytes
)
```

---

## Appendix

### Complexity Reference Card

| Operation | Complexity | Latency (1M Files) | RAM Tier |
| :--- | :--- | :--- | :--- |
| **Path lookup** | $\mathcal{O}(1)$ | < 25 ns | HOT |
| **Prefix search** | $\mathcal{O}(k)$ | < 0.5 ms | HOT |
| **Keyword search** | $\mathcal{O}(1)$ / $\mathcal{O}(N/64)$ | < 2 ms | HOT |
| **Folder listing** | $\mathcal{O}(1)$ | < 1 ms | HOT |
| **Size/Time range** | $\mathcal{O}(\log \log U)$ | < 1 ms | WARM |
| **Duplicate check** | $\mathcal{O}(1)$ | < 1 ms | WARM |
| **Semantic AI search** | $\mathcal{O}(\log n)$ | < 10 ms | COLD (mmap) |
| **Logical delete** | $\mathcal{O}(N/64)$ | < 2 ms per 1k | HOT |
| **App cold start** | — | < 800 ms | mmap restore |

### Android Permissions Reference
* `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` (API 16–32): Legacy filesystem read/write.
* `MANAGE_EXTERNAL_STORAGE` (API 30+): Broad local storage access required to build FLUX indexes.
* `READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO` / `READ_MEDIA_AUDIO` (API 33+): Specialized media file reading.
* `FOREGROUND_SERVICE`: Prevents background service interruption during deep scans.
* `USE_BIOMETRIC`: Secure folder authentication.
