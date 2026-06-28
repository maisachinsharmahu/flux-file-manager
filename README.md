# FLUX: File Lookup & Unified eXperience Index

FLUX is a native Android file indexing and management framework bridged to a reactive, cross-platform UI. By replacing legacy database and filesystem scan pathways with a custom **9-layer composite local index**, FLUX achieves sub-millisecond search execution, zero-latency change synchronization, and local natural-language semantic searches. 

Every user-perceived operation — lookup, delete, search, filter, list — executes in $\mathcal{O}(1)$ or $\mathcal{O}(\log n)$ time.

---

## 1. The Android Filesystem Bottleneck

### The ext4 and HTree Foundation
Android devices run on the Linux kernel and format user data partitions using **ext4**.
* **inodes:** Every file/directory is represented by an *index node* (inode) containing metadata (size, UID, permissions, modification times) and pointers to content blocks. Renaming or moving files updates only the parent directory entry mapping the name to the inode, executing instantaneously at the kernel level.
* **ext4 Extents:** Inside the inode, a 60-byte `i_block` field holds the root of an Extent B-Tree mapping logical offsets to physical disk blocks, enabling seek/write operations in $\mathcal{O}(\log n)$ time.
* **Directory Indexing (HTree):** Large folders use an HTree (Hashed B-Tree), allowing directory lookups in $\mathcal{O}(\log n)$ time.

### The MediaStore SQLite Bottleneck
Because file explorer applications cannot access ext4 directly due to sandbox permissions, they rely on Android's **MediaStore** — a system SQLite database. 
1. **Full Table Scans ($\mathcal{O}(n)$):** Substring search queries (e.g. search for `report`) issue SQL `LIKE '%report%'` statements. SQLite cannot use B-tree index lookups for leading-wildcard queries, forcing a linear row scan across the entire database.
2. **The Staleness Problem:** MediaStore is updated asynchronously by the OS Media Scanner. File mutations made by other apps often lag, resulting in "ghost files" (deleted files appearing as active) or delay in discovery.
3. **UI Blocker during Batch Operations:** Deleting or moving 1,000 files issues consecutive SQL writes, trigger notifications, and redraw overhead that blocks the UI thread for 30–60 seconds.

---

## 2. The FLUX Composite Index Architecture

FLUX maintains a custom, memory-mapped composite index directly inside the application process memory, eliminating operating system database bottlenecks.

### The File ID (FID) System
Each discovered file is assigned a unique 64-bit integer **FID** at discovery (allocated thread-safely via `AtomicLong`).
* **Rename Safety:** Moving or renaming updates only the path map. Other indexes reference the FID, requiring zero cascading updates.
* **Memory Compression:** Storing 8-byte integer FIDs in postings lists instead of 80-byte path strings reduces the memory index footprint by 87–93%.
* **Set Operations:** Integer FIDs enable set intersections, unions, and differences directly using 64-bit CPU bitwise operations.

```kotlin
// O(1) Master Record Array
val masterIndex = Array<FileRecord>(MAX_FILES) { FileRecord.EMPTY }

inline fun getRecord(fid: Int): FileRecord = masterIndex[fid]
```

### The 64-Byte FileRecord Layout
Optimized for memory density, each file record fits in a 64-byte cache-aligned boundary:

| Field | Type | Size | Offset | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `fid` | uint64 | 8 B | 0 | Unique file identifier |
| `parentDirFid` | uint64 | 8 B | 8 | FID of parent directory |
| `nameOffset` | uint24 | 3 B | 16 | Offset into shared name string pool |
| `nameLen` | uint16 | 2 B | 19 | Filename length in bytes |
| `pathOffset` | uint24 | 3 B | 21 | Offset into shared path string pool |
| `pathLen` | uint16 | 2 B | 24 | Full path length in bytes |
| `size` | uint64 | 8 B | 26 | File size in bytes |
| `mtime` | uint32 | 4 B | 34 | Modified time (epoch seconds since 2020-01-01) |
| `atime` | uint32 | 4 B | 38 | Accessed time |
| `ctime` | uint32 | 4 B | 42 | Created time |
| `mimeType` | uint16 | 2 B | 46 | Index mapping to MIME table |
| `flags` | uint32 | 4 B | 48 | Binary flags (Deleted, Starred, Hidden) |
| `vectorSlot` | uint24 | 3 B | 52 | Index slot in vector store |
| `accessCount` | uint16 | 2 B | 55 | Frequency tally for ranking |
| `checksum` | uint64 | 8 B | 57 | xxHash64 fingerprint of content |

* **Footprint:** 100,000 files consume only 6.4 MB of RAM in the hot tier.

### The Nine Core Indexes

| Index | Name | Underlying Structure | Primary Query | Time Complexity |
| :-: | :--- | :--- | :--- | :--- |
| 1 | **Path Map** | HashMap (xxHash64) | Exact path lookups | $\mathcal{O}(1)$ |
| 2 | **Name Trie** | Radix Trie | Autocomplete & prefix matching | $\mathcal{O}(k)$ |
| 3 | **Token Index** | HashMap + RoaringBitmap | Keyword & Boolean searches | $\mathcal{O}(1)$ / $\mathcal{O}(N/64)$ |
| 4 | **Directory Index** | HashMap + sorted `IntArray` | Folder listing contents | $\mathcal{O}(1)$ |
| 5 | **Type Buckets** | HashMap + RoaringBitmap | Category filters (Images, Audio, Docs) | $\mathcal{O}(1)$ |
| 6 | **Size Index** | Van Emde Boas Tree | File size range queries | $\mathcal{O}(\log \log U)$ |
| 7 | **Time Index** | Van Emde Boas Tree | Date range queries | $\mathcal{O}(\log \log U)$ |
| 8 | **Checksum Map** | HashMap (xxHash64) | Instant duplicate block detection | $\mathcal{O}(1)$ |
| 9 | **Vector Graph** | HNSW Proximity Graph | Semantic AI search queries | $\mathcal{O}(\log n)$ |

---

## 3. Detailed Index Implementations

### Index 2 — Radix Trie: $\mathcal{O}(k)$ Name Autocomplete
Allows looking up matching prefixes in time proportional to key length $k$ (number of characters), independent of the size of the repository.
* **Tokenization Pipeline:** Words like `Q3_Report_2026.pdf` are split at transitions (underscores, dots, case changes) into searchable tokens: `[q3, report, 2026, pdf]`.

### Index 3 — Token Index & RoaringBitmap Intersections
Stores postings lists of FIDs for filename tokens.
* **Boolean Intersections:** Multi-word searches perform high-speed bitset intersections:

```kotlin
// Multi-keyword AND logic via RoaringBitmap intersections
fun searchKeywords(vararg tokens: String): RoaringBitmap {
    var result = tokenIndex[tokens[0]] ?: return RoaringBitmap()
    for (i in 1 until tokens.size) {
        val bitmap = tokenIndex[tokens[i]] ?: return RoaringBitmap()
        result = RoaringBitmap.and(result, bitmap)
    }
    return result.andNot(deletionSet)
}
```

### Index 6 & 7 — Van Emde Boas (vEB) Trees for Range Queries
Instead of sorting lists, file size and modification timestamps are indexed inside a vEB tree with universe size $U = 2^{40}$. Range queries (e.g. finding files between 10MB and 100MB) execute in $\mathcal{O}(\log \log U)$ time, taking at most 13 lookup operations regardless of file volume.

### Index 9 — On-Device HNSW Semantic Graph
Features local semantic searches without network queries:
* **Embeddings Model:** MiniLM-L6 (22 MB) runs locally using ONNX Runtime Mobile, embedding file metadata and text content into a 384-dimensional vector space in ~15 ms.
* **Hierarchical Navigable Small World (HNSW):** A multi-layer proximity graph maps vector relationships, bypassing linear $\mathcal{O}(n)$ scans in favor of $\mathcal{O}(\log n)$ link traversal.

---

## 4. Cross-Application Deletion Sync & Compilation

To prevent stale indices, FLUX employs a **4-Layer Sync System**:
1. **Layer 1 — FileObserver (`inotify`):** Kernel-level event triggers (<1 ms) covering currently watched directories.
2. **Layer 2 — ContentObserver:** Monitors MediaStore broadcasts (100 ms–2 s latency) for background media deletions.
3. **Layer 3 — Root sdcard Observer:** Listens for directory tree mutations.
4. **Layer 4 — Delta Reconciliation:** Background daemon executing an idle delta check every 15 minutes.

### The Deletion BitSet (Logical Tombstoning)
To maintain interface responsiveness during batch deletions, FLUX tombstones entries immediately:

```kotlin
fun logicalDelete(fid: Int) {
    deletionSet.add(fid) // Logical delete (flip single bit in RoaringBitmap)
    masterIndex[fid].flags = masterIndex[fid].flags or FLAG_DELETED
    wal.append(WAL_DELETE, fid) // Log transaction safely to WAL disk file
}
```
Queries filter results via `bitmap.andNot(deletionSet)` in $<1$ ms. Physical deletion from all 9 indexes is deferred to background compilation routines when the device is idle.

---

## 5. Mobile-First Hybrid Architecture

FLUX divides responsibilities based on performance characteristics:
* **Native Layer (Kotlin/NDK C++):** Handles memory-mapped indexes, OS-level filesystem hook listeners, ONNX AI inference, and thread pools.
* **Presentation Layer (Flutter/Dart):** Renders the UI shell, handles GoRouter routing, and consumes Riverpod state notifications.

### Memory Tiering & Lifecycle Management
To run safely under Android memory limits:
* **Tier 1 (HOT CACHE):** `masterIndex`, `pathMap`, `dirIndex`, `tokenIndex`, `deletionSet` (50–80 MB RAM). Anchored in memory.
* **Tier 2 (WARM STORE):** `sizeVEB`, `timeVEB`, `checksumMap`, `nameTrie` (80–150 MB RAM). Evicted dynamically on low memory.
* **Tier 3 (COLD DISK):** HNSW graph, text indexes. Memory-mapped to disk via `mmap`.

```kotlin
override fun onTrimMemory(level: Int) {
    when (level) {
        TRIM_MEMORY_RUNNING_CRITICAL -> {
            warmStore.evictAll() // Purge size trees, checksum maps, and radix trie
            System.gc()
        }
        TRIM_MEMORY_BACKGROUND -> {
            wal.flush() // Force WAL flush to disk
            indexingJob.pause() // Pause scanner
        }
    }
}
```

### CPU Thermal Governor
Regulates thread allocation based on device temperature:
* **COOL:** 4 threads, batch size 500.
* **WARM:** 2 threads, batch size 200, 50ms delay.
* **HOT:** 1 thread, batch size 50, 200ms delay.
* **CRITICAL:** Indexing suspended.

---

## 6. Storage Analytics & Junk Cleaner Engine

Uses the composite index memory tables to identify cleaning targets without traversing directories:

| Junk Category | Target Logic | Scan Time | Efficiency |
| :--- | :--- | :--- | :--- |
| **System Cache** | Trie lookup for `.tmp`, `.log`, `.bak` | < 1 ms | $\mathcal{O}(k)$ |
| **Empty Folders** | `dirIndex` lists evaluating size 0 | < 100 ms | $\mathcal{O}(1)$ |
| **Duplicates** | `checksumMap` finding collisions | < 1 s | $\mathcal{O}(1)$ |
| **Orphaned Folders** | `/Android/data` package verification | < 200 ms | $\mathcal{O}(n)$ package list |

### Safety Constraints
* **Absolute Exclusion:** The camera directory (`/DCIM`) is hard-excluded from all scanner operations.
* **Grace Period:** Files modified within the last 24 hours are skipped to avoid corrupting active files.

---

## 7. Progressive Thumbnail Pipeline

Renders thumbnails smoothly without causing frame drops or high memory allocation during scroll:
1. **Decode Limit:** Decodes images at a maximum size of 256x256 using the `RGB_565` format (2 bytes/pixel), saving 50% memory over `ARGB_8888` (4 bytes/pixel).
2. **Pipeline Tiers:** Micro Placeholder (16x16 stored in `FileRecord`) $\rightarrow$ Memory Cache (50 MB LRU) $\rightarrow$ Disk Cache $\rightarrow$ Generative Decoder.
3. **Scroll Governor:** Pauses thumbnail decoding when scroll velocity exceeds 3,000 px/s.

---

## 8. Data Serialization & WAL Format

Persistence index details are saved in the app's sandboxed storage directory:

| Filename | Purpose | Type |
| :--- | :--- | :--- |
| `flux.wal` | Write-Ahead Log | Append-Only Binary |
| `master.bin` | Master Record Array | Memory-Mapped Binary |
| `pathmap.bin` | Path-to-FID Mapping | Serialization Hash |
| `deletion.bin` | Tombstoned File ID Set | Compressed RoaringBitmap |
| `hnsw.bin` | HNSW Vector Connections | Memory-Mapped Graph |

### WAL Entry Binary Structure (32 Bytes)
Transactions are appended sequentially to the WAL to prevent index corruption during app crashes:

```
+-------------------------------------------------------------+
|  magic (4B)  |  sequence (8B)  |   timestamp (8B)  | op (1B)|
+-------------------------------------------------------------+
|   fid (4B)   |   payload (2B)  |   checksum (4B)   |pad (1B)|
+-------------------------------------------------------------+
```

---

## 9. Local Setup & Development Build

### Prerequisites
* Flutter SDK (v3.19.0 or higher)
* Android SDK (API level 33 or higher)
* Android NDK (for compiling native graph execution)

### Build Instructions
1. Clone the private repository:
   ```bash
   git clone https://github.com/maisachinsharmahu/flux-private.git
   cd flux-private
   ```
2. Retrieve dependencies:
   ```bash
   flutter pub get
   ```
3. Run the development build:
   ```bash
   flutter run
   ```
4. Run testing verification:
   ```bash
   flutter test
   ```

---

## 10. Licensing & Security

### Code of Conduct
Please review [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for collaboration guidelines.

### Security Disclosures
If you discover a vulnerability, do not open a public issue. Review our disclosure policy in [SECURITY.md](SECURITY.md) to report vulnerabilities directly.

### License
This software and its documentation are proprietary and confidential. All rights are reserved to **Sachin Sharma**. Unauthorized usage, modification, or distribution is strictly prohibited. For details, refer to [LICENSE](LICENSE).
