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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultTextColor = isDark ? Colors.white70 : const Color(0xFF2C2C2E);

    final type = elem['type'] as String? ?? 'p';
    if (type == 'p') {
      final runs = elem['runs'] as List? ?? [];
      final align = elem['align'] as String?;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: RichText(
          textAlign: _mapAlignment(align),
          text: TextSpan(
            style: TextStyle(
              color: defaultTextColor,
              fontSize: 15,
              height: 1.6,
              fontFamily: 'Inter',
            ),
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
                  color: color ?? defaultTextColor,
                ),
              );
            }).toList(),
          ),
        ),
      );
    } else if (type == 'table') {
      final rows = elem['rows'] as List? ?? [];
      if (rows.isEmpty) return const SizedBox.shrink();

      final tableBorderColor = isDark ? Colors.white10 : Colors.black12;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tableBorderColor, width: 1.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: Table(
            border: TableBorder.symmetric(
              inside: BorderSide(color: tableBorderColor, width: 0.8),
            ),
            children: rows.map<TableRow>((row) {
              final cells = row as List? ?? [];
              return TableRow(
                children: cells.map<Widget>((cell) {
                  final cellParagraphs = cell as List? ?? [];
                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: cellParagraphs.map<Widget>(_buildElement).toList(),
                    ),
                  );
                }).toList(),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final bgScreenColor = isDark ? const Color(0xFF0A0A0B) : const Color(0xFFF3F3F5);
    final paperBgColor = isDark ? const Color(0xFF161618) : Colors.white;
    final paperBorderColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.08);
    final docTitleColor = isDark ? Colors.white : Colors.black;
    final docMetaColor = isDark ? Colors.white38 : Colors.black45;

    return Scaffold(
      backgroundColor: bgScreenColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF111112) : Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
            height: 1.0,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF00BCD4))))
          : _errorMsg.isNotEmpty
              ? Center(child: Text(_errorMsg, style: const TextStyle(color: Colors.white54)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    decoration: BoxDecoration(
                      color: paperBgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: paperBorderColor, width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.description_rounded,
                                color: Colors.blue,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    style: TextStyle(
                                      color: docTitleColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Word Document",
                                    style: TextStyle(
                                      color: docMetaColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Divider(
                          color: isDark ? Colors.white12 : Colors.black12,
                          height: 1,
                          thickness: 1,
                        ),
                        const SizedBox(height: 24),
                        ..._elements.map<Widget>(_buildElement).toList(),
                      ],
                    ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgScreenColor = isDark ? const Color(0xFF0A0A0B) : const Color(0xFFF3F3F5);
    final headerBgColor = isDark ? const Color(0xFF1E1E22) : const Color(0xFFEAEAEF);
    final cellBgColor = isDark ? const Color(0xFF121214) : Colors.white;
    final gridLineColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);
    final headerTextColor = isDark ? Colors.white70 : Colors.black87;
    final dataTextColor = isDark ? Colors.white60 : Colors.black87;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgScreenColor,
        body: const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF00BCD4)))),
      );
    }

    if (_errorMsg.isNotEmpty) {
      return Scaffold(
        backgroundColor: bgScreenColor,
        body: Center(child: Text(_errorMsg, style: const TextStyle(color: Colors.white54))),
      );
    }

    final maxRow = (_gridData['maxRow'] as int? ?? 0) + 1;
    final maxCol = (_gridData['maxCol'] as int? ?? 0) + 1;
    final cells = _gridData['cells'] as Map<String, dynamic>? ?? {};

    final rowCount = maxRow.clamp(10, 500);
    final colCount = maxCol.clamp(6, 100);

    return Scaffold(
      backgroundColor: bgScreenColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF111112) : Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
            height: 1.0,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: InteractiveViewer(
        constrained: false,
        maxScale: 2.5,
        minScale: 0.7,
        child: Container(
          color: bgScreenColor,
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: gridLineColor, width: 1.0),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Table(
              defaultColumnWidth: const FixedColumnWidth(110.0),
              border: TableBorder.all(color: gridLineColor, width: 0.6),
              children: List<TableRow>.generate(rowCount + 1, (r) {
                if (r == 0) {
                  // Header row (A, B, C...)
                  return TableRow(
                    children: List<Widget>.generate(colCount + 1, (c) {
                      return Container(
                        height: 32,
                        color: headerBgColor,
                        alignment: Alignment.center,
                        child: Text(
                          c == 0 ? '' : _getColLabel(c - 1),
                          style: TextStyle(
                            color: headerTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                        ),
                      );
                    }),
                  );
                }

                final rowBgColor = r % 2 == 0 
                    ? cellBgColor 
                    : (isDark ? const Color(0xFF161619) : const Color(0xFFF9F9FB));

                // Data rows
                return TableRow(
                  children: List<Widget>.generate(colCount + 1, (c) {
                    if (c == 0) {
                      // Row index number (1, 2, 3...)
                      return Container(
                        height: 30,
                        color: headerBgColor,
                        alignment: Alignment.center,
                        child: Text(
                          '$r',
                          style: TextStyle(
                            color: headerTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                        ),
                      );
                    }

                    // Resolve coordinates ref string
                    final colLabel = _getColLabel(c - 1);
                    final cellRef = '$colLabel$r';
                    final cellValue = cells[cellRef] as String? ?? '';

                    return Container(
                      height: 30,
                      color: rowBgColor,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        cellValue,
                        style: TextStyle(
                          color: dataTextColor,
                          fontSize: 12,
                          fontFamily: 'Inter',
                        ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgScreenColor = isDark ? const Color(0xFF0A0A0B) : const Color(0xFFF3F3F5);
    final slideBgColor = isDark ? const Color(0xFF161618) : Colors.white;
    final slideBorderColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.08);
    final dataTextColor = isDark ? Colors.white60 : Colors.black87;

    return Scaffold(
      backgroundColor: bgScreenColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF111112) : Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
            height: 1.0,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF00BCD4))))
          : _errorMsg.isNotEmpty
              ? Center(child: Text(_errorMsg, style: const TextStyle(color: Colors.white54)))
              : ListView.builder(
                  itemCount: _slides.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    final pageNum = slide['slide'] as int;
                    final texts = (slide['texts'] as List).cast<String>();

                    return AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: slideBgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: slideBorderColor, width: 1.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Slide header badge
                            Container(
                              color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text(
                                'Slide $pageNum',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                            // Slide content text blocks
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: texts.isEmpty
                                    ? Center(
                                        child: Text(
                                          'Empty Slide',
                                          style: TextStyle(
                                            color: isDark ? Colors.white24 : Colors.black26,
                                            fontSize: 12,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                      )
                                    : ListView(
                                        physics: const ClampingScrollPhysics(),
                                        children: texts.map<Widget>((t) {
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 6.0),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '•  ',
                                                  style: TextStyle(
                                                    color: Colors.orange.withValues(alpha: 0.8),
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    t,
                                                    style: TextStyle(
                                                      color: dataTextColor,
                                                      fontSize: 13,
                                                      height: 1.4,
                                                      fontFamily: 'Inter',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                              ),
                            ),
                          ],
                        ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultTextColor = isDark ? Colors.white70 : const Color(0xFF2C2C2E);

    final type = elem['type'] as String? ?? 'p';
    if (type == 'p') {
      final runs = elem['runs'] as List? ?? [];
      final align = elem['align'] as String?;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: RichText(
          textAlign: _mapAlignment(align),
          text: TextSpan(
            style: TextStyle(
              color: defaultTextColor,
              fontSize: 15,
              height: 1.6,
              fontFamily: 'Inter',
            ),
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
                  color: defaultTextColor,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final bgScreenColor = isDark ? const Color(0xFF0A0A0B) : const Color(0xFFF3F3F5);
    final paperBgColor = isDark ? const Color(0xFF161618) : Colors.white;
    final paperBorderColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.08);
    final docTitleColor = isDark ? Colors.white : Colors.black;
    final docMetaColor = isDark ? Colors.white38 : Colors.black45;

    return Scaffold(
      backgroundColor: bgScreenColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF111112) : Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
            height: 1.0,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF00BCD4))))
          : _errorMsg.isNotEmpty
              ? Center(child: Text(_errorMsg, style: const TextStyle(color: Colors.white54)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    decoration: BoxDecoration(
                      color: paperBgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: paperBorderColor, width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.description_rounded,
                                color: Colors.teal,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    style: TextStyle(
                                      color: docTitleColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "OpenDocument Text",
                                    style: TextStyle(
                                      color: docMetaColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Divider(
                          color: isDark ? Colors.white12 : Colors.black12,
                          height: 1,
                          thickness: 1,
                        ),
                        const SizedBox(height: 24),
                        ..._elements.map<Widget>(_buildElement).toList(),
                      ],
                    ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgScreenColor = isDark ? const Color(0xFF0A0A0B) : const Color(0xFFF3F3F5);
    final headerBgColor = isDark ? const Color(0xFF1E1E22) : const Color(0xFFEAEAEF);
    final cellBgColor = isDark ? const Color(0xFF121214) : Colors.white;
    final gridLineColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);
    final headerTextColor = isDark ? Colors.white70 : Colors.black87;
    final dataTextColor = isDark ? Colors.white60 : Colors.black87;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgScreenColor,
        body: const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF00BCD4)))),
      );
    }

    if (_errorMsg.isNotEmpty) {
      return Scaffold(
        backgroundColor: bgScreenColor,
        body: Center(child: Text(_errorMsg, style: const TextStyle(color: Colors.white54))),
      );
    }

    final maxRow = (_gridData['maxRow'] as int? ?? 0) + 1;
    final maxCol = (_gridData['maxCol'] as int? ?? 0) + 1;
    final cells = _gridData['cells'] as Map<String, dynamic>? ?? {};

    final rowCount = maxRow.clamp(10, 500);
    final colCount = maxCol.clamp(6, 100);

    return Scaffold(
      backgroundColor: bgScreenColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF111112) : Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
            height: 1.0,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: InteractiveViewer(
        constrained: false,
        maxScale: 2.5,
        minScale: 0.7,
        child: Container(
          color: bgScreenColor,
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: gridLineColor, width: 1.0),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Table(
              defaultColumnWidth: const FixedColumnWidth(110.0),
              border: TableBorder.all(color: gridLineColor, width: 0.6),
              children: List<TableRow>.generate(rowCount + 1, (r) {
                if (r == 0) {
                  // Header Row (A, B, C...)
                  return TableRow(
                    children: [
                      Container(
                        height: 32,
                        color: headerBgColor,
                        alignment: Alignment.center,
                        child: Text(
                          '',
                          style: TextStyle(color: headerTextColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      for (int c = 0; c < colCount; c++)
                        Container(
                          height: 32,
                          color: headerBgColor,
                          alignment: Alignment.center,
                          child: Text(
                            _getColLabel(c),
                            style: TextStyle(
                              color: headerTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                    ],
                  );
                }

                final rowBgColor = r % 2 == 0 
                    ? cellBgColor 
                    : (isDark ? const Color(0xFF161619) : const Color(0xFFF9F9FB));

                // Data Rows
                return TableRow(
                  children: [
                    // Row Index Cell
                    Container(
                      height: 30,
                      color: headerBgColor,
                      alignment: Alignment.center,
                      child: Text(
                        '$r',
                        style: TextStyle(
                          color: headerTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    // Grid cell values
                    for (int c = 0; c < colCount; c++)
                      Container(
                        height: 30,
                        color: rowBgColor,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          cells['${_getColLabel(c)}$r']?.toString() ?? '',
                          style: TextStyle(
                            color: dataTextColor,
                            fontSize: 12,
                            fontFamily: 'Inter',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                );
              }),
            ),
          ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultTextColor = isDark ? Colors.white70 : const Color(0xFF2C2C2E);

    final type = elem['type'] as String? ?? 'p';
    if (type == 'p') {
      final runs = elem['runs'] as List? ?? [];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              color: defaultTextColor,
              fontSize: 15,
              height: 1.6,
              fontFamily: 'Inter',
            ),
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
                  color: defaultTextColor,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final bgScreenColor = isDark ? const Color(0xFF0A0A0B) : const Color(0xFFF3F3F5);
    final paperBgColor = isDark ? const Color(0xFF161618) : Colors.white;
    final paperBorderColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.08);
    final docTitleColor = isDark ? Colors.white : Colors.black;
    final docMetaColor = isDark ? Colors.white38 : Colors.black45;

    return Scaffold(
      backgroundColor: bgScreenColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF111112) : Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
            height: 1.0,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF00BCD4))))
          : _errorMsg.isNotEmpty
              ? Center(child: Text(_errorMsg, style: const TextStyle(color: Colors.white54)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    decoration: BoxDecoration(
                      color: paperBgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: paperBorderColor, width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.description_rounded,
                                color: Colors.purple,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    style: TextStyle(
                                      color: docTitleColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Rich Text Format (RTF)",
                                    style: TextStyle(
                                      color: docMetaColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Divider(
                          color: isDark ? Colors.white12 : Colors.black12,
                          height: 1,
                          thickness: 1,
                        ),
                        const SizedBox(height: 24),
                        ..._elements.map<Widget>(_buildElement).toList(),
                      ],
                    ),
                  ),
                ),
    );
  }
}
