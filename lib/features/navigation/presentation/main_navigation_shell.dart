import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/widgets/flux_icon.dart';
import '../providers/navigation_provider.dart';
import '../../home/presentation/home_screen.dart';
import '../../browser/presentation/browser_screen.dart';
import '../../analytics/presentation/analytics_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../home/presentation/widgets/copy_progress_overlay.dart';

import '../../../core/theme/app_colors.dart';

class MainNavigationShell extends ConsumerWidget {
  const MainNavigationShell({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeIndex = ref.watch(activeIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> screens = const [
      HomeScreen(),
      AnalyticsScreen(),
      SizedBox.shrink(), // Center Add button actions
      BrowserScreen(),
      SettingsScreen(),
    ];

    // Colors mapping based on Dark/Light mode matching the screenshots exactly
    final barColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.15);

    final bgGradient = isDark
        ? const RadialGradient(
            center: Alignment(0.0, -1.2),
            radius: 1.4,
            colors: [
              AppColors.indigoHaze,
              AppColors.pureBlack,
            ],
          )
        : const RadialGradient(
            center: Alignment(0.0, -1.2),
            radius: 1.4,
            colors: [
              AppColors.lightHaze,
              AppColors.pureWhite,
            ],
          );

    return Container(
      decoration: BoxDecoration(
        gradient: bgGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: Stack(
          children: [
            IndexedStack(index: activeIndex, children: screens),
            const CopyProgressOverlay(),
          ],
        ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.0.w, 0.0, 24.0.w, 16.0.h),
          child: Container(
            height: 68.0.h,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(34.0.r),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 16.0.r,
                  offset: Offset(0, 8.h),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavBarItem(
                  fluxIcon: FluxIconType.homeOn,
                  fluxOutlinedIcon: FluxIconType.homeOff,
                  isActive: activeIndex == 0,
                  onTap: () => ref.read(activeIndexProvider.notifier).state = 0,
                ),
                _NavBarItem(
                  fluxIcon: FluxIconType.storageOn,
                  fluxOutlinedIcon: FluxIconType.storageOn, // Keep consistent
                  isActive: activeIndex == 1,
                  onTap: () => ref.read(activeIndexProvider.notifier).state = 1,
                ),
                _NavBarCenterAdd(
                  onTap: () {
                    // Quick add files sheet trigger
                  },
                ),
                _NavBarItem(
                  fluxIcon: FluxIconType.folderOn,
                  fluxOutlinedIcon: FluxIconType.folderOff,
                  isActive: activeIndex == 3,
                  onTap: () => ref.read(activeIndexProvider.notifier).state = 3,
                ),
                _NavBarItem(
                  fallbackIcon: Icons.person,
                  fallbackOutlinedIcon: Icons.person_outline,
                  isActive: activeIndex == 4,
                  onTap: () => ref.read(activeIndexProvider.notifier).state = 4,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}

class _NavBarItem extends StatelessWidget {
  final FluxIconType? fluxIcon;
  final FluxIconType? fluxOutlinedIcon;
  final IconData? fallbackIcon;
  final IconData? fallbackOutlinedIcon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    Key? key,
    this.fluxIcon,
    this.fluxOutlinedIcon,
    this.fallbackIcon,
    this.fallbackOutlinedIcon,
    required this.isActive,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Item colors mapping based on screenshots (No Blue Tint)
    final activeBgColor = isDark
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);
    final activeIconColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF171717);
    final inactiveBgColor = isDark
        ? const Color(0xFFF5F5F5)
        : Colors.transparent;
    final inactiveIconColor = isDark
        ? const Color(0xFFA3A3A3)
        : const Color(0xFFA3A3A3);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48.0.w,
        height: 48.0.h,
        decoration: BoxDecoration(
          color: isActive ? activeBgColor : inactiveBgColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: fluxIcon != null
              ? FluxIcon(
                  isActive ? fluxIcon! : fluxOutlinedIcon!,
                  size: 24.0.r,
                  color: isActive ? activeIconColor : inactiveIconColor,
                )
              : Icon(
                  isActive ? fallbackIcon : fallbackOutlinedIcon,
                  color: isActive ? activeIconColor : inactiveIconColor,
                  size: 24.0.r,
                ),
        ),
      ),
    );
  }
}

class _NavBarCenterAdd extends StatelessWidget {
  final VoidCallback onTap;

  const _NavBarCenterAdd({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFFF5F5F5) : const Color(0xFF262626);
    final iconColor = isDark ? const Color(0xFF000000) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48.0.w,
        height: 48.0.h,
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Center(
          child: FluxIcon(
            FluxIconType.plusMathOff,
            size: 24.0.r,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
