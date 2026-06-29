import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/file_filter_provider.dart';
import 'advanced_filter_sheet.dart';

class QuickSortFilterSheet extends ConsumerWidget {
  const QuickSortFilterSheet({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      isScrollControlled: true,
      builder: (context) => const QuickSortFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final titleColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final labelColor = isDark ? Colors.white70 : AppColors.neutral700;

    // Dynamically labels for Order based on active SortBy
    String ascLabel = 'Ascending';
    String descLabel = 'Descending';
    if (filterState.sortBy == 'Size') {
      ascLabel = 'Low to High';
      descLabel = 'High to Low';
    } else if (filterState.sortBy == 'Date') {
      ascLabel = 'Oldest First';
      descLabel = 'Newest First';
    } else if (filterState.sortBy == 'Name') {
      ascLabel = 'A to Z';
      descLabel = 'Z to A';
    }

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32.0.r)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
        child: Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.0.r)),
            border: Border(
              top: BorderSide(color: borderColor, width: 1.5.r),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            24.0.w,
            12.0.h,
            24.0.w,
            MediaQuery.of(context).padding.bottom + 24.0.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grab Handle
              Center(
                child: Container(
                  width: 48.0.w,
                  height: 4.5.h,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2.5.r),
                  ),
                ),
              ),
              SizedBox(height: 18.0.h),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sort & Filter',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18.0.sp,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      // Open Advanced Sheet
                      AdvancedFilterSheet.show(context);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Advanced',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.0.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mintAccent,
                          ),
                        ),
                        SizedBox(width: 4.0.w),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11.0.r,
                          color: AppColors.mintAccent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.0.h),

              // 1. Sort By Section
              Text(
                'SORT BY',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.0.sp,
                  fontWeight: FontWeight.w800,
                  color: labelColor,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 12.0.h),
              Row(
                children: ['Name', 'Date', 'Size'].map((sort) {
                  final isSelected = filterState.sortBy == sort;
                  return Padding(
                    padding: EdgeInsets.only(right: 10.0.w),
                    child: _buildChoiceChip(
                      label: sort,
                      isSelected: isSelected,
                      onTap: () => filterNotifier.setSortBy(sort),
                      isDark: isDark,
                      borderColor: borderColor,
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 24.0.h),

              // 2. Order Section
              Text(
                'ORDER',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.0.sp,
                  fontWeight: FontWeight.w800,
                  color: labelColor,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 12.0.h),
              Row(
                children: [
                  _buildChoiceChip(
                    label: descLabel,
                    isSelected: filterState.isDescending,
                    onTap: () => filterNotifier.setIsDescending(true),
                    isDark: isDark,
                    borderColor: borderColor,
                  ),
                  SizedBox(width: 10.0.w),
                  _buildChoiceChip(
                    label: ascLabel,
                    isSelected: !filterState.isDescending,
                    onTap: () => filterNotifier.setIsDescending(false),
                    isDark: isDark,
                    borderColor: borderColor,
                  ),
                ],
              ),
              SizedBox(height: 24.0.h),

              // 3. Quick Time Filter Section
              Text(
                'QUICK TIME FILTER',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.0.sp,
                  fontWeight: FontWeight.w800,
                  color: labelColor,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 12.0.h),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: ['All', 'Today', 'This Week', 'This Month'].map((
                    time,
                  ) {
                    final isSelected = filterState.dateRange == time;
                    return Padding(
                      padding: EdgeInsets.only(right: 10.0.w),
                      child: _buildChoiceChip(
                        label: time,
                        isSelected: isSelected,
                        onTap: () => filterNotifier.setDateRange(time),
                        isDark: isDark,
                        borderColor: borderColor,
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 32.0.h),

              // Apply Button
              GestureDetector(
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
                      'Apply Sort & Filter',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 10.0.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.mintAccent
              : (isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.02)),
          borderRadius: BorderRadius.circular(20.0.r),
          border: Border.all(
            color: isSelected ? AppColors.mintAccent : borderColor,
            width: 1.0.r,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.0.sp,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.black
                : (isDark ? AppColors.pureWhite : AppColors.neutral900),
          ),
        ),
      ),
    );
  }
}
