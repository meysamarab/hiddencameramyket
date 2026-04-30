import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../l10n/app_localizations.dart';
import 'settings_screen.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  
  @override
  void initState() {
    super.initState();
    _initIAP();
    _checkNativeState();
  }

  Future<void> _initIAP() async {
    final iap = ref.read(iapServiceProvider);
    await iap.init();
    final isPremium = await iap.checkSubscription();
    ref.read(isPremiumProvider.notifier).state = isPremium;

    // Listen for trial end from native
    final platform = MethodChannel('com.example.hiddencam/camera_channel');
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onTrialEnded') {
        _showTrialEndedDialog();
      }
    });
  }
  
  Future<void> _checkNativeState() async {
    final cameraManager = ref.read(cameraManagerProvider);
    final isRecording = await cameraManager.isRecording();
    final isBursting = await cameraManager.isBursting();
    
    if (mounted) {
      ref.read(isRecordingProvider.notifier).state = isRecording;
      ref.read(isBurstActiveProvider.notifier).state = isBursting;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = ref.watch(isRecordingProvider);
    final isBurstActive = ref.watch(isBurstActiveProvider);
    final l10n = AppLocalizations.of(context)!;
    final selectedCamera = ref.watch(selectedCameraProvider);
    final burstDuration = ref.watch(burstDurationProvider);
    final burstInterval = ref.watch(burstIntervalProvider);
    final cameraManager = ref.read(cameraManagerProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.appTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
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
              const SizedBox(height: 20),
              if (!isPremium && !isRecording && !isBurstActive) _buildPremiumBanner(context),
              const SizedBox(height: 20),
              
              // Burst settings moved below button

              
              if (!isBurstActive)
                _buildActionButton(
                  context: context,
                  label: isRecording ? l10n.stopRecording : l10n.startRecording,
                  icon: isRecording ? Icons.stop_rounded : Icons.videocam_rounded,
                  color: isRecording ? Colors.red : Theme.of(context).colorScheme.primary,
                    onTap: () async {
                    if (isRecording) {
                      await cameraManager.stopVideoRecording();
                      ref.read(isRecordingProvider.notifier).state = false;
                    } else {
                      await cameraManager.startVideoRecording(
                        direction: selectedCamera,
                        maxDurationSeconds: isPremium ? 0 : 30,
                      );
                      ref.read(isRecordingProvider.notifier).state = true;
                    }
                  },
                ),
                if (!isPremium && !isRecording)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'نسخه رایگان: محدودیت ۳۰ ثانیه برای هر ویدیو',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
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
                      await cameraManager.stopBurstPhoto();
                      ref.read(isBurstActiveProvider.notifier).state = false;
                    } else {
                      await cameraManager.startBurstPhoto(
                        direction: selectedCamera,
                        durationMinutes: burstDuration,
                        intervalSeconds: burstInterval,
                      );
                      ref.read(isBurstActiveProvider.notifier).state = true;
                      
                      // Auto reset after duration
                      Future.delayed(Duration(minutes: burstDuration), () {
                         if (mounted) {
                           ref.read(isBurstActiveProvider.notifier).state = false;
                         }
                      });
                    }
                  },
                ),
              
              if (!isRecording && !isBurstActive) ...[
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    children: [
                      const Icon(Icons.tune_rounded, color: Colors.white70, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.burstSettings ?? 'تنظیمات عکس‌برداری خودکار',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildBurstSettings(context, burstDuration, burstInterval, l10n),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBurstSettings(BuildContext context, int duration, int interval, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.burstDuration ?? 'مدت زمان (دقیقه)',
                style: const TextStyle(color: Colors.white70),
              ),
              DropdownButton<int>(
                dropdownColor: Theme.of(context).colorScheme.surface,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                underline: const SizedBox(),
                value: duration,
                items: [1, 2, 5, 10, 30, 60].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value min'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) ref.read(burstDurationProvider.notifier).state = value;
                },
              ),
            ],
          ),
          const Divider(color: Colors.white12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.burstInterval ?? 'فاصله زمانی (ثانیه)',
                style: const TextStyle(color: Colors.white70),
              ),
              DropdownButton<int>(
                dropdownColor: Theme.of(context).colorScheme.surface,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                underline: const SizedBox(),
                value: interval,
                items: [2, 5, 10, 30, 60].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value sec'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) ref.read(burstIntervalProvider.notifier).state = value;
                },
              ),
            ],
          ),
        ],
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

  void _showTrialEndedDialog() {
    if (!mounted) return;
    
    // Stop any UI indicators
    ref.read(isRecordingProvider.notifier).state = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text('پایان زمان تست', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'زمان ۳۰ ثانیه‌ای تست رایگان به پایان رسید. برای ضبط طولانی‌تر، لطفاً اشتراک تهیه کنید.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('متوجه شدم', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(iapServiceProvider).purchasePremium();
              if (success) {
                ref.read(isPremiumProvider.notifier).state = true;
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ارتقا به ویژه'),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.amber, Colors.orange]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ارتقا به نسخه ویژه',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  'فیلم‌برداری نامحدود فقط ۱۰۰,۰۰۰ تومان',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final success = await ref.read(iapServiceProvider).purchasePremium();
              if (success) {
                ref.read(isPremiumProvider.notifier).state = true;
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('خرید'),
          ),
        ],
      ),
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
