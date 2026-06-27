# Implementation Roadmap & AI Agent Coding Rules - FLUX

## Project Structure

```
flux_app/
|-- android/app/src/main/kotlin/com/flux/
|   |-- FluxPlugin.kt           # MethodChannel + EventChannel bridge
|   |-- index/
|   |   |-- FluxIndex.kt        # Main index facade
|   |   |-- FileRecord.kt       # 64-byte FileRecord struct
|   |   |-- StringPool.kt       # Shared string pool (mmap)
|   |   |-- PathMap.kt          # Index 1: path HashMap
|   |   |-- NameTrie.kt         # Index 2: Radix Trie
|   |   |-- TokenIndex.kt       # Index 3: inverted index + Roaring
|   |   |-- DirIndex.kt         # Index 4: directory children
|   |   |-- TypeBuckets.kt      # Index 5: MIME type bitmaps
|   |   |-- SizeIndex.kt        # Index 6: Van Emde Boas Tree
|   |   |-- TimeIndex.kt        # Index 7: Van Emde Boas Tree
|   |   |-- ChecksumMap.kt      # Index 8: content dedup
|   |   `-- HnswGraph.kt        # Index 9: vector graph (ONNX)
|   |-- sync/
|   |   |-- FileObserverHub.kt
|   |   |-- MediaStoreObserver.kt
|   |   `-- DeltaReconciler.kt
|   |-- thermal/ThermalGovernor.kt
|   |-- thumbnail/ThumbnailEngine.kt
|   |-- analytics/StorageAggregator.kt
|   |-- cleaner/JunkScanner.kt
|   `-- persistence/WalManager.kt
`-- lib/
    |-- main.dart
    |-- app.dart
    |-- bridge/flux_bridge.dart
    |-- models/file_record.dart
    |-- screens/
    |   |-- home_screen.dart
    |   |-- browser_screen.dart
    |   |-- search_screen.dart
    |   |-- analytics_screen.dart
    |   |-- trash_screen.dart
    |   `-- settings_screen.dart
    |-- widgets/
    |   |-- flux_file_list_item.dart
    |   |-- flux_thumbnail.dart
    |   |-- flux_search_bar.dart
    |   `-- flux_storage_donut.dart
    `-- providers/
        |-- index_provider.dart
        |-- search_provider.dart
        `-- analytics_provider.dart
```

### Key Dependencies

**Android dependencies (`build.gradle`):**
```groovy
implementation 'org.roaringbitmap:RoaringBitmap:0.9.49'
implementation 'net.openhft:zero-allocation-hashing:0.16'
implementation 'com.microsoft.onnxruntime:onnxruntime-android:1.17.0'
implementation 'androidx.work:work-runtime-ktx:2.9.0'
```

**Flutter dependencies (`pubspec.yaml`):**
```yaml
dependencies:
  flutter_riverpod: ^2.5.1
  go_router: ^13.2.0
  path_provider: ^2.1.3
  permission_handler: ^11.3.1
  shared_preferences: ^2.2.3
  flutter_animate: ^4.5.0
```

---

## 27-Week Implementation Plan

### Phase 1 — Foundation (Weeks 1–4)
* **Goal:** Write-Ahead Log (WAL), `FileRecord` structures, directory traversals, `FileObserverHub`, and basic MethodChannel bridge setup.
* **Milestone:** Browse simple directories through the Flutter UI with zero crashes.

### Phase 2 — Core Indexing (Weeks 5–10)
* **Goal:** Build the Name Radix Trie, Token Index, Size VEB tree, Time VEB tree, and Deletion BitSet. Define content extraction tokenizers.
* **Milestone:** Sub-millisecond prefix searches and fast logical deletions.

### Phase 3 — Flutter User Interface (Weeks 11–16)
* **Goal:** Implement the visual design system tokens, home view, files grid list, parallel search UI stream, progressive thumbnails, and custom canvas-based storage donut widgets.
* **Milestone:** 60 fps browsing lists for 10k directories.

### Phase 4 — AI & Sync Engines (Weeks 17–20)
* **Goal:** Integrate on-device ONNX runtime engine with MiniLM-L6 embeddings. Implement HNSW graph building. Integrate thermal indexing regulator thresholds and MediaStore change listeners.
* **Milestone:** Local natural-language semantic searches and fast synchronization of cross-app file modifications.

### Phase 5 — Junk Cleaner & Analytics (Weeks 21–24)
* **Goal:** Implement duplicate detection routines, package manager comparisons, downloads directory filtering, and system app info deep linking.
* **Milestone:** Full local storage audit under 3 seconds.

### Phase 6 — Production Hardening (Weeks 25–27)
* **Goal:** Perform memory leak audits, background service wake lock validations, crash logging hooks, and draft Google Play permission justification files.
* **Milestone:** App Store approval with zero thread blocks.

---

## Sprint Tracker

| Sprint | Goal | Acceptance Criteria | Blocked By |
| :--- | :--- | :--- | :--- |
| **S1 (W1–2)** | Foundation Setup | Project runs, plugins compile; WAL can serialize and recover | — |
| **S2 (W3–4)** | PathMap & Watcher | Real directories load in memory; observer tracks deletions | S1 |
| **S3 (W5–6)** | Search Indexes | Prefix matching takes <1 ms on 100k synthetic dataset | S2 |
| **S4 (W7–8)** | Tombstones & Docs | Batch delete 1,000 files in <3 s; PDF tokens searchable | S3 |
| **S5 (W9–10)** | Benchmarking | All 9 index architectures meet strict lookup latencies | S4 |
| **S6 (W11–12)** | Core Screens | Home/Browser views scroll at 60 fps on low-end devices | S5 |
| **S7 (W13–14)** | Search UI & Thumbs | Search screen combines streams; stage-4 thumbnail runs | S6 |
| **S8 (W15–16)** | Analytics & Trash | Donut chart rendering takes <50 ms; restorable deletes | S7 |
| **S9 (W17–18)** | HNSW Embeddings | ONNX vector model runs; vector indexing matches recall targets | S8 |
| **S10 (W19–20)** | Sync & Thermals | External changes update list in <1 s; thermal governor throttles | S9 |
| **S11 (W21–22)** | Cleaner Scan | Temp files, large downloads, and duplicates found in <3 s | S10 |
| **S12 (W23–24)** | Cleaner UI & App | App package sizes load; cleaner filters safe directories | S11 |
| **S13 (W25–27)** | Hardening | Zero ANR errors in 48-hour testing logs; production bundle | S12 |

### Risk Register

| Risk | Probability | Impact | Mitigation Plan |
| :--- | :--- | :--- | :--- |
| **Play Store Rejection** | Medium | Critical | Prepare clear permission justifications; build MediaStore fallback |
| **inotify watcher limits** | Medium | Medium | Track only depths 1–2; fall back to delta checks |
| **HNSW memory usage** | High | High | Keep vector file memory-mapped; support BERT-tiny limits |
| **Embedding generation latency** | Medium | Medium | Queue embedding models only when charging and screen is off |
| **Main thread ANR blocks** | Medium | High | Move all database and filesystem read loops to background coroutines |

---

## AI Agent Rules and Coding Standards

Any AI assistant editing this project must conform to the following standards:

### The Prime Directives
1. **Never** loop over the `masterIndex` array on the main UI thread. All calculations must run on coroutines (`Dispatchers.IO`).
2. **Never** use SQLite `LIKE '%query%'` MediaStore calls for filename queries. Use local custom index structures.
3. **Never** pass raw file data or lists of strings across the MethodChannel bridge. Only pass File IDs (FIDs).
4. **Always** document the expected time complexity in a comment block before implementing any index functions.

### Coding Practices

#### Forbidden Patterns
* No calls to `Thread.sleep()` in native Kotlin. Use coroutine `delay()`.
* No usage of standard `ArrayList` lists for integer FID collections. Use primitive `IntArray` or `RoaringBitmap`.
* No String keys in hot path HashMaps. Use `Long` hashes (xxHash64) of strings.
* No raw scaling of bitmap files via `Bitmap.createScaledBitmap()`. Use `ThumbnailUtils` with explicit dimensions.
* No unhandled Kotlin thread exceptions. Catch exceptions and propagate them using `result.error()` over the bridge.
* No mutations without corresponding Write-Ahead Log (WAL) records.

#### Required Patterns
* Prefix index functions with a complexity summary: `// Complexity: O(...) using [index structure]`.
* Mapped array results must be filtered through `andNot(deletionSet)` to exclude tombstoned entries before returning.
* Index iterations tracking more than 100 files must check the state of `ThermalGovernor.currentState()`.
* Map missing/empty FIDs as `-1` (FID `0` is a reserved sentinel).

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
