import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/trash_provider.dart';

class HomeTrashSection extends ConsumerWidget {
  const HomeTrashSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashFiles = ref.watch(trashProvider);
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
            'System Tools',
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
          child: GestureDetector(
            onTap: () {
              context.push('/trash');
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
                  child: Row(
                    children: [
                      Container(
                        width: 44.0.r,
                        height: 44.0.r,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.red.withValues(alpha: 0.15)
                              : Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12.0.r),
                        ),
                        child: Icon(
                          Icons.delete_sweep_outlined,
                          color: isDark ? Colors.redAccent : Colors.red.shade600,
                          size: 24.0.r,
                        ),
                      ),
                      SizedBox(width: 16.0.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Trash & Recovery',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14.0.sp,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                            ),
                            SizedBox(height: 3.0.h),
                            Text(
                              trashFiles.isEmpty
                                  ? 'Trash is empty. Reclaim space here.'
                                  : '${trashFiles.length} items waiting in Trash.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.0.sp,
                                fontWeight: FontWeight.w500,
                                color: trashFiles.isEmpty
                                    ? subtitleColor
                                    : (isDark ? Colors.orangeAccent : Colors.orange.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12.0.r,
                        color: subtitleColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
