import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import 'media_view_screen.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  List<File> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      final cameraManager = ref.read(cameraManagerProvider);
      final paths = await cameraManager.getMediaFiles();
      
      setState(() {
        _files = paths.map((p) => File(p)).toList();
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading gallery: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.gallery),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? Center(child: Text(l10n.noMediaFound))
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    final file = _files[index];
                    final isVideo = file.path.endsWith('.mp4');

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MediaViewScreen(filePath: file.path),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.black12,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (!isVideo)
                              Image.file(file, fit: BoxFit.cover)
                            else
                              Container(
                                color: Colors.black87,
                                child: const Icon(Icons.play_circle_outline, size: 48, color: Colors.white),
                              ),
                            if (isVideo)
                              const Positioned(
                                bottom: 4,
                                right: 4,
                                child: Icon(Icons.videocam, size: 16, color: Colors.white70),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
