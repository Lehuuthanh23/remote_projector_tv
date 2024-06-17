package com.example.play_box.receive

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.example.play_box.service.MyBackgroundService

class MyBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent) {
        if (intent.action.equals(Intent.ACTION_BOOT_COMPLETED) || intent.action.equals("com.htc.intent.action.QUICKBOOT_POWERON")) {
            val serviceIntent = Intent(context, MyBackgroundService::class.java)
            context?.startService(serviceIntent)
        }
    }
}