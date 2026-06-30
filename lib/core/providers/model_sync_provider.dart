import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ModelSyncState { idle, downloading, indexing, completed }

class ModelSyncStatus {
  final ModelSyncState state;
  final double progress;
  final String statusText;

  ModelSyncStatus({
    required this.state,
    required this.progress,
    required this.statusText,
  });

  ModelSyncStatus copyWith({
    ModelSyncState? state,
    double? progress,
    String? statusText,
  }) {
    return ModelSyncStatus(
      state: state ?? this.state,
      progress: progress ?? this.progress,
      statusText: statusText ?? this.statusText,
    );
  }
}

class ModelSyncNotifier extends StateNotifier<ModelSyncStatus> {
  ModelSyncNotifier()
      : super(ModelSyncStatus(
          state: ModelSyncState.idle,
          progress: 0.0,
          statusText: 'Semantic model not downloaded. Tap below to download MiniLM-L6.',
        ));

  void startDownload() {
    if (state.state != ModelSyncState.idle) return;

    state = ModelSyncStatus(
      state: ModelSyncState.downloading,
      progress: 0.0,
      statusText: 'Downloading MiniLM-L6 model (22.4 MB)... 0%',
    );

    // Simulate Model Download progress increments
    double progress = 0.0;
    Timer.periodic(const Duration(milliseconds: 150), (timer) {
      progress += 0.05;
      if (progress >= 1.0) {
        timer.cancel();
        _startIndexing();
      } else {
        state = state.copyWith(
          progress: progress,
          statusText: 'Downloading MiniLM-L6 model (22.4 MB)... ${(progress * 100).toInt()}%',
        );
      }
    });
  }

  void _startIndexing() {
    state = ModelSyncStatus(
      state: ModelSyncState.indexing,
      progress: 0.0,
      statusText: 'Initializing HNSW Vector Graph... 0%',
    );

    // Simulate vector embedding indexing of files
    double progress = 0.0;
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      progress += 0.1;
      if (progress >= 1.0) {
        timer.cancel();
        state = ModelSyncStatus(
          state: ModelSyncState.completed,
          progress: 1.0,
          statusText: 'MiniLM-L6 vector graph loaded successfully. Semantic search active.',
        );
      } else {
        state = state.copyWith(
          progress: progress,
          statusText: 'Generating semantic embeddings... ${(progress * 30).toInt()}/30 files mapped',
        );
      }
    });
  }
}

final modelSyncProvider = StateNotifierProvider<ModelSyncNotifier, ModelSyncStatus>((ref) {
  return ModelSyncNotifier();
});
