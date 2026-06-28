import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectionProvider = StateNotifierProvider<SelectionNotifier, Set<int>>((ref) {
  return SelectionNotifier();
});

class SelectionNotifier extends StateNotifier<Set<int>> {
  SelectionNotifier() : super(<int>{});

  void toggle(int fid) {
    if (state.contains(fid)) {
      state = Set.from(state)..remove(fid);
    } else {
      state = Set.from(state)..add(fid);
    }
  }

  void clear() {
    state = <int>{};
  }
}
