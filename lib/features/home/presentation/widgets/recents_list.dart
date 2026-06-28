import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/widgets/flux_icon.dart';
import '../../../../core/theme/app_colors.dart';

class RecentsList extends StatelessWidget {
  const RecentsList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final headerColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final cardBgColor = isDark 
        ? AppColors.neutral900.withValues(alpha: 0.6) 
        : Colors.white.withValues(alpha: 0.6);
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
                'Recent Uploaded',
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
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0.w),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.0.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(24.0.r),
                  border: Border.all(color: borderColor, width: 1.5.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 8.0.h, horizontal: 16.0.w),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  separatorBuilder: (context, index) => Divider(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                    height: 1.0.h,
                    thickness: 1.0.r,
                    indent: 64.0.w,
                  ),
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

                    final fluxIcons = [
                      null, // Fallback to PowerPoint slides outline
                      FluxIconType.adobeReader, // Premium PDF icon SVG
                      FluxIconType.documentColor, // Premium Spreadsheet document SVG
                    ];

                    final bgColor = isDark ? darkColors[index] : lightColors[index];

                    return _RecentItemRow(
                      title: titles[index],
                      subtitle: subtitles[index],
                      bgColor: bgColor,
                      iconColor: iconColors[index],
                      fallbackIcon: fallbackIcons[index],
                      fluxIcon: fluxIcons[index],
                    );
                  },
                ),
              ),
            ),
          ),
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
  final FluxIconType? fluxIcon;

  const _RecentItemRow({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.bgColor,
    required this.iconColor,
    required this.fallbackIcon,
    this.fluxIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final titleColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final subtitleColor = isDark ? AppColors.textSecondaryLight : AppColors.neutral400;
    final actionIconColor = isDark ? AppColors.textSecondaryLight : AppColors.neutral400;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.0.h),
      child: Row(
        children: [
          Container(
            width: 48.0.w,
            height: 48.0.h,
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: isDark ? 0.35 : 0.8),
              borderRadius: BorderRadius.circular(14.0.r),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.2),
                width: 1.0.r,
              ),
            ),
            child: Center(
              child: fluxIcon != null
                  ? FluxIcon(
                      fluxIcon!,
                      size: 24.0.r,
                    )
                  : Icon(
                      fallbackIcon,
                      color: iconColor,
                      size: 24.0.r,
                    ),
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
                    fontSize: 14.0.sp,
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
          IconButton(
            icon: FluxIcon(
              FluxIconType.menuVerticalOff,
              size: 24.0.r,
              color: actionIconColor,
            ),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20.0.r,
          ),
        ],
      ),
    );
  }
}
