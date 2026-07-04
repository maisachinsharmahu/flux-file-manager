import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CopyTaskDisplayMode {
  compact,
  expanded,
  completedCompact,
  completedExpanded,
}

enum GlobalTaskType { copy, delete, move, archive, unarchive, createFolder, restore }

class CopyTaskState {
  final bool isActive;
  final double progress;
  final bool isCompleted;
  final CopyTaskDisplayMode displayMode;
  final GlobalTaskType taskType;

  /// Number of top-level files/folders being operated on.
  final int fileCount;

  /// Destination path (empty for delete/restore).
  final String destPath;

  /// Speed string shown in the overlay, e.g. "124 MB/s" or "~instant".
  final String speedLabel;

  /// Whether this is a cut (move) operation (so we know the overlay title).
  final bool isCut;

  CopyTaskState({
    this.isActive = false,
    this.progress = 0.0,
    this.isCompleted = false,
    this.displayMode = CopyTaskDisplayMode.compact,
    this.taskType = GlobalTaskType.copy,
    this.fileCount = 0,
    this.destPath = '',
    this.speedLabel = '',
    this.isCut = false,
  });

  CopyTaskState copyWith({
    bool? isActive,
    double? progress,
    bool? isCompleted,
    CopyTaskDisplayMode? displayMode,
    GlobalTaskType? taskType,
    int? fileCount,
    String? destPath,
    String? speedLabel,
    bool? isCut,
  }) {
    return CopyTaskState(
      isActive: isActive ?? this.isActive,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      displayMode: displayMode ?? this.displayMode,
      taskType: taskType ?? this.taskType,
      fileCount: fileCount ?? this.fileCount,
      destPath: destPath ?? this.destPath,
      speedLabel: speedLabel ?? this.speedLabel,
      isCut: isCut ?? this.isCut,
    );
  }

  /// Human-readable destination folder name.
  String get destFolderName {
    if (destPath.isEmpty) return '';
    final name = destPath.split('/').where((s) => s.isNotEmpty).last;
    return name;
  }

  /// Short label: "3 items" or "1 item".
  String get itemCountLabel =>
      '$fileCount ${fileCount == 1 ? 'item' : 'items'}';
}

class CopyTaskNotifier extends StateNotifier<CopyTaskState> {
  CopyTaskNotifier() : super(CopyTaskState());

  Timer? _timer;
  int _currentTaskId = 0;

  /// Starts a mocked animated task (for UI demos / non-real operations).
  int startMockTask(GlobalTaskType type) {
    _timer?.cancel();
    _currentTaskId++;
    final taskId = _currentTaskId;

    state = CopyTaskState(
      isActive: true,
      progress: 0.0,
      isCompleted: false,
      displayMode: CopyTaskDisplayMode.compact,
      taskType: type,
    );

    const interval = Duration(milliseconds: 150);
    _timer = Timer.periodic(interval, (timer) {
      if (taskId != _currentTaskId) {
        timer.cancel();
        return;
      }
      if (state.progress >= 1.0) {
        timer.cancel();
        state = state.copyWith(
          isCompleted: true,
          displayMode: CopyTaskDisplayMode.completedExpanded,
        );
        Future.delayed(const Duration(seconds: 3), () {
          if (taskId == _currentTaskId &&
              state.isCompleted &&
              state.isActive &&
              state.taskType == type) {
            state = state.copyWith(isActive: false);
          }
        });
      } else {
        final newProgress = state.progress + 0.04;
        state = state.copyWith(progress: newProgress > 1.0 ? 1.0 : newProgress);
      }
    });
    return taskId;
  }

  /// Starts a real task driven by actual progress callbacks.
  /// [fileCount] is the number of top-level items being processed.
  /// [destPath] is the destination folder path (empty for delete).
  /// [isCut] distinguishes move from copy in the overlay.
  int startRealTask(
    GlobalTaskType type, {
    int fileCount = 0,
    String destPath = '',
    bool isCut = false,
  }) {
    _timer?.cancel();
    _currentTaskId++;
    state = CopyTaskState(
      isActive: true,
      progress: 0.0,
      isCompleted: false,
      displayMode: CopyTaskDisplayMode.compact,
      taskType: type,
      fileCount: fileCount,
      destPath: destPath,
      isCut: isCut,
    );
    return _currentTaskId;
  }

  void updateProgress(double progress, int taskId) {
    if (taskId != _currentTaskId) return;
    if (!state.isActive || state.isCompleted) return;
    state = state.copyWith(
      progress: progress.clamp(0.0, 1.0),
    );
  }

  /// [elapsedMs] — real wall-clock duration of the operation in milliseconds.
  /// [totalBytes] — total bytes processed (for MB/s calculation). Pass 0 to skip.
  void completeTask(int taskId, {int elapsedMs = 0, int totalBytes = 0}) {
    if (taskId != _currentTaskId) return;
    if (!state.isActive) return;
    final type = state.taskType;

    String speedLabel = '';
    if (elapsedMs > 0) {
      if (elapsedMs < 50) {
        speedLabel = '~instant';
      } else if (totalBytes > 0) {
        final mbPerSec = (totalBytes / 1048576.0) / (elapsedMs / 1000.0);
        speedLabel = '${mbPerSec.toStringAsFixed(0)} MB/s';
      } else {
        speedLabel = '$elapsedMs ms';
      }
    }

    state = state.copyWith(
      progress: 1.0,
      isCompleted: true,
      displayMode: CopyTaskDisplayMode.completedExpanded,
      speedLabel: speedLabel,
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (taskId == _currentTaskId &&
          state.isCompleted &&
          state.isActive &&
          state.taskType == type) {
        state = state.copyWith(isActive: false);
      }
    });
  }

  void failTask(int taskId) {
    if (taskId != _currentTaskId) return;
    _timer?.cancel();
    state = CopyTaskState();
  }

  void toggleExpansion() {
    if (!state.isActive) return;

    CopyTaskDisplayMode nextMode;
    switch (state.displayMode) {
      case CopyTaskDisplayMode.compact:
        nextMode = CopyTaskDisplayMode.expanded;
        break;
      case CopyTaskDisplayMode.expanded:
        nextMode = CopyTaskDisplayMode.compact;
        break;
      case CopyTaskDisplayMode.completedCompact:
        nextMode = CopyTaskDisplayMode.completedExpanded;
        break;
      case CopyTaskDisplayMode.completedExpanded:
        nextMode = CopyTaskDisplayMode.completedCompact;
        break;
    }
    state = state.copyWith(displayMode: nextMode);
  }

  void cancel() {
    _timer?.cancel();
    _currentTaskId++;
    state = CopyTaskState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final copyTaskProvider = StateNotifierProvider<CopyTaskNotifier, CopyTaskState>(
  (ref) {
    return CopyTaskNotifier();
  },
);
