import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../bridge/flux_bridge.dart';
import 'search_state_provider.dart';

final searchStreamProvider = StreamProvider.autoDispose<dynamic>((ref) {
  final query = ref.watch(searchStateProvider);
  if (query.isEmpty) {
    return const Stream.empty();
  }
  return FluxBridge.searchStream(query, 50);
});
