import 'package:flutter_riverpod/flutter_riverpod.dart';

final activeIndexProvider = StateProvider<int>((ref) {
  return 0;
});
