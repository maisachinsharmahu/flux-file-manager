import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../navigation/providers/navigation_provider.dart';
import '../../../../core/theme/app_colors.dart';

class BrowserScreen extends ConsumerWidget {
  const BrowserScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.pureBlack : AppColors.pureWhite;
    final textColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final subtitleColor = isDark ? AppColors.textSecondaryLight.withValues(alpha: 0.6) : AppColors.neutral400;
    final iconColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final dividerColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05);

    // Mock folder list matching the screenshot
    final List<Map<String, dynamic>> folders = [
      {'name': 'Alarms', 'items': 1, 'size': '1 KB', 'heart': false},
      {'name': 'Android', 'items': 6, 'size': '12 MB', 'heart': false},
      {'name': 'Backups', 'items': 1, 'size': '821 MB', 'heart': false},
      {'name': 'Browser', 'items': 3, 'size': '204 KB', 'heart': false},
      {'name': 'Canva', 'items': 23, 'size': '98 MB', 'heart': true},
      {'name': 'DCIM', 'items': 3, 'size': '18.4 GB', 'heart': false},
      {'name': 'Documents', 'items': 6, 'size': '2.4 GB', 'heart': false},
      {'name': 'Download', 'items': 5, 'size': '4.6 GB', 'heart': true},
      {'name': 'Notifications', 'items': 1, 'size': '4 KB', 'heart': false},
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Back button, Title, Add, Search
                Padding(
                  padding: EdgeInsets.fromLTRB(16.0.w, 16.0.h, 20.0.w, 8.0.h),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          ref.read(activeIndexProvider.notifier).state = 0; // Back to Home
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.0.r),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 20.0.r,
                            color: iconColor,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.0.w),
                      Text(
                        'Internal Storage',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24.0.sp,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.add,
                        size: 26.0.r,
                        color: iconColor,
                      ),
                      SizedBox(width: 20.0.w),
                      Icon(
                        Icons.search,
                        size: 26.0.r,
                        color: iconColor,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.0.h),
                // Filters Row: A-Z Dropdown and Grid Toggle
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 8.0.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'A - Z',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14.0.sp,
                              fontWeight: FontWeight.w600,
                              color: subtitleColor,
                            ),
                          ),
                          SizedBox(width: 4.0.w),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 20.0.r,
                            color: subtitleColor,
                          ),
                        ],
                      ),
                      Icon(
                        Icons.grid_view_outlined,
                        size: 22.0.r,
                        color: subtitleColor,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.0.h),
                // Folders ListView
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 24.0.w),
                    physics: const BouncingScrollPhysics(),
                    itemCount: folders.length,
                    separatorBuilder: (context, index) => Divider(
                      color: dividerColor,
                      height: 1.0.h,
                      thickness: 1.0.r,
                    ),
                    itemBuilder: (context, index) {
                      final folder = folders[index];
                      final hasHeart = folder['heart'] as bool;
                      final name = folder['name'] as String;
                      final items = folder['items'] as int;
                      final size = folder['size'] as String;

                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0.h),
                        child: Row(
                          children: [
                            // Folder icon with optional heart badge in the center
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.folder,
                                  size: 44.0.r,
                                  color: const Color(0xFFFFB020), // Exact yellow folder color from screenshot
                                ),
                                if (hasHeart)
                                  Padding(
                                    padding: EdgeInsets.only(top: 6.0.h),
                                    child: Icon(
                                      Icons.favorite,
                                      size: 11.0.r,
                                      color: Colors.red, // Heart icon badge matching screen
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(width: 16.0.w),
                            // Folder Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16.0.sp,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                  SizedBox(height: 4.0.h),
                                  Text(
                                    '$items ${items == 1 ? 'item' : 'items'} • $size',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13.0.sp,
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
                      );
                    },
                  ),
                ),
              ],
            ),
            // Floating scan/layout icon at the bottom right corner
            Positioned(
              right: 24.0.w,
              bottom: 24.0.h,
              child: Container(
                width: 48.0.r,
                height: 48.0.r,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.neutral900 : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10.0.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                  border: Border.all(
                    color: dividerColor,
                    width: 1.0.r,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.fit_screen_outlined, // scanner/alignment icon matching button
                    size: 22.0.r,
                    color: iconColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
