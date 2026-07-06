import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../bridge/flux_bridge.dart';
import '../viewer_router.dart';

class ArchiveViewerScreen extends StatefulWidget {
  final String path;
  final String title;

  const ArchiveViewerScreen({
    Key? key,
    required this.path,
    required this.title,
  }) : super(key: key);

  @override
  State<ArchiveViewerScreen> createState() => _ArchiveViewerScreenState();
}

class _ArchiveViewerScreenState extends State<ArchiveViewerScreen> {
  List<dynamic> _entries = [];
  List<dynamic> _filteredEntries = [];
  bool _isLoading = true;
  String _errorMsg = "";

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    try {
      final jsonStr = await FluxBridge.getArchiveEntries(widget.path);
      final list = json.decode(jsonStr) as List;
      setState(() {
        _entries = list;
        _filteredEntries = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = "Failed to read archive: $e";
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredEntries = _entries;
      } else {
        _filteredEntries = _entries.where((entry) {
          final name = entry['name'] as String? ?? '';
          return name.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _openEntry(Map<String, dynamic> entry) async {
    final entryName = entry['name'] as String;
    final isDir = entry['isDir'] as bool? ?? false;
    if (isDir) return;

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF00BCD4))),
      ),
    );

    try {
      // Create cache file
      final tempDir = Directory('${Directory.systemTemp.path}/flux_archive_cache');
      if (!tempDir.existsSync()) {
        tempDir.createSync(recursive: true);
      }
      
      final cleanFileName = entryName.split('/').last;
      final tempFile = File('${tempDir.path}/$cleanFileName');

      final success = await FluxBridge.extractArchiveEntry(widget.path, entryName, tempFile.path);
      
      // Pop loading dialog
      Navigator.pop(context);

      if (success) {
        // Route recursively using ViewerRouter!
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ViewerRouter(
              path: tempFile.path,
              overrideTitle: cleanFileName,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to extract $cleanFileName')),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Pop loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error extracting file: $e')),
      );
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

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
          widget.title,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF00BCD4))))
          : _errorMsg.isNotEmpty
              ? Center(child: Text(_errorMsg, style: const TextStyle(color: Colors.white54)))
              : Column(
                  children: [
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        onChanged: _onSearchChanged,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search archive files...',
                          hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white30, size: 20),
                          filled: true,
                          fillColor: const Color(0xFF161616),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    // Entries flat list
                    Expanded(
                      child: _filteredEntries.isEmpty
                          ? const Center(child: Text('No Files Found', style: TextStyle(color: Colors.white30)))
                          : ListView.builder(
                              itemCount: _filteredEntries.length,
                              itemBuilder: (context, index) {
                                final entry = _filteredEntries[index] as Map<String, dynamic>;
                                valName = entry['name'] as String? ?? '';
                                final isDir = entry['isDir'] as bool? ?? false;
                                valSize = entry['size'] as int? ?? 0;

                                return ListTile(
                                  leading: Icon(
                                    isDir ? Icons.folder_rounded : Icons.insert_drive_file_rounded,
                                    color: isDir ? const Color(0xFF00BCD4) : Colors.white54,
                                    size: 22,
                                  ),
                                  title: Text(
                                    valName,
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: isDir
                                      ? null
                                      : Text(
                                          _formatBytes(valSize),
                                          style: const TextStyle(color: Colors.white30, fontSize: 11),
                                        ),
                                  trailing: isDir
                                      ? null
                                      : const Icon(Icons.chevron_right_rounded, color: Colors.white24),
                                  onTap: () => _openEntry(entry),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
  
  late String valName;
  late int valSize;
}
