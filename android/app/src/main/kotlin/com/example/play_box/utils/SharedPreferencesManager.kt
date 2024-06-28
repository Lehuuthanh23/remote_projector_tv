package com.example.play_box.utils

import android.content.Context
import android.content.SharedPreferences

class SharedPreferencesManager(context: Context) {
    private var pref: SharedPreferences
    private var editor: SharedPreferences.Editor

    init {
        val sharedPreferences = context.getSharedPreferences(Constants.LOCAL_SHARED_PREF, Context.MODE_PRIVATE)
        this.pref = sharedPreferences
        this.editor = sharedPreferences.edit()
    }

    private fun saveStringByKey(key: String, value: String?): Boolean {
        return try {
            editor.run {
                putString(key, value)
                apply()
            }
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun retrieveStringByKey(key: String) =
        pref.getString(key, null)

    private fun saveLongByKey(key: String, value: Long): Boolean {
        return try {
            editor.run {
                putLong(key, value)
                apply()
            }
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    fun retrieveLongByKey(key: String) =
        pref.getLong(key, 0)

    private fun saveBooleanByKey(key: String, value: Boolean): Boolean {
        return try {
            editor.run {
                putBoolean(key, value)
                apply()
            }
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    fun retrieveBooleanByKey(key: String) =
        pref.getBoolean(key, false)

    fun retrieveBooleanByKey(key: String, defaultValue: Boolean) =
        pref.getBoolean(key, defaultValue)

    fun clearData() {
        try {
            editor.run {
                clear()
                apply()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun saveSerialComputer(deviceId: String?) {
        saveStringByKey(Constants.SERIAL_COMPUTER, deviceId)
    }

    fun getSerialComputer(): String? = retrieveStringByKey(Constants.SERIAL_COMPUTER)

    fun saveIdComputer(deviceId: String?) {
        saveStringByKey(Constants.COMPUTER_ID, deviceId)
    }

    fun getIdComputer(): String? = retrieveStringByKey(Constants.COMPUTER_ID)

    fun saveUserIdConnected(userId: String?) {
        saveStringByKey(Constants.USER_ID_CONNECTED, userId)
    }

    fun getUserIdConnected(): String? = retrieveStringByKey(Constants.USER_ID_CONNECTED)
}