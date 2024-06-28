package com.example.play_box.receive

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.example.play_box.service.MyBackgroundService

class MyBroadcastReceiver : BroadcastReceiver() {
    companion object {
        const val TAG = "MyBroadcastReceiver"
    }

    override fun onReceive(context: Context?, intent: Intent) {
        Log.d(TAG, "onReceive: ${intent.action}")
        if (intent.action.equals(Intent.ACTION_BOOT_COMPLETED) || intent.action.equals("com.htc.intent.action.QUICKBOOT_POWERON")) {
            val serviceIntent = Intent(context, MyBackgroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context?.startForegroundService(serviceIntent)
            } else {
                context?.startService(serviceIntent)
            }
        }
    }
}