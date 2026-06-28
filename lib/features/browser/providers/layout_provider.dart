import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BrowserLayout { list, grid }

final layoutProvider = StateNotifierProvider<LayoutNotifier, BrowserLayout>((ref) {
  return LayoutNotifier();
});

class LayoutNotifier extends StateNotifier<BrowserLayout> {
  LayoutNotifier() : super(BrowserLayout.list);

  void toggle() {
    state = state == BrowserLayout.list ? BrowserLayout.grid : BrowserLayout.list;
  }
}
