import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      SizedBox.shrink(), // Center Add placeholder
      BrowserScreen(),
      SettingsScreen(),
    ];

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
      ),
    );
  }
}
