import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../navigation/providers/navigation_provider.dart';

class StorageBar extends ConsumerWidget {
  const StorageBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBgColor = isDark 
        ? AppColors.neutral900.withValues(alpha: 0.9) 
        : Colors.white.withValues(alpha: 0.95);
    final borderColor = isDark 
        ? Colors.white.withValues(alpha: 0.08) 
        : Colors.black.withValues(alpha: 0.05);

    final usedTextColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final totalTextColor = isDark ? AppColors.textSecondaryDark : AppColors.neutral400;

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
                  // Top Row: 48 GB of 120 GB Used + Upgrade Plan Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: 'Inter',
                          ),
                          children: [
                            TextSpan(
                              text: '48 GB ',
                              style: TextStyle(
                                fontSize: 32.0.sp,
                                fontWeight: FontWeight.w700,
                                color: usedTextColor,
                              ),
                            ),
                            TextSpan(
                              text: 'of 120 GB Used',
                              style: TextStyle(
                                fontSize: 13.0.sp,
                                fontWeight: FontWeight.w400,
                                color: totalTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 8.0.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.0.r),
                        ),
                        child: Text(
                          'Upgrade Plan',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.0.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18.0.h),
                  // Segmented Horizontal Progress Bar (individual capsules with gaps)
                  Row(
                    children: [
                      Expanded(
                        flex: 15,
                        child: Container(
                          height: 10.0.h,
                          decoration: BoxDecoration(
                            color: AppColors.storageYellow,
                            borderRadius: BorderRadius.circular(5.0.r),
                          ),
                        ),
                      ),
                      SizedBox(width: 6.0.w),
                      Expanded(
                        flex: 55,
                        child: Container(
                          height: 10.0.h,
                          decoration: BoxDecoration(
                            color: AppColors.mintAccent,
                            borderRadius: BorderRadius.circular(5.0.r),
                          ),
                        ),
                      ),
                      SizedBox(width: 6.0.w),
                      Expanded(
                        flex: 15,
                        child: Container(
                          height: 10.0.h,
                          decoration: BoxDecoration(
                            color: AppColors.storageSkyBlue,
                            borderRadius: BorderRadius.circular(5.0.r),
                          ),
                        ),
                      ),
                      SizedBox(width: 6.0.w),
                      Expanded(
                        flex: 5,
                        child: Container(
                          height: 10.0.h,
                          decoration: BoxDecoration(
                            color: AppColors.storageOrange,
                            borderRadius: BorderRadius.circular(5.0.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.0.h),
                  // Bottom Row: Custom Legends (Vertical capsule indicator + Label & Size)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLegendItem(isDark, 'Docs', '124 MB', AppColors.storageYellow),
                      _buildLegendItem(isDark, 'Videos', '823 MB', AppColors.mintAccent),
                      _buildLegendItem(isDark, 'Images', '312 MB', AppColors.storageSkyBlue),
                      _buildLegendItem(isDark, 'Audio', '14 MB', AppColors.storageOrange),
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

  Widget _buildLegendItem(bool isDark, String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8.0.w,
          height: 18.0.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3.5.r),
          ),
        ),
        SizedBox(width: 8.0.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.0.sp,
                fontWeight: FontWeight.w400,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            SizedBox(height: 2.0.h),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.0.sp,
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
