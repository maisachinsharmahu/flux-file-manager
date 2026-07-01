import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/flux_icon.dart';
import '../../../../core/widgets/file_type_icon.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/file_filter_provider.dart';
import 'file_detail_sheet.dart';
import '../../../../core/utils/date_formatter.dart';

class DownloadsGrid extends ConsumerWidget {
  const DownloadsGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final headerColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final titleColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final subtitleColor = isDark
        ? AppColors.textSecondaryLight.withValues(alpha: 0.6)
        : AppColors.neutral400;
    final cardBg = isDark
        ? AppColors.neutral900.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.02);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    // Filter files containing '/Downloads/' or '/Download/' or having downloads-associated extensions/categories
    final allFiles = ref.watch(allFilesProvider);
    final downloads = allFiles
        .where((f) => f.path.toLowerCase().contains('download'))
        .toList();

    // Fallback if no explicit download files found: take the first 8 files from allFilesProvider
    final list = downloads.isNotEmpty ? downloads : allFiles;

    if (list.isEmpty) {
      return const SizedBox.shrink();
    }

    const int maxSpots = 6;
    final int displayCount = list.length < maxSpots ? list.length : maxSpots;
    final int extraCount = list.length - (maxSpots - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24.0.w, 24.0.h, 24.0.w, 12.0.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Downloads',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18.0.sp,
                  fontWeight: FontWeight.w700,
                  color: headerColor,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/all_files?title=Recent Downloads'),
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
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0.w),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12.0.w,
              crossAxisSpacing: 12.0.h,
              childAspectRatio: 0.95,
            ),
            itemCount: displayCount,
            itemBuilder: (context, index) {
              // The 6th spot is "+ X more" card if list size is larger
              if (index == maxSpots - 1 && list.length > maxSpots) {
                return GestureDetector(
                  onTap: () =>
                      context.push('/all_files?title=Recent Downloads'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.mintAccent.withValues(
                        alpha: isDark ? 0.06 : 0.04,
                      ),
                      borderRadius: BorderRadius.circular(16.0.r),
                      border: Border.all(
                        color: AppColors.mintAccent.withValues(alpha: 0.2),
                        width: 1.0.r,
                      ),
                    ),
                    padding: EdgeInsets.all(12.0.r),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 36.0.r,
                          height: 36.0.r,
                          decoration: BoxDecoration(
                            color: AppColors.mintAccent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.add_rounded,
                              color: AppColors.mintAccent,
                              size: 22.0.r,
                            ),
                          ),
                        ),
                        SizedBox(height: 10.0.h),
                        Text(
                          '+$extraCount More',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.0.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mintAccent,
                          ),
                        ),
                        SizedBox(height: 2.0.h),
                        Text(
                          'Files',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10.0.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.mintAccent.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final file = list[index];

              // Build friendly dynamic relative time subtitle
              final hoursAgo = DateTime.now()
                  .difference(file.modifiedDate)
                  .inHours;
              final String timeString = hoursAgo <= 0
                  ? 'Just now'
                  : (hoursAgo < 24
                        ? '${hoursAgo}h ago'
                        : '${(hoursAgo / 24).round()}d ago');

              return GestureDetector(
                onTap: () {
                  final detail = FileDetail(
                    name: file.name,
                    size: file.sizeString,
                    createdDate: DateFormatter.formatFriendly(file.modifiedDate),
                    modifiedDate:
                        '${file.modifiedDate.year}-${file.modifiedDate.month.toString().padLeft(2, '0')}-${file.modifiedDate.day.toString().padLeft(2, '0')}',
                    type: file.category,
                    themeColor: file.themeColor,
                    fallbackIcon: file.fallbackIcon,
                    fluxIcon: file.fluxIcon,
                  );
                  FileDetailSheet.show(context, detail);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16.0.r),
                    border: Border.all(color: borderColor, width: 1.0.r),
                  ),
                  padding: EdgeInsets.all(12.0.r),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      FileTypeIcon(
                        extension: file.fileExtension,
                        path: file.path,
                        size: 36.0.r,
                      ),
                      SizedBox(height: 10.0.h),
                      Text(
                        file.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.0.sp,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.0.h),
                      Text(
                        '${file.sizeString} • $timeString',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10.0.sp,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
