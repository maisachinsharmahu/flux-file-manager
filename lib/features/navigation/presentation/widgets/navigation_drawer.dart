import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
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
                              if (category != null) {
                                Navigator.of(context).pop(); // Close drawer
                                context.push('/all_files?title=$title&category=$category');
                              } else {
                                ref.read(selectedBrowserCategoryProvider.notifier).state = null;
                                ref.read(activeIndexProvider.notifier).state = itemIndex;
                                Navigator.of(context).pop(); // Close drawer
                              }
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
                  // Dark/Light Theme Mode custom Toggle row at the bottom
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 16.0.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                                size: 22.0.r,
                                color: subtitleColor,
                              ),
                              SizedBox(width: 12.0.w),
                              Expanded(
                                child: Text(
                                  isDark ? 'Dark Mode' : 'Light Mode',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14.0.sp,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.0.w),
                        _ThemePillToggle(
                          isDark: isDark,
                          onTap: () {
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

class _ThemePillToggle extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _ThemePillToggle({
    Key? key,
    required this.isDark,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkState = theme.brightness == Brightness.dark;

    final containerBg = isDarkState
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);
    final borderColor = isDarkState
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    final sliderBg = isDarkState
        ? AppColors.mintAccent
        : AppColors.neutral900;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 80.0.w,
        height: 34.0.h,
        padding: EdgeInsets.all(3.0.r),
        decoration: BoxDecoration(
          color: containerBg,
          borderRadius: BorderRadius.circular(17.0.r),
          border: Border.all(color: borderColor, width: 1.2.r),
        ),
        child: Stack(
          children: [
            // Sliding Capsule Selector
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: sliderBg,
                    borderRadius: BorderRadius.circular(14.0.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 3.r,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Icons Row
            Row(
              children: [
                // Light mode side
                Expanded(
                  child: Center(
                    child: Icon(
                      Icons.light_mode_rounded,
                      size: 15.0.r,
                      color: isDark
                          ? AppColors.textSecondaryLight.withValues(alpha: 0.4)
                          : Colors.white,
                    ),
                  ),
                ),
                // Dark mode side
                Expanded(
                  child: Center(
                    child: Icon(
                      Icons.dark_mode_rounded,
                      size: 15.0.r,
                      color: isDark
                          ? const Color(0xFF171717)
                          : AppColors.textSecondaryLight.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
