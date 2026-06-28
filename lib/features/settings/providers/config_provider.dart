import 'package:flutter_riverpod/flutter_riverpod.dart';

final configProvider = StateNotifierProvider<ConfigNotifier, Map<String, bool>>((ref) {
  return ConfigNotifier();
});

class ConfigNotifier extends StateNotifier<Map<String, bool>> {
  ConfigNotifier() : super({'thermalThrottling': true, 'embeddingsEnabled': false});

  void toggle(String key) {
    state = Map.from(state)..update(key, (val) => !val);
  }
}
