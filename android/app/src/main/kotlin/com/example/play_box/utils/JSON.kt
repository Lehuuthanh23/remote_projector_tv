package com.example.play_box.utils

import com.google.gson.Gson
import com.google.gson.GsonBuilder
import com.google.gson.JsonElement
import com.google.gson.JsonParser
import org.json.JSONObject

object JSON {
    private val parseGson = GsonBuilder().disableHtmlEscaping().create()

    @Throws(Exception::class)
    fun encode(obj: Any?): String {
        return try {
            parseGson.toJson(obj)
        } catch (e: Exception) {
            throw Exception(e.message)
        }
    }

    fun <T> decode(json: String, tClass: Class<T>?): T? {
        return try {
            parseGson.fromJson(json, tClass)
        } catch (e: Exception) {
            null
        }
    }

    fun <T> decodeToList(jsonElement: Any?, clazz: Class<Array<T>>): List<T> {
        return try {
            val ele: String? = if (jsonElement is String?) jsonElement else Gson().toJson(jsonElement)
            val array: Array<T> = parseGson.fromJson(ele, clazz)
            array.toList()
        } catch (e: Exception) {
            ArrayList()
        }
    }

    fun <T> decodeListToList(
        jsonElement: String?,
        clazz: Class<Array<Array<T>>>
    ): Array<Array<T>>? {
        return try {
            val array: Array<Array<T>> = parseGson.fromJson(jsonElement, clazz)
            array
        } catch (e: Exception) {
            null
        }
    }

    fun <T> decodeListToList(
        jsonElement: String?,
        clazz: Class<Array<Array<Array<T>>>>
    ): Array<Array<Array<T>>>? {
        return try {
            val array: Array<Array<Array<T>>> = parseGson.fromJson(jsonElement, clazz)
            array
        } catch (e: Exception) {
            null
        }
    }

    fun toJsonElement(data: String?): JsonElement? {
        val parser = JsonParser()
        return parser.parse(data)
    }

    fun evertStringToJSON(json: String?): JSONObject? {
        return try {
            json?.let { JSONObject(it) }
        } catch (e: Exception) {
            null
        }
    }
}
