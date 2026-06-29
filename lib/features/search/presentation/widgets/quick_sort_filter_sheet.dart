import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/file_filter_provider.dart';
import 'advanced_filter_sheet.dart';

class QuickSortFilterSheet extends ConsumerWidget {
  final bool hideFileType;
  const QuickSortFilterSheet({Key? key, this.hideFileType = false})
    : super(key: key);

  static void show(BuildContext context, {bool hideFileType = false}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      isScrollControlled: true,
      builder: (context) => QuickSortFilterSheet(hideFileType: hideFileType),
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

    final nameActive = filterState.nameSort != 'Off';
    final dateActive = filterState.dateSort != 'Off';
    final sizeActive = filterState.sizeSort != 'Off';

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
                      AdvancedFilterSheet.show(
                        context,
                        hideFileType: hideFileType,
                      );
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

              // Sort By selection buttons
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
                children: [
                  _buildChoiceChip(
                    label: 'Name',
                    isSelected: nameActive,
                    onTap: () => filterNotifier.setNameSort(
                      nameActive ? 'Off' : 'Ascending',
                    ),
                    isDark: isDark,
                    borderColor: borderColor,
                  ),
                  SizedBox(width: 10.0.w),
                  _buildChoiceChip(
                    label: 'Date',
                    isSelected: dateActive,
                    onTap: () => filterNotifier.setDateSort(
                      dateActive ? 'Off' : 'Descending',
                    ),
                    isDark: isDark,
                    borderColor: borderColor,
                  ),
                  SizedBox(width: 10.0.w),
                  _buildChoiceChip(
                    label: 'Size',
                    isSelected: sizeActive,
                    onTap: () => filterNotifier.setSizeSort(
                      sizeActive ? 'Off' : 'Descending',
                    ),
                    isDark: isDark,
                    borderColor: borderColor,
                  ),
                ],
              ),

              // Animated expansion of order sub-options
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (nameActive) ...[
                      SizedBox(height: 20.0.h),
                      Text(
                        'NAME ORDER',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.0.sp,
                          fontWeight: FontWeight.w800,
                          color: labelColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 10.0.h),
                      Row(
                        children: [
                          _buildChoiceChip(
                            label: 'A to Z',
                            isSelected: filterState.nameSort == 'Ascending',
                            onTap: () =>
                                filterNotifier.setNameSort('Ascending'),
                            isDark: isDark,
                            borderColor: borderColor,
                          ),
                          SizedBox(width: 10.0.w),
                          _buildChoiceChip(
                            label: 'Z to A',
                            isSelected: filterState.nameSort == 'Descending',
                            onTap: () =>
                                filterNotifier.setNameSort('Descending'),
                            isDark: isDark,
                            borderColor: borderColor,
                          ),
                        ],
                      ),
                    ],
                    if (dateActive) ...[
                      SizedBox(height: 20.0.h),
                      Text(
                        'DATE ORDER',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.0.sp,
                          fontWeight: FontWeight.w800,
                          color: labelColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 10.0.h),
                      Row(
                        children: [
                          _buildChoiceChip(
                            label: 'Newest First',
                            isSelected: filterState.dateSort == 'Descending',
                            onTap: () =>
                                filterNotifier.setDateSort('Descending'),
                            isDark: isDark,
                            borderColor: borderColor,
                          ),
                          SizedBox(width: 10.0.w),
                          _buildChoiceChip(
                            label: 'Oldest First',
                            isSelected: filterState.dateSort == 'Ascending',
                            onTap: () =>
                                filterNotifier.setDateSort('Ascending'),
                            isDark: isDark,
                            borderColor: borderColor,
                          ),
                        ],
                      ),
                    ],
                    if (sizeActive) ...[
                      SizedBox(height: 20.0.h),
                      Text(
                        'SIZE ORDER',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.0.sp,
                          fontWeight: FontWeight.w800,
                          color: labelColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 10.0.h),
                      Row(
                        children: [
                          _buildChoiceChip(
                            label: 'High to Low',
                            isSelected: filterState.sizeSort == 'Descending',
                            onTap: () =>
                                filterNotifier.setSizeSort('Descending'),
                            isDark: isDark,
                            borderColor: borderColor,
                          ),
                          SizedBox(width: 10.0.w),
                          _buildChoiceChip(
                            label: 'Low to High',
                            isSelected: filterState.sizeSort == 'Ascending',
                            onTap: () =>
                                filterNotifier.setSizeSort('Ascending'),
                            isDark: isDark,
                            borderColor: borderColor,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 24.0.h),

              // 4. Quick Time Filter Section
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
