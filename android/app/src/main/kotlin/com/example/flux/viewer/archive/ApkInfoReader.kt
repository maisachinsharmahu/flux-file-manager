package com.example.flux.viewer.archive

import android.content.Context
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import java.io.File

/**
 * ApkInfoReader — parses package archive metadata (activities, permissions, and app names).
 */
object ApkInfoReader {

    fun getApkMetadata(context: Context, filePath: String): String {
        val file = File(filePath)
        if (!file.exists()) return "{}"

        try {
            val pm = context.packageManager
            val flags = PackageManager.GET_ACTIVITIES or PackageManager.GET_PERMISSIONS
            val info = pm.getPackageArchiveInfo(filePath, flags) ?: return "{}"

            // Try to load application label
            info.applicationInfo?.let { appInfo ->
                appInfo.sourceDir = filePath
                appInfo.publicSourceDir = filePath
            }
            val appLabel = info.applicationInfo?.loadLabel(pm)?.toString() ?: file.nameWithoutExtension
            val packageName = info.packageName ?: ""
            val versionName = info.versionName ?: "1.0"
            val versionCode = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                info.longVersionCode
            } else {
                info.versionCode.toLong()
            }

            // Extract activities
            val activities = info.activities?.map { it.name } ?: emptyList()
            val permissions = info.requestedPermissions?.toList() ?: emptyList()

            val actJson = activities.joinToString(",") { "\"${escapeJson(it)}\"" }
            val permJson = permissions.joinToString(",") { "\"${escapeJson(it)}\"" }

            return """{
                "appName": "${escapeJson(appLabel)}",
                "packageName": "${escapeJson(packageName)}",
                "versionName": "${escapeJson(versionName)}",
                "versionCode": $versionCode,
                "activities": [$actJson],
                "permissions": [$permJson]
            }""".trimIndent()
        } catch (e: Exception) {
            return """{"error":"${escapeJson(e.message ?: "Failed parsing APK")}"}"""
        }
    }

    private fun escapeJson(str: String): String {
        return str.replace("\\", "\\\\")
            .replace("\"", "\\\"")
            .replace("\n", "\\n")
            .replace("\r", "\\r")
            .replace("\t", "\\t")
    }
}
