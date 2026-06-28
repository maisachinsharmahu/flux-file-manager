import 'package:flutter/material.dart';
import 'progressive_thumbnail.dart';

class FileGridCell extends StatelessWidget {
  final int index;
  const FileGridCell({Key? key, required this.index}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const ProgressiveThumbnail(),
          const SizedBox(height: 8),
          Text('File $index.txt'),
        ],
      ),
    );
  }
}
