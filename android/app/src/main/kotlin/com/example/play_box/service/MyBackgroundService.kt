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
import androidx.core.app.NotificationCompat
import com.example.play_box.MainActivity
import com.example.play_box.R
import com.example.play_box.base.api.ApiService
import com.example.play_box.model.command.CommandModel
import com.example.play_box.utils.AppApi
import com.example.play_box.utils.JSON
import com.example.play_box.utils.SharedPreferencesManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch

class MyBackgroundService : Service() {
    companion object {
        private const val CHECK_ALIVE_INTERVAL = 60 * 1000L

        var runCheckCommand = false
    }

    private var handler: Handler = Handler(Looper.getMainLooper())

    private val apiService = ApiService()
    private val serviceJob = Job()
    private val serviceScope = CoroutineScope(Dispatchers.IO + serviceJob)

    private lateinit var sharedPreferences: SharedPreferencesManager

    private val checkAliveRunnable = object : Runnable {
        override fun run() {
            checkAlive()
            if (runCheckCommand) checkCommandList()
            handler.postDelayed(this, CHECK_ALIVE_INTERVAL)
        }
    }

    private val openAppRunnable = Runnable {
        if (!isAppRunning()) {
            openFlutterActivity()
        }
    }

    private fun checkCommandList() {
        val customerId = sharedPreferences.getUserIdConnected()
        val idComputer = sharedPreferences.getIdComputer()
        if (!customerId.isNullOrBlank() &&
            !idComputer.isNullOrBlank()
        ) {
            serviceScope.launch {
                val serialComputer: String? = sharedPreferences.getSerialComputer()
                if (serialComputer != null) {
                    val response = apiService.get(
                        url = "${AppApi.GET_NEW_COMMANDS}/$serialComputer",
                    )

                    if (response != null) {
                        val commandList: List<CommandModel> =
                            JSON.decodeToList(response["cmd_list"], Array<CommandModel>::class.java)
                        if (commandList.isNotEmpty()) {
                            for (item in commandList) {

                            }
                        }
                    }
                }
            }
        } else stopSelf()
    }


    @Suppress("DEPRECATION")
    private fun isAppRunning(): Boolean {
        val activityClass = MainActivity::class.java
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val taskInfoList = activityManager.getRunningTasks(Int.MAX_VALUE)

        return taskInfoList.firstOrNull()?.topActivity.toString().contains(activityClass.name)
    }

    private fun openFlutterActivity() {
        val i = Intent(this, MainActivity::class.java)
        i.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
        startActivity(i)
    }

    private fun checkAlive() {
        if (!sharedPreferences.getUserIdConnected().isNullOrBlank()) {
            serviceScope.launch {
                val computerId = sharedPreferences.getIdComputer()
                if (computerId != null) {
                    apiService.get(
                        url = "${AppApi.UPDATE_ALIVE_TIME_DEVICE}/$computerId",
                    )
                }
            }
        } else stopSelf()
    }

    override fun onCreate() {
        sharedPreferences = SharedPreferencesManager(applicationContext)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "my_service_channel"
            val channelName = "My Service Channel"
            val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val channel =
                NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_DEFAULT)
            notificationManager.createNotificationChannel(channel)
        }

        super.onCreate()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        handler.removeCallbacks(checkAliveRunnable)
        handler.post(checkAliveRunnable)
        handler.postDelayed(openAppRunnable, 10000)

        val notification = createNotification()
        startForeground(1001, notification)

        return START_STICKY
    }

    private fun createNotification(): Notification {
        val channelId = "my_service_channel"
        val channelName = "My Service Channel"
        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel =
                NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_DEFAULT)
            notificationManager.createNotificationChannel(channel)
        }

        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent =
            PendingIntent.getActivity(this, 0, notificationIntent, PendingIntent.FLAG_IMMUTABLE)

        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("Projector")
            .setContentText("Service is running")
            .setSmallIcon(R.drawable.ic_projector)
            .setContentIntent(pendingIntent)
            .build()
    }

    override fun onDestroy() {
        handler.removeCallbacks(checkAliveRunnable)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}
