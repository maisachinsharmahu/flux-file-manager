import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ImageViewerScreen — displays the native zoomable image view PlatformView.
///
/// Under the hood, this loads the image with BitmapRegionDecoder and renders it in tiles.
/// Avoids OOMs on large images.
class ImageViewerScreen extends StatelessWidget {
  final String path;
  final String title;

  const ImageViewerScreen({
    Key? key,
    required this.path,
    required this.title,
  }) : super(key: key);

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
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Center(
        child: AndroidView(
          viewType: 'com.flux/image_viewer',
          layoutDirection: TextDirection.ltr,
          creationParams: <String, dynamic>{
            'path': path,
          },
          creationParamsCodec: const StandardMessageCodec(),
          // Capture drag and scale gesture events so they bypass Flutter's gesture arena and go directly to native view
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
          },
        ),
      ),
    );
  }
}
