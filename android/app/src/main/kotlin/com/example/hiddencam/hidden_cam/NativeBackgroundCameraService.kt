package com.example.hiddencam.hidden_cam

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.provider.MediaStore
import android.util.Log
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.video.*
import androidx.camera.video.VideoCapture
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleService
import java.util.Timer
import java.util.TimerTask
import java.io.File

class NativeBackgroundCameraService : LifecycleService() {

    private var videoCapture: VideoCapture<Recorder>? = null
    private var imageCapture: ImageCapture? = null
    private var activeRecording: Recording? = null
    private var burstTimer: Timer? = null
    private var recordingStartTime = 0L
    private var photoCount = 0
    
    var isRecording = false
    var isBursting = false

    companion object {
        const val CHANNEL_ID = "hiddencam_native_channel"
        const val NOTIFICATION_ID = 999
        const val ACTION_START_VIDEO = "START_VIDEO"
        const val ACTION_STOP_VIDEO = "STOP_VIDEO"
        const val ACTION_START_BURST = "START_BURST"
        const val ACTION_STOP_BURST = "STOP_BURST"
        const val EXTRA_DIRECTION = "DIRECTION"
        const val EXTRA_DURATION = "DURATION"
        const val EXTRA_INTERVAL = "INTERVAL"
        const val EXTRA_MAX_DURATION = "MAX_DURATION"
        var instance: NativeBackgroundCameraService? = null

        fun getRecordingDuration(): Int {
            val service = instance ?: return 0
            if (!service.isRecording || service.recordingStartTime == 0L) return 0
            return ((System.currentTimeMillis() - service.recordingStartTime) / 1000).toInt()
        }

        fun getPhotoCount(): Int {
            return instance?.photoCount ?: 0
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        createNotificationChannel()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        instance = null
        stopAll()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        super.onStartCommand(intent, flags, startId)
        
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("System Service")
            .setContentText("Running...")
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .build()
            
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA or ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        intent?.let {
            val directionStr = it.getStringExtra(EXTRA_DIRECTION) ?: "back"
            val lensDirection = if (directionStr == "front") CameraSelector.LENS_FACING_FRONT else CameraSelector.LENS_FACING_BACK

            when (it.action) {
                ACTION_START_VIDEO -> {
                    val maxDuration = it.getIntExtra(EXTRA_MAX_DURATION, 0)
                    startVideo(lensDirection, maxDuration)
                }
                ACTION_STOP_VIDEO -> stopVideo()
                ACTION_START_BURST -> {
                    val duration = it.getIntExtra(EXTRA_DURATION, 2)
                    val interval = it.getIntExtra(EXTRA_INTERVAL, 5)
                    startBurst(lensDirection, duration, interval)
                }
                ACTION_STOP_BURST -> stopBurst()
            }
        }
        
        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "System Background",
                NotificationManager.IMPORTANCE_MIN
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun setupCamera(lensDirection: Int, forVideo: Boolean, onReady: () -> Unit) {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(this)
        cameraProviderFuture.addListener({
            val cameraProvider = cameraProviderFuture.get()
            cameraProvider.unbindAll()

            val cameraSelector = CameraSelector.Builder()
                .requireLensFacing(lensDirection)
                .build()

            try {
                if (forVideo) {
                    val recorder = Recorder.Builder()
                        .setQualitySelector(QualitySelector.from(Quality.HIGHEST))
                        .build()
                    videoCapture = VideoCapture.withOutput(recorder)
                    cameraProvider.bindToLifecycle(this, cameraSelector, videoCapture)
                } else {
                    imageCapture = ImageCapture.Builder().build()
                    cameraProvider.bindToLifecycle(this, cameraSelector, imageCapture)
                }
                onReady()
            } catch (exc: Exception) {
                Log.e("CameraService", "Use case binding failed", exc)
                stopSelf()
            }
        }, ContextCompat.getMainExecutor(this))
    }

    @SuppressLint("MissingPermission")
    private fun startVideo(lensDirection: Int, maxDurationSeconds: Int = 0) {
        if (isRecording) return
        Log.d("HiddenCam", "Starting video recording. Max duration: $maxDurationSeconds seconds")
        
        setupCamera(lensDirection, true) {
            val videoCapture = this.videoCapture ?: return@setupCamera
            
            val name = "video_${System.currentTimeMillis()}.mp4"
            val contentValues = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, name)
                put(MediaStore.MediaColumns.MIME_TYPE, "video/mp4")
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    put(MediaStore.Video.Media.RELATIVE_PATH, "Movies/HiddenCam")
                }
            }

            val mediaStoreOutputOptions = MediaStoreOutputOptions
                .Builder(contentResolver, MediaStore.Video.Media.EXTERNAL_CONTENT_URI)
                .setContentValues(contentValues)
                .build()

            activeRecording = videoCapture.output
                .prepareRecording(this, mediaStoreOutputOptions)
                .withAudioEnabled()
                .start(ContextCompat.getMainExecutor(this)) { recordEvent: VideoRecordEvent ->
                    if (recordEvent is VideoRecordEvent.Start) {
                        isRecording = true
                        recordingStartTime = System.currentTimeMillis()
                        
                        if (maxDurationSeconds > 0) {
                            Log.d("HiddenCam", "Trial timer started for $maxDurationSeconds seconds")
                            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                                Log.d("HiddenCam", "Trial timer fired! isRecording: $isRecording")
                                if (isRecording) {
                                    Log.d("HiddenCam", "Stopping video via trial timer")
                                    stopVideo()
                                    // Notify that trial ended
                                    MainActivity.notifyFlutter("onTrialEnded")
                                }
                            }, maxDurationSeconds * 1000L)
                        }
                    } else if (recordEvent is VideoRecordEvent.Finalize) {
                        isRecording = false
                        recordingStartTime = 0L
                        if (!isBursting) stopSelf()
                    }
                }
        }
    }

    private fun stopVideo() {
        activeRecording?.stop()
        activeRecording = null
        if (!isBursting) stopSelf()
    }

    private fun startBurst(lensDirection: Int, durationMinutes: Int, intervalSeconds: Int) {
        if (isBursting) return
        
        setupCamera(lensDirection, false) {
            isBursting = true
            photoCount = 0
            val endTime = System.currentTimeMillis() + (durationMinutes * 60 * 1000L)
            
            burstTimer = Timer()
            burstTimer?.scheduleAtFixedRate(object : TimerTask() {
                override fun run() {
                    if (System.currentTimeMillis() > endTime || !isBursting) {
                        stopBurst()
                        return
                    }
                    takePhoto()
                }
            }, 0, intervalSeconds * 1000L)
        }
    }
    
    private fun takePhoto() {
        val imageCapture = this.imageCapture ?: return
        
        val name = "photo_${System.currentTimeMillis()}.jpg"
        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, "image/jpeg")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/HiddenCam")
            }
        }

        val outputOptions = ImageCapture.OutputFileOptions.Builder(
            contentResolver,
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            contentValues
        ).build()

        imageCapture.takePicture(
            outputOptions, 
            ContextCompat.getMainExecutor(this),
            object : ImageCapture.OnImageSavedCallback {
                override fun onImageSaved(outputFileResults: ImageCapture.OutputFileResults) {
                    Log.d("HiddenCam", "Photo saved.")
                    photoCount++
                }
                override fun onError(exception: ImageCaptureException) {
                    Log.e("CameraService", "Photo capture failed", exception)
                }
            }
        )
    }

    private fun stopBurst() {
        isBursting = false
        photoCount = 0
        burstTimer?.cancel()
        burstTimer = null
        if (!isRecording) stopSelf()
    }
    
    private fun stopAll() {
        stopVideo()
        stopBurst()
        try {
            val cameraProviderFuture = ProcessCameraProvider.getInstance(this)
            cameraProviderFuture.get().unbindAll()
        } catch (e: Exception) {}
    }
}
