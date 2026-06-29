import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../navigation/providers/navigation_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../home/presentation/widgets/file_detail_sheet.dart';
import '../../../core/providers/file_filter_provider.dart';
import '../../search/presentation/widgets/quick_sort_filter_sheet.dart';
import '../../../core/widgets/flux_icon.dart';

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
    final filterState = ref.watch(fileFilterProvider);
    
    // Resolve dynamic list based on whether category view is active
    bool isFolderList = activeCategory == null;
    List<FluxFile> currentFileList = [];
    
    if (!isFolderList) {
      final allFiltered = ref.watch(filteredFilesProvider(''));
      currentFileList = allFiltered.where((file) => file.category == activeCategory).toList();
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
                    
                    // Filters Row: Sorting and Layout settings
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 8.0.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                filterState.nameSort != 'Off'
                                    ? 'Name'
                                    : (filterState.sizeSort != 'Off' ? 'Size' : 'Date'),
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
                          
                          // Quick Actions: Advanced Filters & Grid toggle
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isFolderList) ...[
                                GestureDetector(
                                  onTap: () {
                                    QuickSortFilterSheet.show(context);
                                  },
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Icon(
                                        Icons.tune_rounded,
                                        size: 22.0.r,
                                        color: filterState.activeFiltersCount > 0
                                            ? AppColors.mintAccent
                                            : subtitleColor,
                                      ),
                                      if (filterState.activeFiltersCount > 0)
                                        Positioned(
                                          top: -3.0.r,
                                          right: -3.0.r,
                                          child: Container(
                                            padding: EdgeInsets.all(2.0.r),
                                            decoration: const BoxDecoration(
                                              color: Colors.redAccent,
                                              shape: BoxShape.circle,
                                            ),
                                            constraints: BoxConstraints(
                                              minWidth: 8.0.r,
                                              minHeight: 8.0.r,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 16.0.w),
                              ],
                              Icon(
                                Icons.grid_view_outlined,
                                size: 22.0.r,
                                color: subtitleColor,
                              ),
                            ],
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
                        child: isFolderList
                            ? ListView.separated(
                                padding: EdgeInsets.symmetric(horizontal: 24.0.w),
                                physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics(),
                                ),
                                itemCount: folders.length,
                                separatorBuilder: (context, index) => Divider(
                                  color: dividerColor,
                                  height: 1.0.h,
                                  thickness: 1.0.r,
                                ),
                                itemBuilder: (context, index) {
                                  final item = folders[index];
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
                                },
                              )
                            : (currentFileList.isEmpty
                                ? ListView(
                                    physics: const BouncingScrollPhysics(
                                      parent: AlwaysScrollableScrollPhysics(),
                                    ),
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(top: 80.0.h),
                                        child: Center(
                                          child: Text(
                                            'No matching files found.',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 14.0.sp,
                                              color: subtitleColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.symmetric(horizontal: 24.0.w),
                                    physics: const BouncingScrollPhysics(
                                      parent: AlwaysScrollableScrollPhysics(),
                                    ),
                                    itemCount: currentFileList.length,
                                    separatorBuilder: (context, index) => Divider(
                                      color: dividerColor,
                                      height: 1.0.h,
                                      thickness: 1.0.r,
                                    ),
                                    itemBuilder: (context, index) {
                                      final file = currentFileList[index];

                                      return GestureDetector(
                                        onTap: () {
                                          final detail = FileDetail(
                                            name: file.name,
                                            size: file.sizeString,
                                            createdDate: 'June 28, 2026, 12:14 PM',
                                            modifiedDate: '${file.modifiedDate.year}-${file.modifiedDate.month.toString().padLeft(2, '0')}-${file.modifiedDate.day.toString().padLeft(2, '0')}',
                                            type: file.category,
                                            themeColor: file.themeColor,
                                            fallbackIcon: file.fallbackIcon,
                                            fluxIcon: file.fluxIcon,
                                          );
                                          FileDetailSheet.show(context, detail);
                                        },
                                        behavior: HitTestBehavior.opaque,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(vertical: 12.0.h),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 44.0.r,
                                                height: 44.0.r,
                                                decoration: BoxDecoration(
                                                  color: file.themeColor.withValues(alpha: isDark ? 0.2 : 0.8),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: file.fluxIcon != null
                                                      ? FluxIcon(file.fluxIcon!, size: 22.0.r)
                                                      : Icon(
                                                          file.fallbackIcon,
                                                          size: 22.0.r,
                                                          color: file.themeColor,
                                                        ),
                                                ),
                                              ),
                                              SizedBox(width: 16.0.w),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      file.name,
                                                      style: TextStyle(
                                                        fontFamily: 'Inter',
                                                        fontSize: 16.0.sp,
                                                        fontWeight: FontWeight.w600,
                                                        color: textColor,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    SizedBox(height: 4.0.h),
                                                    Text(
                                                      '${file.sizeString} • ${file.location}',
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
                                              GestureDetector(
                                                onTap: () {
                                                  final detail = FileDetail(
                                                    name: file.name,
                                                    size: file.sizeString,
                                                    createdDate: 'June 28, 2026, 12:14 PM',
                                                    modifiedDate: '${file.modifiedDate.year}-${file.modifiedDate.month.toString().padLeft(2, '0')}-${file.modifiedDate.day.toString().padLeft(2, '0')}',
                                                    type: file.category,
                                                    themeColor: file.themeColor,
                                                    fallbackIcon: file.fallbackIcon,
                                                    fluxIcon: file.fluxIcon,
                                                  );
                                                  FileDetailSheet.show(context, detail);
                                                },
                                                behavior: HitTestBehavior.opaque,
                                                child: Padding(
                                                  padding: EdgeInsets.all(8.0.r),
                                                  child: Icon(
                                                    Icons.more_vert,
                                                    size: 20.0.r,
                                                    color: isDark ? Colors.white38 : Colors.black38,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  )),
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
