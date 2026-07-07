import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../bridge/flux_bridge.dart';

// ── JSON / XML / YAML TREE EXPLORER ──────────────────────────────────────────

class JsonTreeViewerScreen extends StatefulWidget {
  final String path;
  final String title;

  const JsonTreeViewerScreen({
    Key? key,
    required this.path,
    required this.title,
  }) : super(key: key);

  @override
  State<JsonTreeViewerScreen> createState() => _JsonTreeViewerScreenState();
}

class _JsonTreeViewerScreenState extends State<JsonTreeViewerScreen> {
  dynamic _parsedData;
  bool _isLoading = true;
  String _errorMsg = "";

  @override
  void initState() {
    super.initState();
    _loadJson();
  }

  Future<void> _loadJson() async {
    try {
      final content = await FluxBridge.getFileContent(widget.path);
      setState(() {
        _parsedData = json.decode(content);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = "Failed to parse JSON tree structure: $e. Displaying as code...";
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
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(_errorMsg, style: const TextStyle(color: Colors.white54), textAlign: TextAlign.center),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: JsonTreeNodeWidget(
                    label: "root",
                    value: _parsedData,
                    isLast: true,
                  ),
                ),
    );
  }
}

class JsonTreeNodeWidget extends StatefulWidget {
  final String label;
  final dynamic value;
  final bool isLast;

  const JsonTreeNodeWidget({
    Key? key,
    required this.label,
    required this.value,
    this.isLast = false,
  }) : super(key: key);

  @override
  State<JsonTreeNodeWidget> createState() => _JsonTreeNodeWidgetState();
}

class _JsonTreeNodeWidgetState extends State<JsonTreeNodeWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final val = widget.value;

    if (val is Map) {
      final keys = val.keys.toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Icon(
                    _expanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                    color: const Color(0xFF00BCD4),
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.label}: ',
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const Text(
                    '{ }',
                    style: TextStyle(color: Colors.white30, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(keys.length, (index) {
                  final k = keys[index];
                  return JsonTreeNodeWidget(
                    label: k.toString(),
                    value: val[k],
                    isLast: index == keys.length - 1,
                  );
                }),
              ),
            ),
        ],
      );
    }

    if (val is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Icon(
                    _expanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                    color: const Color(0xFF00BCD4),
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.label}: ',
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    '[ ${val.length} ]',
                    style: const TextStyle(color: Colors.white30, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(val.length, (index) {
                  return JsonTreeNodeWidget(
                    label: '[$index]',
                    value: val[index],
                    isLast: index == val.length - 1,
                  );
                }),
              ),
            ),
        ],
      );
    }

    // Leaf values (string, number, boolean, null)
    String valStr = 'null';
    Color valColor = Colors.grey;

    if (val != null) {
      valStr = val.toString();
      if (val is String) {
        valStr = '"$valStr"';
        valColor = Colors.greenAccent;
      } else if (val is num) {
        valColor = Colors.amberAccent;
      } else if (val is bool) {
        valColor = Colors.cyanAccent;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 24.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13),
          children: [
            TextSpan(
              text: '${widget.label}: ',
              style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w500),
            ),
            TextSpan(
              text: valStr,
              style: TextStyle(color: valColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ── CSV VIRTUAL SHEET VIEWER ─────────────────────────────────────────────────

class CsvViewerScreen extends StatefulWidget {
  final String path;
  final String title;

  const CsvViewerScreen({
    Key? key,
    required this.path,
    required this.title,
  }) : super(key: key);

  @override
  State<CsvViewerScreen> createState() => _CsvViewerScreenState();
}

class _CsvViewerScreenState extends State<CsvViewerScreen> {
  int _rowCount = 0;
  List<String> _headers = [];
  bool _isLoading = true;
  String _errorMsg = "";

  // Page caching parameters
  final Map<int, List<String>> _rowCache = {};
  final Set<int> _fetchingPages = {};
  static const int pageSize = 50;

  @override
  void initState() {
    super.initState();
    _loadCsvMetadata();
  }

  @override
  void dispose() {
    FluxBridge.closeCsv(widget.path);
    super.dispose();
  }

  Future<void> _loadCsvMetadata() async {
    try {
      final jsonStr = await FluxBridge.getCsvMetadata(widget.path);
      final meta = json.decode(jsonStr) as Map<String, dynamic>;
      setState(() {
        _rowCount = meta['rowCount'] as int? ?? 0;
        _headers = (meta['headers'] as List? ?? []).cast<String>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = "Failed to open CSV dataset: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchRow(int index) async {
    final pageStart = (index ~/ pageSize) * pageSize;
    if (_fetchingPages.contains(pageStart)) return;
    _fetchingPages.add(pageStart);

    try {
      final rowsJsonStr = await FluxBridge.getCsvRows(widget.path, pageStart, pageSize);
      final list = json.decode(rowsJsonStr) as List;
      if (mounted) {
        setState(() {
          for (int i = 0; i < list.length; i++) {
            final rowCells = (list[i] as List).cast<String>();
            _rowCache[pageStart + i] = rowCells;
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching CSV rows: $e");
    } finally {
      _fetchingPages.remove(pageStart);
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

  Widget _buildIndexCell(String text) {
    return Container(
      width: 50.0,
      height: 26,
      color: const Color(0xFF161616),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.white24, width: 0.5),
          bottom: BorderSide(color: Colors.white12, width: 0.5),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white60, fontSize: 11),
      ),
    );
  }

  Widget _buildDataCell(String text, {bool isPlaceholder = false, bool isHeader = false}) {
    return Container(
      width: 110.0,
      height: isHeader ? 28 : 26,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isHeader ? const Color(0xFF161616) : Colors.transparent,
        border: const Border(
          right: BorderSide(color: Colors.white12, width: 0.5),
          bottom: BorderSide(color: Colors.white12, width: 0.5),
        ),
      ),
      alignment: isHeader ? Alignment.center : Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          color: isPlaceholder
              ? Colors.white24
              : (isHeader ? Colors.white60 : Colors.white70),
          fontSize: isHeader ? 11 : 12,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildRow(int r) {
    final cells = _rowCache[r];
    if (cells == null) {
      _fetchRow(r);
      return Row(
        children: [
          _buildIndexCell('${r + 1}'),
          for (int c = 0; c < _headers.length; c++)
            _buildDataCell('...', isPlaceholder: true),
        ],
      );
    }

    return Row(
      children: [
        _buildIndexCell('${r + 1}'),
        for (int c = 0; c < _headers.length; c++)
          _buildDataCell(c < cells.length ? cells[c] : ''),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colCount = _headers.length;
    final totalWidth = 50.0 + (colCount * 110.0);

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
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: totalWidth,
                    child: ListView.builder(
                      itemCount: _rowCount + 1,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // Headers row
                          return Row(
                            children: [
                              Container(
                                width: 50.0,
                                height: 28,
                                color: const Color(0xFF161616),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: Colors.white24, width: 0.5),
                                    bottom: BorderSide(color: Colors.white24, width: 0.5),
                                  ),
                                ),
                              ),
                              for (int c = 0; c < colCount; c++)
                                _buildDataCell(_getColLabel(c), isHeader: true),
                            ],
                          );
                        }
                        return _buildRow(index - 1);
                      },
                    ),
                  ),
                ),
    );
  }
}

// ── SQLITE READONLY DATABASE BROWSER ─────────────────────────────────────────

class SqliteViewerScreen extends StatefulWidget {
  final String path;
  final String title;

  const SqliteViewerScreen({
    Key? key,
    required this.path,
    required this.title,
  }) : super(key: key);

  @override
  State<SqliteViewerScreen> createState() => _SqliteViewerScreenState();
}

class _SqliteViewerScreenState extends State<SqliteViewerScreen> {
  List<String> _tables = [];
  String? _selectedTable;
  List<String> _columns = [];
  List<List<dynamic>> _rows = [];
  bool _isLoading = true;
  bool _isTableLoading = false;
  String _errorMsg = "";

  int _currentPage = 0;
  static const int pageSize = 50;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    try {
      final jsonStr = await FluxBridge.getSqliteTables(widget.path);
      final tables = (json.decode(jsonStr) as List).cast<String>();
      setState(() {
        _tables = tables;
        _isLoading = false;
        if (tables.isNotEmpty) {
          _selectTable(tables.first);
        }
      });
    } catch (e) {
      setState(() {
        _errorMsg = "Failed to load database tables: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _selectTable(String tableName) async {
    setState(() {
      _selectedTable = tableName;
      _isTableLoading = true;
      _currentPage = 0;
    });

    try {
      final schemaJsonStr = await FluxBridge.getSqliteTableSchema(widget.path, tableName);
      final columns = (json.decode(schemaJsonStr) as List).cast<String>();

      final rowsJsonStr = await FluxBridge.getSqliteTableRows(widget.path, tableName, 0, pageSize);
      final rawRows = json.decode(rowsJsonStr) as List;
      final rows = rawRows.map<List<dynamic>>((r) => r as List).toList();

      setState(() {
        _columns = columns;
        _rows = rows;
        _isTableLoading = false;
      });
    } catch (_) {
      setState(() {
        _isTableLoading = false;
      });
    }
  }

  Future<void> _loadPage(int page) async {
    if (_selectedTable == null) return;
    setState(() {
      _isTableLoading = true;
      _currentPage = page;
    });

    try {
      final rowsJsonStr = await FluxBridge.getSqliteTableRows(widget.path, _selectedTable!, page * pageSize, pageSize);
      final rawRows = json.decode(rowsJsonStr) as List;
      final rows = rawRows.map<List<dynamic>>((r) => r as List).toList();

      setState(() {
        _rows = rows;
        _isTableLoading = false;
      });
    } catch (_) {
      setState(() {
        _isTableLoading = false;
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
      drawer: Drawer(
        backgroundColor: const Color(0xFF1A1A1A),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF0F0F0F)),
              child: Text(
                'Tables List',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _tables.length,
                itemBuilder: (context, index) {
                  final t = _tables[index];
                  final isSelected = t == _selectedTable;
                  return ListTile(
                    title: Text(
                      t,
                      style: TextStyle(color: isSelected ? const Color(0xFF00BCD4) : Colors.white70),
                    ),
                    trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF00BCD4), size: 18) : null,
                    onTap: () {
                      Navigator.pop(context);
                      _selectTable(t);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF00BCD4))))
          : _errorMsg.isNotEmpty
              ? Center(child: Text(_errorMsg, style: const TextStyle(color: Colors.white54)))
              : Column(
                  children: [
                    // Database Header Toolbar info
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Builder(
                            builder: (context) => IconButton(
                              icon: const Icon(Icons.menu_rounded, color: Colors.white),
                              onPressed: () => Scaffold.of(context).openDrawer(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Table: ${_selectedTable ?? "None"}',
                              style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    // Table contents sheet grid
                    Expanded(
                      child: _isTableLoading
                          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF00BCD4))))
                          : _rows.isEmpty
                              ? const Center(child: Text('No Rows Found', style: TextStyle(color: Colors.white30)))
                              : InteractiveViewer(
                                  constrained: false,
                                  maxScale: 2.0,
                                  minScale: 0.8,
                                  child: Container(
                                    color: const Color(0xFF0F0F0F),
                                    child: Table(
                                      defaultColumnWidth: const FixedColumnWidth(120.0),
                                      border: TableBorder.all(color: Colors.white12, width: 0.5),
                                      children: [
                                        // Header Row
                                        TableRow(
                                          children: _columns.map<Widget>((col) {
                                            return Container(
                                              height: 30,
                                              color: const Color(0xFF161616),
                                              alignment: Alignment.center,
                                              padding: const EdgeInsets.symmetric(horizontal: 6),
                                              child: Text(
                                                col,
                                                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                        // Data Rows
                                        ..._rows.map<TableRow>((row) {
                                          return TableRow(
                                            children: row.map<Widget>((cell) {
                                              return Container(
                                                height: 28,
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  cell?.toString() ?? 'NULL',
                                                  style: TextStyle(
                                                    color: cell == null ? Colors.white30 : Colors.white70,
                                                    fontSize: 12,
                                                    fontStyle: cell == null ? FontStyle.italic : FontStyle.normal,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              );
                                            }).toList(),
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                  ),
                                ),
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    // Pagination controller row
                    Container(
                      height: 50,
                      color: const Color(0xFF161616),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                            onPressed: _currentPage > 0 ? () => _loadPage(_currentPage - 1) : null,
                          ),
                          Text(
                            'Page ${_currentPage + 1}',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                            onPressed: _rows.length == pageSize ? () => _loadPage(_currentPage + 1) : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
