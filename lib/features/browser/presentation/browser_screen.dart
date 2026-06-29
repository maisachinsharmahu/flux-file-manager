import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../navigation/providers/navigation_provider.dart';
import '../../../../core/theme/app_colors.dart';

class BrowserScreen extends ConsumerStatefulWidget {
  const BrowserScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends ConsumerState<BrowserScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    // Simulate a network refresh delay
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Detect visibility changes inside IndexedStack (BrowserScreen is at index 3)
    final isActive = ref.watch(activeIndexProvider) == 3;
    if (isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_controller.isAnimating && _controller.value == 0.0) {
          _controller.forward();
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.value > 0.0) {
          _controller.reset();
        }
      });
    }

    final activeCategory = ref.watch(selectedBrowserCategoryProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.pureBlack : AppColors.pureWhite;
    final textColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final subtitleColor = isDark ? AppColors.textSecondaryLight.withValues(alpha: 0.6) : AppColors.neutral400;
    final iconColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final dividerColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05);

    // Mock category file lists
    final List<Map<String, dynamic>> photosFiles = [
      {'name': 'vacation_pic_1.jpg', 'size': '2.4 MB', 'type': 'JPEG Image', 'color': const Color(0xFFFFD020), 'icon': Icons.image_outlined},
      {'name': 'screenshot_2.png', 'size': '850 KB', 'type': 'PNG Image', 'color': const Color(0xFFFFD020), 'icon': Icons.image_outlined},
      {'name': 'profile_3.jpg', 'size': '1.2 MB', 'type': 'JPEG Image', 'color': const Color(0xFFFFD020), 'icon': Icons.image_outlined},
      {'name': 'insta_story_4.jpeg', 'size': '3.1 MB', 'type': 'JPEG Image', 'color': const Color(0xFFFFD020), 'icon': Icons.image_outlined},
      {'name': 'avatar_glowing.png', 'size': '400 KB', 'type': 'PNG Image', 'color': const Color(0xFFFFD020), 'icon': Icons.image_outlined},
    ];

    final List<Map<String, dynamic>> videosFiles = [
      {'name': 'vlog_v3.mp4', 'size': '48 MB', 'type': 'MP4 Video', 'color': const Color(0xFFFF9010), 'icon': Icons.play_circle_outline},
      {'name': 'tutorial_flutter.mov', 'size': '125 MB', 'type': 'MOV Video', 'color': const Color(0xFFFF9010), 'icon': Icons.play_circle_outline},
      {'name': 'movie_sample.mkv', 'size': '820 MB', 'type': 'MKV Video', 'color': const Color(0xFFFF9010), 'icon': Icons.play_circle_outline},
      {'name': 'screen_recording.mp4', 'size': '12 MB', 'type': 'MP4 Video', 'color': const Color(0xFFFF9010), 'icon': Icons.play_circle_outline},
    ];

    final List<Map<String, dynamic>> docsFiles = [
      {'name': 'resume_sachin.pdf', 'size': '1.2 MB', 'type': 'PDF Document', 'color': const Color(0xFFA020F0), 'icon': Icons.description_outlined},
      {'name': 'invoice_flux.docx', 'size': '240 KB', 'type': 'Word Document', 'color': const Color(0xFFA020F0), 'icon': Icons.description_outlined},
      {'name': 'budget_june.xlsx', 'size': '670 KB', 'type': 'Excel Sheet', 'color': const Color(0xFFA020F0), 'icon': Icons.description_outlined},
      {'name': 'project_proposal.pdf', 'size': '4.2 MB', 'type': 'PDF Document', 'color': const Color(0xFFA020F0), 'icon': Icons.description_outlined},
    ];

    final List<Map<String, dynamic>> audioFiles = [
      {'name': 'audio_recording.wav', 'size': '15 MB', 'type': 'WAV Audio', 'color': const Color(0xFFFF40A0), 'icon': Icons.music_note_outlined},
      {'name': 'song_remix.mp3', 'size': '8.2 MB', 'type': 'MP3 Audio', 'color': const Color(0xFFFF40A0), 'icon': Icons.music_note_outlined},
      {'name': 'podcast_e1.m4a', 'size': '42 MB', 'type': 'M4A Audio', 'color': const Color(0xFFFF40A0), 'icon': Icons.music_note_outlined},
    ];

    // Mock folder list for root "Internal Storage"
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

    // Determine current display configuration
    final String pageTitle = activeCategory ?? 'Internal Storage';
    
    List<Map<String, dynamic>> currentList = folders;
    bool isFolderList = true;

    if (activeCategory != null) {
      isFolderList = false;
      if (activeCategory == 'Photos') {
        currentList = photosFiles;
      } else if (activeCategory == 'Videos') {
        currentList = videosFiles;
      } else if (activeCategory == 'Documents') {
        currentList = docsFiles;
      } else if (activeCategory == 'Audio') {
        currentList = audioFiles;
      }
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.0.w, 16.0.h, 20.0.w, 8.0.h),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (activeCategory != null) {
                                // If viewing a category, go back to Analytics and clear category filter
                                ref.read(selectedBrowserCategoryProvider.notifier).state = null;
                                ref.read(activeIndexProvider.notifier).state = 1; // Back to Analytics
                              } else {
                                // If root folders, go back to Home
                                ref.read(activeIndexProvider.notifier).state = 0; // Back to Home
                              }
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
                            pageTitle,
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
                    // Dynamic Files/Folders ListView wrapped in RefreshIndicator
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.mintAccent,
                        backgroundColor: isDark ? AppColors.neutral900 : Colors.white,
                        displacement: 20.h,
                        onRefresh: _handleRefresh,
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: 24.0.w),
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          itemCount: currentList.length,
                          separatorBuilder: (context, index) => Divider(
                            color: dividerColor,
                            height: 1.0.h,
                            thickness: 1.0.r,
                          ),
                          itemBuilder: (context, index) {
                            final item = currentList[index];

                            if (isFolderList) {
                              // Render standard folder row
                              final hasHeart = item['heart'] as bool;
                              final name = item['name'] as String;
                              final itemsCount = item['items'] as int;
                              final size = item['size'] as String;

                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0.h),
                                child: Row(
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Icon(
                                          Icons.folder,
                                          size: 44.0.r,
                                          color: const Color(0xFFFFB020),
                                        ),
                                        if (hasHeart)
                                          Padding(
                                            padding: EdgeInsets.only(top: 6.0.h),
                                            child: Icon(
                                              Icons.favorite,
                                              size: 11.0.r,
                                              color: Colors.red,
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(width: 16.0.w),
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
                                            '$itemsCount ${itemsCount == 1 ? 'item' : 'items'} • $size',
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
                            } else {
                              // Render files list row
                              final name = item['name'] as String;
                              final size = item['size'] as String;
                              final type = item['type'] as String;
                              final color = item['color'] as Color;
                              final icon = item['icon'] as IconData;

                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0.h),
                                child: Row(
                                  children: [
                                    // File Category Icon inside circular frame
                                    Container(
                                      width: 44.0.r,
                                      height: 44.0.r,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          icon,
                                          size: 22.0.r,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 16.0.w),
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
                                            '$size • $type',
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
                            }
                          },
                        ),
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
                        Icons.fit_screen_outlined,
                        size: 22.0.r,
                        color: iconColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
