import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_player_provider.dart';

/// AudioPlayerScreen — premium audio player featuring centered overlay card view
/// that seamlessly expands to fullscreen playback mode, syncing playback state.
class AudioPlayerScreen extends ConsumerStatefulWidget {
  final String path;
  final String title;

  const AudioPlayerScreen({
    Key? key,
    required this.path,
    required this.title,
  }) : super(key: key);

  @override
  ConsumerState<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends ConsumerState<AudioPlayerScreen> {
  @override
  void initState() {
    super.initState();
    // Schedule initialization after frame binding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioPlayerProvider.notifier).openAudio(widget.path, widget.title);
      ref.read(audioPlayerProvider.notifier).play();
    });
  }

  @override
  void dispose() {
    // Stop playback when the entire viewer route is dismissed
    // We run it post-frame or check if still active
    super.dispose();
  }

  String _formatTime(int ms) {
    final totalSecs = ms ~/ 1000;
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildMiniPlayer(AudioState state) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF161616).withOpacity(0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white12, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.music_note_rounded, color: Color(0xFF00BCD4), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'NOW PLAYING',
                          style: TextStyle(color: Color(0xFF00BCD4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        ref.read(audioPlayerProvider.notifier).stop();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Audio Title (Tap to expand)
                GestureDetector(
                  onTap: () => ref.read(audioPlayerProvider.notifier).setFullScreen(true),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tap to expand full screen',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Mini control row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10_rounded, color: Colors.white70, size: 24),
                      onPressed: () {
                        final target = (state.position - 10000).clamp(0, state.duration);
                        ref.read(audioPlayerProvider.notifier).seek(target);
                      },
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      iconSize: 48,
                      icon: Icon(
                        state.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                        color: const Color(0xFF00BCD4),
                      ),
                      onPressed: () {
                        final n = ref.read(audioPlayerProvider.notifier);
                        if (state.isPlaying) {
                          n.pause();
                        } else {
                          n.play();
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.forward_10_rounded, color: Colors.white70, size: 24),
                      onPressed: () {
                        final target = (state.position + 10000).clamp(0, state.duration);
                        ref.read(audioPlayerProvider.notifier).seek(target);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullScreenPlayer(AudioState state) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 30),
          onPressed: () => ref.read(audioPlayerProvider.notifier).setFullScreen(false),
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rotating Vinyl record representation
            Container(
              width: 200,
              height: 200,
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
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF00BCD4),
                  ),
                  child: const Icon(Icons.music_note_rounded, color: Colors.black, size: 32),
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
                ref.read(audioPlayerProvider.notifier).seek((progress * state.duration).toInt());
              },
              onTapUp: (details) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final localOffset = box.globalToLocal(details.globalPosition);
                final progress = (localOffset.dx - 24).clamp(0.0, box.size.width - 48) / (box.size.width - 48);
                ref.read(audioPlayerProvider.notifier).seek((progress * state.duration).toInt());
              },
              child: CustomPaint(
                size: const Size(double.infinity, 80),
                painter: WaveformPainter(
                  amplitudes: state.amplitudes,
                  progress: state.duration > 0 ? state.position / state.duration : 0.0,
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
                  _formatTime(state.position),
                  style: const TextStyle(color: Colors.white60, fontSize: 12, fontFamily: 'monospace'),
                ),
                Text(
                  _formatTime(state.duration),
                  style: const TextStyle(color: Colors.white60, fontSize: 12, fontFamily: 'monospace'),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Main Player control row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 36),
                  onPressed: () => ref.read(audioPlayerProvider.notifier).seek(0),
                ),
                const SizedBox(width: 24),
                IconButton(
                  iconSize: 64,
                  icon: Icon(
                    state.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                    color: const Color(0xFF00BCD4),
                  ),
                  onPressed: () {
                    final n = ref.read(audioPlayerProvider.notifier);
                    if (state.isPlaying) {
                      n.pause();
                    } else {
                      n.play();
                    }
                  },
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 36),
                  onPressed: () => ref.read(audioPlayerProvider.notifier).seek(state.duration),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioPlayerProvider);

    // If still extracting/loading basic waveforms, show fullscreen initial loading
    if (!audioState.isLoaded) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: audioState.isFullScreen
          ? _buildFullScreenPlayer(audioState)
          : Scaffold(
              backgroundColor: Colors.black.withOpacity(0.4),
              body: Stack(
                children: [
                  // Dismiss player on tapping background blur area
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(audioPlayerProvider.notifier).stop();
                        Navigator.pop(context);
                      },
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  _buildMiniPlayer(audioState),
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
      final double amp = amplitudes[i].toDouble() / 100.0;
      final double barHeight = size.height * amp;

      final double x = i * barWidth;
      final double y = (size.height - barHeight) / 2.0;

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
