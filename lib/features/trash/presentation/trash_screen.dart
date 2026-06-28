import 'package:flutter/material.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
      ),
      body: const Center(
        child: Text('Tombstoned Files (Empty)'),
      ),
    );
  }
}
