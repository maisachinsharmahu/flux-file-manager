import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/widgets/flux_icon.dart';
import 'widgets/storage_bar.dart';
import 'widgets/quick_access_grid.dart';
import 'widgets/recents_list.dart';
import 'widgets/smart_cards_list.dart';
import 'widgets/all_storage_section.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/copy_task_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Key _storageBarKey = UniqueKey();

  Future<void> _handleRefresh() async {
    // Simulate a network refresh delay
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() {
        // Force StorageBar state reset so its entry capsule animation plays again
        _storageBarKey = UniqueKey();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent, // Let main navigation radial glow backdrop show through
      child: SafeArea(
        child: RefreshIndicator(
          color: AppColors.mintAccent,
          backgroundColor: isDark ? AppColors.neutral900 : Colors.white,
          displacement: 20.h,
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: EdgeInsets.only(
              bottom: 120.0.h,
            ), // Spacing to prevent overlay collisions
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HomeSearchBar(),
                StorageBar(key: _storageBarKey),
                const QuickAccessGrid(),
                const RecentsList(),
                const AllStorageSection(),
                const SmartCardsList(),
                SizedBox(height: 12.0.h),
                const _DevSimulationConsole(),
              ],
            ),
          ),
        ),
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
      padding: EdgeInsets.fromLTRB(24.0.w, 16.0.h, 24.0.w, 8.0.h),
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
                  padding: EdgeInsets.symmetric(horizontal: 14.0.w),
                  child: Row(
                    children: [
                      // Clickable Sidebar open Menu Icon on the Left
                      GestureDetector(
                        onTap: () {
                          Scaffold.of(context).openDrawer();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Icon(
                          Icons.menu_rounded,
                          color: iconColor,
                          size: 22.0.r,
                        ),
                      ),
                      SizedBox(width: 12.0.w),
                      // Search Label in the middle
                      Expanded(
                        child: Text(
                          'Search files, folders...',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15.0.sp,
                            color: iconColor,
                            decoration: TextDecoration.none,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // Search Icon on the Right
                      FluxIcon(
                        FluxIconType.searchOff,
                        color: iconColor,
                        size: 22.0.r,
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
              border: Border.all(color: borderColor, width: 1.2.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                            Icons.terminal,
                            size: 18.0.r,
                            color: isDark ? AppColors.mintAccent : Colors.teal,
                          ),
                          SizedBox(width: 8.0.w),
                          Text(
                            'Task Simulator Console',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14.0.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.pureWhite : AppColors.neutral900,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 20.0.r,
                        color: isDark ? AppColors.textSecondaryLight : AppColors.neutral400,
                      ),
                    ],
                  ),
                ),
                if (_isExpanded) ...[
                  SizedBox(height: 12.0.h),
                  const Divider(color: Colors.white12, height: 1),
                  SizedBox(height: 12.0.h),
                  _buildControlRow(
                    context,
                    title: 'Simulate Storage Transfer',
                    desc: 'Trigger background files copy',
                    buttonText: 'Trigger Copy',
                    color: isDark ? AppColors.mintAccent : Colors.teal,
                    onPressed: (ref) {
                      ref.read(copyTaskProvider.notifier).startMockTask(GlobalTaskType.copy);
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

  Widget _buildControlRow(
    BuildContext context, {
    required String title,
    required String desc,
    required String buttonText,
    required Color color,
    required void Function(WidgetRef) onPressed,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer(
      builder: (context, ref, child) {
        final copyState = ref.watch(copyTaskProvider);
        final bool isActive = copyState.isActive;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.0.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.pureWhite : AppColors.neutral900,
                    ),
                  ),
                  SizedBox(height: 2.0.h),
                  Text(
                    isActive
                        ? 'Transfer progress: ${(copyState.progress * 100).toInt()}%'
                        : desc,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.0.sp,
                      color: isDark ? AppColors.textSecondaryLight : AppColors.neutral400,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.0.w),
            GestureDetector(
              onTap: isActive ? null : () => onPressed(ref),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.0.w, vertical: 8.0.h),
                decoration: BoxDecoration(
                  color: isActive ? Colors.grey.withValues(alpha: 0.3) : color,
                  borderRadius: BorderRadius.circular(16.0.r),
                ),
                child: Text(
                  isActive ? 'In Progress' : buttonText,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.0.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
