import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/flux_icon.dart';
import 'package:lottie/lottie.dart';

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
    if (detail.type == 'System') {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      _showSystemFileAlert(context, detail.name, isDark);
      return;
    }

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
  late Animation<double> _titleOpacity;

  // List of row animations
  final List<Animation<double>> _rowOpacities = [];
  final List<Animation<Offset>> _rowSlides = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    // 1. Sheet title fade
    _titleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    // 2. Staggered detail rows (5 rows total)
    const staggerStep = 0.08;
    for (int i = 0; i < 5; i++) {
      final start = 0.15 + (i * staggerStep);
      final end = (start + 0.35).clamp(0.0, 1.0);

      _rowOpacities.add(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );

      _rowSlides.add(
        Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(
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
        ? AppColors.neutral900.withValues(alpha: 0.95)
        : Colors.white.withValues(alpha: 0.98);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final labelColor = isDark ? Colors.white : AppColors.neutral900;
    final valueColor = isDark ? Colors.white30 : Colors.black45;

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
            12.0.h,
            24.0.w,
            MediaQuery.of(context).padding.bottom + 32.0.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Center Grab Handle
              Center(
                child: Container(
                  width: 48.0.w,
                  height: 4.5.h,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2.5.r),
                  ),
                ),
              ),
              SizedBox(height: 20.0.h),

              // Centered File Detail Header Text
              Center(
                child: FadeTransition(
                  opacity: _titleOpacity,
                  child: Text(
                    'File Detail',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20.0.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.pureWhite
                          : AppColors.neutral900,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 28.0.h),

              // Detail List Rows Stacked Vertically as per Screenshot
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
          padding: EdgeInsets.symmetric(vertical: 12.0.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15.0.sp,
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                ),
              ),
              SizedBox(height: 6.0.h),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.0.sp,
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showSystemFileAlert(BuildContext context, String filename, bool isDark) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'SystemFileAlert',
    barrierColor: Colors.black.withValues(alpha: 0.6),
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, anim1, anim2) {
      return const SizedBox.shrink();
    },
    transitionBuilder: (context, anim1, anim2, child) {
      final curvedValue = Curves.easeInOutBack.transform(anim1.value);
      final cardBorderColor = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.05);

      return Transform.scale(
        scale: curvedValue,
        child: FadeTransition(
          opacity: anim1,
          child: AlertDialog(
            backgroundColor: isDark ? AppColors.neutral950 : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.0.r),
              side: BorderSide(color: cardBorderColor, width: 1.2.r),
            ),
            title: Column(
              children: [
                // Premium cute Wumpus 'no' denial Lottie animation
                SizedBox(
                  width: 140.0.r,
                  height: 140.0.r,
                  child: Lottie.asset(
                    'assets/newsv/no.json',
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 12.0.h),
                Text(
                  'Access Restricted',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20.0.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.pureWhite : AppColors.neutral900,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Opening "$filename" is restricted.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.0.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.pureWhite.withValues(alpha: 0.8)
                        : AppColors.neutral700,
                  ),
                ),
                SizedBox(height: 16.0.h),
                Container(
                  padding: EdgeInsets.all(14.0.r),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(16.0.r),
                    border: Border.all(color: cardBorderColor, width: 1.0.r),
                  ),
                  child: Text(
                    'Modifying or accessing core system files is disabled to prevent operating system instability, partition corruption, or device malfunction.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.0.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.mintAccent,
                  padding: EdgeInsets.symmetric(
                    horizontal: 28.0.w,
                    vertical: 12.0.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0.r),
                  ),
                  elevation: 2,
                  shadowColor: AppColors.mintAccent.withValues(alpha: 0.3),
                ),
                child: Text(
                  'Acknowledge & Close',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.0.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
