import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../navigation/providers/navigation_provider.dart';

class TrashScreen extends ConsumerWidget {
  const TrashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(activeIndexProvider.notifier).state = 0; // Return to Home screen
          },
        ),
        title: const Text('Trash'),
      ),
      body: const Center(
        child: Text('Tombstoned Files (Empty)'),
      ),
    );
  }
}
