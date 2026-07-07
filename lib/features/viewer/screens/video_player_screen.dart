import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// VideoPlayerScreen — native video player PlatformView with Flutter custom control HUD overlays.
class VideoPlayerScreen extends StatefulWidget {
  final String path;
  final String title;

  const VideoPlayerScreen({
    Key? key,
    required this.path,
    required this.title,
  }) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  MethodChannel? _channel;
  bool _isPlaying = false;
  bool _isPrepared = false;
  int _duration = 0;
  int _position = 0;
  Timer? _positionTimer;

  // Aspect ratio parameters
  double _videoWidth = 0;
  double _videoHeight = 0;

  // Custom player properties
  double _playbackSpeed = 1.0;
  bool _isMuted = false;

  Future<void> _setSpeed(double speed) async {
    await _channel?.invokeMethod('setSpeed', {'speed': speed});
    setState(() => _playbackSpeed = speed);
  }

  Future<void> _toggleMute() async {
    final nextMute = !_isMuted;
    await _channel?.invokeMethod('setVolume', {'volume': nextMute ? 0.0 : 1.0});
    setState(() => _isMuted = nextMute);
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    super.dispose();
  }

  void _onPlatformViewCreated(int id) {
    final channel = MethodChannel('com.flux.channel/video_player_$id');
    _channel = channel;

    // Listen to events from Kotlin (e.g. prepared status, errors)
    channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onPrepared':
          final args = call.arguments as Map?;
          setState(() {
            _isPrepared = true;
            _duration = args?['duration'] ?? 0;
            _videoWidth = (args?['width'] ?? 0).toDouble();
            _videoHeight = (args?['height'] ?? 0).toDouble();
          });
          // Auto start playing
          _play();
          break;
        case 'onCompleted':
          setState(() {
            _isPlaying = false;
            _position = 0;
          });
          _positionTimer?.cancel();
          break;
        case 'onError':
          final error = call.arguments as String?;
          debugPrint('Native Video error: $error');
          break;
      }
    });
  }

  // ── Player Controls ────────────────────────────────────────────────────────

  Future<void> _play() async {
    final success = await _channel?.invokeMethod<bool>('play') ?? false;
    if (success) {
      setState(() => _isPlaying = true);
      _startPositionPolling();
    }
  }

  Future<void> _pause() async {
    final success = await _channel?.invokeMethod<bool>('pause') ?? false;
    if (success) {
      setState(() => _isPlaying = false);
      _positionTimer?.cancel();
    }
  }

  Future<void> _seek(int targetMs) async {
    await _channel?.invokeMethod('seekTo', {'position': targetMs});
    setState(() => _position = targetMs);
  }

  void _startPositionPolling() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) async {
      if (_isPlaying && _isPrepared) {
        final pos = await _channel?.invokeMethod<int>('getCurrentPosition') ?? 0;
        setState(() => _position = pos);
      }
    });
  }

  // ── Helper formatting ──────────────────────────────────────────────────────

  String _formatTime(int ms) {
    final totalSecs = ms ~/ 1000;
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final double aspectRatio = (_videoWidth > 0 && _videoHeight > 0)
        ? _videoWidth / _videoHeight
        : 16 / 9;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Stack(
        children: [
          // Centered Native video frame
          Center(
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: AndroidView(
                viewType: 'com.flux/video_viewer',
                layoutDirection: TextDirection.ltr,
                creationParams: <String, dynamic>{
                  'path': widget.path,
                },
                creationParamsCodec: const StandardMessageCodec(),
                onPlatformViewCreated: _onPlatformViewCreated,
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                },
              ),
            ),
          ),

          // Custom control overlay HUD
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withOpacity(0.6),
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Playback seek slider bar
                  Row(
                    children: [
                      Text(
                        _formatTime(_position),
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3.0,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                            activeTrackColor: const Color(0xFF00BCD4),
                            inactiveTrackColor: Colors.white24,
                            thumbColor: const Color(0xFF00BCD4),
                          ),
                          child: Slider(
                            value: _position.toDouble().clamp(0.0, _duration.toDouble()),
                            min: 0,
                            max: _duration.toDouble() > 0 ? _duration.toDouble() : 1.0,
                            onChanged: (val) {
                              _seek(val.toInt());
                            },
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(_duration),
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Media Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mute/Unmute
                      IconButton(
                        icon: Icon(
                          _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: _toggleMute,
                      ),
                      
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 28),
                            onPressed: () {
                              final target = (_position - 10000).clamp(0, _duration);
                              _seek(target);
                            },
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            iconSize: 48,
                            icon: Icon(
                              _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                              color: const Color(0xFF00BCD4),
                            ),
                            onPressed: () {
                              if (!_isPrepared) return;
                              if (_isPlaying) {
                                _pause();
                              } else {
                                _play();
                              }
                            },
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 28),
                            onPressed: () {
                              final target = (_position + 10000).clamp(0, _duration);
                              _seek(target);
                            },
                          ),
                        ],
                      ),

                      // Speed selector dropdown popup
                      PopupMenuButton<double>(
                        initialValue: _playbackSpeed,
                        icon: const Icon(Icons.speed_rounded, color: Colors.white, size: 24),
                        tooltip: 'Playback speed',
                        onSelected: _setSpeed,
                        color: const Color(0xFF1E1E1E),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 0.25,
                            child: Text('0.25x', style: TextStyle(color: Colors.white70)),
                          ),
                          const PopupMenuItem(
                            value: 0.5,
                            child: Text('0.5x', style: TextStyle(color: Colors.white70)),
                          ),
                          const PopupMenuItem(
                            value: 1.0,
                            child: Text('Normal', style: TextStyle(color: Colors.white70)),
                          ),
                          const PopupMenuItem(
                            value: 1.25,
                            child: Text('1.25x', style: TextStyle(color: Colors.white70)),
                          ),
                          const PopupMenuItem(
                            value: 1.5,
                            child: Text('1.5x', style: TextStyle(color: Colors.white70)),
                          ),
                          const PopupMenuItem(
                            value: 2.0,
                            child: Text('2.0x', style: TextStyle(color: Colors.white70)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
