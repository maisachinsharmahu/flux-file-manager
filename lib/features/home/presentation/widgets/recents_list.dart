import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/flux_icon.dart';
import '../../../../core/widgets/file_type_icon.dart';
import '../../../../core/theme/app_colors.dart';

import 'file_detail_sheet.dart';

class RecentsList extends StatelessWidget {
  const RecentsList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final headerColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

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
          itemCount: 3,
          separatorBuilder: (context, index) =>
              Divider(color: dividerColor, height: 1.0.h, thickness: 1.0.r),
          itemBuilder: (context, index) {
            final titles = [
              'Quarterly_Report.pptx',
              'Project_Design_Brief.pdf',
              'Revenue_Model_2026.xlsx',
            ];
            final subtitles = [
              'PowerPoint • 2.4 MB • 2 hours ago',
              'PDF Document • 4.8 MB • 5 hours ago',
              'Excel Sheet • 1.1 MB • Yesterday',
            ];

            final lightColors = [
              AppColors.pptLightBg,
              AppColors.pdfBackground,
              AppColors.excelLightBg,
            ];
            final darkColors = [
              AppColors.pptDarkBg,
              AppColors.pdfDarkBg,
              AppColors.excelDarkBg,
            ];

            final iconColors = [
              AppColors.pptIcon,
              AppColors.pdfIcon,
              AppColors.excelIcon,
            ];

            final fallbackIcons = [
              Icons.slideshow_outlined,
              Icons.picture_as_pdf_outlined,
              Icons.table_chart_outlined,
            ];

            final extensions = ['pptx', 'pdf', 'xlsx'];

            final bgColor = isDark ? darkColors[index] : lightColors[index];

            return _RecentItemRow(
              title: titles[index],
              subtitle: subtitles[index],
              bgColor: bgColor,
              iconColor: iconColors[index],
              fallbackIcon: fallbackIcons[index],
              extension: extensions[index],
            );
          },
        ),
      ],
    );
  }
}

class _RecentItemRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color bgColor;
  final Color iconColor;
  final IconData fallbackIcon;
  final String extension;

  const _RecentItemRow({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.bgColor,
    required this.iconColor,
    required this.fallbackIcon,
    required this.extension,
  }) : super(key: key);

  void _showDetails(BuildContext context) {
    FileDetail detail;
    if (title.contains('Report')) {
      detail = FileDetail(
        name: 'Quarterly_Report.pptx',
        size: '2.4 MB',
        createdDate: 'June 28, 2026, 12:14 PM',
        modifiedDate: 'June 29, 2026, 12:20 PM',
        type: 'PowerPoint Presentation',
        themeColor: iconColor,
        fallbackIcon: fallbackIcon,
        fluxIcon: fluxIcon,
      );
    } else if (title.contains('Brief')) {
      detail = FileDetail(
        name: 'Project_Design_Brief.pdf',
        size: '4.8 MB',
        createdDate: 'June 28, 2026, 09:10 AM',
        modifiedDate: 'June 29, 2026, 09:14 AM',
        type: 'PDF Document',
        themeColor: iconColor,
        fallbackIcon: fallbackIcon,
        fluxIcon: fluxIcon,
      );
    } else {
      detail = FileDetail(
        name: 'Revenue_Model_2026.xlsx',
        size: '1.1 MB',
        createdDate: 'June 27, 2026, 03:40 PM',
        modifiedDate: 'June 28, 2026, 05:30 PM',
        type: 'Excel Spreadsheet',
        themeColor: iconColor,
        fallbackIcon: fallbackIcon,
        fluxIcon: null,
      );
    }

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

    return GestureDetector(
      onTap: () => _showDetails(context),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0.h),
        child: Row(
          children: [
            FileTypeIcon(
              extension: extension,
              size: 44.0.r,
            ),
            SizedBox(width: 16.0.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
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
