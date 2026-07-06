import 'package:flutter/material.dart';
import 'file_format.dart';
import 'screens/unknown_file_screen.dart';
import 'screens/unsupported_file_screen.dart';
import 'screens/image_viewer_screen.dart';
import 'screens/video_player_screen.dart';
import 'screens/audio_player_screen.dart';

import 'screens/text_viewer_screen.dart';

import 'screens/pdf_viewer_screen.dart';

import 'screens/office_viewer_screens.dart';
import 'screens/data_viewer_screens.dart';

export 'file_format.dart';

/// ViewerRouter — format-based screen dispatch.
///
/// From doc2, Ch. 15 ViewerRouter.dart:
///   Every file format maps to exactly one viewer screen.
///   Unknown formats fall through to UnknownFileScreen (hex viewer placeholder).
///
/// Usage:
///   Navigator.push(context, MaterialPageRoute(
///     builder: (_) => ViewerRouter(path: filePath),
///   ));
class ViewerRouter extends StatelessWidget {
  final String path;
  final String? mimeType;
  final String? overrideTitle;

  const ViewerRouter({
    super.key,
    required this.path,
    this.mimeType,
    this.overrideTitle,
  });

  @override
  Widget build(BuildContext context) {
    final format = detectFormatFromPath(path);
    final title = overrideTitle ?? _filenameFromPath(path);

    return switch (format) {
      // ── Documents ──────────────────────────────────────────────────────────
      FileFormat.pdf =>
        PdfViewerScreen(path: path, title: title),
      FileFormat.docx || FileFormat.doc =>
        DocxViewerScreen(path: path, title: title),
      FileFormat.xlsx || FileFormat.xls =>
        XlsxViewerScreen(path: path, title: title),
      FileFormat.pptx || FileFormat.ppt =>
        PptxViewerScreen(path: path, title: title),
      FileFormat.odt || FileFormat.ods =>
        UnknownFileScreen(path: path, format: format, title: title, phase: 'V5'),
      FileFormat.rtf =>
        UnknownFileScreen(path: path, format: format, title: title, phase: 'V5'),

      // ── Images ────────────────────────────────────────────────────────────
      FileFormat.jpeg || FileFormat.png || FileFormat.webp || FileFormat.gif ||
      FileFormat.heic || FileFormat.heif || FileFormat.bmp || FileFormat.avif ||
      FileFormat.dng =>
        ImageViewerScreen(path: path, title: title),
      FileFormat.svg =>
        UnknownFileScreen(path: path, format: format, title: title, phase: 'V8'),

      // ── Video ─────────────────────────────────────────────────────────────
      FileFormat.videoMp4 || FileFormat.videoMkv || FileFormat.videoAvi ||
      FileFormat.videoMov || FileFormat.videoWebm || FileFormat.video3gp =>
        VideoPlayerScreen(path: path, title: title),

      // ── Audio ─────────────────────────────────────────────────────────────
      FileFormat.audioMp3 || FileFormat.audioFlac || FileFormat.audioAac ||
      FileFormat.audioOgg || FileFormat.audioWav || FileFormat.audioOpus ||
      FileFormat.audioM4a =>
        AudioPlayerScreen(path: path, title: title),

      // ── Text & Code ───────────────────────────────────────────────────────
      FileFormat.plainText || FileFormat.log =>
        TextViewerScreen(path: path, format: format.name, title: title),
      FileFormat.markdown =>
        UnknownFileScreen(path: path, format: format, title: title, phase: 'V8'),
      FileFormat.html =>
        UnknownFileScreen(path: path, format: format, title: title, phase: 'V7'),
      _ when format.isCode =>
        TextViewerScreen(path: path, format: format.name, title: title),

      // ── Data formats ──────────────────────────────────────────────────────
      FileFormat.json =>
        JsonTreeViewerScreen(path: path, title: title),
      FileFormat.xml =>
        TextViewerScreen(path: path, format: format.name, title: title),
      FileFormat.yaml || FileFormat.toml || FileFormat.ini || FileFormat.env =>
        TextViewerScreen(path: path, format: format.name, title: title),
      FileFormat.csv || FileFormat.tsv =>
        CsvViewerScreen(path: path, title: title),
      FileFormat.sql =>
        TextViewerScreen(path: path, format: format.name, title: title),
      FileFormat.sqlite =>
        SqliteViewerScreen(path: path, title: title),

      // ── Archives ──────────────────────────────────────────────────────────
      FileFormat.zip || FileFormat.jar || FileFormat.aar =>
        UnknownFileScreen(path: path, format: format, title: title, phase: 'V7'),
      FileFormat.apk =>
        UnknownFileScreen(path: path, format: format, title: title, phase: 'V7'),
      FileFormat.epub =>
        UnknownFileScreen(path: path, format: format, title: title, phase: 'V7'),
      FileFormat.rar || FileFormat.sevenZip =>
        UnknownFileScreen(path: path, format: format, title: title, phase: 'V7'),

      // ── Fonts ─────────────────────────────────────────────────────────────
      FileFormat.fontTtf || FileFormat.fontOtf ||
      FileFormat.fontWoff || FileFormat.fontWoff2 =>
        UnknownFileScreen(path: path, format: format, title: title, phase: 'V8'),

      // ── Unknown / Binary ──────────────────────────────────────────────────
      _ => UnsupportedFileScreen(path: path, format: format, title: title),
    };
  }

  String _filenameFromPath(String path) {
    return path.split('/').last;
  }
}
