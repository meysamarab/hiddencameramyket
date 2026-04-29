import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:gal/gal.dart';

class CameraManager {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;

  bool get isRecording => _isRecording;

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
    
    await _controller!.dispose();
    _controller = null;
    
    return savedFile.path;
  }

  Future<String?> takePhoto({CameraLensDirection direction = CameraLensDirection.back}) async {
    if (_cameras == null || _cameras!.isEmpty) await initialize();

    final camera = _cameras!.firstWhere(
      (c) => c.lensDirection == direction,
      orElse: () => _cameras!.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();
    final file = await _controller!.takePicture();
    
    // Save to permanent storage for in-app gallery
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedFile = await File(file.path).copy(p.join(appDir.path, fileName));

    // Save to system gallery
    await Gal.putImage(savedFile.path);

    await _controller!.dispose();
    _controller = null;

    return savedFile.path;
  }

  Future<void> dispose() async {
    await _controller?.dispose();
  }
}
