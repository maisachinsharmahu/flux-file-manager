import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/file_filter_provider.dart';

class AdvancedFilterSheet extends ConsumerStatefulWidget {
  const AdvancedFilterSheet({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      isScrollControlled: true,
      builder: (context) => const AdvancedFilterSheet(),
    );
  }

  @override
  ConsumerState<AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends ConsumerState<AdvancedFilterSheet> {
  int _activeCategoryIndex = 0;

  final List<String> _categories = [
    'File Type',
    'Size',
    'Time',
    'Location',
    'Advanced',
    'Sort By',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filterState = ref.watch(fileFilterProvider);
    final filterNotifier = ref.read(fileFilterProvider.notifier);

    final sheetBg = isDark
        ? AppColors.neutral900.withValues(alpha: 0.95)
        : Colors.white.withValues(alpha: 0.98);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final sidebarBg = isDark
        ? Colors.white.withValues(alpha: 0.02)
        : Colors.black.withValues(alpha: 0.01);
    final titleColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final activeItemColor = isDark ? Colors.white : AppColors.neutral900;
    final inactiveItemColor = isDark ? Colors.white30 : Colors.black38;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32.0.r)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.0.r)),
            border: Border(
              top: BorderSide(color: borderColor, width: 1.5.r),
            ),
          ),
          child: Column(
            children: [
              // Grab Handle
              SizedBox(height: 12.0.h),
              Container(
                width: 48.0.w,
                height: 4.5.h,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2.5.r),
                ),
              ),
              SizedBox(height: 16.0.h),

              // Title Row
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Advanced Filters',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18.0.sp,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    if (filterState.activeFiltersCount > 0)
                      GestureDetector(
                        onTap: () {
                          filterNotifier.reset();
                        },
                        child: Text(
                          'Reset All',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.0.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 16.0.h),
              Divider(color: borderColor, height: 1.0.h, thickness: 1.0.r),

              // Sidebar + Sub-filters body
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Column Sidebar
                    Container(
                      width: 120.0.w,
                      decoration: BoxDecoration(
                        color: sidebarBg,
                        border: Border(
                          right: BorderSide(color: borderColor, width: 1.0.r),
                        ),
                      ),
                      child: ListView.builder(
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final isSelected = _activeCategoryIndex == index;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _activeCategoryIndex = index;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.0.w,
                                vertical: 16.0.h,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark
                                        ? Colors.white.withValues(alpha: 0.04)
                                        : Colors.black.withValues(alpha: 0.02))
                                    : Colors.transparent,
                                border: Border(
                                  left: BorderSide(
                                    color: isSelected
                                        ? AppColors.mintAccent
                                        : Colors.transparent,
                                    width: 3.0.w,
                                  ),
                                ),
                              ),
                              child: Text(
                                _categories[index],
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13.0.sp,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? activeItemColor
                                      : inactiveItemColor,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Right Column Sub-filters list
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(20.0.r),
                        child: _buildSubFilters(
                          filterState,
                          filterNotifier,
                          isDark,
                          borderColor,
                          activeItemColor,
                          inactiveItemColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: borderColor, height: 1.0.h, thickness: 1.0.r),

              // Bottom Apply Button
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24.0.w,
                  16.0.h,
                  24.0.w,
                  MediaQuery.of(context).padding.bottom + 16.0.h,
                ),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    height: 48.0.h,
                    decoration: BoxDecoration(
                      color: AppColors.mintAccent,
                      borderRadius: BorderRadius.circular(24.0.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.mintAccent.withValues(alpha: 0.2),
                          blurRadius: 16.r,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        filterState.activeFiltersCount > 0
                            ? 'Apply (${filterState.activeFiltersCount} Filters)'
                            : 'Apply Filters',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14.0.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubFilters(
    FileFilterState state,
    FileFilterNotifier notifier,
    bool isDark,
    Color borderColor,
    Color activeItemColor,
    Color inactiveItemColor,
  ) {
    switch (_activeCategoryIndex) {
      case 0: // File Type (Multi-select)
        final categories = [
          'Photos',
          'Videos',
          'Documents',
          'Audio',
          'Application',
          'Others'
        ];
        return SingleChildScrollView(
          child: Wrap(
            spacing: 8.0.w,
            runSpacing: 10.0.h,
            children: categories.map((cat) {
              final isSelected = state.categories.contains(cat);
              return GestureDetector(
                onTap: () => notifier.toggleCategory(cat),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.0.w,
                    vertical: 8.0.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.mintAccent
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.02)),
                    borderRadius: BorderRadius.circular(20.0.r),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.mintAccent
                          : borderColor,
                      width: 1.0.r,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.0.sp,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.black : activeItemColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      case 1: // Size Options
        final options = [
          'All',
          'Small (<1MB)',
          'Medium (1-10MB)',
          'Large (10-100MB)',
          'Huge (>100MB)'
        ];
        return _buildRadioList(
          options,
          state.sizeRange,
          notifier.setSizeRange,
          isDark,
          borderColor,
        );
      case 2: // Time Options
        final options = ['All', 'Today', 'This Week', 'This Month', 'Older'];
        return _buildRadioList(
          options,
          state.dateRange,
          notifier.setDateRange,
          isDark,
          borderColor,
        );
      case 3: // Location Options
        final options = ['All', 'Local', 'Cloud', 'SD Card'];
        return _buildRadioList(
          options,
          state.location,
          notifier.setLocation,
          isDark,
          borderColor,
        );
      case 4: // Advanced Options
        return Column(
          children: [
            _buildSwitchTile(
              'Show Vault Files Only',
              'Filter files inside the password secure vault',
              state.showVaultOnly,
              notifier.toggleVault,
              isDark,
            ),
            SizedBox(height: 12.0.h),
            _buildSwitchTile(
              'Show Duplicate Files',
              'Display duplicate items on local storage',
              state.showDuplicatesOnly,
              notifier.toggleDuplicates,
              isDark,
            ),
          ],
        );
      case 5: // Sort By Options
        final options = ['Name', 'Date', 'Size'];
        return _buildRadioList(
          options,
          state.sortBy,
          notifier.setSortBy,
          isDark,
          borderColor,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRadioList(
    List<String> options,
    String currentValue,
    Function(String) onChanged,
    bool isDark,
    Color borderColor,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: options.length,
      separatorBuilder: (context, index) => SizedBox(height: 8.0.h),
      itemBuilder: (context, index) {
        final opt = options[index];
        final isSelected = currentValue == opt;
        return GestureDetector(
          onTap: () => onChanged(opt),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.0.w, vertical: 10.0.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.mintAccent.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16.0.r),
              border: Border.all(
                color: isSelected ? AppColors.mintAccent : borderColor,
                width: 1.0.r,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  opt,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.0.sp,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isDark ? AppColors.pureWhite : AppColors.neutral900,
                  ),
                ),
                Container(
                  width: 16.0.r,
                  height: 16.0.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.mintAccent : Colors.grey,
                      width: 2.0.r,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 8.0.r,
                            height: 8.0.r,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.mintAccent,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    bool isDark,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.0.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.pureWhite : AppColors.neutral900,
                ),
              ),
              SizedBox(height: 2.0.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.0.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.mintAccent,
          activeTrackColor: AppColors.mintAccent.withValues(alpha: 0.2),
        ),
      ],
    );
  }
}
