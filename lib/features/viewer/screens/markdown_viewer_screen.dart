import 'package:flutter/material.dart';
import '../../../../bridge/flux_bridge.dart';

class MarkdownViewerScreen extends StatefulWidget {
  final String path;
  final String title;

  const MarkdownViewerScreen({
    Key? key,
    required this.path,
    required this.title,
  }) : super(key: key);

  @override
  State<MarkdownViewerScreen> createState() => _MarkdownViewerScreenState();
}

class _MarkdownViewerScreenState extends State<MarkdownViewerScreen> {
  String _content = "";
  bool _isLoading = true;
  String _errorMsg = "";

  @override
  void initState() {
    super.initState();
    _loadMarkdown();
  }

  Future<void> _loadMarkdown() async {
    try {
      final content = await FluxBridge.getFileContent(widget.path);
      setState(() {
        _content = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = "Failed to load Markdown: $e";
        _isLoading = false;
      });
    }
  }

  List<Widget> _parseAndRenderMarkdown(String source) {
    final widgets = <Widget>[];
    final lines = source.split('\n');
    var i = 0;

    while (i < lines.length) {
      final line = lines[i];

      // Code block
      if (line.startsWith('```')) {
        final code = StringBuffer();
        i++;
        while (i < lines.length && !lines[i].startsWith('```')) {
          code.writeln(lines[i]);
          i++;
        }
        widgets.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12, width: 0.5),
          ),
          child: Text(
            code.toString(),
            style: const TextStyle(color: Colors.greenAccent, fontFamily: 'Courier', fontSize: 12),
          ),
        ));
      }
      // Headings
      else if (line.startsWith('#')) {
        var level = 0;
        while (level < line.length && line[level] == '#') {
          level++;
        }
        final text = line.substring(level).trim();
        final fontSize = (32 - (level * 3)).toDouble().clamp(14.0, 30.0);
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ));
      }
      // Horizontal rule
      else if (line.trim().length >= 3 && line.trim().replaceAll('-', '').isEmpty) {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Divider(color: Colors.white12, height: 1),
        ));
      }
      // Lists / Bullets
      else if (line.trim().startsWith('- ') || line.trim().startsWith('* ')) {
        final text = line.trim().substring(2);
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(color: Color(0xFF00BCD4), fontSize: 16)),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    children: _parseInlineSpans(text),
                  ),
                ),
              ),
            ],
          ),
        ));
      }
      // Plain paragraphs
      else if (line.trim().isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
              children: _parseInlineSpans(line),
            ),
          ),
        ));
      }

      i++;
    }

    return widgets;
  }

  List<TextSpan> _parseInlineSpans(String text) {
    final spans = <TextSpan>[];
    // Regex matching bold, italic, code segments
    final pattern = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`|\[(.+?)\]\((.+?)\)');
    var last = 0;

    for (final m in pattern.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }

      final bold = m.group(1);
      final italic = m.group(2);
      final code = m.group(3);
      final linkText = m.group(4);

      if (bold != null) {
        spans.add(TextSpan(text: bold, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)));
      } else if (italic != null) {
        spans.add(TextSpan(text: italic, style: const TextStyle(fontStyle: FontStyle.italic)));
      } else if (code != null) {
        spans.add(TextSpan(
          text: code,
          style: const TextStyle(color: Colors.cyanAccent, fontFamily: 'Courier', fontSize: 13),
        ));
      } else if (linkText != null) {
        spans.add(TextSpan(
          text: linkText,
          style: const TextStyle(color: Color(0xFF00BCD4), decoration: TextDecoration.underline),
        ));
      }

      last = m.end;
    }

    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }

    return spans;
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
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _parseAndRenderMarkdown(_content),
                  ),
                ),
    );
  }
}
