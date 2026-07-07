import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../bridge/flux_bridge.dart';

class AudioState {
  final String path;
  final String title;
  final bool isPlaying;
  final int position;
  final int duration;
  final List<int> amplitudes;
  final bool isFullScreen;
  final bool isLoaded;

  AudioState({
    this.path = '',
    this.title = '',
    this.isPlaying = false,
    this.position = 0,
    this.duration = 0,
    this.amplitudes = const [],
    this.isFullScreen = false,
    this.isLoaded = false,
  });

  AudioState copyWith({
    String? path,
    String? title,
    bool? isPlaying,
    int? position,
    int? duration,
    List<int>? amplitudes,
    bool? isFullScreen,
    bool? isLoaded,
  }) {
    return AudioState(
      path: path ?? this.path,
      title: title ?? this.title,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      amplitudes: amplitudes ?? this.amplitudes,
      isFullScreen: isFullScreen ?? this.isFullScreen,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class AudioPlayerNotifier extends StateNotifier<AudioState> {
  AudioPlayerNotifier() : super(AudioState());

  Timer? _pollingTimer;

  Future<void> openAudio(String path, String title) async {
    if (state.path != path) {
      await stop();
      
      state = AudioState(
        path: path,
        title: title,
        isLoaded: false,
        isPlaying: false,
        isFullScreen: false,
      );

      // Load waveform
      try {
        final points = await FluxBridge.extractAudioWaveform(path, bars: 128);
        state = state.copyWith(
          amplitudes: points,
          isLoaded: true,
        );
      } catch (e) {
        debugPrint('[AudioPlayerNotifier] Waveform load error: $e');
        state = state.copyWith(
          amplitudes: List.filled(128, 2),
          isLoaded: true,
        );
      }
    } else {
      state = state.copyWith(
        isLoaded: true,
      );
    }
  }

  Future<void> play() async {
    if (state.path.isEmpty) return;

    final success = await FluxBridge.playAudio(state.path);
    if (success) {
      final dur = await FluxBridge.getAudioDuration();
      state = state.copyWith(
        isPlaying: true,
        duration: dur,
      );
      _startPolling();
    }
  }

  Future<void> pause() async {
    final success = await FluxBridge.pauseAudio();
    if (success) {
      state = state.copyWith(isPlaying: false);
      _pollingTimer?.cancel();
    }
  }

  Future<void> seek(int positionMs) async {
    await FluxBridge.seekAudio(positionMs);
    state = state.copyWith(position: positionMs);
  }

  Future<void> stop() async {
    _pollingTimer?.cancel();
    await FluxBridge.stopAudio();
    state = AudioState();
  }

  void setFullScreen(bool full) {
    state = state.copyWith(isFullScreen: full);
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) async {
      if (state.isPlaying) {
        final pos = await FluxBridge.getAudioPosition();
        final dur = await FluxBridge.getAudioDuration();
        state = state.copyWith(
          position: pos,
          duration: dur,
        );
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

final audioPlayerProvider = StateNotifierProvider<AudioPlayerNotifier, AudioState>((ref) {
  return AudioPlayerNotifier();
});
