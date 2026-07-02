import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/storage_category_icon.dart';
import '../../../navigation/providers/navigation_provider.dart';
import '../../providers/storage_status_provider.dart';

class AllStorageSection extends ConsumerWidget {
  const AllStorageSection({Key? key}) : super(key: key);

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1000) return '$bytes B';
    final double kb = bytes / 1000.0;
    if (kb < 1000.0) return '${kb.toStringAsFixed(1)} KB';
    final double mb = kb / 1000.0;
    if (mb < 1000.0) return '${mb.toStringAsFixed(1)} MB';
    final double gb = mb / 1000.0;
    return '${gb.toStringAsFixed(1)} GB';
  }

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

    final storageAsync = ref.watch(storageStatusProvider);

    return storageAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
      data: (data) {
        final totalStorage =
            data['totalStorage'] as int? ?? 128 * 1000 * 1000 * 1000;
        final totalUsed = data['totalUsed'] as int? ?? 0;
        final hasSecondary = data['hasSecondary'] as bool? ?? false;
        final secondaryTotal = data['secondaryTotal'] as int? ?? 0;
        final secondaryUsed = data['secondaryUsed'] as int? ?? 0;

        final internalProgress = totalStorage > 0
            ? (totalUsed / totalStorage)
            : 0.0;
        final secondaryProgress = secondaryTotal > 0
            ? (secondaryUsed / secondaryTotal)
            : 0.0;

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
                        context.push('/browser');
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
                              border: Border.all(
                                color: borderColor,
                                width: 1.2.r,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                  '${_formatSize(totalUsed)} / ${_formatSize(totalStorage)}',
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
                                    value: internalProgress,
                                    minHeight: 4.0.h,
                                    backgroundColor: isDark
                                        ? Colors.white10
                                        : Colors.black.withValues(alpha: 0.05),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
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
                  if (hasSecondary) ...[
                    SizedBox(width: 14.0.w),
                    // Removable SD Card Card
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // SD Card browsable if navigated
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20.0.r),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 10.0,
                              sigmaY: 10.0,
                            ),
                            child: Container(
                              padding: EdgeInsets.all(16.0.r),
                              decoration: BoxDecoration(
                                color: cardBgColor,
                                borderRadius: BorderRadius.circular(20.0.r),
                                border: Border.all(
                                  color: borderColor,
                                  width: 1.2.r,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                    'SD Card',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14.0.sp,
                                      fontWeight: FontWeight.w700,
                                      color: titleColor,
                                    ),
                                  ),
                                  SizedBox(height: 4.0.h),
                                  Text(
                                    '${_formatSize(secondaryUsed)} / ${_formatSize(secondaryTotal)}',
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
                                      value: secondaryProgress,
                                      minHeight: 4.0.h,
                                      backgroundColor: isDark
                                          ? Colors.white10
                                          : Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
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
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
