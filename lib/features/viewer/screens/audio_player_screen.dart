import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../bridge/flux_bridge.dart';

/// AudioPlayerScreen — premium audio player featuring native waveform extraction
/// and an interactive CustomPainter-drawn waveform seek bar.
class AudioPlayerScreen extends StatefulWidget {
  final String path;
  final String title;

  const AudioPlayerScreen({
    Key? key,
    required this.path,
    required this.title,
  }) : super(key: key);

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  List<int> _amplitudes = [];
  bool _isLoading = true;
  bool _isPlaying = false;
  int _position = 0;
  int _duration = 0;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadWaveform();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    FluxBridge.stopAudio();
    super.dispose();
  }

  Future<void> _loadWaveform() async {
    try {
      final points = await FluxBridge.extractAudioWaveform(widget.path, bars: 128);
      setState(() {
        _amplitudes = points;
        _isLoading = false;
      });
      // Start audio playing
      _play();
    } catch (e) {
      debugPrint('Waveform extraction failed: $e');
      setState(() => _isLoading = false);
    }
  }

  // ── Audio Controls ─────────────────────────────────────────────────────────

  Future<void> _play() async {
    final success = await FluxBridge.playAudio(widget.path);
    if (success) {
      final dur = await FluxBridge.getAudioDuration();
      setState(() {
        _isPlaying = true;
        _duration = dur;
      });
      _startPolling();
    }
  }

  Future<void> _pause() async {
    final success = await FluxBridge.pauseAudio();
    if (success) {
      setState(() => _isPlaying = false);
      _pollingTimer?.cancel();
    }
  }

  Future<void> _seek(int positionMs) async {
    await FluxBridge.seekAudio(positionMs);
    setState(() => _position = positionMs);
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) async {
      if (_isPlaying) {
        final pos = await FluxBridge.getAudioPosition();
        final dur = await FluxBridge.getAudioDuration();
        setState(() {
          _position = pos;
          _duration = dur;
        });
      }
    });
  }

  // ── Time helper ────────────────────────────────────────────────────────────

  String _formatTime(int ms) {
    final totalSecs = ms ~/ 1000;
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Vinyl record icon placeholder for music
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF161616),
                      border: Border.all(color: const Color(0xFF262626), width: 8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF00BCD4),
                        ),
                        child: const Icon(Icons.music_note_rounded, color: Colors.black, size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Song Title
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 32),

                  // Interactive Waveform Seekbar
                  GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      final RenderBox box = context.findRenderObject() as RenderBox;
                      final localOffset = box.globalToLocal(details.globalPosition);
                      final progress = (localOffset.dx - 24).clamp(0.0, box.size.width - 48) / (box.size.width - 48);
                      _seek((progress * _duration).toInt());
                    },
                    onTapUp: (details) {
                      final RenderBox box = context.findRenderObject() as RenderBox;
                      final localOffset = box.globalToLocal(details.globalPosition);
                      final progress = (localOffset.dx - 24).clamp(0.0, box.size.width - 48) / (box.size.width - 48);
                      _seek((progress * _duration).toInt());
                    },
                    child: CustomPaint(
                      size: const Size(double.infinity, 80),
                      painter: WaveformPainter(
                        amplitudes: _amplitudes,
                        progress: _duration > 0 ? _position / _duration : 0.0,
                        activeColor: const Color(0xFF00BCD4),
                        inactiveColor: const Color(0xFF2E2E2E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Time counters
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTime(_position),
                        style: const TextStyle(color: Colors.white60, fontSize: 12, fontFamily: 'monospace'),
                      ),
                      Text(
                        _formatTime(_duration),
                        style: const TextStyle(color: Colors.white60, fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Main Player control layout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 36),
                        onPressed: () => _seek(0),
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        iconSize: 64,
                        icon: Icon(
                          _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                          color: const Color(0xFF00BCD4),
                        ),
                        onPressed: () {
                          if (_isPlaying) {
                            _pause();
                          } else {
                            _play();
                          }
                        },
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 36),
                        onPressed: () => _seek(_duration),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

/// Custom painter to draw rounded bars reflecting decoded audio amplitudes.
class WaveformPainter extends CustomPainter {
  final List<int> amplitudes;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  WaveformPainter({
    required this.amplitudes,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final double barWidth = size.width / amplitudes.length;
    final double spacing = barWidth * 0.25;
    final double drawWidth = barWidth - spacing;

    for (int i = 0; i < amplitudes.length; i++) {
      final double amp = amplitudes[i].toDouble() / 100.0; // normalization [0, 1]
      final double barHeight = size.height * amp;

      final double x = i * barWidth;
      final double y = (size.height - barHeight) / 2.0;

      // Color coding based on seek progress
      final bool isActive = (i / amplitudes.length) <= progress;
      paint.color = isActive ? activeColor : inactiveColor;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, drawWidth, barHeight),
          Radius.circular(drawWidth / 2.0),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.amplitudes != amplitudes;
  }
}
