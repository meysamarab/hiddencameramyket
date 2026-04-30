package com.example.hiddencam.hidden_cam

import android.content.Intent
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.provider.MediaStore
import android.database.Cursor
import android.net.Uri

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
                "isRecording" -> {
                    val isRecording = NativeBackgroundCameraService.instance?.isRecording ?: false
                    result.success(isRecording)
                }
                "isBursting" -> {
                    val isBursting = NativeBackgroundCameraService.instance?.isBursting ?: false
                    result.success(isBursting)
                }
                "getMediaFiles" -> {
                    val files = getMediaFilesList()
                    result.success(files)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getMediaFilesList(): List<String> {
        val filePaths = mutableListOf<String>()
        
        // Query Images
        val imageProjection = arrayOf(MediaStore.Images.Media.DATA)
        val imageCursor = contentResolver.query(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            imageProjection,
            "${MediaStore.Images.Media.RELATIVE_PATH} LIKE ?",
            arrayOf("%Pictures/HiddenCam%"),
            "${MediaStore.Images.Media.DATE_ADDED} DESC"
        )
        imageCursor?.use { cursor ->
            val dataColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA)
            while (cursor.moveToNext()) {
                filePaths.add(cursor.getString(dataColumn))
            }
        }

        // Query Videos
        val videoProjection = arrayOf(MediaStore.Video.Media.DATA)
        val videoCursor = contentResolver.query(
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
            videoProjection,
            "${MediaStore.Video.Media.RELATIVE_PATH} LIKE ?",
            arrayOf("%Movies/HiddenCam%"),
            "${MediaStore.Video.Media.DATE_ADDED} DESC"
        )
        videoCursor?.use { cursor ->
            val dataColumn = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DATA)
            while (cursor.moveToNext()) {
                filePaths.add(cursor.getString(dataColumn))
            }
        }

        return filePaths
    }

    private fun startServiceIntent(intent: Intent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
}
