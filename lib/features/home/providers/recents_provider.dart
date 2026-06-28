import 'package:flutter_riverpod/flutter_riverpod.dart';

final recentsProvider = StateProvider<List<int>>((ref) {
  return [];
});
