import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/widgets/flux_icon.dart';
import '../../../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────
// Data model for a recent file
// ─────────────────────────────────────────────
class RecentFileInfo {
  final String name;
  final String type;
  final String size;
  final String modified;
  final String path;
  final Color iconColor;
  final Color iconBg;
  final FluxIconType? fluxIcon;
  final IconData fallbackIcon;

  const RecentFileInfo({
    required this.name,
    required this.type,
    required this.size,
    required this.modified,
    required this.path,
    required this.iconColor,
    required this.iconBg,
    this.fluxIcon,
    required this.fallbackIcon,
  });
}

// ─────────────────────────────────────────────
// Public entry point
// ─────────────────────────────────────────────
Future<void> showFileDetailSheet(
  BuildContext context,
  RecentFileInfo file,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => _FileDetailSheet(file: file),
  );
}

// ─────────────────────────────────────────────
// Sheet widget
// ─────────────────────────────────────────────
class _FileDetailSheet extends StatefulWidget {
  final RecentFileInfo file;
  const _FileDetailSheet({required this.file});

  @override
  State<_FileDetailSheet> createState() => _FileDetailSheetState();
}

class _FileDetailSheetState extends State<_FileDetailSheet>
    with TickerProviderStateMixin {
  late final AnimationController _masterCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _pulseCtrl;

  // Header animations
  late final Animation<double> _iconScale;
  late final Animation<double> _iconOpacity;
  late final Animation<double> _glowRadius;

  // Row stagger
  static const int _rowCount = 5;
  final List<Animation<Offset>> _rowSlide = [];
  final List<Animation<double>> _rowFade = [];

  // Bottom action bar
  late final Animation<double> _barSlide;
  late final Animation<double> _barFade;

  // Size meter fill
  late final Animation<double> _meterFill;

  @override
  void initState() {
    super.initState();

    _masterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    // Icon entrance
    _iconScale = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
    );
    _iconOpacity = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
    );
    _glowRadius = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    // Row stagger
    for (int i = 0; i < _rowCount; i++) {
      final start = 0.30 + i * 0.10;
      final end = (start + 0.22).clamp(0.0, 1.0);
      _rowSlide.add(
        Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _masterCtrl,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        ),
      );
      _rowFade.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _masterCtrl,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );
    }

    // Storage meter
    _meterFill = Tween<double>(begin: 0.0, end: 0.62).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.55, 0.92, curve: Curves.easeOutCubic),
      ),
    );

    // Bottom bar
    _barSlide = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _barFade = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
    );

    _masterCtrl.forward();
  }

  @override
  void dispose() {
    _masterCtrl.dispose();
    _shimmerCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final file = widget.file;

    final sheetBg = isDark ? const Color(0xFF0F0F0F) : AppColors.pureWhite;
    final titleColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final subtitleColor = isDark ? AppColors.textSecondaryDark : AppColors.neutral400;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.06);
    final cardBg = isDark ? const Color(0xFF1A1A1A) : AppColors.neutral50;

    return DraggableScrollableSheet(
      initialChildSize: 0.68,
      minChildSize: 0.45,
      maxChildSize: 0.90,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.0.r)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.04),
              width: 1.0.r,
            ),
          ),
          child: Column(
            children: [
              // ── Drag handle
              _DragHandle(isDark: isDark),

              // ── Scrollable body
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24.0.w, 4.0.h, 24.0.w, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Animated glowing icon header
                        _buildHeader(file, isDark, titleColor, subtitleColor),
                        SizedBox(height: 24.0.h),

                        // ── Storage meter card
                        _buildMeterCard(file, isDark, cardBg, subtitleColor),
                        SizedBox(height: 20.0.h),

                        // ── Staggered detail rows
                        _buildDetailRows(
                          file, isDark, cardBg, titleColor, subtitleColor, dividerColor,
                        ),
                        SizedBox(height: 20.0.h),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Animated action bar
              _buildActionBar(isDark, file),
            ],
          ),
        );
      },
    );
  }

  // ─────────────── HEADER ───────────────
  Widget _buildHeader(
    RecentFileInfo file,
    bool isDark,
    Color titleColor,
    Color subtitleColor,
  ) {
    return Center(
      child: Column(
        children: [
          // Glowing icon
          AnimatedBuilder(
            animation: Listenable.merge([_masterCtrl, _pulseCtrl]),
            builder: (context, child) {
              final glow = _glowRadius.value;
              final pulse = _pulseCtrl.value;
              return Opacity(
                opacity: _iconOpacity.value,
                child: Transform.scale(
                  scale: _iconScale.value,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow ring
                      Container(
                        width: (80 + 24 * glow * (1 + pulse * 0.12)).r,
                        height: (80 + 24 * glow * (1 + pulse * 0.12)).r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              file.iconColor.withValues(alpha: 0.18 * glow),
                              file.iconColor.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                      // Mid glow
                      Container(
                        width: 72.0.r,
                        height: 72.0.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              file.iconColor.withValues(alpha: 0.12 * glow),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // Icon container
                      Container(
                        width: 64.0.r,
                        height: 64.0.r,
                        decoration: BoxDecoration(
                          color: file.iconBg.withValues(alpha: isDark ? 0.4 : 0.85),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: file.iconColor.withValues(alpha: 0.25),
                            width: 1.5.r,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: file.iconColor.withValues(alpha: 0.22 * glow),
                              blurRadius: 22.0.r,
                              spreadRadius: 2.0.r,
                            ),
                          ],
                        ),
                        child: Center(
                          child: file.fluxIcon != null
                              ? FluxIcon(file.fluxIcon!, size: 28.0.r)
                              : Icon(file.fallbackIcon, color: file.iconColor, size: 28.0.r),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 14.0.h),
          // File name with staggered fade
          FadeTransition(
            opacity: _rowFade.isNotEmpty ? _rowFade[0] : const AlwaysStoppedAnimation(1.0),
            child: Text(
              widget.file.name,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 17.0.sp,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: 4.0.h),
          FadeTransition(
            opacity: _rowFade.isNotEmpty ? _rowFade[0] : const AlwaysStoppedAnimation(1.0),
            child: Text(
              widget.file.type,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.0.sp,
                fontWeight: FontWeight.w500,
                color: subtitleColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── METER CARD ───────────────
  Widget _buildMeterCard(
    RecentFileInfo file,
    bool isDark,
    Color cardBg,
    Color subtitleColor,
  ) {
    return AnimatedBuilder(
      animation: _masterCtrl,
      builder: (context, _) {
        return FadeTransition(
          opacity: _meterFill,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 18.0.w, vertical: 14.0.h),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16.0.r),
              border: Border.all(
                color: file.iconColor.withValues(alpha: 0.12),
                width: 1.0.r,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'File Size',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.0.sp,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                      ),
                    ),
                    Text(
                      file.size,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.0.sp,
                        fontWeight: FontWeight.w700,
                        color: file.iconColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.0.h),
                // Animated fill bar
                Container(
                  height: 6.0.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(3.0.r),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _meterFill.value,
                    child: AnimatedBuilder(
                      animation: _shimmerCtrl,
                      builder: (context, _) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3.0.r),
                            gradient: LinearGradient(
                              colors: [
                                file.iconColor,
                                file.iconColor.withValues(alpha: 0.6),
                                file.iconColor,
                              ],
                              stops: [
                                0.0,
                                (_shimmerCtrl.value * 1.4 - 0.2).clamp(0.0, 1.0),
                                1.0,
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 8.0.h),
                Text(
                  'of 128 GB Internal Storage',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.0.sp,
                    fontWeight: FontWeight.w400,
                    color: subtitleColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────── DETAIL ROWS ───────────────
  Widget _buildDetailRows(
    RecentFileInfo file,
    bool isDark,
    Color cardBg,
    Color titleColor,
    Color subtitleColor,
    Color dividerColor,
  ) {
    final rows = [
      _RowData(Icons.drive_file_rename_outline_rounded, 'File Name', file.name),
      _RowData(Icons.folder_open_rounded, 'Location', file.path),
      _RowData(Icons.category_outlined, 'Type', file.type),
      _RowData(Icons.access_time_filled_rounded, 'Modified', file.modified),
      _RowData(Icons.data_usage_rounded, 'Size', file.size),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.0.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.05),
          width: 1.0.r,
        ),
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final row = rows[i];
          final isLast = i == rows.length - 1;
          return Column(
            children: [
              SlideTransition(
                position: _rowSlide[i.clamp(0, _rowSlide.length - 1)],
                child: FadeTransition(
                  opacity: _rowFade[i.clamp(0, _rowFade.length - 1)],
                  child: _DetailRow(
                    icon: row.icon,
                    label: row.label,
                    value: row.value,
                    iconColor: file.iconColor,
                    titleColor: titleColor,
                    subtitleColor: subtitleColor,
                    isDark: isDark,
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  color: dividerColor,
                  height: 1.0.h,
                  thickness: 1.0.r,
                  indent: 56.0.w,
                  endIndent: 0,
                ),
            ],
          );
        }),
      ),
    );
  }

  // ─────────────── ACTION BAR ───────────────
  Widget _buildActionBar(bool isDark, RecentFileInfo file) {
    return AnimatedBuilder(
      animation: _masterCtrl,
      builder: (context, _) {
        return FadeTransition(
          opacity: _barFade,
          child: Transform.translate(
            offset: Offset(0, 32.0.h * _barSlide.value),
            child: Container(
              padding: EdgeInsets.fromLTRB(20.0.w, 14.0.h, 20.0.w, 28.0.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141414) : AppColors.neutral50,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.06),
                    width: 1.0.r,
                  ),
                ),
              ),
              child: Row(
                children: [
                  _ActionButton(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    color: AppColors.actionBlue,
                    isDark: isDark,
                    flex: 1,
                    onTap: () {
                      HapticFeedback.lightImpact();
                    },
                  ),
                  SizedBox(width: 10.0.w),
                  _ActionButton(
                    icon: Icons.copy_rounded,
                    label: 'Copy',
                    color: AppColors.mintAccent,
                    isDark: isDark,
                    flex: 1,
                    onTap: () {
                      HapticFeedback.lightImpact();
                    },
                  ),
                  SizedBox(width: 10.0.w),
                  _ActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    color: AppColors.errorRed,
                    isDark: isDark,
                    flex: 1,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Helper: drag handle
// ─────────────────────────────────────────────
class _DragHandle extends StatelessWidget {
  final bool isDark;
  const _DragHandle({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.0.h),
      child: Center(
        child: Container(
          width: 36.0.w,
          height: 4.0.h,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(2.0.r),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Helper: a single metadata row
// ─────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color titleColor;
  final Color subtitleColor;
  final bool isDark;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 13.0.h),
      child: Row(
        children: [
          Container(
            width: 32.0.r,
            height: 32.0.r,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9.0.r),
            ),
            child: Icon(icon, size: 16.0.r, color: iconColor),
          ),
          SizedBox(width: 14.0.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.0.sp,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                  ),
                ),
                SizedBox(height: 2.0.h),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.0.sp,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Helper: action button
// ─────────────────────────────────────────────
class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final int flex;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.flex,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp: (_) {
          _pressCtrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _pressCtrl.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            height: 48.0.h,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: widget.isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(14.0.r),
              border: Border.all(
                color: widget.color.withValues(alpha: 0.20),
                width: 1.0.r,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 18.0.r, color: widget.color),
                SizedBox(height: 3.0.h),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w600,
                    color: widget.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Internal helper data class
// ─────────────────────────────────────────────
class _RowData {
  final IconData icon;
  final String label;
  final String value;
  const _RowData(this.icon, this.label, this.value);
}
