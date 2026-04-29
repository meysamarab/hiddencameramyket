import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../l10n/app_localizations.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<File> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final entities = await directory.list().toList();
    
    setState(() {
      _files = entities
          .whereType<File>()
          .where((f) => f.path.endsWith('.mp4') || f.path.endsWith('.jpg'))
          .toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      _isLoading = false;
    });
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
                        // Open file
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (!isVideo)
                            Image.file(file, fit: BoxFit.cover)
                          else
                            Container(
                              color: Colors.black87,
                              child: const Icon(Icons.play_circle_outline, size: 48),
                            ),
                          if (isVideo)
                            const Positioned(
                              bottom: 4,
                              right: 4,
                              child: Icon(Icons.videocam, size: 16, color: Colors.white70),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
