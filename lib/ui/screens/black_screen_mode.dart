import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:screen_brightness/screen_brightness.dart';

class BlackScreenMode extends StatefulWidget {
  const BlackScreenMode({super.key});

  @override
  State<BlackScreenMode> createState() => _BlackScreenModeState();
}

class _BlackScreenModeState extends State<BlackScreenMode> {
  double _currentBrightness = 0.5;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _enterBlackScreenMode();
  }

  Future<void> _enterBlackScreenMode() async {
    // Hide status bar and navigation bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Keep screen awake
    WakelockPlus.enable();

    try {
      // Save current brightness and set to minimum
      _currentBrightness = await ScreenBrightness().current;
      await ScreenBrightness().setScreenBrightness(0.0);
    } catch (e) {
      debugPrint("Failed to set brightness: \$e");
    }
  }

  Future<void> _exitBlackScreenMode() async {
    if (_isExiting) return;
    _isExiting = true;

    // Restore UI overlays
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // Release wakelock
    WakelockPlus.disable();

    try {
      // Restore brightness
      await ScreenBrightness().setScreenBrightness(_currentBrightness);
      await ScreenBrightness().resetScreenBrightness();
    } catch (e) {
      debugPrint("Failed to restore brightness: \$e");
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use GestureDetector to catch double taps or long presses to exit
    return GestureDetector(
      onDoubleTap: _exitBlackScreenMode,
      onLongPress: _exitBlackScreenMode,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          color: Colors.black,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Ensure we always clean up if the widget is disposed unexpectedly
    _exitBlackScreenMode();
    super.dispose();
  }
}
