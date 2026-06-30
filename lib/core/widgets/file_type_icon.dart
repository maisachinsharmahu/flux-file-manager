import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Returns the asset path for the colorful filetype SVG icon
/// corresponding to [extension] (e.g. 'pdf', 'mp4', 'docx').
///
/// All icons live under `assets/newsv/`.
String fileTypeIconPath(String extension) {
  switch (extension.toLowerCase().trim()) {
    // Documents
    case 'pdf':
      return 'assets/newsv/PDF.svg';
    case 'doc':
      return 'assets/newsv/DOC.svg';
    case 'docx':
      return 'assets/newsv/DOCX.svg';
    case 'xls':
    case 'xlsx':
      return 'assets/newsv/XSL.svg';
    case 'csv':
      return 'assets/newsv/CSV.svg';
    case 'ppt':
    case 'pptx':
      return 'assets/newsv/PPT.svg';
    case 'txt':
    case 'md':
    case 'log':
      return 'assets/newsv/TXT.svg';
    case 'xml':
      return 'assets/newsv/XML.svg';
    case 'html':
    case 'htm':
      return 'assets/newsv/HTML.svg';
    case 'svg':
      return 'assets/newsv/SVG.svg';
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
      return 'assets/newsv/JAVA.svg';
    case 'pub':
      return 'assets/newsv/PUB.svg';
    case 'rss':
      return 'assets/newsv/RSS.svg';

    // Images
    case 'jpg':
    case 'jpeg':
      return 'assets/newsv/JPG.svg';
    case 'png':
      return 'assets/newsv/PNG.svg';
    case 'gif':
      return 'assets/newsv/GIFF.svg';
    case 'bmp':
      return 'assets/newsv/BMP.svg';
    case 'tiff':
    case 'tif':
      return 'assets/newsv/TIFF.svg';
    case 'raw':
    case 'cr2':
    case 'nef':
      return 'assets/newsv/RAW.svg';
    case 'psd':
      return 'assets/newsv/PSD.svg';
    case 'ai':
      return 'assets/newsv/AI.svg';
    case 'eps':
      return 'assets/newsv/EPS.svg';
    case 'cdr':
    case 'crd':
      return 'assets/newsv/CRD.svg';
    case 'dwg':
      return 'assets/newsv/DWG.svg';
    case 'ps':
      return 'assets/newsv/PS.svg';

    // Video
    case 'mp4':
    case 'm4v':
      return 'assets/newsv/MP4.svg';
    case 'avi':
      return 'assets/newsv/AVI.svg';
    case 'mov':
    case 'qt':
      return 'assets/newsv/MOV.svg';
    case 'flv':
      return 'assets/newsv/FLV.svg';
    case 'mpeg':
    case 'mpg':
      return 'assets/newsv/MPEG.svg';
    case 'mkv':
    case 'webm':
    case 'wmv':
      return 'assets/newsv/AVI.svg';

    // Audio
    case 'mp3':
      return 'assets/newsv/MP3.svg';
    case 'wav':
      return 'assets/newsv/WAV.svg';
    case 'wma':
      return 'assets/newsv/WMA.svg';
    case 'mid':
    case 'midi':
      return 'assets/newsv/MID.svg';
    case 'aac':
    case 'flac':
    case 'ogg':
    case 'm4a':
      return 'assets/newsv/MP3.svg';

    // Archives
    case 'zip':
      return 'assets/newsv/ZIP.svg';
    case 'rar':
      return 'assets/newsv/RAR.svg';
    case '7z':
    case 'tar':
    case 'gz':
    case 'bz2':
      return 'assets/newsv/ZIP.svg';
    case 'iso':
      return 'assets/newsv/ISO.svg';
    case 'dll':
      return 'assets/newsv/DLL.svg';
    case 'exe':
      return 'assets/newsv/EXE.svg';
    case 'apk':
      return 'assets/newsv/APK.svg';
    case 'mdb':
    case 'db':
    case 'sqlite':
      return 'assets/newsv/MDB.svg';

    // Default — generic file icon for unknown types
    default:
      return 'assets/newsv/other.svg';
  }
}

/// A widget that renders the correct colorful file-type icon
/// or a memory-efficient thumbnail image for image formats.
class FileTypeIcon extends StatelessWidget {
  final String extension;
  final String? path;
  final double size;

  const FileTypeIcon({
    super.key,
    required this.extension,
    this.path,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final isImage = const ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension.toLowerCase().trim());

    if (isImage && path != null && path!.isNotEmpty) {
      // Listing 4.3 layout pattern: strict RGB_565 decodes with 256x256 cacheWidth bounds
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(path!),
          width: size,
          height: size,
          cacheWidth: 256,
          cacheHeight: 256,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.low,
          errorBuilder: (context, error, stackTrace) {
            // Instant fallback placeholder
            return SvgPicture.asset(
              fileTypeIconPath(extension),
              width: size,
              height: size,
              fit: BoxFit.contain,
            );
          },
        ),
      );
    }

    return SvgPicture.asset(
      fileTypeIconPath(extension),
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
