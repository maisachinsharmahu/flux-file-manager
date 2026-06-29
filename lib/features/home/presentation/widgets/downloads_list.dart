import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/flux_icon.dart';
import '../../../../core/theme/app_colors.dart';
import 'file_detail_sheet.dart';

class DownloadsList extends StatefulWidget {
  const DownloadsList({Key? key}) : super(key: key);

  @override
  State<DownloadsList> createState() => _DownloadsListState();
}

class _DownloadsListState extends State<DownloadsList> {
  late PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    // 0.6 viewportFraction perfectly displays:
    // Active item: 60% screen width
    // Next item: ~30% visible
    // Third item: ~10% peeking
    _pageController = PageController(viewportFraction: 0.62);
    _pageController.addListener(() {
      if (mounted) {
        setState(() {
          _currentPage = _pageController.page ?? 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final headerColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final cardBgColor = isDark ? AppColors.neutral900 : AppColors.neutral100;
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
      'budget_sheets.xlsx',
    ];
    final sizeStrings = ['240 KB', '1.2 MB', '125 MB', '2.4 MB', '670 KB'];
    final formatLabels = ['Word', 'PDF', 'Video', 'Image', 'Excel'];
    final dates = ['2026-06-29', '2026-06-29', '2026-06-29', '2026-06-29', '2026-06-29'];

    final lightColors = [
      AppColors.excelLightBg,
      AppColors.pdfBackground,
      AppColors.pptLightBg,
      AppColors.excelLightBg,
      AppColors.excelLightBg,
    ];
    final darkColors = [
      AppColors.excelDarkBg,
      AppColors.pdfDarkBg,
      AppColors.pptDarkBg,
      AppColors.excelDarkBg,
      AppColors.excelDarkBg,
    ];
    final colors = isDark ? darkColors : lightColors;

    final icons = [
      FluxIconType.documentColor,
      FluxIconType.adobeReader,
      FluxIconType.videoFileColor,
      FluxIconType.imageFileColor,
      FluxIconType.documentColor,
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
          height: 180.0.h,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: titles.length,
            padEnds: false, // Ensures the 1st card aligns to the left padding boundary
            itemBuilder: (context, index) {
              final title = titles[index];
              final sizeStr = sizeStrings[index];
              final formatLabel = formatLabels[index];
              final itemColor = colors[index];
              final iconType = icons[index];

              // Calculate relative distance from current view page
              final double diff = index - _currentPage;
              
              // Apply smooth scale and translation offsets for deep 3D carousel effect
              final double scale = (1.0 - (diff.abs() * 0.1)).clamp(0.85, 1.0);
              final double opacity = (1.0 - (diff.abs() * 0.3)).clamp(0.6, 1.0);
              
              return Transform.scale(
                scale: scale,
                alignment: Alignment.centerLeft, // Keep left aligned so margins match naturally
                child: Opacity(
                  opacity: opacity,
                  child: Padding(
                    padding: EdgeInsets.only(left: 24.0.w, right: 4.0.w),
                    child: GestureDetector(
                      onTap: () {
                        final categories = ['Documents', 'Documents', 'Videos', 'Photos', 'Documents'];
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
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(24.0.r),
                          border: Border.all(color: borderCol, width: 1.0.r),
                          boxShadow: [
                            if (diff.abs() < 0.5)
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                blurRadius: 12.0.r,
                                offset: Offset(0, 6.h),
                              ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Upper preview part (Large illustration/icon placeholder)
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: itemColor.withValues(alpha: isDark ? 0.08 : 0.3),
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(24.0.r)),
                                ),
                                child: Center(
                                  child: FluxIcon(
                                    iconType,
                                    size: 38.0.r,
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
                                  SizedBox(height: 4.0.h),
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
                                        padding: EdgeInsets.symmetric(horizontal: 6.0.w, vertical: 2.0.h),
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
                    ),
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
