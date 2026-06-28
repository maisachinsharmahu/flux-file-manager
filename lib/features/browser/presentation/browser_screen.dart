import 'package:flutter/material.dart';
import 'widgets/browser_toolbar.dart';
import 'widgets/file_list_row.dart';

class BrowserScreen extends StatelessWidget {
  const BrowserScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
