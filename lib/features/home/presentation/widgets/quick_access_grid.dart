import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/widgets/flux_icon.dart';
import '../../../../core/theme/app_colors.dart';

class QuickAccessGrid extends StatelessWidget {
  const QuickAccessGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final headerColor = isDark ? AppColors.pureWhite : AppColors.neutral900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 8.0.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18.0.sp,
                  fontWeight: FontWeight.w700,
                  color: headerColor,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.0.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mintAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.0.h),
        SizedBox(
          height: 180.0.h,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 24.0.w),
            child: Row(
              children: [
                const _CategoryCard(
                  title: 'Audio',
                  count: '12 items',
                  fluxIcon: FluxIconType.audioColor,
                  accentColor: AppColors.storageCoral,
                ),
                SizedBox(width: 16.0.w),
                const _CategoryCard(
                  title: 'Images',
                  count: '9,128 items',
                  fluxIcon: FluxIconType.imageFileColor,
                  accentColor: AppColors.storageSkyBlue,
                ),
                SizedBox(width: 16.0.w),
                const _CategoryCard(
                  title: 'Docs',
                  count: '135 items',
                  fluxIcon: FluxIconType.documentColor,
                  accentColor: AppColors.storageYellow,
                ),
                SizedBox(width: 24.0.w),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String count;
  final FluxIconType fluxIcon;
  final Color accentColor;

  const _CategoryCard({
    Key? key,
    required this.title,
    required this.count,
    required this.fluxIcon,
    required this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBgColor = isDark 
        ? AppColors.neutral900.withValues(alpha: 0.6) 
        : Colors.white.withValues(alpha: 0.6);
    final borderColor = isDark 
        ? Colors.white.withValues(alpha: 0.08) 
        : Colors.black.withValues(alpha: 0.05);
    final titleColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final subtitleColor = isDark ? AppColors.textSecondaryLight : AppColors.neutral400;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24.0.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          width: 130.0.w,
          height: 170.0.h,
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(24.0.r),
            border: Border.all(color: borderColor, width: 1.5.r),
          ),
          padding: EdgeInsets.symmetric(vertical: 20.0.h, horizontal: 16.0.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48.0.w,
                height: 48.0.h,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.25),
                    width: 1.5.r,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.15),
                      blurRadius: 10.r,
                      spreadRadius: 1.r,
                    ),
                  ],
                ),
                child: Center(
                  child: FluxIcon(
                    fluxIcon, 
                    size: 24.0.r,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15.0.sp,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              SizedBox(height: 4.0.h),
              Text(
                count,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.0.sp,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
