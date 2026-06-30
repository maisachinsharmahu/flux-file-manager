import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ModelSyncState { idle, downloading, indexing, completed, error }

class ModelSyncStatus {
  final ModelSyncState state;
  final double progress;
  final String statusText;
  final bool modelExists;

  ModelSyncStatus({
    required this.state,
    required this.progress,
    required this.statusText,
    this.modelExists = false,
  });

  ModelSyncStatus copyWith({
    ModelSyncState? state,
    double? progress,
    String? statusText,
    bool? modelExists,
  }) {
    return ModelSyncStatus(
      state: state ?? this.state,
      progress: progress ?? this.progress,
      statusText: statusText ?? this.statusText,
      modelExists: modelExists ?? this.modelExists,
    );
  }
}

class ModelSyncNotifier extends StateNotifier<ModelSyncStatus> {
  static const _methodChannel = MethodChannel('com.flux.channel/methods');
  static const _downloadEventChannel =
      EventChannel('com.flux.channel/download_progress');

  StreamSubscription? _progressSubscription;

  ModelSyncNotifier()
      : super(ModelSyncStatus(
          state: ModelSyncState.idle,
          progress: 0.0,
          statusText: 'Checking for on-device model...',
        )) {
    _checkAndAutoStart();
  }

  Future<void> _checkAndAutoStart() async {
    try {
      // Check if model already exists on device via native bridge
      final String? modelPath =
          await _methodChannel.invokeMethod('getModelFilePath');

      if (modelPath != null) {
        print('[ModelSync] Model already exists at: $modelPath');
        state = ModelSyncStatus(
          state: ModelSyncState.completed,
          progress: 1.0,
          statusText: 'MiniLM-L6 model loaded. Semantic search active.',
          modelExists: true,
        );
      } else {
        print('[ModelSync] Model not found. Auto-starting foreground download...');
        state = state.copyWith(
          statusText: 'Model not found. Starting background download...',
        );
        await Future.delayed(const Duration(milliseconds: 600));
        await startDownload();
      }
    } catch (e) {
      print('[ModelSync] Error checking model: $e');
      state = state.copyWith(
        state: ModelSyncState.error,
        statusText: 'Error checking model: $e',
      );
    }
  }

  /// Starts the Android Foreground Service download.
  /// The service uses HTTP Range headers to resume from the last downloaded byte.
  /// Download continues even when app is minimized/backgrounded.
  Future<void> startDownload() async {
    if (state.state == ModelSyncState.downloading ||
        state.state == ModelSyncState.indexing) return;

    state = ModelSyncStatus(
      state: ModelSyncState.downloading,
      progress: 0.0,
      statusText: 'Starting background download (survives minimize)...',
    );

    // Listen to progress events from the foreground service via EventChannel
    _progressSubscription?.cancel();
    _progressSubscription = _downloadEventChannel
        .receiveBroadcastStream()
        .listen(_onServiceEvent, onError: _onServiceError);

    try {
      // Start the Android foreground download service
      await _methodChannel.invokeMethod('startModelDownload');
      print('[ModelSync] Foreground download service started');
    } catch (e) {
      print('[ModelSync] Failed to start download service: $e');
      state = state.copyWith(
        state: ModelSyncState.error,
        statusText: 'Failed to start download: $e',
      );
    }
  }

  void _onServiceEvent(dynamic event) {
    final map = event as Map;
    final type = map['type'] as String;

    switch (type) {
      case 'progress':
        final percent = (map['percent'] as num).toInt();
        final received = (map['received'] as num).toInt();
        final total = (map['total'] as num).toInt();
        final receivedMb = (received / (1024 * 1024)).toStringAsFixed(1);
        final totalMb = (total / (1024 * 1024)).toStringAsFixed(1);
        print('[ModelSync] Download: $percent% ($receivedMb MB / $totalMb MB)');
        if (mounted) {
          state = state.copyWith(
            progress: (percent / 100.0).clamp(0.0, 0.99),
            statusText: 'Downloading: $receivedMb MB / $totalMb MB ($percent%)',
          );
        }
        break;

      case 'complete':
        print('[ModelSync] Download complete via foreground service!');
        _progressSubscription?.cancel();
        if (mounted) {
          state = ModelSyncStatus(
            state: ModelSyncState.completed,
            progress: 1.0,
            statusText: 'MiniLM-L6 model ready. Semantic search active.',
            modelExists: true,
          );
        }
        break;

      case 'error':
        final msg = map['message'] as String? ?? 'Unknown error';
        print('[ModelSync] Download error from service: $msg');
        // Partial file is preserved — next tap will resume from last byte
        if (mounted) {
          state = state.copyWith(
            state: ModelSyncState.error,
            statusText: 'Download paused. Partial file saved — tap to resume.',
          );
        }
        break;
    }
  }

  void _onServiceError(dynamic error) {
    print('[ModelSync] EventChannel error: $error');
  }

  Future<void> cancelDownload() async {
    _progressSubscription?.cancel();
    try {
      await _methodChannel.invokeMethod('cancelModelDownload');
    } catch (_) {}
    if (mounted) {
      state = state.copyWith(
        state: ModelSyncState.idle,
        statusText: 'Download cancelled. Tap to resume.',
      );
    }
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    super.dispose();
  }
}

final modelSyncProvider =
    StateNotifierProvider<ModelSyncNotifier, ModelSyncStatus>((ref) {
  return ModelSyncNotifier();
});
