import 'package:flutter/material.dart';

class AppStorageRow extends StatelessWidget {
  final int index;
  const AppStorageRow({Key? key, required this.index}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.apps),
      title: Text('App Package $index'),
      trailing: const Text('120 MB'),
    );
  }
}
