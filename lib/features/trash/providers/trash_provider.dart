import 'package:flutter_riverpod/flutter_riverpod.dart';

final trashProvider = StateNotifierProvider<TrashNotifier, List<int>>((ref) {
  return TrashNotifier();
});

class TrashNotifier extends StateNotifier<List<int>> {
  TrashNotifier() : super([]);

  void loadTrash() {
    state = [];
  }
}
