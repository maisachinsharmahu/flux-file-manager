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

class RecentsList extends ConsumerWidget {
  const RecentsList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final headerColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    // Watch the dynamic files list and sort by modification date descending
    final allFiles = ref.watch(allFilesProvider);
    final sorted = List<FluxFile>.from(allFiles)
      ..sort((a, b) => b.modifiedDate.compareTo(a.modifiedDate));
    final recents = sorted.take(3).toList();

    if (recents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24.0.w, 24.0.h, 24.0.w, 12.0.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Uploaded',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18.0.sp,
                  fontWeight: FontWeight.w700,
                  color: headerColor,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/all_files?title=Recent Uploads'),
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
        ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 24.0.w),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recents.length,
          separatorBuilder: (context, index) =>
              Divider(color: dividerColor, height: 1.0.h, thickness: 1.0.r),
          itemBuilder: (context, index) {
            return _RecentItemRow(file: recents[index]);
          },
        ),
      ],
    );
  }
}

class _RecentItemRow extends StatelessWidget {
  final FluxFile file;

  const _RecentItemRow({
    Key? key,
    required this.file,
  }) : super(key: key);

  void _showDetails(BuildContext context) {
    final detail = FileDetail(
      name: file.name,
      size: file.sizeString,
      createdDate: DateFormatter.formatFriendly(file.modifiedDate),
      modifiedDate: '${file.modifiedDate.year}-${file.modifiedDate.month.toString().padLeft(2, '0')}-${file.modifiedDate.day.toString().padLeft(2, '0')}',
      type: file.category,
      themeColor: file.themeColor,
      fallbackIcon: file.fallbackIcon,
      fluxIcon: file.fluxIcon,
    );
    FileDetailSheet.show(context, detail);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final titleColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final subtitleColor = isDark
        ? AppColors.textSecondaryLight.withValues(alpha: 0.6)
        : AppColors.neutral400;

    // Build subtitle description
    final hoursAgo = DateTime.now().difference(file.modifiedDate).inHours;
    final String timeString = hoursAgo <= 0 
        ? 'Just now' 
        : (hoursAgo < 24 ? '$hoursAgo hours ago' : '${(hoursAgo/24).round()} days ago');
    final subtitle = '${file.category} • ${file.sizeString} • $timeString';

    return GestureDetector(
      onTap: () => context.push('/viewer?path=${Uri.encodeQueryComponent(file.path)}'),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0.h),
        child: Row(
          children: [
            FileTypeIcon(
              extension: file.fileExtension,
              path: file.path,
              size: 44.0.r,
            ),
            SizedBox(width: 16.0.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15.0.sp,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.0.h),
                  Text(
                    subtitle,
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
            GestureDetector(
              onTap: () => _showDetails(context),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.all(8.0.r),
                child: Icon(
                  Icons.more_vert,
                  size: 20.0.r,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
