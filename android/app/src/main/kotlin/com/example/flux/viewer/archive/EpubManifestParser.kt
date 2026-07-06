package com.example.flux.viewer.archive

import org.xmlpull.v1.XmlPullParser
import org.xmlpull.v1.XmlPullParserFactory
import java.io.File
import java.util.zip.ZipFile

/**
 * EpubManifestParser — extracts spine reading order chapters from EPUB container packages.
 */
object EpubManifestParser {

    fun getEpubChapters(filePath: String): String {
        val file = File(filePath)
        if (!file.exists()) return "[]"

        var zip: ZipFile? = null
        try {
            zip = ZipFile(file)
            
            // 1. Parse container.xml to locate root OPF path
            val containerEntry = zip.getEntry("META-INF/container.xml") ?: return "[]"
            var opfPath = ""
            
            zip.getInputStream(containerEntry).use { input ->
                val factory = XmlPullParserFactory.newInstance()
                val parser = factory.newPullParser()
                parser.setInput(input, "UTF-8")
                var event = parser.eventType
                while (event != XmlPullParser.END_DOCUMENT) {
                    if (event == XmlPullParser.START_TAG && parser.name == "rootfile") {
                        opfPath = parser.getAttributeValue(null, "full-path") ?: ""
                        break
                    }
                    event = parser.next()
                }
            }

            if (opfPath.isEmpty()) return "[]"

            // 2. Parse OPF file
            val opfEntry = zip.getEntry(opfPath) ?: return "[]"
            val baseDir = if (opfPath.contains("/")) opfPath.substringBeforeLast('/') else ""

            val manifest = HashMap<String, String>() // id -> href
            val spine = ArrayList<String>() // idref list
            val navPoints = ArrayList<EpubChapter>()

            zip.getInputStream(opfEntry).use { input ->
                val factory = XmlPullParserFactory.newInstance()
                val parser = factory.newPullParser()
                parser.setInput(input, "UTF-8")
                var event = parser.eventType
                while (event != XmlPullParser.END_DOCUMENT) {
                    if (event == XmlPullParser.START_TAG) {
                        when (parser.name) {
                            "item" -> {
                                val id = parser.getAttributeValue(null, "id") ?: ""
                                val href = parser.getAttributeValue(null, "href") ?: ""
                                if (id.isNotEmpty() && href.isNotEmpty()) {
                                    manifest[id] = href
                                }
                            }
                            "itemref" -> {
                                val idref = parser.getAttributeValue(null, "idref") ?: ""
                                if (idref.isNotEmpty()) {
                                    spine.add(idref)
                                }
                            }
                        }
                    }
                    event = parser.next()
                }
            }

            // 3. Resolve spine order and build chapters list
            val chaptersJson = ArrayList<String>()
            for (idref in spine) {
                val href = manifest[idref] ?: continue
                // Prepend baseDir path prefix to resolve entries in zip correctly
                val zipHref = if (baseDir.isNotEmpty()) "$baseDir/$href" else href
                val title = href.substringBeforeLast('.').replace('_', ' ').replace('-', ' ')
                    .capitalize()

                chaptersJson.add("""{"title":"${escapeJson(title)}","href":"${escapeJson(zipHref)}"}""")
            }

            return "[${chaptersJson.joinToString(",")}]"
        } catch (e: Exception) {
            return "[]"
        } finally {
            zip?.close()
        }
    }

    data class EpubChapter(val title: String, val href: String)

    private fun escapeJson(str: String): String {
        return str.replace("\\", "\\\\")
            .replace("\"", "\\\"")
            .replace("\n", "\\n")
            .replace("\r", "\\r")
            .replace("\t", "\\t")
    }
}
