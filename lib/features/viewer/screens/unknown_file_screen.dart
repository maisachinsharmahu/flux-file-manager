import 'package:flutter/material.dart';
import '../file_format.dart';

/// UnknownFileScreen — placeholder for formats not yet implemented.
///
/// Shows the file name, detected format, and which build phase will implement it.
/// This screen is replaced as each phase (V2–V8) is completed.
///
/// Rule: Every format MUST show something within 100ms (doc2, Ch. 16).
/// This placeholder satisfies that requirement during development.
class UnknownFileScreen extends StatelessWidget {
  final String path;
  final FileFormat format;
  final String title;
  final String phase;

  const UnknownFileScreen({
    super.key,
    required this.path,
    required this.format,
    required this.title,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
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
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _phaseColor(phase).withAlpha(30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _phaseColor(phase).withAlpha(80)),
            ),
            child: Text(
              'Phase $phase',
              style: TextStyle(
                color: _phaseColor(phase),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Format icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _formatColor(format).withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _formatColor(format).withAlpha(60),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  _formatIcon(format),
                  color: _formatColor(format),
                  size: 36,
                ),
              ),
              const SizedBox(height: 24),

              // Format name
              Text(
                format.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),

              // File path (truncated)
              Text(
                path.length > 60 ? '…${path.substring(path.length - 57)}' : path,
                style: TextStyle(
                  color: Colors.white.withAlpha(100),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // "Coming in Phase X" card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.construction_rounded,
                          color: _phaseColor(phase), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Viewer coming in Phase $phase',
                          style: TextStyle(
                            color: _phaseColor(phase),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _phaseDescription(phase, format),
                      style: TextStyle(
                        color: Colors.white.withAlpha(150),
                        fontSize: 13,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
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

  Color _phaseColor(String phase) {
    return switch (phase) {
      'V1' => const Color(0xFF6C63FF),
      'V2' => const Color(0xFF00BCD4),
      'V3' => const Color(0xFF4CAF50),
      'V4' => const Color(0xFFFF5722),
      'V5' => const Color(0xFFFF9800),
      'V6' => const Color(0xFF9C27B0),
      'V7' => const Color(0xFF2196F3),
      'V8' => const Color(0xFFE91E63),
      _ => const Color(0xFF757575),
    };
  }

  Color _formatColor(FileFormat f) {
    if (f.isImage) return const Color(0xFF00BCD4);
    if (f.isVideo) return const Color(0xFFFF5722);
    if (f.isAudio) return const Color(0xFF9C27B0);
    if (f == FileFormat.pdf) return const Color(0xFFFF5722);
    if (f.isOffice) return const Color(0xFF2196F3);
    if (f.isCode) return const Color(0xFF4CAF50);
    if (f.isArchive) return const Color(0xFFFF9800);
    if (f.isFont) return const Color(0xFFE91E63);
    return const Color(0xFF9E9E9E);
  }

  IconData _formatIcon(FileFormat f) {
    if (f.isImage) return Icons.image_rounded;
    if (f.isVideo) return Icons.play_circle_rounded;
    if (f.isAudio) return Icons.music_note_rounded;
    if (f == FileFormat.pdf) return Icons.picture_as_pdf_rounded;
    if (f == FileFormat.docx || f == FileFormat.doc) return Icons.article_rounded;
    if (f == FileFormat.xlsx || f == FileFormat.xls) return Icons.table_chart_rounded;
    if (f == FileFormat.pptx || f == FileFormat.ppt) return Icons.slideshow_rounded;
    if (f.isCode || f == FileFormat.json || f == FileFormat.xml) return Icons.code_rounded;
    if (f.isArchive) return Icons.folder_zip_rounded;
    if (f.isFont) return Icons.font_download_rounded;
    if (f == FileFormat.sqlite) return Icons.storage_rounded;
    return Icons.insert_drive_file_rounded;
  }

  String _phaseDescription(String phase, FileFormat format) {
    return switch (phase) {
      'V2' => 'Image & video viewer using BitmapRegionDecoder + MediaPlayer.\n< 80ms first paint, 60fps scroll, zero external libraries.',
      'V3' => 'Text & code viewer using Canvas LineRenderer + MmapSource.\n< 30ms first paint, 60fps scroll for 300,000-line files.',
      'V4' => 'PDF viewer using Android PdfRenderer API + tile cache.\n< 80ms first tile, hardware-accelerated, annotation support.',
      'V5' => 'Office viewer using OOXML ZIP+XML parser + Canvas layout.\n< 150ms open, 60fps scroll, zero POI/Apache library dependency.',
      'V6' => 'Data viewer: streaming JSON/XML tree, virtual CSV grid, SQLite browser.\n< 100ms open for 50MB files.',
      'V7' => 'Archive browser + HTML WebView + APK inspector.\nZIP central directory read in < 30ms, no extraction on open.',
      'V8' => 'SVG renderer, font preview, Markdown, EPUB + edit/save for all formats.',
      _ => 'Coming soon.',
    };
  }
}
