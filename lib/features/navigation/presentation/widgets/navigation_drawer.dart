import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/navigation_provider.dart';
import '../../../../core/theme/app_colors.dart';

class FluxNavigationDrawer extends ConsumerWidget {
  const FluxNavigationDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeIndex = ref.watch(activeIndexProvider);
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
      {'index': 0, 'title': 'Dashboard', 'icon': Icons.dashboard_outlined},
      {'index': 3, 'title': 'Internal Storage', 'icon': Icons.folder_open_outlined},
      {'index': 1, 'title': 'Storage Analytics', 'icon': Icons.pie_chart_outline_rounded},
      {'index': 5, 'title': 'Trash & Recovery', 'icon': Icons.delete_outline_rounded},
      {'index': 4, 'title': 'Settings & Tuning', 'icon': Icons.settings_outlined},
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
                  // Drawer Header
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 16.0.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                        SizedBox(height: 24.0.h),
                        // Profile Info Row
                        Row(
                          children: [
                            Container(
                              width: 40.0.r,
                              height: 40.0.r,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [AppColors.mintAccent, Color(0xFF059669)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'S',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15.0.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.0.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sachin Sharma',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14.0.sp,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 2.0.h),
                                  Text(
                                    'sachin@flux.io',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11.5.sp,
                                      fontWeight: FontWeight.w500,
                                      color: subtitleColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.0.h),
                        // Mini Storage Meter Card inside drawer
                        Container(
                          padding: EdgeInsets.all(12.0.r),
                          decoration: BoxDecoration(
                            color: isDark 
                                ? Colors.white.withValues(alpha: 0.03) 
                                : Colors.black.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(16.0.r),
                            border: Border.all(color: borderColor, width: 1.0.r),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Storage Used',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11.5.sp,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    '24.5 GB / 128 GB',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11.0.sp,
                                      fontWeight: FontWeight.w500,
                                      color: subtitleColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.0.h),
                              // Spaced capsule progress bar matching home style
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3.0.r),
                                child: Container(
                                  height: 6.0.h,
                                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 25,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: AppColors.mintAccent,
                                            borderRadius: BorderRadius.circular(3.0.r),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 2.0.w),
                                      Expanded(
                                        flex: 75,
                                        child: SizedBox.shrink(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: borderColor, height: 1.0.h, thickness: 1.0.r),
                  SizedBox(height: 12.0.h),
                  // Navigation Items
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.0.w),
                      itemCount: menuItems.length,
                      itemBuilder: (context, index) {
                        final item = menuItems[index];
                        final itemIndex = item['index'] as int;
                        final title = item['title'] as String;
                        final icon = item['icon'] as IconData;
                        final isActive = activeIndex == itemIndex;

                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.0.h),
                          child: InkWell(
                            onTap: () {
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
                  // Footer
                  Padding(
                    padding: EdgeInsets.fromLTRB(24.0.w, 16.0.h, 24.0.w, 24.0.h),
                    child: Text(
                      'FLUX v1.0.0',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.0.sp,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                      ),
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
