import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/flux_icon.dart';

class FileDetail {
  final String name;
  final String size;
  final String createdDate;
  final String modifiedDate;
  final String type;
  final Color themeColor;
  final IconData fallbackIcon;
  final FluxIconType? fluxIcon;

  FileDetail({
    required this.name,
    required this.size,
    required this.createdDate,
    required this.modifiedDate,
    required this.type,
    required this.themeColor,
    required this.fallbackIcon,
    this.fluxIcon,
  });
}

class FileDetailSheet extends StatefulWidget {
  final FileDetail detail;

  const FileDetailSheet({Key? key, required this.detail}) : super(key: key);

  static void show(BuildContext context, FileDetail detail) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      isScrollControlled: true,
      builder: (context) => FileDetailSheet(detail: detail),
    );
  }

  @override
  State<FileDetailSheet> createState() => _FileDetailSheetState();
}

class _FileDetailSheetState extends State<FileDetailSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Staggered Animations
  late Animation<double> _iconScale;
  late Animation<double> _titleOpacity;

  // List of row animations
  final List<Animation<double>> _rowOpacities = [];
  final List<Animation<Offset>> _rowSlides = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    // 1. Icon card pops up first
    _iconScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
    );

    // 2. Sheet title fade
    _titleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.55, curve: Curves.easeOut),
    );

    // 3. Staggered detail rows (5 rows total + 1 actions row = 6 items)
    const staggerStep = 0.08;
    for (int i = 0; i < 6; i++) {
      final start = 0.3 + (i * staggerStep);
      final end = (start + 0.3).clamp(0.0, 1.0);

      _rowOpacities.add(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );

      _rowSlides.add(
        Tween<Offset>(begin: const Offset(0.0, 0.25), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        ),
      );
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sheetBg = isDark
        ? AppColors.neutral900.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.95);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final labelColor = isDark ? Colors.white38 : Colors.black38;
    final valueColor = isDark ? AppColors.pureWhite : AppColors.neutral900;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32.0.r)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
        child: Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.0.r)),
            border: Border(
              top: BorderSide(color: borderColor, width: 1.5.r),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            24.0.w,
            8.0.h,
            24.0.w,
            MediaQuery.of(context).padding.bottom + 24.0.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab Handle
              Container(
                width: 48.0.w,
                height: 4.5.h,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2.5.r),
                ),
              ),
              SizedBox(height: 24.0.h),

              // Floating preview icon representing the file type
              ScaleTransition(
                scale: _iconScale,
                child: Center(
                  child: Container(
                    width: 76.0.r,
                    height: 76.0.r,
                    decoration: BoxDecoration(
                      color: widget.detail.themeColor.withValues(
                        alpha: isDark ? 0.2 : 0.85,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.detail.themeColor.withValues(alpha: 0.25),
                        width: 2.0.r,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.detail.themeColor.withValues(
                            alpha: 0.15,
                          ),
                          blurRadius: 16.r,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: widget.detail.fluxIcon != null
                          ? FluxIcon(widget.detail.fluxIcon!, size: 36.0.r)
                          : Icon(
                              widget.detail.fallbackIcon,
                              color: widget.detail.themeColor,
                              size: 36.0.r,
                            ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 18.0.h),

              // Title
              FadeTransition(
                opacity: _titleOpacity,
                child: Text(
                  'File Details',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20.0.sp,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                  ),
                ),
              ),
              SizedBox(height: 24.0.h),

              // Detail List Rows
              _buildStaggeredRow(
                0,
                'Name File:',
                widget.detail.name,
                labelColor,
                valueColor,
              ),
              _buildStaggeredRow(
                1,
                'Size:',
                widget.detail.size,
                labelColor,
                valueColor,
              ),
              _buildStaggeredRow(
                2,
                'Created Date:',
                widget.detail.createdDate,
                labelColor,
                valueColor,
              ),
              _buildStaggeredRow(
                3,
                'Modified Date:',
                widget.detail.modifiedDate,
                labelColor,
                valueColor,
              ),
              _buildStaggeredRow(
                4,
                'Type File:',
                widget.detail.type,
                labelColor,
                valueColor,
              ),

              SizedBox(height: 24.0.h),

              // Action Buttons Row (Animated)
              SlideTransition(
                position: _rowSlides[5],
                child: FadeTransition(
                  opacity: _rowOpacities[5],
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.share_rounded,
                          label: 'Share',
                          onTap: () => Navigator.pop(context),
                          isDark: isDark,
                        ),
                      ),
                      SizedBox(width: 12.0.w),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.edit_rounded,
                          label: 'Rename',
                          onTap: () => Navigator.pop(context),
                          isDark: isDark,
                        ),
                      ),
                      SizedBox(width: 12.0.w),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.delete_outline_rounded,
                          label: 'Delete',
                          onTap: () => Navigator.pop(context),
                          isDark: isDark,
                          isDanger: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaggeredRow(
    int index,
    String label,
    String value,
    Color labelColor,
    Color valueColor,
  ) {
    return SlideTransition(
      position: _rowSlides[index],
      child: FadeTransition(
        opacity: _rowOpacities[index],
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10.0.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110.0.w,
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.0.sp,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.0.sp,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    bool isDanger = false,
  }) {
    final bgColor = isDanger
        ? Colors.red.withValues(alpha: 0.1)
        : (isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03));
    final textColor = isDanger
        ? Colors.redAccent
        : (isDark ? AppColors.pureWhite : AppColors.neutral900);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48.0.h,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16.0.r),
          border: Border.all(
            color: isDanger
                ? Colors.redAccent.withValues(alpha: 0.2)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05)),
            width: 1.0.r,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 18.0.r),
            SizedBox(width: 8.0.w),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.0.sp,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
