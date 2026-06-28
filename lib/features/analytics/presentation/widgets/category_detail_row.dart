import 'package:flutter/material.dart';

class CategoryDetailRow extends StatelessWidget {
  final int index;
  const CategoryDetailRow({Key? key, required this.index}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.category_outlined),
      title: Text('Category $index'),
      trailing: const Text('2.5 GB'),
    );
  }
}
