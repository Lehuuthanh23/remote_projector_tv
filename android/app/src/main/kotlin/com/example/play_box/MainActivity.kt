package com.example.play_box

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.app.ActivityManager
import android.app.AlertDialog
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.util.Log
import android.content.pm.PackageManager
import android.hardware.usb.UsbManager
import android.os.Environment
import android.os.storage.StorageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.widget.Toast
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import com.example.play_box.service.MyBackgroundService
import com.example.play_box.utils.AppApi
import com.example.play_box.utils.Constants
import com.example.play_box.utils.RestartPlugin
import com.example.play_box.utils.SharedPreferencesManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import io.flutter.plugins.GeneratedPluginRegistrant.registerWith
import com.example.play_box.plugin.InstallPlugin
import android.app.AlarmManager
import android.app.PendingIntent
import androidx.annotation.NonNull
import com.example.play_box.receive.WakeUpReceiver

class MainActivity : FlutterActivity() {
    private lateinit var sharedPreferencesManager: SharedPreferencesManager
    private var eventSink: EventChannel.EventSink? = null

    companion object {
        private const val TAG = "MainActivity"
        private const val SERIAL_CHANNEL = "com.example.usb/serial"
        private const val USB_EVENT_CHANNEL = "com.example.usb/event"
        private const val WAKE_UP_CHANNEL = "com.example.play_box.wakeup"
        private const val REQUEST_EXTERNAL_STORAGE = 1
        private const val OVERLAY_PERMISSION_REQUEST_CODE = 1234
        private val PERMISSIONS_STORAGE = arrayOf(
            Manifest.permission.READ_EXTERNAL_STORAGE,
            Manifest.permission.WRITE_EXTERNAL_STORAGE,
        )
        private lateinit var wakeUpReceiver: WakeUpReceiver
        lateinit var channel: MethodChannel
        lateinit var eventChannel: EventChannel
        lateinit var wakeUpChannel: MethodChannel
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(RestartPlugin())
        flutterEngine.plugins.add(InstallPlugin())

        registerWith(flutterEngine)
        eventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            USB_EVENT_CHANNEL
        )

        eventChannel.setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    registerReceiver(
                        usbReceiver,
                        IntentFilter(UsbManager.ACTION_USB_DEVICE_ATTACHED)
                    )
                    registerReceiver(
                        usbReceiver,
                        IntentFilter(UsbManager.ACTION_USB_DEVICE_DETACHED)
                    )
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    unregisterReceiver(usbReceiver)
                }
            }
        )

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SERIAL_CHANNEL)
        MyBackgroundService.channel = channel

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "saveUser" -> {
                    val argument = call.argument<String>(Constants.USER_ID_CONNECTED)
                    sharedPreferencesManager.saveUserIdConnected(argument)
                    if (argument != null) {
                        startMyBackgroundService()
                    }
                    result.success("")
                }

                "saveComputer" -> {
                    val serialComputer = call.argument<String>(Constants.SERIAL_COMPUTER)
                    val computerId = call.argument<String>(Constants.COMPUTER_ID)
                    sharedPreferencesManager.saveSerialComputer(serialComputer)
                    sharedPreferencesManager.saveIdComputer(computerId)
                    if (computerId != null && serialComputer != null) {
                        startMyBackgroundService()
                    }
                    result.success("")
                }

                "clearUser" -> {
                    sharedPreferencesManager.clearData()
                    result.success("")
                }

                "getUsbPath" -> {
                    val usbPath = getUsbPath2()
                    result.success(usbPath)
                }

                "getSerial" -> {
                    val androidId = getDeviceId(this)
                    result.success(androidId)
                }

                "setHost" -> {
                    val host = call.argument<String>(Constants.HOST)
                    if (host != null) {
                        AppApi.BASE_URL = host
                    }
                    sharedPreferencesManager.saveHost(host)
                    result.success("")
                }

                "firebase" -> {
                    val check = call.argument<Boolean>(Constants.FIRE_BASE)
                    sharedPreferencesManager.saveFirebaseCheck(check)
                    MyBackgroundService.isFirebase = check ?: false
                    result.success("")
                }

                else -> {
                    result.success("")
                }
            }
        }

        wakeUpChannel  = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WAKE_UP_CHANNEL)
        MyBackgroundService.wakeUpChannel = wakeUpChannel
        wakeUpReceiver = WakeUpReceiver()
        wakeUpReceiver.setMethodChannel(wakeUpChannel)
        
        wakeUpChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "setWakeUpAlarm" -> {
                    val delay = call.argument<Int>("delay")
                    if (delay != null) {
                        setWakeUpAlarm(delay)
                        result.success(null)
                    } else {
                        result.error("INVALID_DELAY", "Delay không hợp lệ", null)
                    }
                }
                else -> {
                    result.success("")
                }
            }
        }
    }

    private fun setWakeUpAlarm(delayInSeconds: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, WakeUpReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val triggerAtMillis = System.currentTimeMillis() + delayInSeconds * 1000L

        // Sử dụng setExactAndAllowWhileIdle để đảm bảo alarm hoạt động trong Doze Mode
        alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
    }

    private val usbReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                UsbManager.ACTION_USB_DEVICE_ATTACHED -> {
                    eventSink?.success("USB_CONNECTED")
                }

                UsbManager.ACTION_USB_DEVICE_DETACHED -> {
                    eventSink?.success("USB_DISCONNECTED")
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 200)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(this)) {
                showPermissionDialog()
            }
        }

        sharedPreferencesManager = SharedPreferencesManager(context)

        verifyStoragePermissions(this)

        startMyBackgroundService()
    }

    override fun onResume() {
        super.onResume()

        MyBackgroundService.isAppRunning = true
    }

    override fun onPause() {
        super.onPause()

        MyBackgroundService.isAppRunning = false
    }

    override fun onStop() {
        super.onStop()

        MyBackgroundService.isAppRunning = false
    }

    override fun onDestroy() {
        super.onDestroy()

        eventChannel.setStreamHandler(null)
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun showPermissionDialog() {
        val builder = AlertDialog.Builder(this)
        builder.setTitle("Cấp quyền hiển thị trên ứng dụng khác")
        builder.setMessage("Ứng dụng cần quyền này để có thể khởi động lại khi cần thiết. Vui lòng cấp quyền hiển thị trên ứng dụng khác.")
        builder.setPositiveButton("OK") { _, _ ->
            openOverlayPermissionSettings()
        }
        builder.setNegativeButton("Cancel") { dialog, _ ->
            dialog.dismiss()
        }
        builder.setCancelable(true)
        builder.show()
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun openOverlayPermissionSettings() {
        val intent = Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            Uri.parse("package:" + this.packageName)
        )
        startActivityForResult(intent, OVERLAY_PERMISSION_REQUEST_CODE)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        if (requestCode == 200 && permissions.contains(Manifest.permission.POST_NOTIFICATIONS)) {
            startMyBackgroundService()
        }
        if (requestCode == 200 && permissions.contains(Manifest.permission.SYSTEM_ALERT_WINDOW)) {
            startMyBackgroundService()
        }

        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    @RequiresApi(Build.VERSION_CODES.M)
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (resultCode == Activity.RESULT_OK) {
            if (requestCode == OVERLAY_PERMISSION_REQUEST_CODE) {
                if (Settings.canDrawOverlays(activity)) {
                    Toast.makeText(
                        activity,
                        "Quyền hiển thị trên ứng dụng khác đã được cấp",
                        Toast.LENGTH_SHORT,
                    ).show()
                } else {
                    Toast.makeText(
                        activity,
                        "Quyền hiển thị trên ứng dụng khác bị từ chối",
                        Toast.LENGTH_SHORT,
                    ).show()
                }
            }
        }
    }

    private fun startMyBackgroundService() {
        if (checkStartService()) {
            val serviceIntent = Intent(this, MyBackgroundService::class.java)
            MyBackgroundService.isAppRunning = true
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent)
            } else {
                startService(serviceIntent)
            }
        }
    }

    private fun checkStartService() = !isMyServiceRunning(
        MyBackgroundService::class.java,
        this
    ) && sharedPreferencesManager.getUserIdConnected() != null
            && sharedPreferencesManager.getIdComputer() != null

    private fun isMyServiceRunning(serviceClass: Class<*>?, context: Context): Boolean {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val services = activityManager.getRunningServices(Int.MAX_VALUE)
        for (runningService in services) {
            if (serviceClass?.name == runningService.service.className) {
                return true
            }
        }
        return false
    }

    private fun verifyStoragePermissions(activity: Activity) {
        val permission =
            ActivityCompat.checkSelfPermission(activity, Manifest.permission.WRITE_EXTERNAL_STORAGE)

        if (permission != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(
                activity,
                PERMISSIONS_STORAGE,
                REQUEST_EXTERNAL_STORAGE,
            )
        }
    }

    private fun getUsbPath(): List<String> {
        val usbPaths = mutableListOf<String>()
        val storageDirectory = File("/storage")

        try {
            if (storageDirectory.exists() && storageDirectory.isDirectory) {
                val directories = storageDirectory.listFiles { file -> file.isDirectory }
                if (directories != null) {
                    for (dir in directories) {
                        if (File(dir, "Android").exists()) {
                            usbPaths.add(dir.absolutePath)
                        }
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        return usbPaths
    }

    private fun getUsbPath2(): List<String> {
        val usbPaths = mutableListOf<String>()

        try {
            val externalDirs = context.getExternalFilesDirs(null)
            for (file in externalDirs) {
                file?.let {
                    if (!Environment.isExternalStorageEmulated(it)) {
                        val usbPath = it.absolutePath.split("/Android").first()
                        usbPaths.add(usbPath)
                    }
                }
            }

            val possiblePaths = arrayOf(
                "/storage",
                "/mnt/usb_storage",
                "/mnt/media_rw"
            )

            for (path in possiblePaths) {
                val file = File(path)
                if (file.exists() && file.isDirectory) {
                    file.listFiles()?.filter { it.isDirectory && File(it, "Android").exists() }?.forEach {
                        if (!usbPaths.contains(it.absolutePath)) {
                            usbPaths.add(it.absolutePath)
                        }
                    }
                }
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val storageManager = context.getSystemService(Context.STORAGE_SERVICE) as StorageManager
                val storageVolumes = storageManager.storageVolumes
                for (volume in storageVolumes) {
                    val path = volume.javaClass.getMethod("getPath").invoke(volume) as String?
                    path?.let {
                        val usbFile = File(it)
                        if (usbFile.exists() && usbFile.isDirectory && File(usbFile, "Android").exists()) {
                            if (!usbPaths.contains(usbFile.absolutePath)) {
                                usbPaths.add(usbFile.absolutePath)
                            }
                        }
                    }
                }
            }

        } catch (e: Exception) {
            e.printStackTrace()
        }

        return usbPaths
    }

    @SuppressLint("HardwareIds")
    fun getDeviceId(context: Context): String? {
        return Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ANDROID_ID
        )
    }
}
