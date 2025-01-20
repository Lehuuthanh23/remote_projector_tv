package com.example.play_box.receive

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.widget.Toast
import io.flutter.plugin.common.MethodChannel

class WakeUpReceiver : BroadcastReceiver() {

    // Tạo một MethodChannel để gửi kết quả về Flutter
    private lateinit var wakeUpChannel: MethodChannel

    override fun onReceive(context: Context, intent: Intent) {
        // Đánh thức màn hình
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(
            PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
            PowerManager.FULL_WAKE_LOCK or
            PowerManager.ACQUIRE_CAUSES_WAKEUP or
            PowerManager.ON_AFTER_RELEASE,
            "MyApp::WakeUpReceiverWakeLock"
        )

        wakeLock.acquire(3000) // Giữ WakeLock trong 3 giây
        wakeLock.release()

        // Gửi thông báo về Flutter qua MethodChannel
        wakeUpChannel.invokeMethod("onDeviceWokenUp", "Device has been woken up!")

        // Hiển thị Toast cho người dùng (tuỳ chọn)
        Toast.makeText(context, "Device has been woken up", Toast.LENGTH_SHORT).show()
    }

    // Phương thức để nhận MethodChannel từ Flutter (gọi trong MainActivity)
    fun setMethodChannel(channel: MethodChannel) {
        wakeUpChannel = channel
    }
}
