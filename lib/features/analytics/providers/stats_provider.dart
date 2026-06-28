import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../bridge/flux_bridge.dart';

final statsProvider = FutureProvider<Map<dynamic, dynamic>>((ref) async {
  return await FluxBridge.getStorageStatistics();
});
