import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';

class SmartCardsList extends StatelessWidget {
  const SmartCardsList({Key? key}) : super(key: key);

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
    final titleColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final descriptionColor = isDark ? AppColors.textSecondaryLight.withValues(alpha: 0.6) : AppColors.neutral400;

    final List<Map<String, dynamic>> cards = [
      {
        'title': 'AI Cleanup Suggestion',
        'desc': 'Found 1.2 GB of temporary caches & logs.',
        'btn': 'Clean Now',
        'icon': Icons.auto_awesome_outlined,
      },
      {
        'title': 'Duplicate Files Detected',
        'desc': '24 matching document blocks (recovers 420 MB).',
        'btn': 'Prune duplicates',
        'icon': Icons.file_copy_outlined,
      },
      {
        'title': 'Large Files Review',
        'desc': '6 files exceeding 100 MB (recovers 2.4 GB).',
        'btn': 'Review',
        'icon': Icons.assignment_late_outlined,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24.0.w, 24.0.h, 24.0.w, 12.0.h),
          child: Text(
            'Smart Recommendations',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18.0.sp,
              fontWeight: FontWeight.w700,
              color: headerColor,
            ),
          ),
        ),
        SizedBox(
          height: 145.0.h,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 24.0.w),
            child: Row(
              children: cards.map((card) {
                final icon = card['icon'] as IconData;
                final title = card['title'] as String;
                final desc = card['desc'] as String;
                final btnLabel = card['btn'] as String;

                return Container(
                  width: 250.0.w,
                  margin: EdgeInsets.only(right: 14.0.w),
                  padding: EdgeInsets.all(16.0.r),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(20.0.r),
                    border: Border.all(color: borderColor, width: 1.2.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28.0.r,
                            height: 28.0.r,
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? Colors.white.withValues(alpha: 0.06) 
                                  : Colors.black.withValues(alpha: 0.04),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                icon,
                                size: 15.0.r,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          SizedBox(width: 10.0.w),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13.0.sp,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.0.h),
                      Text(
                        desc,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w500,
                          color: descriptionColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.0.w, vertical: 6.0.h),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white : AppColors.neutral900,
                              borderRadius: BorderRadius.circular(12.0.r),
                            ),
                            child: Text(
                              btnLabel,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11.0.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
