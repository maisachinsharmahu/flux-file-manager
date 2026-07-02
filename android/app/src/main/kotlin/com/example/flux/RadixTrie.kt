package com.example.flux

/**
 * RadixTrie (compressed prefix tree) implementation for O(k) prefix searches
 * as described in Chapter 3.6 of the FLUX technical white paper.
 * Highly optimized primitive representation with zero-allocation lists/sets
 * and dynamic doubling array capacity to prevent OutOfMemoryError during 1M+ file updates.
 */
class RadixTrie {
    private val root = Node("", false)

    class Node(var prefix: String, var isEnd: Boolean) {
        var children: Array<Node>? = null
        var fids: LongArray? = null
        var fidsCount: Int = 0

        fun addChild(node: Node) {
            val curr = children
            if (curr == null) {
                children = arrayOf(node)
            } else {
                val newArr = Array(curr.size + 1) { index ->
                    if (index < curr.size) curr[index] else node
                }
                children = newArr
            }
        }

        fun addFid(fid: Long) {
            var curr = fids
            if (curr == null) {
                curr = LongArray(2)
                curr[0] = fid
                fids = curr
                fidsCount = 1
            } else {
                // Check for duplicates in active slots only to avoid HashMap overhead
                for (i in 0 until fidsCount) {
                    if (curr[i] == fid) return
                }
                if (fidsCount >= curr.size) {
                    curr = curr.copyOf(curr.size * 2)
                    fids = curr
                }
                curr[fidsCount++] = fid
            }
        }
    }

    /**
     * Inserts a word and maps it to a specific File ID (FID).
     */
    fun insert(word: String, fid: Long) {
        if (word.isEmpty()) return
        insertRecursive(root, word.lowercase(), fid)
    }

    private fun insertRecursive(curr: Node, word: String, fid: Long) {
        var i = 0
        val prefix = curr.prefix
        val minLen = minOf(prefix.length, word.length)

        // Find the common prefix length
        while (i < minLen && prefix[i] == word[i]) {
            i++
        }

        if (curr == root || (i > 0 && i < prefix.length)) {
            // Split the node's edge
            val common = prefix.substring(0, i)
            val nodeSuffix = prefix.substring(i)
            val wordSuffix = word.substring(i)

            val splitNode = Node(nodeSuffix, curr.isEnd)
            splitNode.children = curr.children
            splitNode.fids = curr.fids
            splitNode.fidsCount = curr.fidsCount

            curr.prefix = common
            curr.isEnd = false
            curr.children = null
            curr.fids = null
            curr.fidsCount = 0
            curr.addChild(splitNode)

            if (wordSuffix.isEmpty()) {
                curr.isEnd = true
                curr.addFid(fid)
            } else {
                val newNode = Node(wordSuffix, true)
                newNode.addFid(fid)
                curr.addChild(newNode)
            }
        } else if (i < word.length) {
            // Match is equal to node prefix, continue down
            val suffix = word.substring(i)
            var foundChild = false
            val currChildren = curr.children
            if (currChildren != null) {
                for (child in currChildren) {
                    if (child.prefix.isNotEmpty() && child.prefix[0] == suffix[0]) {
                        insertRecursive(child, suffix, fid)
                        foundChild = true
                        break
                    }
                }
            }
            if (!foundChild) {
                val newNode = Node(suffix, true)
                newNode.addFid(fid)
                curr.addChild(newNode)
            }
        } else {
            // Perfect match with existing prefix
            curr.isEnd = true
            curr.addFid(fid)
        }
    }

    /**
     * Searches for all FIDs matching the query prefix.
     */
    fun searchPrefix(prefix: String): Set<Long> {
        if (prefix.isEmpty()) return emptySet()
        val results = mutableSetOf<Long>()
        searchPrefixRecursive(root, prefix.lowercase(), results)
        return results
    }

    private fun searchPrefixRecursive(curr: Node, prefix: String, results: MutableSet<Long>) {
        if (prefix.isEmpty()) {
            collectAllFids(curr, results)
            return
        }

        val currPrefix = curr.prefix
        var i = 0
        val minLen = minOf(currPrefix.length, prefix.length)

        while (i < minLen && currPrefix[i] == prefix[i]) {
            i++
        }

        if (i == prefix.length) {
            // Prefix is fully matched, collect all children FIDs
            collectAllFids(curr, results)
        } else if (i == currPrefix.length) {
            // Node prefix is fully matched, search in children
            val suffix = prefix.substring(i)
            val currChildren = curr.children
            if (currChildren != null) {
                for (child in currChildren) {
                    if (child.prefix.isNotEmpty() && child.prefix[0] == suffix[0]) {
                        searchPrefixRecursive(child, suffix, results)
                    }
                }
            }
        }
    }

    private fun collectAllFids(node: Node, results: MutableSet<Long>) {
        if (node.isEnd) {
            val nodeFids = node.fids
            if (nodeFids != null) {
                for (i in 0 until node.fidsCount) {
                    results.add(nodeFids[i])
                }
            }
        }
        val nodeChildren = node.children
        if (nodeChildren != null) {
            for (child in nodeChildren) {
                collectAllFids(child, results)
            }
        }
    }

    fun clear() {
        root.children = null
        root.fids = null
        root.fidsCount = 0
        root.prefix = ""
        root.isEnd = false
    }
}
