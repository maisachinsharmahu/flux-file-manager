import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../bridge/flux_bridge.dart';

/// AnnotationStroke — holds draw coordinates for drawing canvas.
class AnnotationStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  AnnotationStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'color': color.value,
      'strokeWidth': strokeWidth,
    };
  }

  factory AnnotationStroke.fromJson(Map<String, dynamic> json) {
    final ptsList = json['points'] as List;
    final points = ptsList.map((p) => Offset(p['x'] as double, p['y'] as double)).toList();
    return AnnotationStroke(
      points: points,
      color: Color(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
    );
  }
}

class PdfViewerScreen extends StatefulWidget {
  final String path;
  final String title;

  const PdfViewerScreen({
    Key? key,
    required this.path,
    required this.title,
  }) : super(key: key);

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  int _pageCount = 0;
  bool _isLoading = true;
  bool _isDrawingMode = false;
  Color _activeColor = const Color(0xFF00BCD4);
  double _activeWidth = 3.0;

  // Key: pageIndex, Value: List of drawing strokes
  final Map<int, List<AnnotationStroke>> _pageAnnotations = {};
  
  // Track currently active drawing stroke
  List<Offset> _currentStrokePoints = [];

  // Future cache for PDF page JPEG byte streams
  final Map<int, Future<Uint8List?>> _pageFutures = {};

  Future<Uint8List?> _getPageFuture(int index) {
    return _pageFutures.putIfAbsent(index, () {
      return FluxBridge.getPdfPageBytes(widget.path, index, 1.5);
    });
  }

  @override
  void initState() {
    super.initState();
    _initPdf();
  }

  @override
  void dispose() {
    FluxBridge.closePdf(widget.path);
    super.dispose();
  }

  Future<void> _initPdf() async {
    try {
      final count = await FluxBridge.getPdfPageCount(widget.path);
      await _loadAnnotations();
      setState(() {
        _pageCount = count;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load PDF count: $e');
      setState(() => _isLoading = false);
    }
  }

  // ── Annotations Persistence ────────────────────────────────────────────────

  File get _annotationsFile => File('${widget.path}.annotations');

  Future<void> _loadAnnotations() async {
    try {
      final file = _annotationsFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = json.decode(content) as Map<String, dynamic>;
        data.forEach((key, val) {
          final pageIdx = int.parse(key);
          final list = (val as List).map((x) => AnnotationStroke.fromJson(x as Map<String, dynamic>)).toList();
          _pageAnnotations[pageIdx] = list;
        });
      }
    } catch (e) {
      debugPrint('Error loading annotations: $e');
    }
  }

  Future<void> _saveAnnotations() async {
    try {
      final data = _pageAnnotations.map((key, value) {
        return MapEntry(key.toString(), value.map((v) => v.toJson()).toList());
      });
      await _annotationsFile.writeAsString(json.encode(data));
    } catch (e) {
      debugPrint('Error saving annotations: $e');
    }
  }

  // ── UI Drawing Handler ─────────────────────────────────────────────────────

  void _onDrawingPanStart(int pageIndex, DragStartDetails details, BoxConstraints constraints) {
    if (!_isDrawingMode) return;
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localOffset = box.globalToLocal(details.globalPosition);
    setState(() {
      _currentStrokePoints = [localOffset];
    });
  }

  void _onDrawingPanUpdate(int pageIndex, DragUpdateDetails details, BoxConstraints constraints) {
    if (!_isDrawingMode) return;
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localOffset = box.globalToLocal(details.globalPosition);
    setState(() {
      _currentStrokePoints.add(localOffset);
    });
  }

  void _onDrawingPanEnd(int pageIndex, DragEndDetails details) {
    if (!_isDrawingMode || _currentStrokePoints.isEmpty) return;
    setState(() {
      final newStroke = AnnotationStroke(
        points: List.from(_currentStrokePoints),
        color: _activeColor,
        strokeWidth: _activeWidth,
      );
      _pageAnnotations.putIfAbsent(pageIndex, () => []).add(newStroke);
      _currentStrokePoints.clear();
    });
    _saveAnnotations();
  }

  // ── Main Build Layout ──────────────────────────────────────────────────────

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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Toggle Drawing Button
          IconButton(
            icon: Icon(
              _isDrawingMode ? Icons.draw_rounded : Icons.edit_note_rounded,
              color: _isDrawingMode ? const Color(0xFF00BCD4) : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isDrawingMode = !_isDrawingMode;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isDrawingMode ? "Drawing Mode Active" : "View Mode Active"),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          if (_isDrawingMode)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
              onPressed: () {
                setState(() {
                  _pageAnnotations.clear();
                });
                _saveAnnotations();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
              ),
            )
          : Column(
              children: [
                // Highlight Settings Panel (Visible only in drawing mode)
                if (_isDrawingMode)
                  Container(
                    color: const Color(0xFF161616),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Annotation Pen:",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        Row(
                          children: [
                            _buildColorDot(const Color(0xFF00BCD4)),
                            _buildColorDot(const Color(0xFFFFEB3B)),
                            _buildColorDot(const Color(0xFF4CAF50)),
                            _buildColorDot(const Color(0xFFE91E63)),
                          ],
                        ),
                        // Pen thickness slider
                        Row(
                          children: [
                            const Icon(Icons.line_weight_rounded, color: Colors.white60, size: 16),
                            SizedBox(
                              width: 100,
                              child: Slider(
                                value: _activeWidth,
                                min: 1.0,
                                max: 10.0,
                                activeColor: const Color(0xFF00BCD4),
                                onChanged: (val) {
                                  setState(() => _activeWidth = val);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Main PDF scroll list
                Expanded(
                  child: InteractiveViewer(
                    maxScale: 3.0,
                    minScale: 1.0,
                    child: ListView.builder(
                      itemCount: _pageCount,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Standard PDF Page aspect ratio (typical A4 is 1:1.414)
                              final pageHeight = constraints.maxWidth * 1.414;

                              return Center(
                                child: Container(
                                  width: constraints.maxWidth,
                                  height: pageHeight,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      // Render page using Image.memory fetched from native byte stream
                                      Positioned.fill(
                                        child: FutureBuilder<Uint8List?>(
                                          future: _getPageFuture(index),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                              return const Center(
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation(Color(0xFF00BCD4)),
                                                ),
                                              );
                                            }
                                            if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                                              return const Center(
                                                child: Icon(Icons.broken_image_rounded, color: Colors.white24, size: 48),
                                              );
                                            }
                                            return Image.memory(
                                              snapshot.data!,
                                              fit: BoxFit.contain,
                                              gaplessPlayback: true,
                                            );
                                          },
                                        ),
                                      ),

                                      // Canvas Annotation drawing overlay layer
                                      Positioned.fill(
                                        child: _isDrawingMode
                                            ? GestureDetector(
                                                behavior: HitTestBehavior.opaque,
                                                onPanStart: (details) => _onDrawingPanStart(index, details, constraints),
                                                onPanUpdate: (details) => _onDrawingPanUpdate(index, details, constraints),
                                                onPanEnd: (details) => _onDrawingPanEnd(index, details),
                                                child: CustomPaint(
                                                  painter: AnnotationPainter(
                                                    savedStrokes: _pageAnnotations[index] ?? [],
                                                    currentStrokePoints: _currentStrokePoints,
                                                    activeColor: _activeColor,
                                                    activeWidth: _activeWidth,
                                                  ),
                                                ),
                                              )
                                            : IgnorePointer(
                                                child: CustomPaint(
                                                  painter: AnnotationPainter(
                                                    savedStrokes: _pageAnnotations[index] ?? [],
                                                    currentStrokePoints: _currentStrokePoints,
                                                    activeColor: _activeColor,
                                                    activeWidth: _activeWidth,
                                                  ),
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
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildColorDot(Color color) {
    final isSelected = _activeColor == color;
    return GestureDetector(
      onTap: () => setState(() => _activeColor = color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 2.0) : null,
        ),
      ),
    );
  }
}

/// Custom painter to draw annotations on top of individual PDF page bitmap layout.
class AnnotationPainter extends CustomPainter {
  final List<AnnotationStroke> savedStrokes;
  final List<Offset> currentStrokePoints;
  final Color activeColor;
  final double activeWidth;

  AnnotationPainter({
    required this.savedStrokes,
    required this.currentStrokePoints,
    required this.activeColor,
    required this.activeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 1. Draw saved strokes
    for (final stroke in savedStrokes) {
      paint.color = stroke.color;
      paint.strokeWidth = stroke.strokeWidth;
      
      final path = Path();
      if (stroke.points.isNotEmpty) {
        path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
        for (int i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }

    // 2. Draw current active path
    if (currentStrokePoints.isNotEmpty) {
      paint.color = activeColor;
      paint.strokeWidth = activeWidth;

      final path = Path();
      path.moveTo(currentStrokePoints.first.dx, currentStrokePoints.first.dy);
      for (int i = 1; i < currentStrokePoints.length; i++) {
        path.lineTo(currentStrokePoints[i].dx, currentStrokePoints[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant AnnotationPainter oldDelegate) {
    return true;
  }
}
