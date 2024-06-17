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
import com.example.play_box.api.ApiService
import com.example.play_box.api.Constants
import com.example.play_box.model.camp.CampModel
import com.example.play_box.model.camp.TimeRunModel
import com.example.play_box.model.user.UserModel
import com.example.play_box.utils.JSON
import com.example.play_box.utils.SharedPreferencesManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import okhttp3.FormBody

class MyBackgroundService : Service() {
    companion object {
        val TAG = "MyBackgroundService"
    }

    private val apiService = ApiService()
    private val serviceJob = Job()
    private val serviceScope = CoroutineScope(Dispatchers.IO + serviceJob)
    private var handler: Handler = Handler(Looper.getMainLooper())

    private val checkInterval = 20 * 1000L
    private val checkRunnable = object : Runnable {
        override fun run() {
            checkingCampTime()

            handler.postDelayed(this, checkInterval)
        }
    }

    private fun checkingCampTime() {
        serviceScope.launch {
            val sharedPreferences = SharedPreferencesManager(applicationContext)
            val userProfile = sharedPreferences.getUserProfile()
            Log.d(TAG, "checkingUser: $userProfile")
            if (userProfile == null) {
                stopSelf()
            } else {
                val formBody = FormBody.Builder()
                    .add("email", userProfile.phoneNumber!!)
                    .add("password", userProfile.password!!)
                    .build()

                val response = apiService.post(
                    url = Constants.USER_LOGIN,
                    body = formBody
                )

                if (response != null) {
                    val user: UserModel? =
                        JSON.decodeToList(response["info"], Array<UserModel>::class.java).firstOrNull()
                    checkTimeRun(user)
                }
            }
        }
    }

    private suspend fun checkTimeRun(userModel: UserModel?) {
        if (userModel != null) {
            try {
                val listCamp = getAllCampByCustomerId(userModel.customerId!!)

                if (listCamp != null) {
                    for (item in listCamp) {
                        item.listTimeRun = getAllTimeRunByCampId(item.campaignId)
                    }

                    // check Time
                    if (!isAppRunning(applicationContext)) {
                        openFlutterActivity(applicationContext)
                    } else {
                        Handler(Looper.getMainLooper()).postDelayed({
                            callFlutterMethod(applicationContext)
                        }, 1000)
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private suspend fun getAllCampByCustomerId(customerId: String): List<CampModel>? {
        val response = apiService.get(
            url = "${Constants.GET_CAMP_BY_ID_CUSTOMER}/$customerId",
        )

        if (response != null) {
            Log.d(TAG, "getAllCampByCustomerId: ${response["camp_list"]}")
            return JSON.decodeToList(response["camp_list"], Array<CampModel>::class.java).toList()
        } else {
            return null
        }
    }

    private suspend fun getAllTimeRunByCampId(campaignId: String): List<TimeRunModel>? {
        val response = apiService.get(
            url = "${Constants.GET_TIME_RUN_BY_CAMP_ID}/$campaignId",
        )

        if (response != null) {
            Log.d(TAG, "getAllTimeRunByCampId: ${response["camp_list_time"]}")
            return JSON.decodeToList(response["camp_list_time"], Array<TimeRunModel>::class.java).toList()
        } else {
            return null
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

        Handler(Looper.getMainLooper()).postDelayed({
            callFlutterMethod(context)
        }, 5000)
    }

    private fun callFlutterMethod(context: Context) {
        Log.d(TAG, "Received broadcast: callMethod")
        val flutterEngine = FlutterEngine(context)
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        FlutterEngineCache.getInstance().put("my_engine_id", flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.app/channel")
            .invokeMethod("performAction", null)
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
