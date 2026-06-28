import 'package:flutter/material.dart';

class ProgressiveThumbnail extends StatelessWidget {
  const ProgressiveThumbnail({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      color: Colors.grey[300],
      child: const Icon(Icons.insert_drive_file, color: Colors.grey),
    );
  }
}
