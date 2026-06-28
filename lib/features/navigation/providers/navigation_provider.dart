import 'package:flutter_riverpod/flutter_riverpod.dart';

final activeIndexProvider = StateProvider<int>((ref) {
  return 0;
});

final selectedAnalyticsCategoryProvider = StateProvider<String>((ref) {
  return 'Photos';
});

final selectedBrowserCategoryProvider = StateProvider<String?>((ref) {
  return null;
});
