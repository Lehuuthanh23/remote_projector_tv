package com.example.play_box.service

import android.app.ActivityManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.play_box.MainActivity
import com.example.play_box.R

class MyBackgroundService : Service() {
    companion object {
        val TAG = "MyBackgroundService"
    }

    private var handler: Handler = Handler(Looper.getMainLooper())

    private val checkInterval = 20 * 1000L
    private val checkRunnable = object : Runnable {
        override fun run() {
            if (!isAppRunning(applicationContext)) {
                openFlutterActivity(applicationContext)
            }

            handler.postDelayed(this, checkInterval)
        }
    }

    private fun isAppRunning(context: Context): Boolean {
        val activityClass = MainActivity::class.java
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val taskInfoList = activityManager.getRunningTasks(Int.MAX_VALUE)

        Log.d(TAG, "Received broadcast: ${taskInfoList.size} - ${taskInfoList.firstOrNull()?.topActivity} - ${activityClass.name}")

        return taskInfoList.firstOrNull()?.topActivity.toString().contains(activityClass.name)
    }

    private fun openFlutterActivity(context: Context) {
        Log.d(TAG, "Received broadcast: openActivity")

        val i = Intent(this, MainActivity::class.java)
        i.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY)
        startActivity(i)
    }

    override fun onCreate() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "my_service_channel"
            val channelName = "My Service Channel"
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val channel = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_DEFAULT)
            notificationManager.createNotificationChannel(channel)
        }
        super.onCreate()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        handler.postDelayed(checkRunnable, checkInterval)
        val notification = createNotification()
        startForeground(1001, notification)
        return START_STICKY
    }

    private fun createNotification(): Notification {
        val channelId = "my_service_channel"
        val channelName = "My Service Channel"
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_DEFAULT)
            notificationManager.createNotificationChannel(channel)
        }

        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(this, 0, notificationIntent, PendingIntent.FLAG_IMMUTABLE)

        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("Projector")
            .setContentText("Service is running")
            .setSmallIcon(R.drawable.ic_projector)
            .setContentIntent(pendingIntent)
            .build()
    }

    override fun onDestroy() {
        handler.removeCallbacks(checkRunnable)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}
