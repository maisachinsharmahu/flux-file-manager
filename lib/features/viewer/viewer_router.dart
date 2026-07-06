import 'package:flutter/material.dart';
import 'file_format.dart';
import 'screens/unknown_file_screen.dart';
import 'screens/image_viewer_screen.dart';
import 'screens/video_player_screen.dart';
import 'screens/audio_player_screen.dart';

import 'screens/text_viewer_screen.dart';

import 'screens/pdf_viewer_screen.dart';

import 'screens/office_viewer_screens.dart';
import 'screens/data_viewer_screens.dart';
import 'screens/html_viewer_screen.dart';
import 'screens/archive_viewer_screen.dart';
import 'screens/hex_viewer_screen.dart';
import 'screens/svg_viewer_screen.dart';
import 'screens/font_viewer_screen.dart';
import 'screens/apk_info_screen.dart';
import 'screens/epub_viewer_screen.dart';
import 'screens/markdown_viewer_screen.dart';
import 'widgets/error_boundary.dart';

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

    return ViewerErrorBoundary(
      child: switch (format) {
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
          SvgViewerScreen(path: path, title: title),

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
          MarkdownViewerScreen(path: path, title: title),
        FileFormat.html =>
          HtmlViewerScreen(path: path, title: title),
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
          ArchiveViewerScreen(path: path, title: title),
        FileFormat.apk =>
          ApkInfoScreen(path: path, title: title),
        FileFormat.epub =>
          EpubViewerScreen(path: path, title: title),
        FileFormat.rar || FileFormat.sevenZip =>
          ArchiveViewerScreen(path: path, title: title),

        // ── Fonts ─────────────────────────────────────────────────────────────
        FileFormat.fontTtf || FileFormat.fontOtf ||
        FileFormat.fontWoff || FileFormat.fontWoff2 =>
          FontViewerScreen(path: path, title: title),

        // ── Unknown / Binary (Hex Fallback) ───────────────────────────────────
        _ => HexViewerScreen(path: path, title: title),
      },
    );
  }

  String _filenameFromPath(String path) {
    return path.split('/').last;
  }
}
