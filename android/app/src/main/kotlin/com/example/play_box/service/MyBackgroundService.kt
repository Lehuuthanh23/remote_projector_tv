package com.example.play_box.service

import android.annotation.SuppressLint
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
import com.example.play_box.model.command.CommandEnum
import com.example.play_box.model.command.CommandModel
import com.example.play_box.utils.AppApi
import com.example.play_box.utils.JSON
import com.example.play_box.utils.SharedPreferencesManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import okhttp3.FormBody
import io.flutter.plugin.common.MethodChannel
import com.example.play_box.utils.getCurrentTime

class MyBackgroundService : Service() {
    companion object {
        private const val CHECK_ALIVE_INTERVAL = 60 * 1000L
        private const val CHECK_COMMAND_INTERVAL = 5 * 1000L

        var isAppRunning = true
        var isFirebase = false

        var channel: MethodChannel? = null
        lateinit var wakeUpChannel: MethodChannel
    }

    private var handler: Handler = Handler(Looper.getMainLooper())

    private val apiService = ApiService()
    private val serviceJob = Job()
    private val serviceScope = CoroutineScope(Dispatchers.IO + serviceJob)

    private lateinit var sharedPreferences: SharedPreferencesManager

    private val checkAliveRunnable = object : Runnable {
        override fun run() {
            checkAlive()
            handler.postDelayed(this, CHECK_ALIVE_INTERVAL)
        }
    }

    private val checkCommandRunnable = object : Runnable {
        override fun run() {
            if (!isFirebase || !isAppRunning || !isAppRunning()) {
                isAppRunning = false
                checkCommandList()
            }

            handler.postDelayed(this, CHECK_COMMAND_INTERVAL)
        }
    }

    private val openAppRunnable = Runnable {
        if (!isAppRunning()) {
            openFlutterActivity()
        }
    }

    @SuppressLint("Wakelock")
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

                replayCommand(value = timeString, commandId = command.cmdId)
            }

            CommandEnum.RESTART_APP.command -> {
                replayCommand(value = "OK", commandId = command.cmdId)

                openFlutterActivity()
            }

            CommandEnum.VIDEO_STOP.command -> invokeCommandToFlutter(
                CommandEnum.VIDEO_STOP,
                command.cmdId
            )

            CommandEnum.VIDEO_PAUSE.command -> invokeCommandToFlutter(
                CommandEnum.VIDEO_PAUSE,
                command.cmdId
            )

            CommandEnum.VIDEO_RESTART.command -> invokeCommandToFlutter(
                CommandEnum.VIDEO_RESTART,
                command.cmdId
            )

            CommandEnum.VIDEO_FROMUSB.command -> invokeCommandToFlutter(
                CommandEnum.VIDEO_FROMUSB,
                command.cmdId
            )

            CommandEnum.VIDEO_FROMCAMP.command -> invokeCommandToFlutter(
                CommandEnum.VIDEO_FROMCAMP,
                command.cmdId
            )

            CommandEnum.DELETE_DEVICE.command -> {
                sharedPreferences.saveIdComputer(null)
                sharedPreferences.saveSerialComputer(null)
                replayCommand(value = "OK", commandId = command.cmdId)
                stopSelf()

                Handler(Looper.getMainLooper()).post {
                    channel?.invokeMethod(
                        CommandEnum.DELETE_DEVICE.command,
                        mapOf("command" to CommandEnum.DELETE_DEVICE.command)
                    )
                }
            }

            else -> {}
        }
    }

    private fun invokeCommandToFlutter(commandEnum: CommandEnum, commandId: String?) {
        if (!isAppRunning()) {
            replayCommand(value = "APP_NOT_SHOW", commandId = commandId)

            return
        }
        Handler(Looper.getMainLooper()).post {
            channel?.invokeMethod(
                commandEnum.command,
                mapOf("command" to commandEnum.command),
                object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        val returnValue: String? = result?.toString()

                        if (returnValue != null) {
                            replayCommand(value = returnValue, commandId = commandId)
                        }
                    }

                    override fun error(
                        errorCode: String,
                        errorMessage: String?,
                        errorDetails: Any?
                    ) {
                    }

                    override fun notImplemented() {}
                })
        }
    }

    private fun replayCommand(value: String, commandId: String?) {
        serviceScope.launch {
            val formBody = FormBody.Builder()
                .add("return_value", value)
                .build()

            apiService.post(
                url = "${AppApi.REPLY_COMMAND}/$commandId",
                body = formBody,
            )
        }
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
            val channelId = "ts_screen_channel"
            val channelName = "TS Screen Channel"
            val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val channel =
                NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_DEFAULT)
            notificationManager.createNotificationChannel(channel)
        }

        isFirebase = sharedPreferences.getFirebaseCheck()

        super.onCreate()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        handler.removeCallbacks(checkAliveRunnable)
        handler.removeCallbacks(openAppRunnable)
        handler.removeCallbacks(checkCommandRunnable)

        handler.post(checkAliveRunnable)
        handler.postDelayed(checkCommandRunnable, CHECK_COMMAND_INTERVAL)
        handler.postDelayed(openAppRunnable, 2 * CHECK_COMMAND_INTERVAL)

        val notification = createNotification()
        startForeground(1001, notification)

        return START_STICKY
    }

    private fun createNotification(): Notification {
        val channelId = "ts_screen_channel"
        val channelName = "TS Screen Channel"
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
            .setContentTitle("TS Screen")
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