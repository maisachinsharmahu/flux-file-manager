import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/widgets/flux_icon.dart';
import 'widgets/storage_bar.dart';
import 'widgets/quick_access_grid.dart';
import 'widgets/recents_list.dart';
import 'widgets/smart_cards_list.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/copy_task_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors
          .transparent, // Let main navigation radial glow backdrop show through
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: 120.0.h,
          ), // Spacing to prevent overlay collisions
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HomeHeader(),
              const _HomeSearchBar(),
              const StorageBar(),
              const QuickAccessGrid(),
              const RecentsList(),
              const SmartCardsList(),
              SizedBox(height: 12.0.h),
              const _DevSimulationConsole(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final titleColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final subtitleColor = isDark
        ? AppColors.textSecondaryLight
        : AppColors.neutral400;

    return Padding(
      padding: EdgeInsets.fromLTRB(24.0.w, 16.0.h, 24.0.w, 16.0.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi Sachin',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.0.sp,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                  ),
                ),
                SizedBox(height: 4.0.h),
                Text(
                  'Manage All Your Documents',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20.0.sp,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 12.0.w),
          Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                Scaffold.of(
                  context,
                ).openDrawer(); // Tapping Profile Avatar opens Sidebar Drawer!
              },
              child: Container(
                width: 44.0.w,
                height: 44.0.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.mintAccent, Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.mintAccent.withValues(alpha: 0.3),
                      blurRadius: 8.r,
                      spreadRadius: 1.r,
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(2.0.r),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.neutral900,
                    ),
                    child: Center(
                      child: Text(
                        'S',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16.0.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.mintAccent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSearchBar extends StatelessWidget {
  const _HomeSearchBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final iconColor = isDark
        ? AppColors.textSecondaryLight
        : AppColors.neutral400;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 8.0.h),
      child: GestureDetector(
        onTap: () {
          context.push('/search');
        },
        child: Hero(
          tag: 'search_bar_hero',
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26.0.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                child: Container(
                  height: 52.0.h,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(26.0.r),
                    border: Border.all(color: borderColor, width: 1.5.r),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 18.0.w),
                  child: Row(
                    children: [
                      FluxIcon(
                        FluxIconType.searchOff,
                        color: iconColor,
                        size: 22.0.r,
                      ),
                      SizedBox(width: 12.0.w),
                      Text(
                        'Search files, folders...',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15.0.sp,
                          color: iconColor,
                          decoration: TextDecoration.none,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DevSimulationConsole extends StatefulWidget {
  const _DevSimulationConsole({Key? key}) : super(key: key);

  @override
  State<_DevSimulationConsole> createState() => _DevSimulationConsoleState();
}

class _DevSimulationConsoleState extends State<_DevSimulationConsole> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBgColor = isDark
        ? AppColors.neutral900.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.6);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 16.0.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 12.0.h),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(20.0.r),
              border: Border.all(color: borderColor, width: 1.0.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.developer_mode,
                            size: 16.0.r,
                            color: AppColors.mintAccent,
                          ),
                          SizedBox(width: 8.0.w),
                          Text(
                            'Task Simulator Console',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.0.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.pureWhite
                                  : AppColors.neutral900,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 16.0.r,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ],
                  ),
                ),
                if (_isExpanded) ...[
                  SizedBox(height: 12.0.h),
                  Consumer(
                    builder: (context, ref, child) {
                      return Wrap(
                        spacing: 8.0.w,
                        runSpacing: 8.0.h,
                        alignment: WrapAlignment.start,
                        children: [
                          _buildTaskPill(
                            ref,
                            'Copy',
                            GlobalTaskType.copy,
                            AppColors.mintAccent,
                          ),
                          _buildTaskPill(
                            ref,
                            'Delete',
                            GlobalTaskType.delete,
                            AppColors.errorRed,
                          ),
                          _buildTaskPill(
                            ref,
                            'Move',
                            GlobalTaskType.move,
                            const Color(0xFF8B5CF6),
                          ),
                          _buildTaskPill(
                            ref,
                            'Archive',
                            GlobalTaskType.archive,
                            const Color(0xFFF59E0B),
                          ),
                          _buildTaskPill(
                            ref,
                            'Unarchive',
                            GlobalTaskType.unarchive,
                            const Color(0xFF14B8A6),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskPill(
    WidgetRef ref,
    String label,
    GlobalTaskType type,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(copyTaskProvider.notifier).startMockTask(type);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.0.w, vertical: 6.0.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12.0.r),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.0.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sync_alt, size: 12.0.r, color: color),
            SizedBox(width: 4.0.w),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.0.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
