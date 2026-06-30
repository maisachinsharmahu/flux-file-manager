package com.example.flux

/**
 * RadixTrie (compressed prefix tree) implementation for O(k) prefix searches
 * as described in Chapter 3.6 of the FLUX technical white paper.
 */
class RadixTrie {
    private val root = Node("", false)

    class Node(var prefix: String, var isEnd: Boolean) {
        val children = mutableListOf<Node>()
        val fids = mutableSetOf<Long>()
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
            splitNode.children.addAll(curr.children)
            splitNode.fids.addAll(curr.fids)

            curr.prefix = common
            curr.isEnd = false
            curr.children.clear()
            curr.fids.clear()
            curr.children.add(splitNode)

            if (wordSuffix.isEmpty()) {
                curr.isEnd = true
                curr.fids.add(fid)
            } else {
                val newNode = Node(wordSuffix, true)
                newNode.fids.add(fid)
                curr.children.add(newNode)
            }
        } else if (i < word.length) {
            // Match is equal to node prefix, continue down
            val suffix = word.substring(i)
            var foundChild = false
            for (child in curr.children) {
                if (child.prefix.isNotEmpty() && child.prefix[0] == suffix[0]) {
                    insertRecursive(child, suffix, fid)
                    foundChild = true
                    break
                }
            }
            if (!foundChild) {
                val newNode = Node(suffix, true)
                newNode.fids.add(fid)
                curr.children.add(newNode)
            }
        } else {
            // Perfect match with existing prefix
            curr.isEnd = true
            curr.fids.add(fid)
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
            for (child in curr.children) {
                if (child.prefix.isNotEmpty() && child.prefix[0] == suffix[0]) {
                    searchPrefixRecursive(child, suffix, results)
                }
            }
        }
    }

    private fun collectAllFids(node: Node, results: MutableSet<Long>) {
        if (node.isEnd) {
            results.addAll(node.fids)
        }
        for (child in node.children) {
            collectAllFids(child, results)
        }
    }
}
