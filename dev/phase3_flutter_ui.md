# Phase 3 — Flutter UI & Navigation
**Weeks 11–16 | Sprint S6 (W11–12) + S7 (W13–14) + S8 (W15–16)**

> **Gate:** All screens built and navigable. Fluid 60 fps verified on target devices under a 10,000-file directory list stress test. 4-stage thumbnail pipeline works seamlessly without memory leaks.

---

## Overview

Phase 3 transitions development to the Flutter presentation layer. While the native database layers operate in microseconds, the UI must match this speed, rendering lists smoothly at 60 fps (16.6ms frame budget). This phase implements the design system, basic file management screens, search screens, the 4-stage progressive thumbnail system, and the storage analytics panel.

---

## 1. Design System & Tokens (Week 11, Days 1–3)

### Spacing & Colors (Achromatic Theme)

FLUX follows a strict premium achromatic styling system. Colors are limited to pure black, pure white, and neutral greys. High-contrast colors are reserved for file-specific identifiers (e.g., Red for PDF, Blue for Docs).

### File: `lib/core/constants/design_tokens.dart`

```dart
import 'package:flutter/material.dart';

class DesignTokens {
  // Spacing & Padding
  static const double padXS = 4.0;
  static const double padS = 8.0;
  static const double padM = 12.0;
  static const double padL = 16.0;
  static const double padXL = 24.0;
  static const double padXXL = 32.0;

  // Corner Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;

  // Animation Durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
}
```

### File: `lib/core/theme/achromatic_theme.dart`

```dart
import 'package:flutter/material.dart';

class AchromaticTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: Colors.black,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: Colors.black,
        secondary: Color(0xFF616161),
        surface: Color(0xFFF5F5F5),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: Colors.black),
        bodyLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, color: Colors.black),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: Colors.white,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        secondary: Color(0xFF9E9E9E),
        surface: Color(0xFF212121),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: Colors.white),
        bodyLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, color: Colors.white),
      ),
    );
  }
}
```

---

## 2. Home & Browser Screens (Week 12, Days 1–5)

### Grid / List Virtualization & Layout Optimization
To achieve 60 fps, list scroll views must recycle widgets efficiently. We use `ListView.builder` combined with explicit heights for items to minimize layout passes.

### File: `lib/features/browser/presentation/widgets/file_list_row.dart`

```dart
import 'package:flutter/material.dart';
import '../../../../core/widgets/file_type_icon.dart';
import '../../../../core/utils/byte_formatter.dart';

class FileListRow extends StatelessWidget {
  final String filename;
  final String path;
  final int size;
  final int mtime;
  final String extension;
  final VoidCallback onTap;

  const FileListRow({
    super.key,
    required this.filename,
    required this.path,
    required this.size,
    required this.mtime,
    required this.extension,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 64.0, // Fixed height avoids layout reflows during fast scrolling
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            FileTypeIcon(extension: extension, size: 44.0),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    filename,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15.0),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    '${ByteFormatter.format(size)} • ${_timeString(mtime)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12.0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeString(int secondsSinceEpoch) {
    final date = DateTime.fromMillisecondsSinceEpoch(secondsSinceEpoch * 1000);
    return '${date.day}/${date.month}/${date.year}';
  }
}
```

---

## 3. Debounced Search Screen & EventChannel (Week 13, Days 1–5)

To prevent UI lag when searching through a large file database, results are streamed from the native engine using a Kotlin-backed `EventChannel` directly into a Flutter stream.

### File: `lib/features/search/presentation/widgets/streaming_results.dart`

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StreamingResults extends StatefulWidget {
  final String query;
  const StreamingResults({super.key, required this.query});

  @override
  State<StreamingResults> createState() => _StreamingResultsState();
}

class _StreamingResultsState extends State<StreamingResults> {
  static const _eventChannel = EventChannel('com.flux.channel/search_stream');
  StreamSubscription? _subscription;
  final List<int> _results = [];
  Timer? _debounce;

  @override
  void didUpdateWidget(StreamingResults oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _startSearchDebounced();
    }
  }

  void _startSearchDebounced() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _subscription?.cancel();
      setState(() {
        _results.clear();
      });

      _subscription = _eventChannel.receiveBroadcastStream(widget.query).listen(
        (data) {
          final List<int> batch = List<int>.from(data);
          setState(() {
            _results.addAll(batch);
          });
        },
        onError: (err) {
          debugPrint('Search error: \$err');
        },
      );
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final fid = _results[index];
        return ListTile(
          title: Text('File FID: \$fid'),
        );
      },
    );
  }
}
```

---

## 4. Progressive Thumbnail Engine (Week 14, Days 1–5)

### Performance Guideline:
- Decode at maximum size of 256x256 pixels in RGB_565 format (reduces memory consumption by 50% compared to ARGB_8888).
- Use `cacheWidth` and `cacheHeight` on the Flutter `Image` widgets.

```dart
// Progressive Thumbnail Rendering Widget
class ProgressiveThumbnail extends StatelessWidget {
  final List<int> thumbnailBytes;

  const ProgressiveThumbnail({super.key, required this.thumbnailBytes});

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      Uint8List.fromList(thumbnailBytes),
      cacheWidth: 256, // Enforces resized decoding in memory
      cacheHeight: 256,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low, // Bypasses slow high-quality filtering
    );
  }
}
```

---

## 5. Storage Analytics Screen & Donut Chart (Week 15, Days 1–5)

Renders category details using a custom `CustomPainter` to maintain 60 fps rendering.

### File: `lib/features/analytics/presentation/widgets/canvas_donut_chart.dart`

```dart
import 'dart:math';
import 'package:flutter/material.dart';

class CanvasDonutChart extends StatelessWidget {
  final List<double> percentages;
  final List<Color> colors;

  const CanvasDonutChart({
    super.key,
    required this.percentages,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(180.0, 180.0),
      painter: _DonutPainter(percentages: percentages, colors: colors),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> percentages;
  final List<Color> colors;

  _DonutPainter({required this.percentages, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 14.0;
    final Rect rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (size.width - strokeWidth) / 2,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngle = -pi / 2;
    for (int i = 0; i < percentages.length; i++) {
      final sweepAngle = percentages[i] * 2 * pi;
      paint.color = colors[i];
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}
```

---

## 6. Trash Screen & Undo Systems (Week 16, Days 1–5)

Files are stored in the Deletion BitSet (`deletionSet`) as tombstones. The trash screen presents these records and lets users restore them or prune them forever.

```dart
// Restore operation trigger
Future<void> restoreSelectedFiles(List<int> fids) async {
  await _methodChannel.invokeMethod('restoreTombstones', {'fids': fids});
}
```

---

## Verification & Testing Requirements
- **Automated Tests:**
  - Build mock `EventChannel` listener tests in Dart to verify data stream serialization.
  - Implement unit tests for `AchromaticTheme` matching palette configurations.
- **Manual Verification:**
  - Use Flutter DevTools CPU and Memory profile views to ensure frame build time is well below 16ms under 10k mock listings.
