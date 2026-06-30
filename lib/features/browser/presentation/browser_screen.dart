import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../navigation/providers/navigation_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../home/presentation/widgets/file_detail_sheet.dart';
import '../../../core/providers/file_filter_provider.dart';
import '../../search/presentation/widgets/quick_sort_filter_sheet.dart';
import '../../../core/widgets/flux_icon.dart';
import '../../../core/widgets/file_type_icon.dart';

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

  bool _isSearching = false;
  String _searchQuery = '';
  String _searchScope = 'local'; // 'local' or 'global'
  final TextEditingController _searchController = TextEditingController();

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
    _searchController.dispose();
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
      {'name': 'Alarms', 'items': 1, 'size': '1 KB', 'heart': false, 'date': DateTime.now().subtract(const Duration(days: 10))},
      {'name': 'Android', 'items': 6, 'size': '12 MB', 'heart': false, 'date': DateTime.now().subtract(const Duration(days: 1))},
      {'name': 'Backups', 'items': 1, 'size': '821 MB', 'heart': false, 'date': DateTime.now().subtract(const Duration(days: 15))},
      {'name': 'Browser', 'items': 3, 'size': '204 KB', 'heart': false, 'date': DateTime.now().subtract(const Duration(days: 3))},
      {'name': 'Canva', 'items': 23, 'size': '98 MB', 'heart': true, 'date': DateTime.now().subtract(const Duration(hours: 4))},
      {'name': 'DCIM', 'items': 3, 'size': '18.4 GB', 'heart': false, 'date': DateTime.now().subtract(const Duration(days: 20))},
      {'name': 'Documents', 'items': 6, 'size': '2.4 GB', 'heart': false, 'date': DateTime.now().subtract(const Duration(days: 30))},
      {'name': 'Download', 'items': 5, 'size': '4.6 GB', 'heart': true, 'date': DateTime.now().subtract(const Duration(hours: 1))},
      {'name': 'Notifications', 'items': 1, 'size': '4 KB', 'heart': false, 'date': DateTime.now().subtract(const Duration(days: 8))},
    ];

    final filterState = ref.watch(fileFilterProvider);

    // Sort folders dynamically if sorting parameters are active
    double parseSizeToMb(String sizeStr) {
      final parts = sizeStr.split(' ');
      if (parts.length < 2) return 0.0;
      final val = double.tryParse(parts[0]) ?? 0.0;
      final unit = parts[1].toUpperCase();
      if (unit == 'KB') return val / 1024.0;
      if (unit == 'GB') return val * 1024.0;
      return val;
    }

    folders.sort((a, b) {
      if (filterState.nameSort != 'Off') {
        final isDesc = filterState.nameSort == 'Descending';
        final comp = (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase());
        return isDesc ? -comp : comp;
      }
      if (filterState.dateSort != 'Off') {
        final isDesc = filterState.dateSort == 'Descending';
        final comp = (a['date'] as DateTime).compareTo(b['date'] as DateTime);
        return isDesc ? -comp : comp;
      }
      if (filterState.sizeSort != 'Off') {
        final isDesc = filterState.sizeSort == 'Descending';
        final sizeA = parseSizeToMb(a['size'] as String);
        final sizeB = parseSizeToMb(b['size'] as String);
        final comp = sizeA.compareTo(sizeB);
        return isDesc ? -comp : comp;
      }
      return 0;
    });
    
    // Resolve dynamic list based on whether category view is active
    bool isFolderList = activeCategory == null;
    final String pageTitle = activeCategory ?? 'Internal Storage';
    List<FluxFile> currentFileList = [];

    if (_isSearching && _searchScope == 'global') {
      isFolderList = false;
      currentFileList = ref.watch(filteredFilesProvider(_searchQuery));
    } else {
      if (!isFolderList) {
        final allFiltered = ref.watch(filteredFilesProvider(_isSearching ? _searchQuery : ''));
        currentFileList = allFiltered.where((file) => file.category == activeCategory).toList();
      } else {
        if (_isSearching && _searchQuery.isNotEmpty) {
          final lowerQuery = _searchQuery.toLowerCase();
          folders.removeWhere((folder) => !(folder['name'] as String).toLowerCase().contains(lowerQuery));
        }
      }
    }

    return PopScope(
      canPop: activeCategory == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final source = ref.read(categoryNavigationSourceProvider);
        ref.read(selectedBrowserCategoryProvider.notifier).state = null;
        ref.read(activeIndexProvider.notifier).state = source;
      },
      child: Scaffold(
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
                      // Header Row with Animated Switcher for Search Mode
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, -0.2),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: _isSearching
                            ? Padding(
                                key: const ValueKey('searchHeader'),
                                padding: EdgeInsets.fromLTRB(16.0.w, 16.0.h, 20.0.w, 8.0.h),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isSearching = false;
                                          _searchQuery = '';
                                          _searchController.clear();
                                        });
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
                                    Expanded(
                                      child: Container(
                                        height: 40.0.h,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.05)
                                              : Colors.black.withValues(alpha: 0.03),
                                          borderRadius: BorderRadius.circular(20.0.r),
                                        ),
                                        padding: EdgeInsets.symmetric(horizontal: 16.0.w),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.search,
                                              size: 18.0.r,
                                              color: subtitleColor,
                                            ),
                                            SizedBox(width: 8.0.w),
                                            Expanded(
                                              child: TextField(
                                                controller: _searchController,
                                                autofocus: true,
                                                onChanged: (val) {
                                                  setState(() {
                                                    _searchQuery = val;
                                                  });
                                                },
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 14.0.sp,
                                                  color: textColor,
                                                ),
                                                decoration: InputDecoration(
                                                  hintText: 'Search...',
                                                  hintStyle: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 14.0.sp,
                                                    color: subtitleColor,
                                                  ),
                                                  border: InputBorder.none,
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.zero,
                                                ),
                                              ),
                                            ),
                                            if (_searchQuery.isNotEmpty)
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _searchQuery = '';
                                                    _searchController.clear();
                                                  });
                                                },
                                                child: Icon(
                                                  Icons.close_rounded,
                                                  size: 18.0.r,
                                                  color: subtitleColor,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Padding(
                                key: const ValueKey('normalHeader'),
                                padding: EdgeInsets.fromLTRB(16.0.w, 16.0.h, 20.0.w, 8.0.h),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (activeCategory != null) {
                                          final source = ref.read(categoryNavigationSourceProvider);
                                          ref.read(selectedBrowserCategoryProvider.notifier).state = null;
                                          ref.read(activeIndexProvider.notifier).state = source;
                                        } else {
                                          ref.read(activeIndexProvider.notifier).state = 0;
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
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isSearching = true;
                                        _searchScope = 'local';
                                      });
                                    },
                                    child: Icon(
                                      Icons.search,
                                      size: 26.0.r,
                                      color: iconColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),

                    // macOS Finder style Search Scope Bar
                    if (_isSearching)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 8.0.h),
                        child: Row(
                          children: [
                            Text(
                              'Search: ',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13.0.sp,
                                fontWeight: FontWeight.w600,
                                color: subtitleColor,
                              ),
                            ),
                            SizedBox(width: 8.0.w),
                            _buildScopePill(
                              label: pageTitle,
                              isActive: _searchScope == 'local',
                              onTap: () {
                                setState(() {
                                  _searchScope = 'local';
                                });
                              },
                              isDark: isDark,
                              borderColor: dividerColor,
                            ),
                            SizedBox(width: 8.0.w),
                            _buildScopePill(
                              label: 'All Files',
                              isActive: _searchScope == 'global',
                              onTap: () {
                                setState(() {
                                  _searchScope = 'global';
                                });
                              },
                              isDark: isDark,
                              borderColor: dividerColor,
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
                                GestureDetector(
                                  onTap: () {
                                    QuickSortFilterSheet.show(context, hideFileType: true);
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
                                              FileTypeIcon(
                                                extension: file.fileExtension,
                                                path: file.path,
                                                size: 44.0.r,
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
    ),);
  }
  Widget _buildScopePill({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
    required Color borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.0.w, vertical: 6.0.h),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.mintAccent
              : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.02)),
          borderRadius: BorderRadius.circular(16.0.r),
          border: Border.all(
            color: isActive ? AppColors.mintAccent : borderColor,
            width: 1.0.r,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.0.sp,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive
                ? Colors.black
                : (isDark ? AppColors.pureWhite : AppColors.neutral900),
          ),
        ),
      ),
    );
  }
}
