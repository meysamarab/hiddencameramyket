package com.example.hiddencam.hidden_cam

import android.content.Intent
import android.net.Uri
import android.content.Context
import android.content.BroadcastReceiver
import android.content.IntentFilter
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.hiddencam/camera_channel"

    companion object {
        var methodChannel: MethodChannel? = null
        
        fun notifyFlutter(method: String, arguments: Any? = null) {
            // Ensure we are on the main thread
            android.os.Handler(android.os.Looper.getMainLooper()).post {
                methodChannel?.invokeMethod(method, arguments)
            }
        }
    }

    // Remove trialEndedReceiver as we'll use direct calls

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            val intent = Intent(this, NativeBackgroundCameraService::class.java)
            
            when (call.method) {
                "startVideo" -> {
                    intent.action = NativeBackgroundCameraService.ACTION_START_VIDEO
                    intent.putExtra(NativeBackgroundCameraService.EXTRA_DIRECTION, call.argument<String>("direction"))
                    val maxDuration = call.argument<Int>("maxDurationSeconds") ?: 0
                    intent.putExtra(NativeBackgroundCameraService.EXTRA_MAX_DURATION, maxDuration)
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
                "isRecording" -> {
                    val isRecording = NativeBackgroundCameraService.instance?.isRecording ?: false
                    result.success(isRecording)
                }
                "isBursting" -> {
                    val isBursting = NativeBackgroundCameraService.instance?.isBursting ?: false
                    result.success(isBursting)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        methodChannel = null
    }


    private fun startServiceIntent(intent: Intent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
}
