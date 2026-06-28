import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../navigation/providers/navigation_provider.dart';
import 'widgets/canvas_donut_chart.dart';
import 'widgets/category_detail_row.dart';
import 'widgets/app_storage_row.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

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
        title: const Text('Storage Analytics'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height: 200,
              child: CanvasDonutChart(),
            ),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                return CategoryDetailRow(index: index);
              },
            ),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                return AppStorageRow(index: index);
              },
            ),
          ],
        ),
      ),
    );
  }
}
