import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../bridge/flux_bridge.dart';
import '../../../core/providers/platform_monitor_provider.dart';

final storageStatusProvider = FutureProvider<Map<dynamic, dynamic>>((ref) async {
  ref.read(platformMonitorProvider.notifier).logAction(
    'getStorageStatistics',
    'PENDING',
    'Querying native category statistics...',
  );
  final stats = await FluxBridge.getStorageStatistics();
  ref.read(platformMonitorProvider.notifier).logAction(
    'getStorageStatistics',
    'SUCCESS',
    'Loaded storage size statistics: ${stats.keys.join(", ")}',
  );
  return stats;
});
 