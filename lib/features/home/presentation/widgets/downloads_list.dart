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
    final cardBgColor = isDark
        ? AppColors.neutral900
        : AppColors.neutral100;
    final titleColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final subtitleColor = isDark
        ? AppColors.textSecondaryLight.withValues(alpha: 0.6)
        : AppColors.neutral400;
    final borderCol = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);

    final titles = [
      'invoice_flux.docx',
      'resume_sachin.pdf',
      'tutorial_flutter.mov',
      'vacation_pic.jpg',
    ];
    final sizeStrings = ['240 KB', '1.2 MB', '125 MB', '2.4 MB'];
    final formatLabels = ['Word', 'PDF', 'Video', 'Image'];
    final dates = ['2026-06-29', '2026-06-29', '2026-06-29', '2026-06-29'];

    final lightColors = [
      AppColors.excelLightBg,
      AppColors.pdfBackground,
      AppColors.pptLightBg,
      AppColors.excelLightBg,
    ];
    final darkColors = [
      AppColors.excelDarkBg,
      AppColors.pdfDarkBg,
      AppColors.pptDarkBg,
      AppColors.excelDarkBg,
    ];
    final colors = isDark ? darkColors : lightColors;

    final icons = [
      FluxIconType.documentColor,
      FluxIconType.adobeReader,
      FluxIconType.videoFileColor,
      FluxIconType.imageFileColor,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24.0.w, 24.0.h, 24.0.w, 16.0.h),
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
        SizedBox(
          height: 176.0.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 24.0.w),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: titles.length,
            separatorBuilder: (context, index) => SizedBox(width: 14.0.w),
            itemBuilder: (context, index) {
              final title = titles[index];
              final sizeStr = sizeStrings[index];
              final formatLabel = formatLabels[index];
              final itemColor = colors[index];
              final iconType = icons[index];

              return GestureDetector(
                onTap: () {
                  final categories = ['Documents', 'Documents', 'Videos', 'Photos'];
                  final detail = FileDetail(
                    name: title,
                    size: sizeStr,
                    createdDate: 'June 28, 2026, 12:14 PM',
                    modifiedDate: dates[index],
                    type: categories[index],
                    themeColor: itemColor,
                    fallbackIcon: categories[index] == 'Videos'
                        ? Icons.play_circle_outline
                        : Icons.description_outlined,
                    fluxIcon: iconType,
                  );
                  FileDetailSheet.show(context, detail);
                },
                child: Container(
                  width: 140.0.w,
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(20.0.r),
                    border: Border.all(color: borderCol, width: 1.0.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Upper preview part (Large illustration/icon placeholder)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: itemColor.withValues(alpha: isDark ? 0.08 : 0.3),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20.0.r)),
                          ),
                          child: Center(
                            child: Hero(
                              tag: 'download_icon_$index',
                              child: FluxIcon(
                                iconType,
                                size: 36.0.r,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Card details
                      Padding(
                        padding: EdgeInsets.all(12.0.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13.0.sp,
                                fontWeight: FontWeight.w600,
                                color: titleColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 3.0.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  sizeStr,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11.0.sp,
                                    fontWeight: FontWeight.w500,
                                    color: subtitleColor,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 5.0.w, vertical: 2.0.h),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(6.0.r),
                                  ),
                                  child: Text(
                                    formatLabel,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 9.0.sp,
                                      fontWeight: FontWeight.bold,
                                      color: subtitleColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
