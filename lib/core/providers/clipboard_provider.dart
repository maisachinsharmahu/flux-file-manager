import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ClipboardMode { copy, cut }

class ClipboardState {
  final Set<int> fids;
  final ClipboardMode mode;
  final String sourcePath; // display label (e.g. "Internal Storage/Downloads")
  final int fileCount;
  final int folderCount;

  const ClipboardState({
    this.fids = const {},
    this.mode = ClipboardMode.copy,
    this.sourcePath = '',
    this.fileCount = 0,
    this.folderCount = 0,
  });

  bool get isEmpty => fids.isEmpty;
  bool get isNotEmpty => fids.isNotEmpty;

  int get totalCount => fileCount + folderCount;

  String get label {
    final parts = <String>[];
    if (folderCount > 0) parts.add('$folderCount ${folderCount == 1 ? 'folder' : 'folders'}');
    if (fileCount > 0) parts.add('$fileCount ${fileCount == 1 ? 'file' : 'files'}');
    return parts.join(', ');
  }

  ClipboardState copyWith({
    Set<int>? fids,
    ClipboardMode? mode,
    String? sourcePath,
    int? fileCount,
    int? folderCount,
  }) {
    return ClipboardState(
      fids: fids ?? this.fids,
      mode: mode ?? this.mode,
      sourcePath: sourcePath ?? this.sourcePath,
      fileCount: fileCount ?? this.fileCount,
      folderCount: folderCount ?? this.folderCount,
    );
  }
}

class ClipboardNotifier extends StateNotifier<ClipboardState> {
  ClipboardNotifier() : super(const ClipboardState());

  void copyFiles({
    required Set<int> fids,
    required String sourcePath,
    required int fileCount,
    required int folderCount,
  }) {
    state = ClipboardState(
      fids: Set.unmodifiable(fids),
      mode: ClipboardMode.copy,
      sourcePath: sourcePath,
      fileCount: fileCount,
      folderCount: folderCount,
    );
  }

  void cutFiles({
    required Set<int> fids,
    required String sourcePath,
    required int fileCount,
    required int folderCount,
  }) {
    state = ClipboardState(
      fids: Set.unmodifiable(fids),
      mode: ClipboardMode.cut,
      sourcePath: sourcePath,
      fileCount: fileCount,
      folderCount: folderCount,
    );
  }

  void clear() {
    state = const ClipboardState();
  }
}

final clipboardProvider =
    StateNotifierProvider<ClipboardNotifier, ClipboardState>(
  (ref) => ClipboardNotifier(),
);
