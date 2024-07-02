package com.example.play_box

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.widget.Toast
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import android.content.pm.PackageManager
import android.util.Log
import android.app.AlertDialog
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel
import java.io.File
import com.example.play_box.service.MyBackgroundService
import com.example.play_box.utils.Constants
import com.example.play_box.utils.SharedPreferencesManager

class MainActivity : FlutterActivity() {
    private lateinit var sharedPreferencesManager: SharedPreferencesManager

    companion object {
        const val TAG = "MainActivity"

        private const val CHANNEL = "com.example.usb/serial"
        private const val REQUEST_EXTERNAL_STORAGE = 1
        private val PERMISSIONS_STORAGE = arrayOf(
            Manifest.permission.READ_EXTERNAL_STORAGE,
            Manifest.permission.WRITE_EXTERNAL_STORAGE,
        )
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
        startActivityForResult(intent, 200)
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

    private fun startMyBackgroundService() {
        val serviceIntent = Intent(this, MyBackgroundService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        FlutterEngineCache.getInstance().put("my_engine_id", flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveUser" -> {
                    val argument = call.argument<String>(Constants.USER_ID_CONNECTED)
                    sharedPreferencesManager.saveUserIdConnected(argument)
                    startMyBackgroundService()
                    Log.d(TAG, "saveUser: $argument")
                }

                "saveComputer" -> {
                    val serialComputer = call.argument<String>(Constants.SERIAL_COMPUTER)
                    val computerId = call.argument<String>(Constants.COMPUTER_ID)
                    sharedPreferencesManager.saveSerialComputer(serialComputer)
                    sharedPreferencesManager.saveIdComputer(computerId)
                }

                "clearUser" -> {
                    sharedPreferencesManager.clearData()
                }

                "getUsbPath" -> {
                    val usbPath = getUsbPath()
                    result.success(usbPath)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getUsbPath(): List<String> {
        val usbPaths = mutableListOf<String>()
        val storageDirectory = File("/storage")

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

        return usbPaths
    }
}
