import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../bridge/flux_bridge.dart';

// ── DOCX DOCUMENT VIEWER ─────────────────────────────────────────────────────

class DocxViewerScreen extends StatefulWidget {
  final String path;
  final String title;

  const DocxViewerScreen({
    Key? key,
    required this.path,
    required this.title,
  }) : super(key: key);

  @override
  State<DocxViewerScreen> createState() => _DocxViewerScreenState();
}

class _DocxViewerScreenState extends State<DocxViewerScreen> {
  List<dynamic> _elements = [];
  bool _isLoading = true;
  String _errorMsg = "";

  @override
  void initState() {
    super.initState();
    _loadDocx();
  }

  Future<void> _loadDocx() async {
    try {
      final jsonStr = await FluxBridge.parseDocx(widget.path);
      setState(() {
        _elements = json.decode(jsonStr) as List;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = "Failed to parse Word Document: $e";
        _isLoading = false;
      });
    }
  }

  TextAlign _mapAlignment(String? align) {
    if (align == null) return TextAlign.left;
    switch (align.toLowerCase()) {
      case 'center': return TextAlign.center;
      case 'right': return TextAlign.right;
      case 'both':
      case 'justify': return TextAlign.justify;
      default: return TextAlign.left;
    }
  }

  Widget _buildElement(dynamic elem) {
    final type = elem['type'] as String? ?? 'p';
    if (type == 'p') {
      final runs = elem['runs'] as List? ?? [];
      final align = elem['align'] as String?;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: RichText(
          textAlign: _mapAlignment(align),
          text: TextSpan(
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            children: runs.map<TextSpan>((r) {
              final text = r['text'] as String? ?? '';
              final bold = r['b'] as bool? ?? false;
              final italic = r['i'] as bool? ?? false;
              final underline = r['u'] as bool? ?? false;
              final colorHex = r['color'] as String?;

              Color? color;
              if (colorHex != null && colorHex.length >= 7) {
                try {
                  color = Color(int.parse(colorHex.replaceAll('#', '0xFF')));
                } catch (_) {}
              }

              return TextSpan(
                text: text,
                style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                  decoration: underline ? TextDecoration.underline : TextDecoration.none,
                  color: color ?? Colors.white70,
                ),
              );
            }).toList(),
          ),
        ),
      );
    } else if (type == 'table') {
      final rows = elem['rows'] as List? ?? [];
      if (rows.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Table(
          border: TableBorder.all(color: Colors.white24, width: 1),
          children: rows.map<TableRow>((row) {
            final cells = row as List? ?? [];
            return TableRow(
              children: cells.map<Widget>((cell) {
                final cellParagraphs = cell as List? ?? [];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: cellParagraphs.map<Widget>(_buildElement).toList(),
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ),
      );
    }
    return const SizedBox.shrink();
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _elements.map<Widget>(_buildElement).toList(),
                  ),
                ),
    );
  }
}

// ── XLSX SPREADSHEET VIEWER ──────────────────────────────────────────────────

class XlsxViewerScreen extends StatefulWidget {
  final String path;
  final String title;

  const XlsxViewerScreen({
    Key? key,
    required this.path,
    required this.title,
  }) : super(key: key);

  @override
  State<XlsxViewerScreen> createState() => _XlsxViewerScreenState();
}

class _XlsxViewerScreenState extends State<XlsxViewerScreen> {
  Map<String, dynamic> _gridData = {};
  bool _isLoading = true;
  String _errorMsg = "";

  @override
  void initState() {
    super.initState();
    _loadXlsx();
  }

  Future<void> _loadXlsx() async {
    try {
      final jsonStr = await FluxBridge.parseXlsx(widget.path);
      setState(() {
        _gridData = json.decode(jsonStr) as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = "Failed to parse Spreadsheet: $e";
        _isLoading = false;
      });
    }
  }

  String _getColLabel(int colIndex) {
    String label = "";
    int temp = colIndex;
    while (temp >= 0) {
      label = String.fromCharCode((temp % 26) + 65) + label;
      temp = (temp ~/ 26) - 1;
    }
    return label;
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

    final maxRow = (_gridData['maxRow'] as int? ?? 0) + 1;
    final maxCol = (_gridData['maxCol'] as int? ?? 0) + 1;
    final cells = _gridData['cells'] as Map<String, dynamic>? ?? {};

    // Adjust count grid layout constraints
    final rowCount = maxRow.clamp(10, 500);
    final colCount = maxCol.clamp(6, 100);

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
      body: InteractiveViewer(
        constrained: false,
        maxScale: 2.0,
        minScale: 0.8,
        child: Container(
          color: const Color(0xFF0F0F0F),
          child: Table(
            defaultColumnWidth: const FixedColumnWidth(110.0),
            border: TableBorder.all(color: Colors.white12, width: 0.5),
            children: List<TableRow>.generate(rowCount + 1, (r) {
              if (r == 0) {
                // Header row (A, B, C...)
                return TableRow(
                  children: List<Widget>.generate(colCount + 1, (c) {
                    return Container(
                      height: 28,
                      color: const Color(0xFF161616),
                      alignment: Alignment.center,
                      child: Text(
                        c == 0 ? '' : _getColLabel(c - 1),
                        style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    );
                  }),
                );
              }

              // Data rows
              return TableRow(
                children: List<Widget>.generate(colCount + 1, (c) {
                  if (c == 0) {
                    // Row index number (1, 2, 3...)
                    return Container(
                      height: 26,
                      color: const Color(0xFF161616),
                      alignment: Alignment.center,
                      child: Text(
                        '$r',
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    );
                  }

                  // Resolve coordinates ref string
                  final colLabel = _getColLabel(c - 1);
                  final cellRef = '$colLabel$r';
                  final cellValue = cells[cellRef] as String? ?? '';

                  return Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      cellValue,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── PPTX SLIDESHOW VIEWER ────────────────────────────────────────────────────

class PptxViewerScreen extends StatefulWidget {
  final String path;
  final String title;

  const PptxViewerScreen({
    Key? key,
    required this.path,
    required this.title,
  }) : super(key: key);

  @override
  State<PptxViewerScreen> createState() => _PptxViewerScreenState();
}

class _PptxViewerScreenState extends State<PptxViewerScreen> {
  List<dynamic> _slides = [];
  bool _isLoading = true;
  String _errorMsg = "";

  @override
  void initState() {
    super.initState();
    _loadPptx();
  }

  Future<void> _loadPptx() async {
    try {
      final jsonStr = await FluxBridge.parsePptx(widget.path);
      setState(() {
        _slides = json.decode(jsonStr) as List;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = "Failed to parse PowerPoint Presentation: $e";
        _isLoading = false;
      });
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
              : ListView.builder(
                  itemCount: _slides.length,
                  padding: const EdgeInsets.all(24),
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    final pageNum = slide['slide'] as int;
                    final texts = (slide['texts'] as List).cast<String>();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Slide header badge
                          Container(
                            color: Colors.white.withOpacity(0.04),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              'Slide $pageNum',
                              style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          // Slide content text blocks
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: texts.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'Empty Slide',
                                        style: TextStyle(color: Colors.white24, fontSize: 12),
                                      ),
                                    )
                                  : ListView(
                                      children: texts.map<Widget>((t) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 4.0),
                                          child: Text(
                                            t,
                                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

// ── ODT DOCUMENT VIEWER ──────────────────────────────────────────────────────

class OdtViewerScreen extends StatefulWidget {
  final String path;
  final String title;

  const OdtViewerScreen({
    Key? key,
    required this.path,
    required this.title,
  }) : super(key: key);

  @override
  State<OdtViewerScreen> createState() => _OdtViewerScreenState();
}

class _OdtViewerScreenState extends State<OdtViewerScreen> {
  List<dynamic> _elements = [];
  bool _isLoading = true;
  String _errorMsg = "";

  @override
  void initState() {
    super.initState();
    _loadOdt();
  }

  Future<void> _loadOdt() async {
    try {
      final jsonStr = await FluxBridge.parseOdt(widget.path);
      setState(() {
        _elements = json.decode(jsonStr) as List;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = "Failed to parse ODT document: $e";
        _isLoading = false;
      });
    }
  }

  TextAlign _mapAlignment(String? align) {
    if (align == null) return TextAlign.left;
    switch (align.toLowerCase()) {
      case 'center': return TextAlign.center;
      case 'right': return TextAlign.right;
      case 'both':
      case 'justify': return TextAlign.justify;
      default: return TextAlign.left;
    }
  }

  Widget _buildElement(dynamic elem) {
    final type = elem['type'] as String? ?? 'p';
    if (type == 'p') {
      final runs = elem['runs'] as List? ?? [];
      final align = elem['align'] as String?;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: RichText(
          textAlign: _mapAlignment(align),
          text: TextSpan(
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            children: runs.map<TextSpan>((r) {
              final text = r['text'] as String? ?? '';
              final bold = r['b'] as bool? ?? false;
              final italic = r['i'] as bool? ?? false;
              final underline = r['u'] as bool? ?? false;

              return TextSpan(
                text: text,
                style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                  decoration: underline ? TextDecoration.underline : TextDecoration.none,
                  color: Colors.white70,
                ),
              );
            }).toList(),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _elements.map<Widget>(_buildElement).toList(),
                  ),
                ),
    );
  }
}

// ── ODS SPREADSHEET VIEWER ───────────────────────────────────────────────────

class OdsViewerScreen extends StatefulWidget {
  final String path;
  final String title;

  const OdsViewerScreen({
    Key? key,
    required this.path,
    required this.title,
  }) : super(key: key);

  @override
  State<OdsViewerScreen> createState() => _OdsViewerScreenState();
}

class _OdsViewerScreenState extends State<OdsViewerScreen> {
  Map<String, dynamic> _gridData = {};
  bool _isLoading = true;
  String _errorMsg = "";

  @override
  void initState() {
    super.initState();
    _loadOds();
  }

  Future<void> _loadOds() async {
    try {
      final jsonStr = await FluxBridge.parseOds(widget.path);
      setState(() {
        _gridData = json.decode(jsonStr) as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = "Failed to parse ODS spreadsheet: $e";
        _isLoading = false;
      });
    }
  }

  String _getColLabel(int colIndex) {
    String label = "";
    int temp = colIndex;
    while (temp >= 0) {
      label = String.fromCharCode((temp % 26) + 65) + label;
      temp = (temp ~/ 26) - 1;
    }
    return label;
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

    final maxRow = (_gridData['maxRow'] as int? ?? 0) + 1;
    final maxCol = (_gridData['maxCol'] as int? ?? 0) + 1;
    final cells = _gridData['cells'] as Map<String, dynamic>? ?? {};

    final rowCount = maxRow.clamp(10, 500);
    final colCount = maxCol.clamp(6, 100);

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
      body: InteractiveViewer(
        constrained: false,
        maxScale: 2.0,
        minScale: 0.8,
        child: Table(
          defaultColumnWidth: const FixedColumnWidth(100),
          border: TableBorder.all(color: Colors.white12, width: 0.5),
          children: [
            // Header Row (A, B, C...)
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFF161616)),
              children: [
                const TableCell(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                for (int c = 0; c < colCount; c++)
                  TableCell(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(_getColLabel(c), style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ],
            ),
            // Data Rows
            for (int r = 0; r < rowCount; r++)
              TableRow(
                children: [
                  // Row Index Cell
                  TableCell(
                    child: Container(
                      color: const Color(0xFF161616),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('${r + 1}', style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  // Grid cell values
                  for (int c = 0; c < colCount; c++)
                    TableCell(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          cells['${_getColLabel(c)}${r + 1}']?.toString() ?? '',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ── RTF DOCUMENT VIEWER ──────────────────────────────────────────────────────

class RtfViewerScreen extends StatefulWidget {
  final String path;
  final String title;

  const RtfViewerScreen({
    Key? key,
    required this.path,
    required this.title,
  }) : super(key: key);

  @override
  State<RtfViewerScreen> createState() => _RtfViewerScreenState();
}

class _RtfViewerScreenState extends State<RtfViewerScreen> {
  List<dynamic> _elements = [];
  bool _isLoading = true;
  String _errorMsg = "";

  @override
  void initState() {
    super.initState();
    _loadRtf();
  }

  Future<void> _loadRtf() async {
    try {
      final jsonStr = await FluxBridge.parseRtf(widget.path);
      setState(() {
        _elements = json.decode(jsonStr) as List;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = "Failed to parse RTF document: $e";
        _isLoading = false;
      });
    }
  }

  Widget _buildElement(dynamic elem) {
    final type = elem['type'] as String? ?? 'p';
    if (type == 'p') {
      final runs = elem['runs'] as List? ?? [];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            children: runs.map<TextSpan>((r) {
              final text = r['text'] as String? ?? '';
              final bold = r['b'] as bool? ?? false;
              final italic = r['i'] as bool? ?? false;
              final underline = r['u'] as bool? ?? false;

              return TextSpan(
                text: text,
                style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                  decoration: underline ? TextDecoration.underline : TextDecoration.none,
                  color: Colors.white70,
                ),
              );
            }).toList(),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _elements.map<Widget>(_buildElement).toList(),
                  ),
                ),
    );
  }
}
