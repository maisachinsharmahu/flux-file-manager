/// FileFormat enum — mirrors the Kotlin FileFormat exactly.
/// Every format dispatch in ViewerRouter uses this.
enum FileFormat {
  // Documents
  pdf,
  docx, doc,
  xlsx, xls,
  pptx, ppt,
  odt, ods,
  rtf,

  // Images
  jpeg, png, webp, gif, heic, heif, bmp, svg, avif, dng,

  // Video
  videoMp4, videoMkv, videoAvi, videoMov, videoWebm, video3gp,

  // Audio
  audioMp3, audioFlac, audioAac, audioOgg, audioWav, audioOpus, audioM4a,

  // Text / Code
  plainText,
  markdown,
  html,
  codeKotlin, codeJava, codePython, codeJs, codeTs, codeDart,
  codeC, codeCpp, codeRust, codeGo, codeSwift, codePhp, codeRuby, codeBash,
  codeCss, codeR,

  // Data
  json, xml, yaml, csv, tsv, toml, ini, env, log, sql,

  // Database
  sqlite,

  // Archives
  zip, jar, apk, aar, epub, rar, sevenZip,

  // Fonts
  fontTtf, fontOtf, fontWoff, fontWoff2,

  // Fallback
  binary,
  unknown;

  bool get isImage => [jpeg, png, webp, gif, heic, heif, bmp, svg, avif, dng].contains(this);
  bool get isVideo => [videoMp4, videoMkv, videoAvi, videoMov, videoWebm, video3gp].contains(this);
  bool get isAudio => [audioMp3, audioFlac, audioAac, audioOgg, audioWav, audioOpus, audioM4a].contains(this);
  bool get isOffice => [docx, doc, xlsx, xls, pptx, ppt, odt, ods, rtf].contains(this);
  bool get isArchive => [zip, jar, apk, aar, epub, rar, sevenZip].contains(this);
  bool get isFont => [fontTtf, fontOtf, fontWoff, fontWoff2].contains(this);
  bool get isCode => name.startsWith('code');
  bool get isText => [plainText, markdown, html, json, xml, yaml, csv, tsv, toml, ini, env, log, sql].contains(this) || isCode;

  String get displayName {
    switch (this) {
      case FileFormat.pdf: return 'PDF';
      case FileFormat.docx: case FileFormat.doc: return 'Word Document';
      case FileFormat.xlsx: case FileFormat.xls: return 'Spreadsheet';
      case FileFormat.pptx: case FileFormat.ppt: return 'Presentation';
      case FileFormat.jpeg: return 'JPEG Image';
      case FileFormat.png: return 'PNG Image';
      case FileFormat.svg: return 'SVG Vector';
      case FileFormat.videoMp4: case FileFormat.videoMkv: case FileFormat.videoAvi:
      case FileFormat.videoMov: case FileFormat.videoWebm: case FileFormat.video3gp: return 'Video';
      case FileFormat.audioMp3: case FileFormat.audioFlac: case FileFormat.audioAac:
      case FileFormat.audioOgg: case FileFormat.audioWav: case FileFormat.audioOpus:
      case FileFormat.audioM4a: return 'Audio';
      case FileFormat.plainText: return 'Plain Text';
      case FileFormat.markdown: return 'Markdown';
      case FileFormat.html: return 'HTML';
      case FileFormat.json: return 'JSON';
      case FileFormat.xml: return 'XML';
      case FileFormat.csv: return 'CSV Spreadsheet';
      case FileFormat.sqlite: return 'SQLite Database';
      case FileFormat.zip: case FileFormat.jar: return 'ZIP Archive';
      case FileFormat.apk: return 'Android Package';
      case FileFormat.epub: return 'E-Book';
      case FileFormat.rar: return 'RAR Archive';
      case FileFormat.sevenZip: return '7-Zip Archive';
      default:
        if (isCode) return 'Source Code';
        if (isFont) return 'Font File';
        return 'File';
    }
  }
}

/// Detect FileFormat from file extension — O(1) lookup.
/// Magic-byte detection is done on the Kotlin side; this is for quick UI use.
FileFormat detectFormatFromPath(String path) {
  final ext = path.split('.').last.toLowerCase();
  return _extensionMap[ext] ?? FileFormat.unknown;
}

/// Detect code language name for display in the code viewer.
String detectLanguageName(String path) {
  final ext = path.split('.').last.toLowerCase();
  return _languageNames[ext] ?? 'Text';
}

/// Detect format from Kotlin-returned format name string.
FileFormat formatFromKotlinName(String name) {
  final lower = name.toLowerCase().replaceAll('_', '');
  return _kotlinNameMap[lower] ?? FileFormat.unknown;
}

const _extensionMap = <String, FileFormat>{
  'pdf': FileFormat.pdf,
  'docx': FileFormat.docx, 'doc': FileFormat.doc,
  'xlsx': FileFormat.xlsx, 'xls': FileFormat.xls,
  'pptx': FileFormat.pptx, 'ppt': FileFormat.ppt,
  'odt': FileFormat.odt, 'ods': FileFormat.ods,
  'rtf': FileFormat.rtf,
  'jpg': FileFormat.jpeg, 'jpeg': FileFormat.jpeg,
  'png': FileFormat.png,
  'webp': FileFormat.webp,
  'gif': FileFormat.gif,
  'bmp': FileFormat.bmp,
  'heic': FileFormat.heic, 'heif': FileFormat.heif,
  'svg': FileFormat.svg,
  'avif': FileFormat.avif,
  'dng': FileFormat.dng, 'raw': FileFormat.dng,
  'mp4': FileFormat.videoMp4, 'm4v': FileFormat.videoMp4,
  'mkv': FileFormat.videoMkv,
  'avi': FileFormat.videoAvi,
  'mov': FileFormat.videoMov,
  'webm': FileFormat.videoWebm,
  '3gp': FileFormat.video3gp,
  'mp3': FileFormat.audioMp3,
  'flac': FileFormat.audioFlac,
  'aac': FileFormat.audioAac,
  'ogg': FileFormat.audioOgg,
  'wav': FileFormat.audioWav,
  'opus': FileFormat.audioOpus,
  'm4a': FileFormat.audioM4a,
  'txt': FileFormat.plainText,
  'log': FileFormat.log,
  'md': FileFormat.markdown, 'markdown': FileFormat.markdown,
  'html': FileFormat.html, 'htm': FileFormat.html,
  'kt': FileFormat.codeKotlin,
  'java': FileFormat.codeJava,
  'py': FileFormat.codePython,
  'js': FileFormat.codeJs,
  'ts': FileFormat.codeTs,
  'dart': FileFormat.codeDart,
  'c': FileFormat.codeC,
  'cpp': FileFormat.codeCpp, 'cc': FileFormat.codeCpp, 'cxx': FileFormat.codeCpp,
  'h': FileFormat.codeC, 'hpp': FileFormat.codeCpp,
  'rs': FileFormat.codeRust,
  'go': FileFormat.codeGo,
  'swift': FileFormat.codeSwift,
  'php': FileFormat.codePhp,
  'rb': FileFormat.codeRuby,
  'sh': FileFormat.codeBash, 'bash': FileFormat.codeBash,
  'css': FileFormat.codeCss,
  'r': FileFormat.codeR,
  'json': FileFormat.json,
  'xml': FileFormat.xml,
  'yaml': FileFormat.yaml, 'yml': FileFormat.yaml,
  'csv': FileFormat.csv,
  'tsv': FileFormat.tsv,
  'toml': FileFormat.toml,
  'ini': FileFormat.ini, 'conf': FileFormat.ini,
  'env': FileFormat.env,
  'sql': FileFormat.sql,
  'db': FileFormat.sqlite, 'sqlite': FileFormat.sqlite, 'sqlite3': FileFormat.sqlite,
  'zip': FileFormat.zip,
  'jar': FileFormat.jar,
  'apk': FileFormat.apk,
  'aar': FileFormat.aar,
  'epub': FileFormat.epub,
  'rar': FileFormat.rar,
  '7z': FileFormat.sevenZip,
  'ttf': FileFormat.fontTtf,
  'otf': FileFormat.fontOtf,
  'woff': FileFormat.fontWoff,
  'woff2': FileFormat.fontWoff2,
};

const _languageNames = <String, String>{
  'kt': 'Kotlin', 'kts': 'Kotlin',
  'java': 'Java',
  'py': 'Python',
  'js': 'JavaScript', 'mjs': 'JavaScript',
  'ts': 'TypeScript',
  'dart': 'Dart',
  'c': 'C', 'h': 'C',
  'cpp': 'C++', 'cc': 'C++', 'cxx': 'C++', 'hpp': 'C++',
  'rs': 'Rust',
  'go': 'Go',
  'swift': 'Swift',
  'php': 'PHP',
  'rb': 'Ruby',
  'sh': 'Shell', 'bash': 'Bash',
  'css': 'CSS',
  'r': 'R',
  'sql': 'SQL',
  'html': 'HTML', 'htm': 'HTML',
  'xml': 'XML',
  'json': 'JSON',
  'yaml': 'YAML', 'yml': 'YAML',
  'toml': 'TOML',
  'md': 'Markdown',
};

const _kotlinNameMap = <String, FileFormat>{
  'pdf': FileFormat.pdf,
  'docx': FileFormat.docx, 'doc': FileFormat.doc,
  'xlsx': FileFormat.xlsx, 'xls': FileFormat.xls,
  'pptx': FileFormat.pptx, 'ppt': FileFormat.ppt,
  'odt': FileFormat.odt, 'ods': FileFormat.ods,
  'rtf': FileFormat.rtf,
  'jpeg': FileFormat.jpeg,
  'png': FileFormat.png,
  'webp': FileFormat.webp,
  'gif': FileFormat.gif,
  'bmp': FileFormat.bmp,
  'heic': FileFormat.heic, 'heif': FileFormat.heif,
  'svg': FileFormat.svg,
  'avif': FileFormat.avif,
  'dng': FileFormat.dng,
  'videomp4': FileFormat.videoMp4,
  'videomkv': FileFormat.videoMkv,
  'videoavi': FileFormat.videoAvi,
  'videomov': FileFormat.videoMov,
  'videowebm': FileFormat.videoWebm,
  'video3gp': FileFormat.video3gp,
  'audiomp3': FileFormat.audioMp3,
  'audioflac': FileFormat.audioFlac,
  'audioaac': FileFormat.audioAac,
  'audioogg': FileFormat.audioOgg,
  'audiowav': FileFormat.audioWav,
  'audioopus': FileFormat.audioOpus,
  'audiom4a': FileFormat.audioM4a,
  'plaintext': FileFormat.plainText,
  'markdown': FileFormat.markdown,
  'html': FileFormat.html,
  'codekotlin': FileFormat.codeKotlin,
  'codejava': FileFormat.codeJava,
  'codepython': FileFormat.codePython,
  'codejs': FileFormat.codeJs,
  'codets': FileFormat.codeTs,
  'codedart': FileFormat.codeDart,
  'codec': FileFormat.codeC,
  'codecpp': FileFormat.codeCpp,
  'coderust': FileFormat.codeRust,
  'codego': FileFormat.codeGo,
  'codeswift': FileFormat.codeSwift,
  'codephp': FileFormat.codePhp,
  'coderuby': FileFormat.codeRuby,
  'codebash': FileFormat.codeBash,
  'codecss': FileFormat.codeCss,
  'coder': FileFormat.codeR,
  'json': FileFormat.json,
  'xml': FileFormat.xml,
  'yaml': FileFormat.yaml,
  'csv': FileFormat.csv,
  'tsv': FileFormat.tsv,
  'toml': FileFormat.toml,
  'ini': FileFormat.ini,
  'env': FileFormat.env,
  'log': FileFormat.log,
  'sql': FileFormat.sql,
  'sqlite': FileFormat.sqlite,
  'zip': FileFormat.zip,
  'jar': FileFormat.jar,
  'apk': FileFormat.apk,
  'aar': FileFormat.aar,
  'epub': FileFormat.epub,
  'rar': FileFormat.rar,
  'sevenzip': FileFormat.sevenZip,
  'fontttf': FileFormat.fontTtf,
  'fontotf': FileFormat.fontOtf,
  'fontwoff': FileFormat.fontWoff,
  'fontwoff2': FileFormat.fontWoff2,
  'binary': FileFormat.binary,
  'unknown': FileFormat.unknown,
};
