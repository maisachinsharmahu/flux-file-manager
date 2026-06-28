import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../navigation/providers/navigation_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

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
        title: const Text('Settings'),
      ),
      body: ListView(
        children: const [
          ListTile(
            title: Text('Thermal Governor Throttling'),
            trailing: Icon(Icons.toggle_on_outlined),
          ),
          ListTile(
            title: Text('Embeddings Generation'),
            trailing: Icon(Icons.toggle_off_outlined),
          ),
        ],
      ),
    );
  }
}
