package com.itisnajim.device_policy_controller

import android.app.admin.DeviceAdminReceiver
import android.app.admin.DevicePolicyManager
import android.content.Context
import android.content.Intent
import android.preference.PreferenceManager
import android.util.Log
import android.view.KeyEvent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import android.content.BroadcastReceiver
import android.content.IntentFilter
import android.os.Handler
import android.os.Looper
import android.app.ActivityManager






class AppDeviceAdminReceiver : DeviceAdminReceiver() {
    companion object {
        fun log(message: String) = Log.d("dpcx::", message)

        private const val KEY_IS_FROM_BOOT_COMPLETED = "is_from_boot_completed"

        fun setIsFromBootCompleted(context: Context, value: Boolean) {
            val sharedPreferences = PreferenceManager.getDefaultSharedPreferences(context)
            sharedPreferences.edit().putBoolean(KEY_IS_FROM_BOOT_COMPLETED, value).apply()
        }

        fun isFromBootCompleted(context: Context): Boolean {
            val sharedPreferences = PreferenceManager.getDefaultSharedPreferences(context)
            return sharedPreferences.getBoolean(KEY_IS_FROM_BOOT_COMPLETED, false)
        }
    }

    override fun onProfileProvisioningComplete(context: Context, intent: Intent) {
        log("onProfileProvisioningComplete")
        val i: Intent? =
            context.packageManager.getLaunchIntentForPackage(context.packageName)
        if (i != null) {
            i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            context.startActivity(i)
        } else {
            log("Couldn't start activity")
        }
    }

    private fun isLauncherReady(context: Context): Boolean {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val tasks = activityManager.getRunningTasks(1)
        if (tasks.isNotEmpty()) {
            val topActivity = tasks[0].topActivity
            log("topActivity?.packageName: ")
            log(topActivity?.packageName ?: "Unknown Package")
            log("------")
            return topActivity?.packageName == "com.android.launcher"
        }
        return false
    }
    private fun isSystemFullyReady(context: Context): Boolean {
        val launcherReady = isLauncherReady(context)
        val bootCompleted = isBootCompleted()
        log("Launcher Ready: $launcherReady, Boot Completed: $bootCompleted")
        return launcherReady && bootCompleted
    }

    private fun isBootCompleted(): Boolean {
        try {
            val clazz = Class.forName("android.os.SystemProperties")
            val method = clazz.getMethod("get", String::class.java)
            val bootCompleted = method.invoke(null, "sys.boot_completed") as String
            return bootCompleted == "1"
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return false
    }

    private fun waitForSystemReady(context: Context, retries: Int = 10, delayMillis: Long = 2000) {
        if (isSystemFullyReady(context)) {
            log("System is fully ready, starting the app")
            startApp(context, "com.example.test_device_owner")
        } else if (retries > 0) {
            log("System not ready, retrying in $delayMillis ms")
            Handler(Looper.getMainLooper()).postDelayed({
                waitForSystemReady(context, retries - 1, delayMillis)
            }, delayMillis)
        } else {
            log("System still not ready after retries, starting app anyway")
            startApp(context, "com.example.test_device_owner")
        }
    }

private fun logAllRunningTasks(context: Context) {
    val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
    val tasks = activityManager.getRunningTasks(10) // Lấy tối đa 10 task
    if (tasks.isNotEmpty()) {
        log("Running tasks:")
        for (task in tasks) {
            val taskInfo = """
                Task ID: ${task.id}
                Top Activity: ${task.topActivity?.className}
                Base Activity: ${task.baseActivity?.className}
                Num Activities: ${task.numActivities}
            """.trimIndent()
            log(taskInfo)
        }
    } else {
        log("No running tasks found.")
    }
}
private fun waitForLauncherReady(context: Context, callback: () -> Unit) {
    val handler = Handler(Looper.getMainLooper())

    handler.post(object : Runnable {
        override fun run() {
            val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val tasks = activityManager.getRunningTasks(1)
            if (tasks.isNotEmpty() && tasks[0].topActivity?.packageName == "com.android.launcher") {
                log("Launcher is ready!")
                callback()
            } else {
                log("Launcher not ready, retrying...")
                val taskss = activityManager.getRunningTasks(10) // Lấy tối đa 10 task
                if (taskss.isNotEmpty()) {
                    log("Running tasks:")
                    for (task in taskss) {
                        val taskInfo = """
                            Task ID: ${task.id}
                            Top Activity: ${task.topActivity?.className}
                            Base Activity: ${task.baseActivity?.className}
                            Num Activities: ${task.numActivities}
                        """.trimIndent()
                        log(taskInfo)
                    }
                }
                handler.postDelayed(this, 2000) // Thử lại sau 2 giây
            }
        }
    })
}

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action
        val extras = intent.extras
        log("onReceive: action: $action, extras: $extras")
        if (DevicePolicyManager.ACTION_MANAGED_PROFILE_PROVISIONED == action || Intent.ACTION_MANAGED_PROFILE_ADDED == action) {
            PreferenceManager.getDefaultSharedPreferences(context)
                .edit().putBoolean("is_provisioned", true).apply()
            log("Vào if (DevicePolicyManager.ACTION_MANAGED_PROFILE_PROVISIONED ==")
        }
        if (action == Intent.ACTION_BOOT_COMPLETED) { // Intent.ACTION_BOOT_COMPLETED
            setIsFromBootCompleted(context, true)
            val flutterEngine = FlutterEngine(context.applicationContext)
            flutterEngine.plugins.get(DevicePolicyControllerPlugin::class.java) as DevicePolicyControllerPlugin?
            flutterEngine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
            val channel =
                DevicePolicyControllerPlugin.methodChannel(flutterEngine.dartExecutor.binaryMessenger)
            log("Vào trả handleBootCompleted")
            // if (isLauncherReady(context)) {
            //     log("System is ready, starting the app")
            //     startApp(context, "com.example.test_device_owner")
            // } else {
            //     log("System is not ready, delaying app start")
            //     Handler(Looper.getMainLooper()).postDelayed({
            //         startApp(context, "com.example.test_device_owner")
            //     }, 20000)
            // }
            // waitForSystemReady(context)
            // logAllRunningTasks(context)
            waitForLauncherReady(context) {
                log("Launcher ready, starting app")
                startApp(context, "com.example.test_device_owner")
            }
            channel.invokeMethod("handleBootCompleted", null)
        }
    }

   private fun startApp(context: Context, packageName: String?) {
        log("Vào startApp")
        val intent =
            context.packageManager.getLaunchIntentForPackage(packageName ?: context.packageName)
        if (intent != null) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            log("App started successfully")
        } else {
            log("Package not found")
        }
    }

}