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
        ? AppColors.neutral900.withValues(alpha: 0.6) 
        : Colors.white.withValues(alpha: 0.6);
    final borderColor = isDark 
        ? Colors.white.withValues(alpha: 0.08) 
        : Colors.black.withValues(alpha: 0.05);

    final usedTextColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final totalTextColor = isDark ? AppColors.textSecondaryLight : AppColors.neutral400;

    final legendLabelColor = isDark ? Colors.white70 : AppColors.neutral700;
    final legendSizeColor = isDark ? Colors.white38 : AppColors.neutral400;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 12.0.h),
      child: GestureDetector(
        onTap: () {
          ref.read(activeIndexProvider.notifier).state = 1;
        },
        behavior: HitTestBehavior.opaque,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.0.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
            child: Container(
              padding: EdgeInsets.all(20.0.r),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(24.0.r),
                border: Border.all(color: borderColor, width: 1.5.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                fontSize: 24.0.sp,
                                fontWeight: FontWeight.w800,
                                color: usedTextColor,
                              ),
                            ),
                            TextSpan(
                              text: 'used of 120 GB',
                              style: TextStyle(
                                fontSize: 14.0.sp,
                                fontWeight: FontWeight.w500,
                                color: totalTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.0.w, vertical: 4.0.h),
                        decoration: BoxDecoration(
                          color: AppColors.mintAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.0.r),
                          border: Border.all(
                            color: AppColors.mintAccent.withValues(alpha: 0.2),
                            width: 1.0.r,
                          ),
                        ),
                        child: Text(
                          '40%',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.0.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mintAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.0.h),
                  // Continuous unified storage track
                  Container(
                    height: 10.0.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(5.0.r),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 12,
                          child: Container(
                            color: AppColors.storageCoral, // Audio
                          ),
                        ),
                        Expanded(
                          flex: 50,
                          child: Container(
                            color: AppColors.storageSkyBlue, // Images
                          ),
                        ),
                        Expanded(
                          flex: 12,
                          child: Container(
                            color: AppColors.storageYellow, // Docs
                          ),
                        ),
                        Expanded(
                          flex: 6,
                          child: Container(
                            color: AppColors.storageOrange, // System
                          ),
                        ),
                        // Remaining space (Free storage)
                        Expanded(
                          flex: 120,
                          child: Container(
                            color: Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.0.h),
                  // Storage categories breakdown legend
                  Wrap(
                    spacing: 14.0.w,
                    runSpacing: 8.0.h,
                    children: [
                      _buildLegendItem('Images', '30.0 GB', AppColors.storageSkyBlue, legendLabelColor, legendSizeColor),
                      _buildLegendItem('Audio', '7.2 GB', AppColors.storageCoral, legendLabelColor, legendSizeColor),
                      _buildLegendItem('Docs', '7.2 GB', AppColors.storageYellow, legendLabelColor, legendSizeColor),
                      _buildLegendItem('System', '3.6 GB', AppColors.storageOrange, legendLabelColor, legendSizeColor),
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

  Widget _buildLegendItem(String label, String size, Color color, Color labelColor, Color sizeColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8.0.r,
          height: 8.0.r,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 4.r,
                spreadRadius: 0.5.r,
              ),
            ],
          ),
        ),
        SizedBox(width: 6.0.w),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.0.sp,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
        ),
        SizedBox(width: 4.0.w),
        Text(
          size,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11.0.sp,
            fontWeight: FontWeight.w400,
            color: sizeColor,
          ),
        ),
      ],
    );
  }
}
