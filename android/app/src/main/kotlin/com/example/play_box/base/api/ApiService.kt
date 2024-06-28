package com.example.play_box.base.api

import com.example.play_box.utils.AppApi.BASE_URL
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.FormBody
import okhttp3.OkHttpClient
import okhttp3.Request

class ApiService {
    private val client = OkHttpClient()

    private suspend fun apiCall(
        request: Request
    ): Map<String, Any>? {
        return withContext(Dispatchers.IO) {
            try {
                val response = client.newCall(request).execute()

                when {
                    response.isSuccessful -> response.body?.string().toMap()

                    else -> null
                }
            } catch (e: Exception) {
                null
            }
        }
    }

    // GET
    suspend fun get(
        url: String,
        headers: Map<String, String>? = null
    ): Map<String, Any>? {
        val requestBuilder = Request.Builder().url("${BASE_URL}${url}")
        headers?.forEach { (key, value) ->
            requestBuilder.addHeader(key, value)
        }
        val request = requestBuilder.build()
        return apiCall(request)
    }

    // POST
    suspend fun post(
        url: String,
        headers: Map<String, String>? = null,
        body: FormBody
    ): Map<String, Any>? {
        val requestBuilder = Request.Builder().url("${BASE_URL}${url}").post(body)
        headers?.forEach { (key, value) ->
            requestBuilder.addHeader(key, value)
        }
        val request = requestBuilder.build()
        return apiCall(request)
    }

    // PUT
    suspend fun put(
        url: String,
        headers: Map<String, String>? = null,
        body: FormBody
    ): Map<String, Any>? {
        val requestBuilder = Request.Builder().url("${BASE_URL}${url}").put(body)
        headers?.forEach { (key, value) ->
            requestBuilder.addHeader(key, value)
        }
        val request = requestBuilder.build()
        return apiCall(request)
    }

    // DELETE
    suspend fun delete(
        url: String,
        headers: Map<String, String>? = null
    ): Map<String, Any>? {
        val requestBuilder = Request.Builder().url("${BASE_URL}${url}").delete()
        headers?.forEach { (key, value) ->
            requestBuilder.addHeader(key, value)
        }
        val request = requestBuilder.build()
        return apiCall(request)
    }

    private fun String?.toMap(): Map<String, Any> {
        if (this == null) return mapOf()

        val gson = Gson()
        val type = object : TypeToken<Map<String, Any>>() {}.type
        return gson.fromJson(this, type)
    }
}
