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
                  ),
                  SizedBox(height: 18.0.h),
                  // Animated Segmented Horizontal Progress Bar (growing sequentially left-to-right)
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      final val = _progressAnimation.value;

                      // Staggered grow durations out of 100 total sum
                      final p1 = _getSegmentProgress(val, 0.0, 10 / 100);
                      final p2 = _getSegmentProgress(val, 10 / 100, 35 / 100);
                      final p3 = _getSegmentProgress(val, 45 / 100, 15 / 100);
                      final p4 = _getSegmentProgress(val, 60 / 100, 5 / 100);
                      final p5 = _getSegmentProgress(val, 65 / 100, 25 / 100);
                      final p6 = _getSegmentProgress(val, 90 / 100, 10 / 100);

                      return Row(
                        children: [
                          Expanded(
                            flex: 10,
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: p1,
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
                          Expanded(
                            flex: 35,
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
                          Expanded(
                            flex: 15,
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: p3,
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
                          Expanded(
                            flex: 5,
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: p4,
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
                          Expanded(
                            flex: 25,
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: p5,
                              child: Container(
                                height: 10.0.h,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF4D4D), // App Red
                                  borderRadius: BorderRadius.circular(5.0.r),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 4.0.w),
                          Expanded(
                            flex: 10,
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: p6,
                              child: Container(
                                height: 10.0.h,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF9E9E9E), // Others Grey
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
                  // Bottom Grid: 2 rows of 3 legends
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildLegendItem(
                              isDark,
                              'Docs',
                              '124 MB',
                              AppColors.storageYellow,
                            ),
                          ),
                          Expanded(
                            child: _buildLegendItem(
                              isDark,
                              'Videos',
                              '823 MB',
                              AppColors.mintAccent,
                            ),
                          ),
                          Expanded(
                            child: _buildLegendItem(
                              isDark,
                              'Images',
                              '312 MB',
                              AppColors.storageSkyBlue,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.0.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildLegendItem(
                              isDark,
                              'Audio',
                              '14 MB',
                              AppColors.storageOrange,
                            ),
                          ),
                          Expanded(
                            child: _buildLegendItem(
                              isDark,
                              'Apps',
                              '1.4 GB',
                              const Color(0xFFFF4D4D),
                            ),
                          ),
                          Expanded(
                            child: _buildLegendItem(
                              isDark,
                              'Others',
                              '512 MB',
                              const Color(0xFF9E9E9E),
                            ),
                          ),
                        ],
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5.0.w,
          height: 12.0.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.5.r),
          ),
        ),
        SizedBox(width: 6.0.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.0.sp,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            SizedBox(height: 1.0.h),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.0.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.pureWhite : AppColors.neutral900,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
