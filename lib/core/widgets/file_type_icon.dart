import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Returns the asset path for the colorful filetype SVG icon
/// corresponding to [extension] (e.g. 'pdf', 'mp4', 'docx').
///
/// All icons live under `assets/filetype/`.
String fileTypeIconPath(String extension) {
  switch (extension.toLowerCase().trim()) {
    // Documents
    case 'pdf':
      return 'assets/filetype/PDF.svg';
    case 'doc':
      return 'assets/filetype/DOC.svg';
    case 'docx':
      return 'assets/filetype/DOCX.svg';
    case 'xls':
    case 'xlsx':
      return 'assets/filetype/XSL.svg';
    case 'csv':
      return 'assets/filetype/CSV.svg';
    case 'ppt':
    case 'pptx':
      return 'assets/filetype/PPT.svg';
    case 'txt':
    case 'md':
    case 'log':
      return 'assets/filetype/TXT.svg';
    case 'xml':
      return 'assets/filetype/XML.svg';
    case 'html':
    case 'htm':
      return 'assets/filetype/HTML.svg';
    case 'svg':
      return 'assets/filetype/SVG.svg';
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
      return 'assets/filetype/JAVA.svg';
    case 'pub':
      return 'assets/filetype/PUB.svg';
    case 'rss':
      return 'assets/filetype/RSS.svg';

    // Images
    case 'jpg':
    case 'jpeg':
      return 'assets/filetype/JPG.svg';
    case 'png':
      return 'assets/filetype/PNG.svg';
    case 'gif':
      return 'assets/filetype/GIFF.svg';
    case 'bmp':
      return 'assets/filetype/BMP.svg';
    case 'tiff':
    case 'tif':
      return 'assets/filetype/TIFF.svg';
    case 'raw':
    case 'cr2':
    case 'nef':
      return 'assets/filetype/RAW.svg';
    case 'psd':
      return 'assets/filetype/PSD.svg';
    case 'ai':
      return 'assets/filetype/AI.svg';
    case 'eps':
      return 'assets/filetype/EPS.svg';
    case 'cdr':
    case 'crd':
      return 'assets/filetype/CRD.svg';
    case 'dwg':
      return 'assets/filetype/DWG.svg';
    case 'ps':
      return 'assets/filetype/PS.svg';

    // Video
    case 'mp4':
    case 'm4v':
      return 'assets/filetype/MP4.svg';
    case 'avi':
      return 'assets/filetype/AVI.svg';
    case 'mov':
    case 'qt':
      return 'assets/filetype/MOV.svg';
    case 'flv':
      return 'assets/filetype/FLV.svg';
    case 'mpeg':
    case 'mpg':
      return 'assets/filetype/MPEG.svg';
    case 'mkv':
    case 'webm':
    case 'wmv':
      return 'assets/filetype/AVI.svg';

    // Audio
    case 'mp3':
      return 'assets/filetype/MP3.svg';
    case 'wav':
      return 'assets/filetype/WAV.svg';
    case 'wma':
      return 'assets/filetype/WMA.svg';
    case 'mid':
    case 'midi':
      return 'assets/filetype/MID.svg';
    case 'aac':
    case 'flac':
    case 'ogg':
    case 'm4a':
      return 'assets/filetype/MP3.svg';

    // Archives
    case 'zip':
      return 'assets/filetype/ZIP.svg';
    case 'rar':
      return 'assets/filetype/RAR.svg';
    case '7z':
    case 'tar':
    case 'gz':
    case 'bz2':
      return 'assets/filetype/ZIP.svg';
    case 'iso':
      return 'assets/filetype/ISO.svg';
    case 'dll':
      return 'assets/filetype/DLL.svg';
    case 'exe':
      return 'assets/filetype/EXE.svg';
    case 'mdb':
    case 'db':
    case 'sqlite':
      return 'assets/filetype/MDB.svg';

    // Default — use the generic document icon
    default:
      return 'assets/filetype/TXT.svg';
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
    return SvgPicture.asset(
      fileTypeIconPath(extension),
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
