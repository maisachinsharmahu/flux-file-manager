# Logic & Functionality Specifications

This document defines the step-by-step implementation sequence, logic flows, background worker tasks, and native bridge APIs for FLUX.

---

## Step-by-Step Implementation Sequence

The implementation is structured into five sequential development stages:

```
+------------------------------------------------------------+
|                     IMPLEMENTATION FLOW                    |
|                                                            |
|  Stage 1: Native Foundation & WAL Configuration             |
|  Stage 2: Core Index Structures (Index 1 to 8)             |
|  Stage 3: Flutter UI Integration & MethodChannel Bridge    |
|  Stage 4: File Observers & Real-Time Sync Engines           |
|  Stage 5: AI Semantic Graph & Performance Profiling        |
+------------------------------------------------------------+
```

### Stage 1: Native Foundation & WAL Configuration (Week 1–2)
1. Configure dependencies in `build.gradle.kts` (RoaringBitmap, zero-allocation-hashing, ONNX Mobile Runtime).
2. Set up the `FileRecord` class with strict 64-byte alignment logic.
3. Build the virtual memory `StringPool` wrapper class utilizing `MappedByteBuffer` to support O(1) filename mappings.
4. Implement the binary sequential `WalManager` class (writing headers, monotonic checks, magic Sentinels, and CRC32 checks).
5. Build index restore logic to reconstruct index records from the mapped master file and outstanding WAL entry files.

### Stage 2: Core Index Structures (Week 3–5)
1. Build `PathMap` (Index 1) using a flat HashMap matching `xxHash64` keys to FIDs.
2. Build the compressed `NameTrie` (Index 2) prefix trie class.
3. Build the token-mapping inverted `TokenIndex` (Index 3) using RoaringBitmap.
4. Implement `DirIndex` (Index 4) directory map.
5. Implement `TypeBuckets` (Index 5) MIME bitmap buckets.
6. Build the `SizeIndex` (Index 6) and `TimeIndex` (Index 7) Van Emde Boas Trees.
7. Build `ChecksumMap` (Index 8) checking content xxHash64 collisions.
8. Set up the `deletionSet` RoaringBitmap filter layer and background compaction task.

### Stage 3: Flutter UI Integration & MethodChannel Bridge (Week 6–8)
1. Define MethodChannel and EventChannel structures inside `FluxPlugin.kt` and `flux_bridge.dart`.
2. Integrate the Riverpod global provider shell and GoRouter configurations.
3. Build all UI screens (Home, Browser, Search, Analytics, Trash, Settings) using achromatic theme parameters.
4. Integrate the progressive `FluxThumbnail` widget with strict image size limits.
5. Create the custom canvas storage donut painter.

### Stage 4: File Observers & Real-Time Sync Engines (Week 9–10)
1. Write the recursive `FileObserverHub` wrapper layer utilizing Android inotify observers.
2. Set up `MediaStoreObserver` listening to database broadcasts.
3. Create `sdcard` root observers.
4. Build the background `DeltaReconciler` executing non-blocking check scans when the system goes idle.

### Stage 5: AI Semantic Graph & Performance Profiling (Week 11–12)
1. Connect ONNX Mobile Runtime for sentence embedding generation.
2. Set up the `HnswGraph` vector index (Index 9) handling O(log n) proximity walks.
3. Hook in `ThermalGovernor` monitoring thermal state steps.
4. Run index benchmarks to verify sub-millisecond prefix searches on 1M files.

---

## Native-to-Flutter Bridge API Specifications

### MethodChannel: `com.flux.channel/methods`

#### 1. `initializeIndex`
* **Direction:** Flutter -> Native
* **Payload:** None
* **Action:** Restores the in-memory composite index from disk. Returns `true` if successful.

#### 2. `getDirectoryContents`
* **Direction:** Flutter -> Native
* **Payload:** `{"parentPath": String}`
* **Action:** Looks up the parent directory FID in the Path Map, queries the Directory Index, and returns a binary buffer containing FIDs, sizes, modification dates, and filename offset blocks.

#### 3. `executeBatchDelete`
* **Direction:** Flutter -> Native
* **Payload:** `{"fids": IntArray}`
* **Action:** Performs logical tombstones in the Deletion BitSet and records WAL delete transactions. Returns completion status.

#### 4. `restoreTombstones`
* **Direction:** Flutter -> Native
* **Payload:** `{"fids": IntArray}`
* **Action:** Removes target FIDs from the deletion RoaringBitmap.

#### 5. `getStorageStatistics`
* **Direction:** Flutter -> Native
* **Payload:** None
* **Action:** Returns category-wise byte counts and file counts gathered in under 50 ms.

#### 6. `getAppStorageUsage`
* **Direction:** Flutter -> Native
* **Payload:** None
* **Action:** Returns app package names and size footprints retrieved via `StorageStatsManager`.

---

### EventChannel: `com.flux.channel/search_stream`

Streams query results dynamically.

* **Trigger:** Flutter opens stream sending a query package: `{"query": String, "limit": Int}`.
* **Stream Sequence:**
  1. Native walks the prefix Radix Trie and sends the first batch of results within 0.5 ms.
  2. If the user submits, native intersects the Token Index bitmaps and pushes the second batch within 2 ms.
  3. If results are sparse, native triggers the ONNX embedding query, walks the HNSW vector graph, and pushes semantic matches within 15 ms.

---

## Key Algorithmic Workflows

### 1. High-Speed Prefix Search
```
[User Types Key] ---> [Debounce 150ms] ---> [Call Method / Stream]
                                                     |
                                                     v
                                       [Radix Trie Prefix Walk]
                                                     |
                                                     v
                                         [Retrieve matching FIDs]
                                                     |
                                                     v
                                          [Filter deletionSet]
                                                     |
                                                     v
                                          [Return sorted list]
```

### 2. Junk Scanner Scan Steps
1. Query `TypeBuckets` for `.tmp`, `.bak`, and `.log` extensions.
2. Read directory arrays from `DirIndex`. Mark folders that contain empty child arrays as empty.
3. Compare the checksum map entries. Groups containing more than one FID are marked as duplicates.
4. Perform package checks. Directories under `/Android/data` that do not match installed packages are marked as orphaned.
5. All discovered paths are aggregated and displayed for review.

### 3. On-Device Semantic AI Search
1. When a query is initiated, check device power state.
2. Vector calculation runs if the device is not thermal-throttled.
3. Convert query text to a 384-dimensional vector using on-device MiniLM-L6.
4. Start entry search at HNSW Graph Layer 2 (top layer). Move between coarse proximity nodes.
5. Descend to Layer 1 and walk nearest neighbors.
6. Gather the closest bottom-layer matches, filter out FIDs found in the `deletionSet`, and stream results to Flutter.
