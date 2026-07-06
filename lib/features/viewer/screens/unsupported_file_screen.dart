import 'package:flutter/material.dart';
import '../file_format.dart';

/// UnsupportedFileScreen — shown for truly binary/unknown files.
///
/// Displays file metadata. In Phase V10, this will show a hex viewer.
/// This is the "no crash on any file type" requirement from doc2, Ch. 16.
class UnsupportedFileScreen extends StatelessWidget {
  final String path;
  final FileFormat format;
  final String title;

  const UnsupportedFileScreen({
    super.key,
    required this.path,
    required this.format,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = path.split('/').last;
    final ext = fileName.contains('.') ? fileName.split('.').last.toUpperCase() : '?';

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Extension badge
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.insert_drive_file_rounded,
                      color: Color(0xFF616161), size: 28),
                    const SizedBox(height: 4),
                    Text(
                      ext.length > 4 ? ext.substring(0, 4) : ext,
                      style: const TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Cannot preview this file',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No viewer available for .$ext files yet.\nA hex viewer will be available in Phase V10.',
                style: const TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // File path
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded, color: Color(0xFF616161), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        path,
                        style: const TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
