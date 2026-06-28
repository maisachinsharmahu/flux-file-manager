import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../navigation/providers/navigation_provider.dart';
import 'widgets/browser_toolbar.dart';
import 'widgets/file_list_row.dart';

class BrowserScreen extends ConsumerWidget {
  const BrowserScreen({Key? key}) : super(key: key);

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
        title: const Text('Browse Files'),
      ),
      body: const Column(
        children: [
          BrowserToolbar(),
          Expanded(
            child: ListViewRowPlaceholder(),
          ),
        ],
      ),
    );
  }
}

class ListViewRowPlaceholder extends StatelessWidget {
  const ListViewRowPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return FileListRow(index: index);
      },
    );
  }
}
