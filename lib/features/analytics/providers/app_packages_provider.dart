import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../bridge/flux_bridge.dart';

final appPackagesProvider = FutureProvider<List<dynamic>>((ref) async {
  return await FluxBridge.getAppStorageUsage();
});
