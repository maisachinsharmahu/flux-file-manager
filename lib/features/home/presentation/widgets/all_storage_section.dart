import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/storage_category_icon.dart';
import '../../../navigation/providers/navigation_provider.dart';

class AllStorageSection extends ConsumerWidget {
  const AllStorageSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final headerColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final cardBgColor = isDark
        ? AppColors.neutral900.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.6);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final titleColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final subtitleColor = isDark
        ? AppColors.textSecondaryLight.withValues(alpha: 0.6)
        : AppColors.neutral400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24.0.w, 24.0.h, 24.0.w, 12.0.h),
          child: Text(
            'All Storage',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18.0.sp,
              fontWeight: FontWeight.w700,
              color: headerColor,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0.w),
          child: Row(
            children: [
              // Internal Storage Card
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Navigate to Internal Storage (Root list view)
                    ref.read(selectedBrowserCategoryProvider.notifier).state =
                        null;
                    ref.read(activeIndexProvider.notifier).state = 3;
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.0.r),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        padding: EdgeInsets.all(16.0.r),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(20.0.r),
                          border: Border.all(color: borderColor, width: 1.2.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                StorageCategoryIconWidget(
                                  icon: StorageCategoryIcon.internalStorage,
                                  size: 36.0.r,
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 12.0.r,
                                  color: subtitleColor,
                                ),
                              ],
                            ),
                            SizedBox(height: 14.0.h),
                            Text(
                              'Internal Storage',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14.0.sp,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                            ),
                            SizedBox(height: 4.0.h),
                            Text(
                              '48 GB / 120 GB',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.0.sp,
                                fontWeight: FontWeight.w500,
                                color: subtitleColor,
                              ),
                            ),
                            SizedBox(height: 12.0.h),
                            // Mini Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4.0.r),
                              child: LinearProgressIndicator(
                                value: 48 / 120,
                                minHeight: 4.0.h,
                                backgroundColor: isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.05),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.mintAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 14.0.w),
              // Other Storage Card
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Other storage clicked
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.0.r),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        padding: EdgeInsets.all(16.0.r),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(20.0.r),
                          border: Border.all(color: borderColor, width: 1.2.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                StorageCategoryIconWidget(
                                  icon: StorageCategoryIcon.sdCard,
                                  size: 36.0.r,
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 12.0.r,
                                  color: subtitleColor,
                                ),
                              ],
                            ),
                            SizedBox(height: 14.0.h),
                            Text(
                              'Other Storage',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14.0.sp,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                            ),
                            SizedBox(height: 4.0.h),
                            Text(
                              '12 GB / 64 GB',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.0.sp,
                                fontWeight: FontWeight.w500,
                                color: subtitleColor,
                              ),
                            ),
                            SizedBox(height: 12.0.h),
                            // Mini Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4.0.r),
                              child: LinearProgressIndicator(
                                value: 12 / 64,
                                minHeight: 4.0.h,
                                backgroundColor: isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.05),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFA020F0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
