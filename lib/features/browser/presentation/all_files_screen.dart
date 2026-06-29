import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../core/providers/file_filter_provider.dart';
import '../../home/presentation/widgets/file_detail_sheet.dart';
import '../../search/presentation/widgets/quick_sort_filter_sheet.dart';
import '../../../core/widgets/flux_icon.dart';

class AllFilesScreen extends ConsumerStatefulWidget {
  const AllFilesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AllFilesScreen> createState() => _AllFilesScreenState();
}

class _AllFilesScreenState extends ConsumerState<AllFilesScreen> {
  bool _isSearching = false;
  String _searchQuery = '';
  String _searchScope = 'all'; // 'all', 'local', 'cloud'
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.pureBlack : AppColors.pureWhite;
    final textColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final subtitleColor = isDark
        ? AppColors.textSecondaryLight.withValues(alpha: 0.6)
        : AppColors.neutral400;
    final iconColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    // Watch the unified sorted and filtered mixed files list (including search query)
    final allFiles = ref.watch(filteredFilesProvider(_searchQuery));

    // Apply search scope
    final List<FluxFile> filesList;
    if (_searchScope == 'local') {
      filesList = allFiles.where((f) => f.location == 'Local').toList();
    } else if (_searchScope == 'cloud') {
      filesList = allFiles.where((f) => f.location == 'Cloud').toList();
    } else {
      filesList = allFiles;
    }

    final filterState = ref.watch(fileFilterProvider);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
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
                      padding: EdgeInsets.fromLTRB(
                        16.0.w,
                        16.0.h,
                        20.0.w,
                        8.0.h,
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isSearching = false;
                                _searchQuery = '';
                                _searchScope = 'all';
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
                      padding: EdgeInsets.fromLTRB(
                        16.0.w,
                        16.0.h,
                        20.0.w,
                        8.0.h,
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.pop(),
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
                            'All Files',
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
                                _searchScope = 'all';
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

            // macOS Finder style Scope Bar inside All Files Screen
            if (_isSearching)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 24.0.w,
                  vertical: 8.0.h,
                ),
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
                      label: 'All Files',
                      isActive: _searchScope == 'all',
                      onTap: () {
                        setState(() {
                          _searchScope = 'all';
                        });
                      },
                      isDark: isDark,
                      borderColor: dividerColor,
                    ),
                    SizedBox(width: 8.0.w),
                    _buildScopePill(
                      label: 'Local Only',
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
                      label: 'Cloud Only',
                      isActive: _searchScope == 'cloud',
                      onTap: () {
                        setState(() {
                          _searchScope = 'cloud';
                        });
                      },
                      isDark: isDark,
                      borderColor: dividerColor,
                    ),
                  ],
                ),
              ),
            SizedBox(height: 16.0.h),

            // Sorting/Filter Row
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 24.0.w,
                vertical: 8.0.h,
              ),
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
                  GestureDetector(
                    onTap: () {
                      QuickSortFilterSheet.show(context, hideFileType: false);
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
                ],
              ),
            ),
            SizedBox(height: 8.0.h),

            // Files List View
            Expanded(
              child: filesList.isEmpty
                  ? Center(
                      child: Text(
                        'No files found',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15.0.sp,
                          color: subtitleColor,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.0.w,
                        vertical: 12.0.h,
                      ),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filesList.length,
                      separatorBuilder: (context, index) => Divider(
                        color: dividerColor,
                        height: 1.0.h,
                        thickness: 1.0.r,
                      ),
                      itemBuilder: (context, index) {
                        final file = filesList[index];
                        return GestureDetector(
                          onTap: () {
                            final detail = FileDetail(
                              name: file.name,
                              size: file.sizeString,
                              createdDate: 'June 28, 2026, 12:14 PM',
                              modifiedDate:
                                  '${file.modifiedDate.year}-${file.modifiedDate.month.toString().padLeft(2, '0')}-${file.modifiedDate.day.toString().padLeft(2, '0')}',
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
                                    color: file.themeColor.withValues(
                                      alpha: isDark ? 0.2 : 0.8,
                                    ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                Icon(
                                  Icons.more_vert,
                                  size: 20.0.r,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
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
