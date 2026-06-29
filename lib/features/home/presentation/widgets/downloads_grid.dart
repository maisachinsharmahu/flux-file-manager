import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/flux_icon.dart';
import '../../../../core/theme/app_colors.dart';
import 'file_detail_sheet.dart';

class DownloadsGrid extends StatelessWidget {
  const DownloadsGrid({Key? key}) : super(key: key);

  static final List<Map<String, dynamic>> _mockDownloads = [
    {
      'title': 'invoice_flux.docx',
      'subtitle': '240 KB • 1h ago',
      'category': 'Documents',
      'size': '240 KB',
      'date': '2026-06-29',
      'icon': FluxIconType.documentColor,
      'color': AppColors.excelLightBg,
      'darkColor': AppColors.excelDarkBg,
      'fallbackIcon': Icons.description_outlined,
    },
    {
      'title': 'resume_sachin.pdf',
      'subtitle': '1.2 MB • 3h ago',
      'category': 'Documents',
      'size': '1.2 MB',
      'date': '2026-06-29',
      'icon': FluxIconType.adobeReader,
      'color': AppColors.pdfBackground,
      'darkColor': AppColors.pdfDarkBg,
      'fallbackIcon': Icons.picture_as_pdf_outlined,
    },
    {
      'title': 'tutorial_flutter.mov',
      'subtitle': '125 MB • 6h ago',
      'category': 'Videos',
      'size': '125 MB',
      'date': '2026-06-29',
      'icon': FluxIconType.videoFileColor,
      'color': AppColors.pptLightBg,
      'darkColor': AppColors.pptDarkBg,
      'fallbackIcon': Icons.play_circle_outline,
    },
    {
      'title': 'vacation_pic_1.jpg',
      'subtitle': '2.4 MB • 12h ago',
      'category': 'Images',
      'size': '2.4 MB',
      'date': '2026-06-29',
      'icon': FluxIconType.imageFileColor,
      'color': AppColors.excelLightBg,
      'darkColor': AppColors.excelDarkBg,
      'fallbackIcon': Icons.image_outlined,
    },
    {
      'title': 'flux_file_manager.apk',
      'subtitle': '18 MB • Yesterday',
      'category': 'Apps',
      'size': '18 MB',
      'date': '2026-06-28',
      'icon': FluxIconType.apk,
      'color': AppColors.pdfBackground,
      'darkColor': AppColors.pdfDarkBg,
      'fallbackIcon': Icons.android_outlined,
    },
    {
      'title': 'audio_recording.wav',
      'subtitle': '15 MB • 2 days ago',
      'category': 'Audio',
      'size': '15 MB',
      'date': '2026-06-27',
      'icon': FluxIconType.audioColor,
      'color': AppColors.pptLightBg,
      'darkColor': AppColors.pptDarkBg,
      'fallbackIcon': Icons.audiotrack_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
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
        SizedBox(
          height: 240.0.h,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 24.0.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12.0.w,
              crossAxisSpacing: 12.0.h,
              childAspectRatio: 1.0, // Exact square ratio!
            ),
            itemCount: _mockDownloads.length,
            itemBuilder: (context, index) {
              final item = _mockDownloads[index];
              final itemThemeColor = isDark ? item['darkColor'] as Color : item['color'] as Color;

              return GestureDetector(
                onTap: () {
                  final detail = FileDetail(
                    name: item['title'] as String,
                    size: item['size'] as String,
                    createdDate: 'June 28, 2026, 12:14 PM',
                    modifiedDate: item['date'] as String,
                    type: item['category'] as String,
                    themeColor: itemThemeColor,
                    fallbackIcon: item['fallbackIcon'] as IconData,
                    fluxIcon: item['icon'] as FluxIconType,
                  );
                  FileDetailSheet.show(context, detail);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16.0.r),
                    border: Border.all(
                      color: borderColor,
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
                          color: itemThemeColor.withValues(alpha: isDark ? 0.2 : 0.8),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: FluxIcon(item['icon'] as FluxIconType, size: 18.0.r),
                        ),
                      ),
                      SizedBox(height: 10.0.h),
                      Text(
                        item['title'] as String,
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
                        item['subtitle'] as String,
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
