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
import com.example.play_box.service.MyBackgroundService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import android.app.AlertDialog
import android.util.Log
import com.example.play_box.api.Constants
import com.example.play_box.utils.JSON
import com.example.play_box.utils.SharedPreferencesManager
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private lateinit var sharedPreferencesManager: SharedPreferencesManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Khởi chạy broadcast khi cần
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 200)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(this)) {
                showPermissionDialog()
            }
        }

        sharedPreferencesManager = SharedPreferencesManager(context)

        startMyBackgroundService()
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun showPermissionDialog() {
        val builder = AlertDialog.Builder(this)
        builder.setTitle("Cấp quyền hiển thị trên ứng dụng khác")
        builder.setMessage("Ứng dụng cần quyền này để thực hiện một số tính năng. Vui lòng cấp quyền để tiếp tục.")
        builder.setPositiveButton("OK") { _, _ ->
            // Người dùng nhấn OK, mở trang cài đặt để cấp quyền
            openOverlayPermissionSettings()
        }
        builder.setNegativeButton("Cancel") { dialog, _ ->
            // Người dùng nhấn Cancel, đóng dialog
            dialog.dismiss()
        }
        builder.setCancelable(true)
        builder.show()
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun openOverlayPermissionSettings() {
        val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            Uri.parse("package:" + this.packageName))
        startActivityForResult(intent, 200)
        Toast.makeText(this, "Vui lòng cấp quyền hiển thị trên ứng dụng khác", Toast.LENGTH_SHORT).show()
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
                Toast.makeText(activity, "Quyền hiển thị trên ứng dụng khác đã được cấp", Toast.LENGTH_SHORT).show()
            } else {
                Toast.makeText(activity, "Quyền hiển thị trên ứng dụng khác bị từ chối", Toast.LENGTH_SHORT).show()
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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        FlutterEngineCache.getInstance().put("my_engine_id", flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example/my_channel")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveUser" -> {
                        val argument = call.argument<String>(Constants.USER_INFO)
                        sharedPreferencesManager.saveUserProfile(argument)
                        startMyBackgroundService()
                        Log.d("MainActivity", "configureFlutterEngine: $argument")
                    }

                    "clearUser" -> {
                        sharedPreferencesManager.clearData()
                    }

                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }
}
