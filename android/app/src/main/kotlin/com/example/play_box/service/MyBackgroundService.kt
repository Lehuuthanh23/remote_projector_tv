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
import com.example.play_box.base.api.ApiService
import com.example.play_box.model.command.CommandEnum
import com.example.play_box.model.command.CommandModel
import com.example.play_box.utils.AppApi
import com.example.play_box.utils.JSON
import com.example.play_box.utils.SharedPreferencesManager
import com.example.play_box.utils.getCurrentTime
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import okhttp3.FormBody
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.dart.DartExecutor

class MyBackgroundService : Service() {
    companion object {
        const val TAG = "MyBackgroundService"
        private const val CHECK_COMMAND_INTERVAL = 5 * 1000L
        private const val CHECK_ALIVE_INTERVAL = 60 * 1000L
    }

    private lateinit var channel: MethodChannel
    private val COMMAND_CHANNEL = "com.example.myapp/command"

    private var handler: Handler = Handler(Looper.getMainLooper())

    private val apiService = ApiService()
    private val serviceJob = Job()
    private val serviceScope = CoroutineScope(Dispatchers.IO + serviceJob)

    private lateinit var sharedPreferences: SharedPreferencesManager

    private var first = true

    private val checkCommandRunnable = object : Runnable {
        override fun run() {
            if (first) {
                first = false
                if (!isAppRunning(applicationContext)) {
                    openFlutterActivity()
                }
            }
            checkCommandList()
            handler.postDelayed(this, CHECK_COMMAND_INTERVAL)
        }
    }

    private val checkAliveRunnable = object : Runnable {
        override fun run() {
            checkAlive()
            handler.postDelayed(this, CHECK_ALIVE_INTERVAL)
        }
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

    private fun checkCommandList() {
        if (!sharedPreferences.getUserIdConnected().isNullOrBlank()) {
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
                                Log.d(TAG, "checkCommandList: ${item.cmdId} - ${item.cmdCode}")
                                invokeCommand(item)
                            }
                        }
                    }
                }
            }
        } else stopSelf()
    }

    private fun invokeCommand(command: CommandModel) {
        when (command.cmdCode) {
            CommandEnum.GET_TIME_NOW.command -> {
                val timeString = getCurrentTime()

                serviceScope.launch {
                    val formBody = FormBody.Builder()
                        .add("return_value", timeString)
                        .build()

                    apiService.post(
                        url = "${AppApi.REPLY_COMMAND}/${command.cmdId}",
                        body = formBody,
                    )
                }
            }

            CommandEnum.RESTART_APP.command -> {
                serviceScope.launch {
                    val formBody = FormBody.Builder()
                        .add("return_value", "OK")
                        .build()

                    apiService.post(
                        url = "${AppApi.REPLY_COMMAND}/${command.cmdId}",
                        body = formBody,
                    )
                    openFlutterActivity()
                }
            }

             CommandEnum.VIDEO_STOP.command -> {
                Handler(Looper.getMainLooper()).post {
                channel.invokeMethod("stopVideo", mapOf("yourParameter" to "Hello from Kotlin"))
                }
                serviceScope.launch {
                    val formBody = FormBody.Builder()
                        .add("return_value", "OK")
                        .build()

                    apiService.post(
                        url = "${AppApi.REPLY_COMMAND}/${command.cmdId}",
                        body = formBody,
                    )
                }
            }

            else -> {}
        }
    }

    private fun isAppRunning(context: Context): Boolean {
        val activityClass = MainActivity::class.java
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val taskInfoList = activityManager.getRunningTasks(Int.MAX_VALUE)

        return taskInfoList.firstOrNull()?.topActivity.toString().contains(activityClass.name)
    }

    private fun openFlutterActivity() {
        val i = Intent(this, MainActivity::class.java)
        i.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
        startActivity(i)
    }

    override fun onCreate() {
        val flutterEngine = FlutterEngine(this)
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, COMMAND_CHANNEL)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "my_service_channel"
            val channelName = "My Service Channel"
            val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val channel =
                NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_DEFAULT)
            notificationManager.createNotificationChannel(channel)
        }
        sharedPreferences = SharedPreferencesManager(applicationContext)
        super.onCreate()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        handler.removeCallbacks(checkCommandRunnable)
        handler.removeCallbacks(checkAliveRunnable)
        handler.postDelayed(checkCommandRunnable, CHECK_COMMAND_INTERVAL)
        handler.postDelayed(checkAliveRunnable, CHECK_ALIVE_INTERVAL)

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
        handler.removeCallbacks(checkCommandRunnable)
        handler.removeCallbacks(checkAliveRunnable)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}
