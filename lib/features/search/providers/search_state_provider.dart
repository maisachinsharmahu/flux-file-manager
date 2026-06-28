import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchStateProvider = StateProvider<String>((ref) {
  return '';
});

final searchHistoryProvider = StateNotifierProvider<SearchHistoryNotifier, List<String>>((ref) {
  return SearchHistoryNotifier();
});

class SearchHistoryNotifier extends StateNotifier<List<String>> {
  SearchHistoryNotifier() : super([
    'Event Pictures',
    'Agreement Contract',
    'Investor Pitch Presentation',
    'Budget 2024 Spreadsheet',
    'Customer Feedback Survey',
    'Product Launch Presentation',
    'Training Manual',
  ]);

  void add(String query) {
    if (query.trim().isEmpty) return;
    state = [query, ...state.where((item) => item != query)].take(10).toList();
  }

  void remove(String query) {
    state = state.where((item) => item != query).toList();
  }

  void clear() {
    state = [];
  }
}
