import 'dart:io';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:gal/gal.dart';

class CameraManager {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  
  Timer? _burstTimer;
  bool _isBurstActive = false;

  bool get isRecording => _isRecording;
  bool get isBurstActive => _isBurstActive;

  Future<void> initialize() async {
    _cameras = await availableCameras();
  }

  Future<void> startVideoRecording({CameraLensDirection direction = CameraLensDirection.back}) async {
    if (_cameras == null || _cameras!.isEmpty) await initialize();
    
    final camera = _cameras!.firstWhere(
      (c) => c.lensDirection == direction,
      orElse: () => _cameras!.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
    );

    await _controller!.initialize();
    await _controller!.startVideoRecording();
    _isRecording = true;
  }

  Future<String?> stopVideoRecording() async {
    if (_controller == null || !_isRecording) return null;

    final file = await _controller!.stopVideoRecording();
    _isRecording = false;
    
    // Save to permanent storage for in-app gallery
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final savedFile = await File(file.path).copy(p.join(appDir.path, fileName));

    // Save to system gallery
    await Gal.putVideo(savedFile.path);
    
    if (!_isBurstActive) {
      await _controller!.dispose();
      _controller = null;
    }
    
    return savedFile.path;
  }

  Future<String?> takePhoto({CameraLensDirection direction = CameraLensDirection.back}) async {
    if (_cameras == null || _cameras!.isEmpty) await initialize();

    final camera = _cameras!.firstWhere(
      (c) => c.lensDirection == direction,
      orElse: () => _cameras!.first,
    );

    bool shouldDispose = false;
    if (_controller == null) {
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _controller!.initialize();
      shouldDispose = true;
    }

    final file = await _controller!.takePicture();
    
    // Save to permanent storage for in-app gallery
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedFile = await File(file.path).copy(p.join(appDir.path, fileName));

    // Save to system gallery
    await Gal.putImage(savedFile.path);

    if (shouldDispose && !_isBurstActive && !_isRecording) {
      await _controller!.dispose();
      _controller = null;
    }

    return savedFile.path;
  }

  Future<void> startBurstPhoto({
    CameraLensDirection direction = CameraLensDirection.back,
    required int durationMinutes,
    required int intervalSeconds,
  }) async {
    if (_cameras == null || _cameras!.isEmpty) await initialize();
    
    final camera = _cameras!.firstWhere(
      (c) => c.lensDirection == direction,
      orElse: () => _cameras!.first,
    );

    if (_controller == null) {
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _controller!.initialize();
    }

    _isBurstActive = true;
    final endTime = DateTime.now().add(Duration(minutes: durationMinutes));

    // Take the first photo immediately
    _takeBurstPhotoWrapper();

    _burstTimer = Timer.periodic(Duration(seconds: intervalSeconds), (timer) async {
      if (DateTime.now().isAfter(endTime) || !_isBurstActive) {
        await stopBurstPhoto();
        return;
      }
      _takeBurstPhotoWrapper();
    });
  }

  Future<void> _takeBurstPhotoWrapper() async {
    try {
      if (_controller != null && _controller!.value.isInitialized) {
         final file = await _controller!.takePicture();
         final appDir = await getApplicationDocumentsDirectory();
         final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
         final savedFile = await File(file.path).copy(p.join(appDir.path, fileName));
         await Gal.putImage(savedFile.path);
      }
    } catch (e) {
      print("Burst photo capture error: \$e");
    }
  }

  Future<void> stopBurstPhoto() async {
    _isBurstActive = false;
    _burstTimer?.cancel();
    _burstTimer = null;
    
    if (!_isRecording && _controller != null) {
      await _controller!.dispose();
      _controller = null;
    }
  }

  Future<void> dispose() async {
    await stopBurstPhoto();
    await _controller?.dispose();
  }
}
