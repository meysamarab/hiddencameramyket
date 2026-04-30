import 'package:flutter/services.dart';
import 'package:camera/camera.dart';

class NativeCameraManager {
  static const platform = MethodChannel('com.example.hiddencam/camera_channel');

  Future<void> startVideoRecording({CameraLensDirection direction = CameraLensDirection.back}) async {
    try {
      await platform.invokeMethod('startVideo', {
        'direction': direction.name,
      });
    } on PlatformException catch (e) {
      print("Failed to start video: '${e.message}'.");
    }
  }

  Future<void> stopVideoRecording() async {
    try {
      await platform.invokeMethod('stopVideo');
    } on PlatformException catch (e) {
      print("Failed to stop video: '${e.message}'.");
    }
  }

  Future<void> startBurstPhoto({
    CameraLensDirection direction = CameraLensDirection.back,
    required int durationMinutes,
    required int intervalSeconds,
  }) async {
    try {
      await platform.invokeMethod('startBurst', {
        'direction': direction.name,
        'durationMinutes': durationMinutes,
        'intervalSeconds': intervalSeconds,
      });
    } on PlatformException catch (e) {
      print("Failed to start burst: '${e.message}'.");
    }
  }

  Future<void> stopBurstPhoto() async {
    try {
      await platform.invokeMethod('stopBurst');
    } on PlatformException catch (e) {
      print("Failed to stop burst: '${e.message}'.");
    }
  }

  Future<bool> isRecording() async {
    try {
      final result = await platform.invokeMethod<bool>('isRecording');
      return result ?? false;
    } on PlatformException catch (e) {
      print("Failed to get recording state: '${e.message}'.");
      return false;
    }
  }

  Future<bool> isBursting() async {
    try {
      final result = await platform.invokeMethod<bool>('isBursting');
      return result ?? false;
    } on PlatformException catch (e) {
      print("Failed to get burst state: '${e.message}'.");
      return false;
    }
  }

  Future<List<String>> getMediaFiles() async {
    try {
      final List<dynamic>? result = await platform.invokeMethod<List<dynamic>>('getMediaFiles');
      return result?.cast<String>() ?? [];
    } on PlatformException catch (e) {
      print("Failed to get media files: '${e.message}'.");
      return [];
    }
  }
}
