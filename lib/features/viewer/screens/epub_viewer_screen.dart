import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../bridge/flux_bridge.dart';
import 'html_viewer_screen.dart';

class EpubViewerScreen extends StatefulWidget {
  final String path;
  final String title;

  const EpubViewerScreen({
    Key? key,
    required this.path,
    required this.title,
  }) : super(key: key);

  @override
  State<EpubViewerScreen> createState() => _EpubViewerScreenState();
}

class _EpubViewerScreenState extends State<EpubViewerScreen> {
  List<dynamic> _chapters = [];
  bool _isLoading = true;
  String _errorMsg = "";

  @override
  void initState() {
    super.initState();
    _loadEpubChapters();
  }

  Future<void> _loadEpubChapters() async {
    try {
      final jsonStr = await FluxBridge.getEpubChapters(widget.path);
      final list = json.decode(jsonStr) as List;
      setState(() {
        _chapters = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = "Failed to load E-book chapters: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _openChapter(Map<String, dynamic> chapter) async {
    final title = chapter['title'] as String;
    final href = chapter['href'] as String;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF00BCD4))),
      ),
    );

    try {
      // Extract specific HTML chapter in temp folder
      final tempDir = Directory('${Directory.systemTemp.path}/flux_epub_cache');
      if (!tempDir.existsSync()) {
        tempDir.createSync(recursive: true);
      }
      
      final cleanName = href.split('/').last;
      final tempFile = File('${tempDir.path}/$cleanName');

      final success = await FluxBridge.extractArchiveEntry(widget.path, href, tempFile.path);
      Navigator.pop(context); // Pop loading

      if (success) {
        // Open local HTML file inside sandboxed HtmlViewerScreen!
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HtmlViewerScreen(
              path: tempFile.path,
              title: title,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to extract chapter: $title')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
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
              : _chapters.isEmpty
                  ? const Center(child: Text('No Chapters Found', style: TextStyle(color: Colors.white30)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _chapters.length,
                      itemBuilder: (context, index) {
                        final chapter = _chapters[index] as Map<String, dynamic>;
                        final title = chapter['title'] as String;

                        return ListTile(
                          leading: Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Colors.white10,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            title,
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          trailing: const Icon(Icons.chrome_reader_mode_rounded, color: Colors.white30, size: 18),
                          onTap: () => _openChapter(chapter),
                        );
                      },
                    ),
    );
  }
}
