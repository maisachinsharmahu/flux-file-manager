import 'package:flutter_riverpod/flutter_riverpod.dart';

final fileSystemProvider = StateNotifierProvider<FileSystemNotifier, String>((ref) {
  return FileSystemNotifier();
});

class FileSystemNotifier extends StateNotifier<String> {
  FileSystemNotifier() : super('/sdcard');

  void navigateTo(String path) {
    state = path;
  }
}
