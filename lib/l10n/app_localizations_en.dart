// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'HiddenCam';

  @override
  String get startRecording => 'Start Secret Recording';

  @override
  String get stopRecording => 'Stop Recording';

  @override
  String get takePhoto => 'Take Secret Photo';

  @override
  String get settings => 'Settings';

  @override
  String get gallery => 'Gallery';

  @override
  String get cameraSelection => 'Camera Selection';

  @override
  String get frontCamera => 'Front Camera';

  @override
  String get rearCamera => 'Rear Camera';

  @override
  String get videoQuality => 'Video Quality';

  @override
  String get audioEnabled => 'Audio Recording';

  @override
  String get masqueradeMode => 'Masquerade Mode';

  @override
  String get permissionsRequired => 'Permissions Required';

  @override
  String get grantPermissions => 'Grant Permissions';

  @override
  String get batteryOptimization => 'Battery Optimization';

  @override
  String get batteryOptimizationDesc => 'For correct background operation, please disable battery optimization for this app.';

  @override
  String get savePath => 'Storage Path';

  @override
  String get noMediaFound => 'No media found.';

  @override
  String get recordingStarted => 'Recording started';

  @override
  String get recordingStopped => 'Recording stopped';

  @override
  String get photoCaptured => 'Photo captured';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get notificationTitle => 'Camera service is running';

  @override
  String get notificationContent => 'Running in background for your safety';

  @override
  String get onboardingWelcome => 'Welcome to HiddenCam';

  @override
  String get onboardingStep1 => 'This app allows you to record videos secretly.';

  @override
  String get onboardingStep2 => 'Please approve all necessary permissions for correct operation.';

  @override
  String get startBurst => 'Start Burst Photo';

  @override
  String get stopBurst => 'Stop Burst Photo';

  @override
  String get burstActive => 'Burst photo active...';

  @override
  String get burstSettings => 'Burst Photo Settings';

  @override
  String get burstDuration => 'Duration (minutes)';

  @override
  String get burstInterval => 'Interval (seconds)';
}
