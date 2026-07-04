import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/copy_task_provider.dart';

class _TaskStyle {
  final String compactText;
  final String completedText;
  final List<Color> bgGradient;
  final List<Color> flapGradient;
  final Color backFlapColor;

  _TaskStyle({
    required this.compactText,
    required this.completedText,
    required this.bgGradient,
    required this.flapGradient,
    required this.backFlapColor,
  });
}

class CopyProgressOverlay extends ConsumerWidget {
  const CopyProgressOverlay({Key? key}) : super(key: key);

  _TaskStyle _getTaskStyle(GlobalTaskType type) {
    switch (type) {
      case GlobalTaskType.copy:
        return _TaskStyle(
          compactText: 'Copying',
          completedText: 'Copy completed',
          bgGradient: const [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          flapGradient: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
          backFlapColor: const Color(0xFF1D4ED8),
        );
      case GlobalTaskType.delete:
        return _TaskStyle(
          compactText: 'Deleting',
          completedText: 'Deletion completed',
          bgGradient: const [Color(0xFF7F1D1D), Color(0xFFDC2626)],
          flapGradient: const [Color(0xFFEF4444), Color(0xFFF87171)],
          backFlapColor: const Color(0xFFB91C1C),
        );
      case GlobalTaskType.move:
        return _TaskStyle(
          compactText: 'Moving',
          completedText: 'Move completed',
          bgGradient: const [Color(0xFF4C1D95), Color(0xFF7C3AED)],
          flapGradient: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
          backFlapColor: const Color(0xFF6D28D9),
        );
      case GlobalTaskType.archive:
        return _TaskStyle(
          compactText: 'Archiving',
          completedText: 'Archiving completed',
          bgGradient: const [Color(0xFF7C2D12), Color(0xFFD97706)],
          flapGradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
          backFlapColor: const Color(0xFFB45309),
        );
      case GlobalTaskType.unarchive:
        return _TaskStyle(
          compactText: 'Unarchiving',
          completedText: 'Unarchiving completed',
          bgGradient: const [Color(0xFF115E59), Color(0xFF0D9488)],
          flapGradient: const [Color(0xFF14B8A6), Color(0xFF5EEAD4)],
          backFlapColor: const Color(0xFF0F766E),
        );
      case GlobalTaskType.createFolder:
        return _TaskStyle(
          compactText: 'Creating',
          completedText: 'Folder created',
          bgGradient: const [Color(0xFF064E3B), Color(0xFF10B981)],
          flapGradient: const [Color(0xFF34D399), Color(0xFF6EE7B7)],
          backFlapColor: const Color(0xFF047857),
        );
      case GlobalTaskType.restore:
        return _TaskStyle(
          compactText: 'Restoring',
          completedText: 'Restore completed',
          bgGradient: const [Color(0xFF0F766E), Color(0xFF0D9488)],
          flapGradient: const [Color(0xFF14B8A6), Color(0xFF5EEAD4)],
          backFlapColor: const Color(0xFF115E59),
        );
    }
  }

  /// Build the line shown below the task title in expanded mode.
  String _buildExpandedSubtitle(CopyTaskState state) {
    final type = state.taskType;
    final count = state.itemCountLabel;
    final dest = state.destFolderName;
    switch (type) {
      case GlobalTaskType.copy:
        return dest.isNotEmpty ? '$count → $dest' : count;
      case GlobalTaskType.move:
        return dest.isNotEmpty ? '$count → $dest' : count;
      case GlobalTaskType.delete:
        return count;
      case GlobalTaskType.restore:
        return count;
      default:
        return dest.isNotEmpty ? dest : count;
    }
  }

  /// Build the operation verb + percentage for the compact pill.
  String _buildCompactLabel(CopyTaskState state, _TaskStyle style) {
    final pct = (state.progress * 100).toInt();
    return '${style.compactText}  $pct%';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(copyTaskProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final style = _getTaskStyle(state.taskType);

    // Pill dimensions
    double width = 200.0.w;
    double height = 36.0.h;

    if (state.isActive) {
      if (state.displayMode == CopyTaskDisplayMode.compact ||
          state.displayMode == CopyTaskDisplayMode.completedCompact) {
        width = 200.0.w;
        height = 36.0.h;
      } else if (state.displayMode == CopyTaskDisplayMode.expanded) {
        width = 340.0.w;
        height = 92.0.h;
      } else if (state.displayMode == CopyTaskDisplayMode.completedExpanded) {
        width = 340.0.w;
        height = 76.0.h;
      }
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 600),
      curve: Curves.fastOutSlowIn,
      top: state.isActive
          ? (MediaQuery.of(context).padding.top + 12.0.h)
          : -140.0.h,
      left: (MediaQuery.of(context).size.width - width) / 2,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: state.isActive ? 1.0 : 0.0,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            ref.read(copyTaskProvider.notifier).toggleExpansion();
          },
          child: Material(
            type: MaterialType.transparency,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.fastOutSlowIn,
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(height / 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 20.0.r,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.0.r,
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal:
                    (state.displayMode == CopyTaskDisplayMode.compact ||
                        state.displayMode ==
                            CopyTaskDisplayMode.completedCompact)
                    ? 16.0.w
                    : 14.0.w,
                vertical:
                    (state.displayMode == CopyTaskDisplayMode.compact ||
                        state.displayMode ==
                            CopyTaskDisplayMode.completedCompact)
                    ? 8.0.h
                    : 12.0.h,
              ),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: _buildPillContent(state, style, isDark),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillContent(CopyTaskState state, _TaskStyle style, bool isDark) {
    // ── Compact: "Copying  42%" ──────────────────────────────────────────────
    if (state.displayMode == CopyTaskDisplayMode.compact) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            style.compactText,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.0.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          // Animated spinning indicator + percentage
          Row(
            children: [
              _SpinningArc(color: _accentColor(style)),
              SizedBox(width: 6.w),
              Text(
                '${(state.progress * 100).toInt()}%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.0.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      );
    }

    // ── Compact Completed ────────────────────────────────────────────────────
    if (state.displayMode == CopyTaskDisplayMode.completedCompact) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Done',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.0.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: const Color(0xFF10B981), size: 14.r),
              SizedBox(width: 4.w),
              Text(
                '100%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.0.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // ── Expanded: in-progress ────────────────────────────────────────────────
    if (state.displayMode == CopyTaskDisplayMode.expanded) {
      final subtitle = _buildExpandedSubtitle(state);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 38.0.w,
                height: 38.0.h,
                child: CustomPaint(
                  painter: _FolderIconPainter(isDark: isDark, style: style),
                ),
              ),
              SizedBox(width: 12.0.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      style.compactText,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.0.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2.0.h),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.0.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              // percentage badge
              Text(
                '${(state.progress * 100).toInt()}%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: _accentColor(style),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.0.h),
          _ProgressBar(progress: state.progress, accentColor: _accentColor(style)),
        ],
      );
    }

    // ── Completed Expanded ───────────────────────────────────────────────────
    final speedText = state.speedLabel.isNotEmpty ? state.speedLabel : '';
    final subtitle = state.fileCount > 0 ? state.itemCountLabel : '';
    final detailLine = [subtitle, speedText]
        .where((s) => s.isNotEmpty)
        .join('  ·  ');

    return Row(
      children: [
        SizedBox(
          width: 38.0.w,
          height: 38.0.h,
          child: CustomPaint(
            painter: _FolderIconPainter(isDark: isDark, style: style),
          ),
        ),
        SizedBox(width: 12.0.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                style.completedText,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.0.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (detailLine.isNotEmpty) ...[
                SizedBox(height: 2.0.h),
                Text(
                  detailLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.0.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(width: 8.0.w),
        // Green checkmark ring
        Container(
          width: 24.0.r,
          height: 24.0.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF10B981),
              width: 2.5.r,
            ),
          ),
          child: Icon(
            Icons.check,
            size: 13.r,
            color: const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  Color _accentColor(_TaskStyle style) => style.flapGradient.first;
}

// ─── Spinning arc indicator ─────────────────────────────────────────────────

class _SpinningArc extends StatefulWidget {
  final Color color;
  const _SpinningArc({required this.color});

  @override
  State<_SpinningArc> createState() => _SpinningArcState();
}

class _SpinningArcState extends State<_SpinningArc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _ctrl,
      child: SizedBox(
        width: 12.r,
        height: 12.r,
        child: CircularProgressIndicator(
          value: 0.72,
          strokeWidth: 2.r,
          color: widget.color,
          backgroundColor: Colors.white12,
        ),
      ),
    );
  }
}

// ─── Smooth progress bar ────────────────────────────────────────────────────

class _ProgressBar extends StatefulWidget {
  final double progress;
  final Color accentColor;
  const _ProgressBar({Key? key, required this.progress, required this.accentColor})
      : super(key: key);

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  double _oldProgress = 0.0;

  @override
  void didUpdateWidget(covariant _ProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _oldProgress = oldWidget.progress;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _oldProgress, end: widget.progress),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Container(
          height: 6.0.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(3.0.r),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.accentColor, Colors.white],
                ),
                borderRadius: BorderRadius.circular(3.0.r),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Folder icon painter ────────────────────────────────────────────────────

class _FolderIconPainter extends CustomPainter {
  final bool isDark;
  final _TaskStyle style;

  _FolderIconPainter({required this.isDark, required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Backing squircle with task gradient
    final backPaint = Paint()
      ..shader = LinearGradient(
        colors: style.bgGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        Radius.circular(w * 0.28),
      ),
      backPaint,
    );

    // 2. Back folder flap
    final folderBackPaint = Paint()
      ..color = style.backFlapColor
      ..style = PaintingStyle.fill;
    final backPath = Path()
      ..moveTo(w * 0.2, h * 0.35)
      ..lineTo(w * 0.45, h * 0.35)
      ..lineTo(w * 0.52, h * 0.42)
      ..lineTo(w * 0.8, h * 0.42)
      ..quadraticBezierTo(w * 0.85, h * 0.42, w * 0.85, h * 0.47)
      ..lineTo(w * 0.85, h * 0.75)
      ..quadraticBezierTo(w * 0.85, h * 0.8, w * 0.8, h * 0.8)
      ..lineTo(w * 0.2, h * 0.8)
      ..quadraticBezierTo(w * 0.15, h * 0.8, w * 0.15, h * 0.75)
      ..lineTo(w * 0.15, h * 0.4)
      ..quadraticBezierTo(w * 0.15, h * 0.35, w * 0.2, h * 0.35);
    canvas.drawPath(backPath, folderBackPaint);

    // 3. Protruding document sheet
    final sheetPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final sheetRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.28, h * 0.25, w * 0.44, h * 0.35),
      Radius.circular(w * 0.05),
    );
    canvas.drawRRect(sheetRect, sheetPaint);

    // Document stripes
    final stripePaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(w * 0.36, h * 0.32), Offset(w * 0.64, h * 0.32), stripePaint);
    canvas.drawLine(Offset(w * 0.36, h * 0.40), Offset(w * 0.64, h * 0.40), stripePaint);
    canvas.drawLine(Offset(w * 0.36, h * 0.48), Offset(w * 0.54, h * 0.48), stripePaint);

    // 4. Front folder flap with task gradient
    final folderFrontPaint = Paint()
      ..shader = LinearGradient(
        colors: style.flapGradient,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final frontPath = Path()
      ..moveTo(w * 0.15, h * 0.46)
      ..quadraticBezierTo(w * 0.15, h * 0.44, w * 0.2, h * 0.44)
      ..lineTo(w * 0.8, h * 0.44)
      ..quadraticBezierTo(w * 0.85, h * 0.44, w * 0.85, h * 0.46)
      ..lineTo(w * 0.85, h * 0.76)
      ..quadraticBezierTo(w * 0.85, h * 0.81, w * 0.8, h * 0.81)
      ..lineTo(w * 0.2, h * 0.81)
      ..quadraticBezierTo(w * 0.15, h * 0.81, w * 0.15, h * 0.76)
      ..close();
    canvas.drawPath(frontPath, folderFrontPaint);
  }

  @override
  bool shouldRepaint(covariant _FolderIconPainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.style != style;
  }
}
