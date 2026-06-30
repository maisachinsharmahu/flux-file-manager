# Phase 2 — Core Indexing & Search Engine
**Weeks 5–10 | Sprint S3 (W5–6) + S4 (W7–8) + S5 (W9–10)**

> **Gate:** Search 1,000,000 synthetic files in under 2 ms. Batch delete 1,000 files in under 3 seconds. Content search inside PDF/DOCX/TXT first 10,000 characters is fully working.

---

## Overview

Phase 2 builds the core indexing structures (Indexes 2 through 8) and the search query router. It also implements the `deletionSet` (Deletion BitSet) for $O(1)$ logical deletions. This phase transition is purely native Kotlin optimization to hit the target sub-millisecond search latencies.

---

## 1. NameTrie — Index 2: $O(k)$ Filename Prefix Search (Week 5, Days 1–3)

### File: `android/app/src/main/kotlin/com/flux/index/NameTrie.kt`

The NameTrie is a Radix Trie (compressed prefix tree) storing filename prefixes.
It splits filenames on camelCase boundaries, underscores, hyphens, dots, and number transitions (e.g. `Q3_Budget_2025_FINAL_v2.xlsx` $\rightarrow$ `[q3, budget, 2025, final, v2, xlsx]`).

```kotlin
class NameTrie {
    class Node {
        var key: String = ""
        val children = mutableListOf<Node>()
        val fids = RoaringBitmap()
    }

    private val root = Node()

    // Complexity: O(k) where k is token length
    @Synchronized
    fun insert(token: String, fid: Int) {
        val cleanToken = token.lowercase()
        var curr = root
        var i = 0
        while (i < cleanToken.length) {
            val child = findChildWithPrefix(curr, cleanToken.substring(i))
            if (child == null) {
                // Insert new suffix node
                val newNode = Node().apply {
                    key = cleanToken.substring(i)
                    fids.add(fid)
                }
                curr.children.add(newNode)
                return
            }
            // Determine common prefix length
            val commonLen = commonPrefixLength(child.key, cleanToken.substring(i))
            if (commonLen < child.key.length) {
                // Split child node
                val splitNode = Node().apply {
                    key = child.key.substring(commonLen)
                    fids.or(child.fids)
                    children.addAll(child.children)
                }
                child.key = child.key.substring(0, commonLen)
                child.children.clear()
                child.children.add(splitNode)
            }
            child.fids.add(fid)
            curr = child
            i += commonLen
        }
    }

    // Complexity: O(k) where k is prefix length
    fun searchPrefix(prefix: String): RoaringBitmap {
        val cleanPrefix = prefix.lowercase()
        var curr = root
        var i = 0
        while (i < cleanPrefix.length) {
            val child = findChildWithPrefix(curr, cleanPrefix.substring(i)) ?: return RoaringBitmap()
            val remaining = cleanPrefix.substring(i)
            if (remaining.startsWith(child.key)) {
                curr = child
                i += child.key.length
            } else if (child.key.startsWith(remaining)) {
                return child.fids
            } else {
                return RoaringBitmap()
            }
        }
        return curr.fids
    }

    private fun findChildWithPrefix(node: Node, str: String): Node? {
        return node.children.find { it.key.isNotEmpty() && (it.key[0] == str[0] || str[0] == it.key[0]) }
    }

    private fun commonPrefixLength(s1: String, s2: String): Int {
        var len = 0
        while (len < s1.length && len < s2.length && s1[len] == s2[len]) {
            len++
        }
        return len
    }
}
```

---

## 2. TokenIndex — Index 3: Inverted Keyword Search (Week 5, Days 4–5)

### File: `android/app/src/main/kotlin/com/flux/index/TokenIndex.kt`

TokenIndex maps individual tokens to sets of FIDs using `RoaringBitmap`.
This supports multi-word search via bitmap intersection.

```kotlin
class TokenIndex {
    // String (token) -> RoaringBitmap of FIDs
    private val tokenMap = HashMap<String, RoaringBitmap>(500_000)

    @Synchronized
    fun insert(token: String, fid: Int) {
        val clean = token.lowercase()
        val bitmap = tokenMap.getOrPut(clean) { RoaringBitmap() }
        bitmap.add(fid)
    }

    @Synchronized
    fun remove(token: String, fid: Int) {
        val clean = token.lowercase()
        tokenMap[clean]?.remove(fid)
    }

    // Complexity: O(1) retrieval + O(N/64) intersection
    fun searchAll(vararg tokens: String, deletionSet: RoaringBitmap): RoaringBitmap {
        if (tokens.isEmpty()) return RoaringBitmap()
        var result = tokenMap[tokens[0].lowercase()]?.clone() ?: return RoaringBitmap()
        
        for (i in 1 until tokens.size) {
            val bitmap = tokenMap[tokens[i].lowercase()] ?: return RoaringBitmap()
            result = RoaringBitmap.and(result, bitmap)
            if (result.isEmpty) break
        }
        
        return RoaringBitmap.andNot(result, deletionSet)
    }

    fun optimize() {
        tokenMap.values.forEach { it.runOptimize() }
    }
}
```

---

## 3. TypeBuckets — Index 5: $O(1)$ MIME Filtering (Week 6, Days 1–2)

### File: `android/app/src/main/kotlin/com/flux/index/TypeBuckets.kt`

TypeBuckets maps high-level MIME types (e.g. `image/*`, `video/*`) and extensions to bitmap FIDs.

```kotlin
class TypeBuckets {
    private val buckets = HashMap<String, RoaringBitmap>()

    @Synchronized
    fun insert(mimeType: String, fid: Int) {
        val clean = mimeType.lowercase()
        buckets.getOrPut(clean) { RoaringBitmap() }.add(fid)
        
        // Also map to wildcard category (e.g., image/*)
        if (clean.contains("/")) {
            val wild = clean.substringBefore("/") + "/*"
            buckets.getOrPut(wild) { RoaringBitmap() }.add(fid)
        }
    }

    // Complexity: O(1) — bitmap fetch
    fun getFids(category: String, deletionSet: RoaringBitmap): RoaringBitmap {
        val bitmap = buckets[category.lowercase()] ?: return RoaringBitmap()
        return RoaringBitmap.andNot(bitmap, deletionSet)
    }
}
```

---

## 4. SizeIndex & TimeIndex — Indexes 6 & 7: Van Emde Boas Trees (Week 6, Days 3–5)

### File: `android/app/src/main/kotlin/com/flux/index/VebTree.kt`

For file sizes (up to 1 TB universe $U = 2^{40}$) and dates (mtime in seconds), standard B-trees execute range queries in $O(\log n)$.
FLUX uses a Van Emde Boas Tree to achieve range lookup in $O(\log \log U)$ time, independent of total files.

```kotlin
/**
 * Van Emde Boas (vEB) Tree for O(log log U) range and successor queries.
 * Universe size U must be a power of 2.
 */
class VebTree(val universeSize: Long) {
    private var min: Long = -1
    private var max: Long = -1
    
    private val sqrtUniverse = Math.sqrt(universeSize.toDouble()).toLong()
    private val summary: VebTree? = if (universeSize > 2) VebTree(sqrtUniverse) else null
    private val cluster: Array<VebTree?>? = if (universeSize > 2) arrayOfNulls(sqrtUniverse.toInt()) else null

    fun getMin(): Long = min
    fun getMax(): Long = max

    // Complexity: O(log log U)
    fun insert(x: Long) {
        if (min == -1L) {
            emptyInsert(x)
            return
        }
        var xVal = x
        if (xVal < min) {
            val temp = min
            min = xVal
            xVal = temp
        }
        if (universeSize > 2) {
            val h = high(xVal)
            val l = low(xVal)
            
            if (cluster!![h.toInt()] == null) {
                cluster!![h.toInt()] = VebTree(sqrtUniverse)
            }
            if (cluster!![h.toInt()]!!.getMin() == -1L) {
                summary!!.insert(h)
                cluster!![h.toInt()]!!.emptyInsert(l)
            } else {
                cluster!![h.toInt()]!!.insert(l)
            }
        }
        if (xVal > max) {
            max = xVal
        }
    }

    // Complexity: O(log log U)
    fun successor(x: Long): Long {
        if (universeSize == 2L) {
            return if (x == 0L && max == 1L) 1L else -1L
        }
        if (min != -1L && x < min) {
            return min
        }
        val h = high(x)
        val l = low(x)
        
        val maxLow = cluster?.get(h.toInt())?.getMax() ?: -1L
        if (maxLow != -1L && l < maxLow) {
            val offset = cluster!![h.toInt()]!!.successor(l)
            return index(h, offset)
        }
        val succCluster = summary?.successor(h) ?: -1L
        if (succCluster == -1L) {
            return -1L
        }
        val offset = cluster!![succCluster.toInt()]!!.getMin()
        return index(succCluster, offset)
    }

    private fun emptyInsert(x: Long) {
        min = x
        max = x
    }

    private fun high(x: Long): Long = x / sqrtUniverse
    private fun low(x: Long): Long = x % sqrtUniverse
    private fun index(x: Long, y: Long): Long = x * sqrtUniverse + y
}
```

---

## 5. ChecksumMap — Index 8: $O(1)$ Duplicate Detection (Week 7, Days 1–3)

### File: `android/app/src/main/kotlin/com/flux/index/ChecksumMap.kt`

Duplicate detection uses xxHash64 over content bytes. Large files are hashed progressively in chunks.

```kotlin
class ChecksumMap {
    // xxHash64(content) -> RoaringBitmap of FIDs
    private val checksumMap = HashMap<Long, RoaringBitmap>()

    @Synchronized
    fun insert(checksum: Long, fid: Int) {
        if (checksum == 0L) return
        checksumMap.getOrPut(checksum) { RoaringBitmap() }.add(fid)
    }

    @Synchronized
    fun remove(checksum: Long, fid: Int) {
        checksumMap[checksum]?.remove(fid)
        if (checksumMap[checksum]?.isEmpty == true) {
            checksumMap.remove(checksum)
        }
    }

    // Complexity: O(1) lookup
    fun findDuplicates(checksum: Long, deletionSet: RoaringBitmap): RoaringBitmap {
        val fids = checksumMap[checksum] ?: return RoaringBitmap()
        val result = RoaringBitmap.andNot(fids, deletionSet)
        return if (result.cardinality > 1) result else RoaringBitmap()
    }
}
```

---

## 6. DeletionBitSet — $O(1)$ Logical Deletions (Week 7, Days 4–5)

To prevent UI freezes when deleting large numbers of files, FLUX uses a **logical tombstone** pattern.

```kotlin
class DeletionBitSet(private val wal: WalManager) {
    val deletionSet = RoaringBitmap()

    // Complexity: O(1) per file
    @Synchronized
    fun logicalDelete(fid: Int) {
        deletionSet.add(fid)
        wal.append(WalOpCode.DELETE, fid)
    }

    // Physical deletion runs asynchronously during idle cycles (Layer 4)
    fun backgroundCompaction(flux: FluxIndex) {
        deletionSet.forEach { fid ->
            flux.physicallyRemoveFromAllIndexes(fid)
        }
        deletionSet.clear()
        wal.checkpoint()
    }
}
```

---

## 7. Content Tokenizer — PDF, DOCX, TXT Extractor (Week 8)

Reads the first 10,000 characters from text documents, tokenizes them, and adds them to `TokenIndex` under the `content:` namespace.

```kotlin
class ContentExtractor {
    fun extractAndIndex(file: File, fid: Int, tokenIndex: TokenIndex) {
        if (file.length() == 0L) return
        val text = when (file.extension.lowercase()) {
            "txt"  -> readTxt(file)
            "pdf"  -> readPdf(file)
            "docx" -> readDocx(file)
            else   -> return
        }

        // Split on non-alphanumeric, camelCase, transitions
        val tokens = tokenize(text)
        tokens.forEach { token ->
            tokenIndex.insert("content:$token", fid)
        }
    }

    private fun readTxt(file: File): String {
        return file.bufferedReader().use { it.readText() }.take(10_000)
    }

    // PDFBox-Android / Apache POI wrappers live here
    private fun readPdf(file: File): String = "" // Stub for P2, wired in P4
    private fun readDocx(file: File): String = "" // Stub for P2, wired in P4

    fun tokenize(text: String): List<String> {
        return text.split(Regex("[^a-zA-Z0-9]+"))
            .filter { it.length > 2 }
            .map { it.lowercase() }
    }
}
```

---

## 8. FLUX Search Query Router (Week 9)

Route query string through NameTrie, TokenIndex, and fall back to semantic vector lookup (Phase 4).

```
          [User Query]
               │
               ▼
     [NameTrie Prefix Match]  ──────► Found? (cardinality > 0) ──► Return Trie FIDs
               │
               ▼ No
     [TokenIndex Inverted Search]  ──► Found? (cardinality > 0) ──► Return Intersected FIDs
               │
               ▼ No
     [Semantic AI HNSW Search]  ────► Return top-K approximate nearest neighbors
```

```kotlin
fun query(queryString: String, limit: Int, deletionSet: RoaringBitmap): RoaringBitmap {
    val clean = queryString.trim().lowercase()
    if (clean.isEmpty()) return RoaringBitmap()

    // 1. Prefix Match (Radix Trie) — < 0.5 ms
    val prefixResult = nameTrie.searchPrefix(clean)
    val prefixFiltered = RoaringBitmap.andNot(prefixResult, deletionSet)
    if (!prefixFiltered.isEmpty) {
        return prefixFiltered.limit(limit)
    }

    // 2. Keyword Match (Token Index AND) — < 2 ms
    val tokens = clean.split(" ").toTypedArray()
    val tokenResult = tokenIndex.searchAll(*tokens, deletionSet = deletionSet)
    if (!tokenResult.isEmpty) {
        return tokenResult.limit(limit)
    }

    // 3. Fallback to Semantic AI (Phase 4 HNSW Graph)
    return hnswGraph.search(clean, limit, deletionSet)
}

private fun RoaringBitmap.limit(limit: Int): RoaringBitmap {
    if (this.cardinality <= limit) return this
    val res = RoaringBitmap()
    val it = this.iterator
    var count = 0
    while (it.hasNext() && count < limit) {
        res.add(it.next())
        count++
    }
    return res
}
```

---

## Sprint S3 Acceptance Criteria (Weeks 5–6)

- [ ] `NameTrie` prefix search matches correctly on camelCase and symbols
- [ ] Inverted index `TokenIndex` intersections complete in under 2 ms on 100k files
- [ ] Range filtering by size on `VebTree` executes in $O(\log \log U)$ time

## Sprint S4 Acceptance Criteria (Weeks 7–8)

- [ ] Deleting 1,000 files completes in under 3 ms via `DeletionBitSet`
- [ ] Text files (.txt) are read, tokenized, and indexed under `content:` namespace
- [ ] ChecksumMap groups duplicate files correctly

## Sprint S5 Acceptance Criteria (Weeks 9–10)

- [ ] Query router routes cleanly through Trie $\rightarrow$ Token Index $\rightarrow$ Semantic stub
- [ ] Search query benchmarks execute in under 2 ms on 1,000,000 synthetic dataset
- [ ] Memory footprint does not leak after 10,000 mock search cycles

## Gate 2 Definition
> Verify that typing `budget` matches `2025_Budget.xlsx` and `budget_plan.pdf` instantly (<2 ms). Batch delete 500 files and verify that they disappear from the list view instantly with zero UI frame drops.

---

## Phase 2 File Checklist

| File | Contents |
|------|----------|
| `android/.../index/NameTrie.kt` | Radix Trie filename matching |
| `android/.../index/TokenIndex.kt` | Inverted posting lists using RoaringBitmap |
| `android/.../index/TypeBuckets.kt` | Wildcard MIME category bitmaps |
| `android/.../index/VebTree.kt` | Van Emde Boas Trees for size/time range queries |
| `android/.../index/ChecksumMap.kt` | Duplicate detection key maps |
| `android/.../index/ContentExtractor.kt` | Text document tokenizer |
| `android/.../index/SearchRouter.kt` | Trie $\rightarrow$ Token Index $\rightarrow$ Semantic stub routing |
