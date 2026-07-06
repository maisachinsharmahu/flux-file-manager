package com.example.flux.viewer.data

import android.database.sqlite.SQLiteDatabase
import java.io.File

/**
 * SqliteParser — lightweight read-only SQLite database browser.
 *
 * Direct database querying via Android's built-in SQLiteDatabase library.
 * Zero-dependency, prevents loading massive database instances into memory.
 */
object SqliteParser {

    fun getSqliteTables(filePath: String): String {
        val file = File(filePath)
        if (!file.exists()) return "[]"

        var db: SQLiteDatabase? = null
        val tablesList = ArrayList<String>()

        try {
            db = SQLiteDatabase.openDatabase(filePath, null, SQLiteDatabase.OPEN_READONLY)
            val cursor = db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'", null)
            
            val nameIndex = cursor.getColumnIndex("name")
            if (cursor.moveToFirst()) {
                do {
                    val name = if (nameIndex >= 0) cursor.getString(nameIndex) else ""
                    if (name.isNotEmpty()) {
                        tablesList.add("\"${escapeJson(name)}\"")
                    }
                } while (cursor.moveToNext())
            }
            cursor.close()
        } catch (e: Exception) {
            return "[]"
        } finally {
            db?.close()
        }

        return "[${tablesList.joinToString(",")}]"
    }

    fun getSqliteTableSchema(filePath: String, tableName: String): String {
        var db: SQLiteDatabase? = null
        val columnsList = ArrayList<String>()

        try {
            db = SQLiteDatabase.openDatabase(filePath, null, SQLiteDatabase.OPEN_READONLY)
            val cursor = db.rawQuery("PRAGMA table_info(\"$tableName\")", null)
            
            val nameIndex = cursor.getColumnIndex("name")
            if (cursor.moveToFirst()) {
                do {
                    val colName = if (nameIndex >= 0) cursor.getString(nameIndex) else ""
                    if (colName.isNotEmpty()) {
                        columnsList.add("\"${escapeJson(colName)}\"")
                    }
                } while (cursor.moveToNext())
            }
            cursor.close()
        } catch (e: Exception) {
            return "[]"
        } finally {
            db?.close()
        }

        return "[${columnsList.joinToString(",")}]"
    }

    fun getSqliteTableRows(filePath: String, tableName: String, offset: Int, limit: Int): String {
        var db: SQLiteDatabase? = null
        val rowsList = ArrayList<String>()

        try {
            db = SQLiteDatabase.openDatabase(filePath, null, SQLiteDatabase.OPEN_READONLY)
            val cursor = db.rawQuery("SELECT * FROM \"$tableName\" LIMIT $limit OFFSET $offset", null)
            
            val columnCount = cursor.columnCount
            if (cursor.moveToFirst()) {
                do {
                    val rowCells = ArrayList<String>()
                    for (i in 0 until columnCount) {
                        if (cursor.isNull(i)) {
                            rowCells.add("null")
                        } else {
                            try {
                                val strVal = cursor.getString(i) ?: ""
                                rowCells.add("\"${escapeJson(strVal)}\"")
                            } catch (e: Exception) {
                                // Fallback for blob or other data types
                                rowCells.add("\"[BLOB/BINARY]\"")
                            }
                        }
                    }
                    rowsList.add("[${rowCells.joinToString(",")}]")
                } while (cursor.moveToNext())
            }
            cursor.close()
        } catch (e: Exception) {
            return "[]"
        } finally {
            db?.close()
        }

        return "[${rowsList.joinToString(",")}]"
    }

    private fun escapeJson(str: String): String {
        return str.replace("\\", "\\\\")
            .replace("\"", "\\\"")
            .replace("\n", "\\n")
            .replace("\r", "\\r")
            .replace("\t", "\\t")
    }
}
