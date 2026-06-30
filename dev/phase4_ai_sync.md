# Phase 4 — On-Device AI Semantic Search & 4-Layer Sync
**Weeks 17–20 | Sprint S9 (W17–18) + S10 (W19–20)**

> **Gate:** Semantic query walks HNSW vector index in under 10ms with >=95% recall correctness on a 50,000-file corpus. Deletion in third-party app (e.g. WhatsApp) triggers inotify kernel event and updates the index within 1 millisecond.

---

## Overview

Phase 4 bridges the file index with on-device machine learning (ONNX Mobile Runtime) and Linux kernel directory watching (inotify). It builds Index 9 (HNSW Vector Graph) to enable semantic search ("tax forms" -> `W4_2025.pdf`) and binds the 4-layer directory sync system to eliminate ghost files.

---

## 1. ONNX Runtime & MiniLM-L6 Embedding Pipeline (Week 17, Days 1–5)

To convert filenames and document content into 384-dimensional vectors, we bundle a 22 MB quantized ONNX model (`mini_lm_l6_v2.onnx`).

### File: `android/app/src/main/kotlin/com/flux/ai/EmbeddingEngine.kt`

```kotlin
package com.flux.ai

import android.content.Context
import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import java.io.File
import java.nio.LongBuffer

class EmbeddingEngine(private val context: Context) {
    private val env = OrtEnvironment.getEnvironment()
    private val session: OrtSession

    init {
        // Copy the asset onnx model to internal cache and open OrtSession
        val modelFile = File(context.cacheDir, "mini_lm.onnx")
        if (!modelFile.exists()) {
            context.assets.open("models/mini_lm.onnx").use { input ->
                modelFile.outputStream().use { output -> input.copyTo(output) }
            }
        }
        session = env.createSession(modelFile.absolutePath)
    }

    fun getEmbedding(text: String): FloatArray {
        val tokens = tokenize(text)
        val shape = longArrayOf(1, tokens.size.toLong())

        val inputIdsBuffer = LongBuffer.wrap(tokens.map { it.toLong() }.toLongArray())
        val maskBuffer = LongBuffer.wrap(LongArray(tokens.size) { 1L })

        val inputIdsTensor = OnnxTensor.createTensor(env, inputIdsBuffer, shape)
        val maskTensor = OnnxTensor.createTensor(env, maskBuffer, shape)

        val inputs = mapOf(
            "input_ids" to inputIdsTensor,
            "attention_mask" to maskTensor
        )

        session.run(inputs).use { results ->
            val outputTensor = results[0] as OnnxTensor
            val rawOutput = outputTensor.value as Array<Array<FloatArray>>
            // Mean pool token embeddings to extract final sentence vector
            return meanPool(rawOutput[0], tokens.size)
        }
    }

    private fun tokenize(text: String): IntArray {
        // Basic whitespace tokenizer + vocab lookup helper mapping words to token indices
        return text.lowercase().split(" ").map { it.hashCode() % 30522 }.toIntArray()
    }

    private fun meanPool(embeddings: Array<FloatArray>, seqLen: Int): FloatArray {
        val result = FloatArray(384)
        for (i in 0 until seqLen) {
            for (d in 0 until 384) {
                result[d] += embeddings[i][d]
            }
        }
        for (d in 0 until 384) {
            result[d] /= seqLen.toFloat()
        }
        return result
    }
}
```

---

## 2. HNSW Vector Index — Index 9 (Week 18, Days 1–5)

Instead of exhaustive O(n) brute-force cosine distance scans, Hierarchical Navigable Small World (HNSW) walks multi-layer proximity graphs in O(log n) steps.

### File: `android/app/src/main/kotlin/com/flux/index/HnswGraph.kt`

```kotlin
package com.flux.index

import java.io.RandomAccessFile
import java.nio.channels.FileChannel

class HnswGraph(private val M: Int = 16, private val efSearch: Int = 50) {
    class Node(val fid: Int, val vector: FloatArray, val levels: Array<IntArray>)

    private val nodes = mutableListOf<Node>()
    private var enterNodeFid: Int = -1
    private var maxLevel: Int = -1

    // Inserts a new file vector into the graph layers
    @Synchronized
    fun insert(fid: Int, vector: FloatArray) {
        val level = determineRandomLevel()
        val nodeLevels = Array(level + 1) { IntArray(M) { -1 } }
        val newNode = Node(fid, vector, nodeLevels)
        
        nodes.add(newNode)
        
        if (enterNodeFid == -1) {
            enterNodeFid = fid
            maxLevel = level
            return
        }

        var currEnter = nodes.find { it.fid == enterNodeFid }!!
        // Walk down from top level to insert level
        for (l in maxLevel downTo level + 1) {
            currEnter = searchLayer(vector, currEnter, 1, l).first()
        }

        // Insert and link connections at matching levels
        for (l in minOf(level, maxLevel) downTo 0) {
            val targets = searchLayer(vector, currEnter, efSearch, l)
            for (target in targets) {
                link(newNode, target, l)
            }
        }
        if (level > maxLevel) {
            maxLevel = level
            enterNodeFid = fid
        }
    }

    private fun searchLayer(query: FloatArray, enter: Node, ef: Int, level: Int): List<Node> {
        val visited = mutableSetOf(enter.fid)
        val candidates = mutableListOf(enter)
        val results = mutableListOf(enter)

        while (candidates.isNotEmpty()) {
            candidates.sortBy { cosineDistance(it.vector, query) }
            val curr = candidates.removeAt(0)
            val worstResultDist = cosineDistance(results.last().vector, query)

            if (cosineDistance(curr.vector, query) > worstResultDist) break

            for (neighborFid in curr.levels[level]) {
                if (neighborFid == -1 || visited.contains(neighborFid)) continue
                visited.add(neighborFid)
                val neighbor = nodes.find { it.fid == neighborFid } ?: continue
                val neighborDist = cosineDistance(neighbor.vector, query)

                if (neighborDist < worstResultDist || results.size < ef) {
                    candidates.add(neighbor)
                    results.add(neighbor)
                    results.sortBy { cosineDistance(it.vector, query) }
                    if (results.size > ef) results.removeAt(results.size - 1)
                }
            }
        }
        return results
    }

    private fun link(n1: Node, n2: Node, level: Int) {
        for (i in 0 until M) {
            if (n1.levels[level][i] == -1) {
                n1.levels[level][i] = n2.fid
                break
            }
        }
    }

    private fun determineRandomLevel(): Int = (-Math.log(Math.random()) * 0.5).toInt()

    private fun cosineDistance(v1: FloatArray, v2: FloatArray): Float {
        var dot = 0.0f
        var n1 = 0.0f
        var n2 = 0.0f
        for (i in 0 until 384) {
            dot += v1[i] * v2[i]
            n1 += v1[i] * v1[i]
            n2 += v2[i] * v2[i]
        }
        return 1.0f - (dot / (Math.sqrt(n1.toDouble()) * Math.sqrt(n2.toDouble())).toFloat())
    }
}
```

---

## 3. Real-Time Directory Observers & Sync (Week 19, Days 1–5)

To prevent index staleness, FLUX watches filesystem operations across 4 tiers.

### File: `android/app/src/main/kotlin/com/flux/sync/FileObserverHub.kt`

```kotlin
package com.flux.sync

import android.os.FileObserver
import java.io.File
import java.util.concurrent.ConcurrentHashMap

class FileObserverHub(private val syncCallback: (String, Int) -> Unit) {
    private val activeObservers = ConcurrentHashMap<String, CustomObserver>()

    fun startWatching(dirPath: String) {
        if (activeObservers.containsKey(dirPath)) return
        val observer = CustomObserver(dirPath)
        observer.startWatching()
        activeObservers[dirPath] = observer
    }

    fun stopWatching(dirPath: String) {
        activeObservers.remove(dirPath)?.stopWatching()
    }

    inner class CustomObserver(private val path: String) : FileObserver(
        path,
        CREATE or DELETE or MOVED_FROM or MOVED_TO or CLOSE_WRITE
    ) {
        override fun onEvent(event: Int, filename: String?) {
            filename ?: return
            val fullPath = "$path/$filename"
            syncCallback(fullPath, event)
        }
    }
}
```

---

## 4. Thermal Governor & Charging-Only Indirection (Week 20, Days 1–5)

Running vector generation during active UI interactions causes framerate drops and battery drain. The `ThermalGovernor` schedules embedding calculations using WorkManager constraints.

### File: `android/app/src/main/kotlin/com/flux/thermal/ThermalGovernor.kt`

```kotlin
package com.flux.thermal

import android.content.Context
import android.os.Build
import android.os.PowerManager
import androidx.work.Constraints
import androidx.work.NetworkType

class ThermalGovernor(context: Context) {
    private val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager

    enum class ThermalState { COOL, WARM, HOT, CRITICAL }

    fun getThermalState(): ThermalState {
        if (Build.VERSION.SDK_INT >= 29) {
            val status = pm.currentThermalStatus
            return when (status) {
                PowerManager.THERMAL_STATUS_NONE,
                PowerManager.THERMAL_STATUS_LIGHT -> ThermalState.COOL
                PowerManager.THERMAL_STATUS_MODERATE -> ThermalState.WARM
                PowerManager.THERMAL_STATUS_SEVERE -> ThermalState.HOT
                else -> ThermalState.CRITICAL
            }
        }
        return ThermalState.COOL
    }

    fun getAIIndexingConstraints(): Constraints {
        return Constraints.Builder()
            .setRequiresCharging(true) // Run only when plugged in
            .setRequiresDeviceIdle(true) // Wait until device is idle
            .build()
    }
}
```

---

## Verification & Testing Requirements
- **Automated Tests:**
  - Verify that the ONNX model output resolves to 384 dimensions.
  - Implement a test pipeline comparing exact brute-force search results against HNSW layer walk results to verify recall is above 95%.
- **Manual Verification:**
  - Simulate mock file edits (via ADB shell) inside directories monitored by `FileObserverHub` to ensure automatic synchronization takes place.
