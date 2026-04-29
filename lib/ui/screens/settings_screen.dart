import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../l10n/app_localizations.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedCamera = ref.watch(selectedCameraProvider);
    final audioEnabled = ref.watch(audioEnabledProvider);
    final quality = ref.watch(videoQualityProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, l10n.cameraSelection),
          ListTile(
            title: Text(l10n.rearCamera),
            leading: const Icon(Icons.camera_rear),
            trailing: Radio<CameraLensDirection>(
              value: CameraLensDirection.back,
              groupValue: selectedCamera,
              onChanged: (value) => ref.read(selectedCameraProvider.notifier).state = value!,
            ),
          ),
          ListTile(
            title: Text(l10n.frontCamera),
            leading: const Icon(Icons.camera_front),
            trailing: Radio<CameraLensDirection>(
              value: CameraLensDirection.front,
              groupValue: selectedCamera,
              onChanged: (value) => ref.read(selectedCameraProvider.notifier).state = value!,
            ),
          ),
          const Divider(),
          _buildSectionHeader(context, l10n.videoQuality),
          _buildQualityTile(ref, '720p', ResolutionPreset.high, quality),
          _buildQualityTile(ref, '1080p', ResolutionPreset.veryHigh, quality),
          _buildQualityTile(ref, '4K', ResolutionPreset.ultraHigh, quality),
          const Divider(),
          SwitchListTile(
            title: Text(l10n.audioEnabled),
            secondary: const Icon(Icons.mic),
            value: audioEnabled,
            onChanged: (value) => ref.read(audioEnabledProvider.notifier).state = value,
          ),
          const Divider(),
          _buildSectionHeader(context, l10n.batteryOptimization),
          ListTile(
            title: Text(l10n.batteryOptimization),
            subtitle: Text(l10n.batteryOptimizationDesc),
            leading: const Icon(Icons.battery_alert),
            onTap: () async {
              await Permission.ignoreBatteryOptimizations.request();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildQualityTile(WidgetRef ref, String label, ResolutionPreset value, ResolutionPreset current) {
    return ListTile(
      title: Text(label),
      trailing: Radio<ResolutionPreset>(
        value: value,
        groupValue: current,
        onChanged: (val) => ref.read(videoQualityProvider.notifier).state = val!,
      ),
    );
  }
}
