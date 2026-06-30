import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../navigation/providers/navigation_provider.dart';

class StorageBar extends ConsumerStatefulWidget {
  const StorageBar({Key? key}) : super(key: key);

  @override
  ConsumerState<StorageBar> createState() => _StorageBarState();
}

class _StorageBarState extends ConsumerState<StorageBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _getSegmentProgress(
    double animationValue,
    double start,
    double duration,
  ) {
    if (animationValue < start) return 0.0;
    if (animationValue > start + duration) return 1.0;
    return (animationValue - start) / duration;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBgColor = isDark
        ? AppColors.neutral900.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.95);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    final usedTextColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final totalTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.neutral400;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 12.0.h),
      child: GestureDetector(
        onTap: () {
          ref.read(activeIndexProvider.notifier).state = 1;
        },
        behavior: HitTestBehavior.opaque,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28.0.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
            child: Container(
              padding: EdgeInsets.all(24.0.r),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(28.0.r),
                border: Border.all(color: borderColor, width: 1.5.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: 48 GB of 120 GB Used
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Inter',
                      ),
                      children: [
                        TextSpan(
                          text: '48 GB ',
                          style: TextStyle(
                            fontSize: 24.0.sp,
                            fontWeight: FontWeight.w700,
                            color: usedTextColor,
                          ),
                        ),
                        TextSpan(
                          text: 'of 120 GB Used',
                          style: TextStyle(
                            fontSize: 14.0.sp,
                            fontWeight: FontWeight.w400,
                            color: totalTextColor,
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 18.0.h),
                  // Animated Segmented Horizontal Progress Bar (growing sequentially left-to-right from largest to smallest segment, ending with Free space)
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      final val = _progressAnimation.value;

                      // High-to-Low sorted staggered grow durations (Apps -> Videos -> Others -> Images -> Docs -> Audio -> Free)
                      final p1 = _getSegmentProgress(val, 0.0, 14 / 100);
                      final p2 = _getSegmentProgress(val, 14 / 100, 10 / 100);
                      final p3 = _getSegmentProgress(val, 24 / 100, 7 / 100);
                      final p4 = _getSegmentProgress(val, 31 / 100, 5 / 100);
                      final p5 = _getSegmentProgress(val, 36 / 100, 3 / 100);
                      final p6 = _getSegmentProgress(val, 39 / 100, 1 / 100);
                      final p7 = _getSegmentProgress(val, 40 / 100, 60 / 100);

                      final freeSegmentColor = isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.06);

                      return Row(
                        children: [
                          // 1. Apps (Red, 14 flex)
                          Expanded(
                            flex: 14,
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: p1,
                              child: Container(
                                height: 10.0.h,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF4D4D),
                                  borderRadius: BorderRadius.circular(5.0.r),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 4.0.w),
                          // 2. Videos (Mint, 10 flex)
                          Expanded(
                            flex: 10,
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: p2,
                              child: Container(
                                height: 10.0.h,
                                decoration: BoxDecoration(
                                  color: AppColors.mintAccent,
                                  borderRadius: BorderRadius.circular(5.0.r),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 4.0.w),
                          // 3. Others (Grey, 7 flex)
                          Expanded(
                            flex: 7,
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: p3,
                              child: Container(
                                height: 10.0.h,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF9E9E9E),
                                  borderRadius: BorderRadius.circular(5.0.r),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 4.0.w),
                          // 4. Images (Blue, 5 flex)
                          Expanded(
                            flex: 5,
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: p4,
                              child: Container(
                                height: 10.0.h,
                                decoration: BoxDecoration(
                                  color: AppColors.storageSkyBlue,
                                  borderRadius: BorderRadius.circular(5.0.r),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 4.0.w),
                          // 5. Docs (Yellow, 3 flex)
                          Expanded(
                            flex: 3,
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: p5,
                              child: Container(
                                height: 10.0.h,
                                decoration: BoxDecoration(
                                  color: AppColors.storageYellow,
                                  borderRadius: BorderRadius.circular(5.0.r),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 4.0.w),
                          // 6. Audio (Orange, 1 flex)
                          Expanded(
                            flex: 1,
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: p6,
                              child: Container(
                                height: 10.0.h,
                                decoration: BoxDecoration(
                                  color: AppColors.storageOrange,
                                  borderRadius: BorderRadius.circular(5.0.r),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 4.0.w),
                          // 7. Free Space (Light/Dark Neutral, 60 flex)
                          Expanded(
                            flex: 60,
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: p7,
                              child: Container(
                                height: 10.0.h,
                                decoration: BoxDecoration(
                                  color: freeSegmentColor,
                                  borderRadius: BorderRadius.circular(5.0.r),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 24.0.h),
                  // Bottom grid layout redesigned as 2 columns of 3 premium compact capsule tags
                  Row(
                    children: [
                      // Left Column: Apps, Others, Docs
                      Expanded(
                        child: Column(
                          children: [
                            _buildLegendItem(
                              isDark,
                              'Apps',
                              '1.4 GB',
                              const Color(0xFFFF4D4D),
                            ),
                            SizedBox(height: 6.0.h),
                            _buildLegendItem(
                              isDark,
                              'Others',
                              '512 MB',
                              const Color(0xFF9E9E9E),
                            ),
                            SizedBox(height: 6.0.h),
                            _buildLegendItem(
                              isDark,
                              'Docs',
                              '124 MB',
                              AppColors.storageYellow,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.0.w),
                      // Right Column: Videos, Images, Audio
                      Expanded(
                        child: Column(
                          children: [
                            _buildLegendItem(
                              isDark,
                              'Videos',
                              '823 MB',
                              AppColors.mintAccent,
                            ),
                            SizedBox(height: 6.0.h),
                            _buildLegendItem(
                              isDark,
                              'Images',
                              '312 MB',
                              AppColors.storageSkyBlue,
                            ),
                            SizedBox(height: 6.0.h),
                            _buildLegendItem(
                              isDark,
                              'Audio',
                              '14 MB',
                              AppColors.storageOrange,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(
    bool isDark,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.0.w, vertical: 6.0.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12.0.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          width: 1.0.r,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6.0.r,
            height: 6.0.r,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8.0.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.0.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.pureWhite : AppColors.neutral900,
                  ),
                ),
                SizedBox(height: 1.0.h),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.0.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
