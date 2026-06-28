import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CopyTaskDisplayMode {
  compact,
  expanded,
  completedCompact,
  completedExpanded,
}

enum GlobalTaskType { copy, delete, move, archive, unarchive }

class CopyTaskState {
  final bool isActive;
  final double progress;
  final bool isCompleted;
  final CopyTaskDisplayMode displayMode;
  final GlobalTaskType taskType;

  CopyTaskState({
    this.isActive = false,
    this.progress = 0.0,
    this.isCompleted = false,
    this.displayMode = CopyTaskDisplayMode.compact,
    this.taskType = GlobalTaskType.copy,
  });

  CopyTaskState copyWith({
    bool? isActive,
    double? progress,
    bool? isCompleted,
    CopyTaskDisplayMode? displayMode,
    GlobalTaskType? taskType,
  }) {
    return CopyTaskState(
      isActive: isActive ?? this.isActive,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      displayMode: displayMode ?? this.displayMode,
      taskType: taskType ?? this.taskType,
    );
  }
}

class CopyTaskNotifier extends StateNotifier<CopyTaskState> {
  CopyTaskNotifier() : super(CopyTaskState());

  Timer? _timer;

  void startMockTask(GlobalTaskType type) {
    _timer?.cancel();

    // Always start compact
    state = CopyTaskState(
      isActive: true,
      progress: 0.0,
      isCompleted: false,
      displayMode: CopyTaskDisplayMode.compact,
      taskType: type,
    );

    const interval = Duration(milliseconds: 150);
    _timer = Timer.periodic(interval, (timer) {
      if (state.progress >= 1.0) {
        timer.cancel();

        // Always transition to completedExpanded (big completion) when reaching 100%
        state = state.copyWith(
          isCompleted: true,
          displayMode: CopyTaskDisplayMode.completedExpanded,
        );

        // Auto-dismiss after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (state.isCompleted && state.isActive && state.taskType == type) {
            state = state.copyWith(isActive: false);
          }
        });
      } else {
        final newProgress = state.progress + 0.04;
        state = state.copyWith(progress: newProgress > 1.0 ? 1.0 : newProgress);
      }
    });
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
