import 'package:flutter/material.dart';

/// Returns the asset path for the colorful filetype PNG icon
/// corresponding to [extension] (e.g. 'pdf', 'mp4', 'docx').
///
/// All icons live under `assets/pngicons/`.
String fileTypeIconPath(String extension) {
  switch (extension.toLowerCase().trim()) {
    // Documents
    case 'pdf':
      return 'assets/pngicons/PDF.png';
    case 'doc':
      return 'assets/pngicons/DOC.png';
    case 'docx':
      return 'assets/pngicons/DOCX.png';
    case 'xls':
    case 'xlsx':
      return 'assets/pngicons/XSL.png';
    case 'csv':
      return 'assets/pngicons/CSV.png';
    case 'ppt':
    case 'pptx':
      return 'assets/pngicons/PPT.png';
    case 'txt':
    case 'md':
    case 'log':
      return 'assets/pngicons/TXT.png';
    case 'xml':
      return 'assets/pngicons/XML.png';
    case 'html':
    case 'htm':
      return 'assets/pngicons/HTML.png';
    case 'svg':
      return 'assets/pngicons/SVG.png';
    case 'java':
    case 'json':
    case 'yaml':
    case 'yml':
    case 'dart':
    case 'py':
    case 'js':
    case 'ts':
    case 'kt':
    case 'swift':
    case 'cpp':
    case 'c':
    case 'h':
    case 'sql':
      return 'assets/pngicons/JAVA.png';
    case 'pub':
      return 'assets/pngicons/PUB.png';
    case 'rss':
      return 'assets/pngicons/RSS.png';

    // Images
    case 'jpg':
    case 'jpeg':
      return 'assets/pngicons/JPG.png';
    case 'png':
      return 'assets/pngicons/PNG.png';
    case 'gif':
      return 'assets/pngicons/GIFF.png';
    case 'bmp':
      return 'assets/pngicons/BMP.png';
    case 'tiff':
    case 'tif':
      return 'assets/pngicons/TIFF.png';
    case 'raw':
    case 'cr2':
    case 'nef':
      return 'assets/pngicons/RAW.png';
    case 'psd':
      return 'assets/pngicons/PSD.png';
    case 'ai':
      return 'assets/pngicons/AI.png';
    case 'eps':
      return 'assets/pngicons/EPS.png';
    case 'cdr':
    case 'crd':
      return 'assets/pngicons/CRD.png';
    case 'dwg':
      return 'assets/pngicons/DWG.png';
    case 'ps':
      return 'assets/pngicons/PS.png';

    // Video
    case 'mp4':
    case 'm4v':
      return 'assets/pngicons/MP4.png';
    case 'avi':
      return 'assets/pngicons/AVI.png';
    case 'mov':
    case 'qt':
      return 'assets/pngicons/MOV.png';
    case 'flv':
      return 'assets/pngicons/FLV.png';
    case 'mpeg':
    case 'mpg':
      return 'assets/pngicons/MPEG.png';
    case 'mkv':
    case 'webm':
    case 'wmv':
      return 'assets/pngicons/AVI.png';

    // Audio
    case 'mp3':
      return 'assets/pngicons/MP3.png';
    case 'wav':
      return 'assets/pngicons/WAV.png';
    case 'wma':
      return 'assets/pngicons/WMA.png';
    case 'mid':
    case 'midi':
      return 'assets/pngicons/MID.png';
    case 'aac':
    case 'flac':
    case 'ogg':
    case 'm4a':
      return 'assets/pngicons/MP3.png';

    // Archives
    case 'zip':
      return 'assets/pngicons/ZIP.png';
    case 'rar':
      return 'assets/pngicons/RAR.png';
    case '7z':
    case 'tar':
    case 'gz':
    case 'bz2':
      return 'assets/pngicons/ZIP.png';
    case 'iso':
      return 'assets/pngicons/ISO.png';
    case 'dll':
      return 'assets/pngicons/DLL.png';
    case 'exe':
      return 'assets/pngicons/EXE.png';
    case 'mdb':
    case 'db':
    case 'sqlite':
      return 'assets/pngicons/MDB.png';

    // Default
    default:
      return 'assets/pngicons/TXT.png';
  }
}

/// A widget that renders the correct colorful file-type icon
/// for a given file [extension].
///
/// Usage:
/// ```dart
/// FileTypeIcon(extension: 'pdf', size: 40)
/// ```
class FileTypeIcon extends StatelessWidget {
  final String extension;
  final double size;

  const FileTypeIcon({
    super.key,
    required this.extension,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      fileTypeIconPath(extension),
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
