import 'dart:io';
import 'package:flutter/material.dart';

class HexViewerScreen extends StatefulWidget {
  final String path;
  final String title;

  const HexViewerScreen({
    Key? key,
    required this.path,
    required this.title,
  }) : super(key: key);

  @override
  State<HexViewerScreen> createState() => _HexViewerScreenState();
}

class _HexViewerScreenState extends State<HexViewerScreen> {
  int _fileSize = 0;
  bool _isLoading = true;
  String _errorMsg = "";

  // Chunk pagination cache
  final Map<int, List<int>> _chunkCache = {};
  static const int chunkSize = 256; // 16 lines * 16 bytes per line

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    try {
      final file = File(widget.path);
      if (!file.existsSync()) {
        setState(() {
          _errorMsg = "File does not exist";
          _isLoading = false;
        });
        return;
      }
      final size = await file.length();
      setState(() {
        _fileSize = size;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = "Failed to load binary metadata: $e";
        _isLoading = false;
      });
    }
  }

  Future<List<int>> _fetchChunk(int chunkIndex) async {
    if (_chunkCache.containsKey(chunkIndex)) {
      return _chunkCache[chunkIndex]!;
    }

    try {
      final start = chunkIndex * chunkSize;
      final file = File(widget.path);
      
      // Read bytes range directly
      final raf = await file.open(mode: FileMode.read);
      await raf.setPosition(start);
      final bytes = await raf.read(chunkSize);
      await raf.close();

      _chunkCache[chunkIndex] = bytes;
      return bytes;
    } catch (_) {
      return [];
    }
  }

  String _formatOffset(int offset) {
    return offset.toRadixString(16).padLeft(8, '0').toUpperCase();
  }

  String _formatHexCell(int val) {
    return val.toRadixString(16).padLeft(2, '0').toUpperCase();
  }

  String _formatAsciiCell(int val) {
    if (val >= 32 && val <= 126) {
      return String.fromCharCode(val);
    }
    return '.';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF00BCD4)))),
      );
    }

    if (_errorMsg.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        body: Center(child: Text(_errorMsg, style: const TextStyle(color: Colors.white54))),
      );
    }

    // Number of lines: each line displays 16 bytes
    final lineCount = (_fileSize / 16).ceil();

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
          widget.title,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView.builder(
        itemCount: lineCount.clamp(0, 5000), // Cap list preview for extremely long binary files safety
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemBuilder: (context, lineIndex) {
          final chunkIndex = lineIndex ~/ 16;
          final lineInChunk = lineIndex % 16;
          final startOffset = lineIndex * 16;

          return FutureBuilder<List<int>>(
            future: _fetchChunk(chunkIndex),
            builder: (context, snapshot) {
              final bytes = snapshot.data;
              if (bytes == null) {
                return const SizedBox(height: 20);
              }

              final lineBytesStart = lineInChunk * 16;
              final lineBytes = bytes.skip(lineBytesStart).take(16).toList();

              if (lineBytes.isEmpty) return const SizedBox.shrink();

              // Build hex string columns
              final hexParts = List<String>.generate(16, (i) {
                if (i < lineBytes.length) {
                  return _formatHexCell(lineBytes[i]);
                }
                return "  ";
              });

              // Build ASCII string columns
              final asciiParts = List<String>.generate(16, (i) {
                if (i < lineBytes.length) {
                  return _formatAsciiCell(lineBytes[i]);
                }
                return " ";
              });

              final hexStr = "${hexParts.take(8).join(' ')}  ${hexParts.skip(8).join(' ')}";
              final asciiStr = asciiParts.join('');

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 12,
                      color: Colors.white30,
                    ),
                    children: [
                      // Offset
                      TextSpan(
                        text: '${_formatOffset(startOffset)}:  ',
                        style: const TextStyle(color: Color(0xFF00BCD4)),
                      ),
                      // Hex content
                      TextSpan(
                        text: '$hexStr  ',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      // ASCII representation
                      TextSpan(
                        text: '|$asciiStr|',
                        style: const TextStyle(color: Colors.greenAccent),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
