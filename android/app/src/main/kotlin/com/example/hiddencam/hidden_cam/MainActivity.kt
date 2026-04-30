package com.example.hiddencam.hidden_cam

import android.content.Intent
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.hiddencam/camera_channel"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val intent = Intent(this, NativeBackgroundCameraService::class.java)
            
            when (call.method) {
                "startVideo" -> {
                    intent.action = NativeBackgroundCameraService.ACTION_START_VIDEO
                    intent.putExtra(NativeBackgroundCameraService.EXTRA_DIRECTION, call.argument<String>("direction"))
                    startServiceIntent(intent)
                    result.success(null)
                }
                "stopVideo" -> {
                    intent.action = NativeBackgroundCameraService.ACTION_STOP_VIDEO
                    startServiceIntent(intent)
                    result.success(null)
                }
                "startBurst" -> {
                    intent.action = NativeBackgroundCameraService.ACTION_START_BURST
                    intent.putExtra(NativeBackgroundCameraService.EXTRA_DIRECTION, call.argument<String>("direction"))
                    val duration = call.argument<Int>("durationMinutes") ?: 2
                    val interval = call.argument<Int>("intervalSeconds") ?: 5
                    intent.putExtra(NativeBackgroundCameraService.EXTRA_DURATION, duration)
                    intent.putExtra(NativeBackgroundCameraService.EXTRA_INTERVAL, interval)
                    startServiceIntent(intent)
                    result.success(null)
                }
                "stopBurst" -> {
                    intent.action = NativeBackgroundCameraService.ACTION_STOP_BURST
                    startServiceIntent(intent)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startServiceIntent(intent: Intent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
}
