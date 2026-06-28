import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeCardProvider = StateNotifierProvider<HomeCardNotifier, List<String>>((ref) {
  return HomeCardNotifier();
});

class HomeCardNotifier extends StateNotifier<List<String>> {
  HomeCardNotifier() : super(['Junk Detected', 'Duplicates Found']);
}
