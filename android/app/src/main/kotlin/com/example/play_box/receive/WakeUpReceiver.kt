package com.example.play_box.receive

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.widget.Toast

class WakeUpReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // Đánh thức màn hình
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(
            PowerManager.FULL_WAKE_LOCK or
            PowerManager.ACQUIRE_CAUSES_WAKEUP or
            PowerManager.ON_AFTER_RELEASE,
            "MyApp::WakeUpReceiverWakeLock"
        )
        wakeLock.acquire(3000) // Giữ WakeLock trong 3 giây

        // Hiển thị thông báo (tuỳ chọn)
        Toast.makeText(context, "Thiết bị đã được đánh thức.", Toast.LENGTH_SHORT).show()

        wakeLock.release()
    }
}
