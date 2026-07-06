import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import '../../../../bridge/flux_bridge.dart';

/// TextViewerScreen — renders syntax highlighted files using flutter_highlight.
/// Automatically handles large files by falling back to virtual scrolling.
class TextViewerScreen extends StatefulWidget {
  final String path;
  final String format;
  final String title;

  const TextViewerScreen({
    Key? key,
    required this.path,
    required this.format,
    required this.title,
  }) : super(key: key);

  @override
  State<TextViewerScreen> createState() => _TextViewerScreenState();
}

class _TextViewerScreenState extends State<TextViewerScreen> {
  bool _isLoading = true;
  bool _isLargeFile = false;
  String _fileContent = "";
  
  // Virtual list state for large files
  int _largeFileTotalLines = 0;
  final Map<int, String> _lineCache = {};

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    try {
      final file = File(widget.path);
      if (!await file.exists()) {
        setState(() {
          _fileContent = "File not found: ${widget.path}";
          _isLoading = false;
        });
        return;
      }

      final size = await file.length();
      // If file is > 1.5MB, handle it as a large file to prevent UI freeze / OOM
      if (size > 1.5 * 1024 * 1024) {
        // Read native line counts or estimate
        final content = await FluxBridge.getFileContent(widget.path);
        final lineCount = '\n'.allMatches(content).length + 1;
        setState(() {
          _isLargeFile = true;
          _largeFileTotalLines = lineCount;
          _isLoading = false;
        });
      } else {
        final content = await FluxBridge.getFileContent(widget.path);
        setState(() {
          _fileContent = content;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _fileContent = "Failed to read file: $e";
        _isLoading = false;
      });
    }
  }

  /// Maps internal FileFormat names to highlight.js supported language tags
  String _mapLanguage(String format) {
    final fmt = format.toLowerCase().replaceAll('code', '');
    switch (fmt) {
      case 'kotlin': return 'kotlin';
      case 'java': return 'java';
      case 'python': return 'python';
      case 'js':
      case 'javascript': return 'javascript';
      case 'ts':
      case 'typescript': return 'typescript';
      case 'dart': return 'dart';
      case 'cpp': return 'cpp';
      case 'c': return 'cpp';
      case 'rust': return 'rust';
      case 'go': return 'go';
      case 'swift': return 'swift';
      case 'php': return 'php';
      case 'ruby': return 'ruby';
      case 'bash': return 'bash';
      case 'css': return 'css';
      case 'r': return 'r';
      case 'json': return 'json';
      case 'xml': return 'xml';
      case 'yaml': return 'yaml';
      case 'toml': return 'toml';
      case 'sql': return 'sql';
      case 'markdown': return 'markdown';
      case 'html': return 'xml';
      default: return 'plaintext';
    }
  }

  // ── Render Helpers ─────────────────────────────────────────────────────────

  Widget _buildHighlightView() {
    final language = _mapLanguage(widget.format);
    return InteractiveViewer(
      constrained: false,
      maxScale: 4.0,
      minScale: 1.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: HighlightView(
          _fileContent,
          language: language,
          theme: vs2015Theme,
          padding: EdgeInsets.zero,
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildLargeFileView() {
    // Virtual Scroll for large files
    return ListView.builder(
      itemCount: _largeFileTotalLines,
      itemExtent: 22.0, // Fixed height per line for O(1) layout seeks
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        return FutureBuilder<String>(
          future: _getLineTextCached(index),
          builder: (context, snapshot) {
            final lineText = snapshot.data ?? "...";
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Gutter number column
                Container(
                  width: 56,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 12),
                  color: const Color(0xFF181818),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFF858585),
                    ),
                  ),
                ),
                // Gutter border line
                Container(width: 1, color: const Color(0xFF2B2B2B)),
                const SizedBox(width: 8),
                // Text Line
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      lineText,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Color(0xFFD4D4D4),
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String> _getLineTextCached(int lineIndex) async {
    if (_lineCache.containsKey(lineIndex)) {
      return _lineCache[lineIndex]!;
    }
    // Fetch a block of 50 lines to populate cache ahead of scroll, minimizing bridge traffic
    final blockStart = (lineIndex ~/ 50) * 50;
    try {
      final lines = await FluxBridge.getFileLines(widget.path, blockStart, 50);
      for (int i = 0; i < lines.length; i++) {
        _lineCache[blockStart + i] = lines[i];
      }
    } catch (e) {
      debugPrint('Failed to load line range starting at $blockStart: $e');
    }
    return _lineCache[lineIndex] ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181818),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF2B2B2B),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF3C3C3C)),
            ),
            child: Center(
              child: Text(
                _isLargeFile ? 'LARGE LOG' : widget.format.toUpperCase().replaceAll('CODE', ''),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
              ),
            )
          : (_isLargeFile ? _buildLargeFileView() : _buildHighlightView()),
    );
  }
}
