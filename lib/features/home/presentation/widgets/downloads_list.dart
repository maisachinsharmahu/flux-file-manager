import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/flux_icon.dart';
import '../../../../core/theme/app_colors.dart';
import 'file_detail_sheet.dart';

class DownloadsList extends StatelessWidget {
  const DownloadsList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final headerColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final titleColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final subtitleColor = isDark
        ? AppColors.textSecondaryLight.withValues(alpha: 0.6)
        : AppColors.neutral400;
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
                'Recent Downloads',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18.0.sp,
                  fontWeight: FontWeight.w700,
                  color: headerColor,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/all_files'),
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
              'invoice_flux.docx',
              'resume_sachin.pdf',
              'tutorial_flutter.mov',
            ];
            final subtitles = [
              'Word Document • 240 KB • 1 hour ago',
              'PDF Document • 1.2 MB • 3 hours ago',
              'Video File • 125 MB • 6 hours ago',
            ];

            // Reuse existing AppColors definitions
            final lightColors = [
              AppColors.excelLightBg,  // light green for docx
              AppColors.pdfBackground, // light red for pdf
              AppColors.pptLightBg,    // light yellow for mov
            ];
            final darkColors = [
              AppColors.excelDarkBg,
              AppColors.pdfDarkBg,
              AppColors.pptDarkBg,
            ];
            final colors = isDark ? darkColors : lightColors;

            final icons = [
              FluxIconType.documentColor,
              FluxIconType.adobeReader,
              FluxIconType.videoFileColor,
            ];

            final itemColor = colors[index];
            final title = titles[index];
            final subtitle = subtitles[index];
            final iconType = icons[index];

            return InkWell(
              onTap: () {
                // Determine file details
                final categories = ['Documents', 'Documents', 'Videos'];
                final sizeStrings = ['240 KB', '1.2 MB', '125 MB'];
                final dateStrings = ['2026-06-29', '2026-06-29', '2026-06-29'];

                final detail = FileDetail(
                  name: title,
                  size: sizeStrings[index],
                  createdDate: 'June 28, 2026, 12:14 PM',
                  modifiedDate: dateStrings[index],
                  type: categories[index],
                  themeColor: itemColor,
                  fallbackIcon: categories[index] == 'Videos'
                      ? Icons.play_circle_outline
                      : Icons.description_outlined,
                  fluxIcon: iconType,
                );

                FileDetailSheet.show(context, detail);
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 14.0.h),
                child: Row(
                  children: [
                    Container(
                      width: 44.0.r,
                      height: 44.0.r,
                      decoration: BoxDecoration(
                        color: itemColor.withValues(alpha: isDark ? 0.2 : 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: FluxIcon(iconType, size: 22.0.r),
                      ),
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
                    Icon(
                      Icons.more_vert,
                      size: 20.0.r,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
