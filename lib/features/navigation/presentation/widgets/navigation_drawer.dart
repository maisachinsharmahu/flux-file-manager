import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/navigation_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';

class FluxNavigationDrawer extends ConsumerWidget {
  const FluxNavigationDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeIndex = ref.watch(activeIndexProvider);
    final browserCategory = ref.watch(selectedBrowserCategoryProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark 
        ? const Color(0xE60D0D0D) 
        : const Color(0xE6FFFFFF);
    final borderColor = isDark 
        ? Colors.white.withValues(alpha: 0.08) 
        : Colors.black.withValues(alpha: 0.05);
    final textColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final subtitleColor = isDark ? AppColors.textSecondaryLight.withValues(alpha: 0.6) : AppColors.neutral400;
    final activeBgColor = isDark 
        ? Colors.white.withValues(alpha: 0.06) 
        : Colors.black.withValues(alpha: 0.04);

    final List<Map<String, dynamic>> menuItems = [
      {'index': 3, 'title': 'Internal', 'category': null, 'icon': Icons.storage_outlined},
      {'index': 3, 'title': 'Photos', 'category': 'Photos', 'icon': Icons.image_outlined},
      {'index': 3, 'title': 'Videos', 'category': 'Videos', 'icon': Icons.play_circle_outline},
      {'index': 0, 'title': 'Recent', 'category': null, 'icon': Icons.access_time_rounded},
    ];

    return Drawer(
      width: 280.0.w,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                right: BorderSide(color: borderColor, width: 1.0.r),
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo Header Only
                  Padding(
                    padding: EdgeInsets.fromLTRB(24.0.w, 24.0.h, 24.0.w, 24.0.h),
                    child: Row(
                      children: [
                        Icon(
                          Icons.all_inclusive_outlined,
                          size: 26.0.r,
                          color: AppColors.mintAccent,
                        ),
                        SizedBox(width: 10.0.w),
                        Text(
                          'FLUX',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20.0.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0.w,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Navigation items list
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.0.w),
                      itemCount: menuItems.length,
                      itemBuilder: (context, index) {
                        final item = menuItems[index];
                        final itemIndex = item['index'] as int;
                        final title = item['title'] as String;
                        final category = item['category'] as String?;
                        final icon = item['icon'] as IconData;
                        
                        // Highlight check
                        bool isActive = false;
                        if (itemIndex == 3) {
                          isActive = (activeIndex == 3 && browserCategory == category);
                        } else {
                          isActive = (activeIndex == itemIndex);
                        }

                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.0.h),
                          child: InkWell(
                            onTap: () {
                              ref.read(selectedBrowserCategoryProvider.notifier).state = category;
                              ref.read(activeIndexProvider.notifier).state = itemIndex;
                              Navigator.of(context).pop(); // Close drawer
                            },
                            borderRadius: BorderRadius.circular(12.0.r),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 12.0.h),
                              decoration: BoxDecoration(
                                color: isActive ? activeBgColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(12.0.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    icon,
                                    size: 22.0.r,
                                    color: isActive ? AppColors.mintAccent : subtitleColor,
                                  ),
                                  SizedBox(width: 14.0.w),
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14.0.sp,
                                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                      color: isActive ? textColor : subtitleColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Divider
                  Divider(color: borderColor, height: 1.0.r, thickness: 1.0.r),
                  // Dark/Light Theme Mode Toggle Switch row at the bottom
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 16.0.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                              size: 22.0.r,
                              color: subtitleColor,
                            ),
                            SizedBox(width: 12.0.w),
                            Text(
                              'Dark Mode',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14.0.sp,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        Switch.adaptive(
                          value: isDark,
                          activeThumbColor: AppColors.mintAccent,
                          activeTrackColor: AppColors.mintAccent.withValues(alpha: 0.3),
                          inactiveThumbColor: AppColors.neutral400,
                          inactiveTrackColor: isDark 
                              ? Colors.white.withValues(alpha: 0.1) 
                              : Colors.black.withValues(alpha: 0.05),
                          onChanged: (bool value) {
                            ref.read(themeModeProvider.notifier).toggleTheme(isDark);
                          },
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
  }
}
