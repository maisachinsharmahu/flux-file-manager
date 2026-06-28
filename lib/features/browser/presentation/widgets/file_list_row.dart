import 'package:flutter/material.dart';
import 'progressive_thumbnail.dart';

class FileListRow extends StatelessWidget {
  final int index;
  const FileListRow({Key? key, required this.index}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const ProgressiveThumbnail(),
      title: Text('File $index.txt'),
      subtitle: const Text('Size: 12 KB | Modified: 2 hours ago'),
      trailing: const Icon(Icons.more_vert),
    );
  }
}
