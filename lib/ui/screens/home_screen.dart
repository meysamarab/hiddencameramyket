import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../l10n/app_localizations.dart';
import 'settings_screen.dart';
import 'gallery_screen.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRecording = ref.watch(isRecordingProvider);
    final isBurstActive = ref.watch(isBurstActiveProvider);
    final l10n = AppLocalizations.of(context)!;
    final selectedCamera = ref.watch(selectedCameraProvider);
    final burstDuration = ref.watch(burstDurationProvider);
    final burstInterval = ref.watch(burstIntervalProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.appTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GalleryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.secondary,
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusIndicator(context, isRecording, isBurstActive, l10n),
              const SizedBox(height: 60),
              if (!isBurstActive)
                _buildActionButton(
                  context: context,
                  label: isRecording ? l10n.stopRecording : l10n.startRecording,
                  icon: isRecording ? Icons.stop_rounded : Icons.videocam_rounded,
                  color: isRecording ? Colors.red : Theme.of(context).colorScheme.primary,
                  onTap: () async {
                    if (isRecording) {
                      FlutterBackgroundService().invoke('stopVideo');
                      ref.read(isRecordingProvider.notifier).state = false;
                      FlutterBackgroundService().invoke('stopService');
                    } else {
                      FlutterBackgroundService().startService();
                      // Small delay to ensure service is started
                      await Future.delayed(const Duration(milliseconds: 500));
                      FlutterBackgroundService().invoke('startVideo', {
                        'direction': selectedCamera.name,
                      });
                      ref.read(isRecordingProvider.notifier).state = true;
                    }
                  },
                ),
              const SizedBox(height: 24),
              if (!isRecording)
                _buildActionButton(
                  context: context,
                  label: isBurstActive ? (l10n.stopBurst ?? 'توقف عکس‌برداری خودکار') : (l10n.startBurst ?? 'شروع عکس‌برداری خودکار'),
                  icon: isBurstActive ? Icons.stop_circle_rounded : Icons.timer_rounded,
                  color: isBurstActive ? Colors.orange : Colors.blueAccent,
                  onTap: () async {
                    if (isBurstActive) {
                      FlutterBackgroundService().invoke('stopBurst');
                      ref.read(isBurstActiveProvider.notifier).state = false;
                      FlutterBackgroundService().invoke('stopService');
                    } else {
                      FlutterBackgroundService().startService();
                      await Future.delayed(const Duration(milliseconds: 500));
                      FlutterBackgroundService().invoke('startBurst', {
                        'direction': selectedCamera.name,
                        'durationMinutes': burstDuration,
                        'intervalSeconds': burstInterval,
                      });
                      ref.read(isBurstActiveProvider.notifier).state = true;
                      
                      // Auto reset after duration
                      Future.delayed(Duration(minutes: burstDuration), () {
                         if (context.mounted) {
                           ref.read(isBurstActiveProvider.notifier).state = false;
                         }
                      });
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context, bool isRecording, bool isBurstActive, AppLocalizations l10n) {
    final isActive = isRecording || isBurstActive;
    final activeColor = isRecording ? Colors.red : Colors.orange;
    
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (isActive)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: 1.5),
                duration: const Duration(seconds: 1),
                onEnd: () {},
                builder: (context, value, child) {
                  return Container(
                    width: 120 * value,
                    height: 120 * value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: activeColor.withOpacity(0.5 / value),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: isActive ? activeColor.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? activeColor : Colors.white24,
                  width: 2,
                ),
              ),
              child: Icon(
                isRecording ? Icons.mic_none_rounded : 
                (isBurstActive ? Icons.camera_rounded : Icons.videocam_off_rounded),
                size: 64,
                color: isActive ? activeColor : Colors.white54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          isRecording ? l10n.recordingStarted : 
          (isBurstActive ? (l10n.burstActive ?? 'در حال عکس‌برداری خودکار...') : l10n.appTitle),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isActive ? activeColor : Colors.white,
              ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
