import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import '../services/camera_manager.dart';

final cameraManagerProvider = Provider((ref) => CameraManager());

final isRecordingProvider = StateProvider<bool>((ref) => false);
final isBurstActiveProvider = StateProvider<bool>((ref) => false);

final selectedCameraProvider = StateProvider<CameraLensDirection>((ref) => CameraLensDirection.back);

final videoQualityProvider = StateProvider<ResolutionPreset>((ref) => ResolutionPreset.high);

final audioEnabledProvider = StateProvider<bool>((ref) => true);

final burstDurationProvider = StateProvider<int>((ref) => 2); // default 2 minutes
final burstIntervalProvider = StateProvider<int>((ref) => 5); // default 5 seconds
