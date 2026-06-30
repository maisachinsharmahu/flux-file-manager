import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';
import '../../home/presentation/home_screen.dart';
import '../../browser/presentation/browser_screen.dart';
import '../../analytics/presentation/analytics_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../trash/presentation/trash_screen.dart';
import '../../home/presentation/widgets/copy_progress_overlay.dart';
import 'widgets/navigation_drawer.dart';
import '../../../core/theme/app_colors.dart';

class MainNavigationShell extends ConsumerWidget {
  const MainNavigationShell({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeIndex = ref.watch(activeIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.pureBlack : AppColors.pureWhite;

    final List<Widget> screens = const [
      HomeScreen(),
      AnalyticsScreen(),
      SizedBox.shrink(), // Center Add placeholder
      BrowserScreen(),
      SettingsScreen(),
      TrashScreen(), // Index 5
    ];

    return PopScope(
      canPop: activeIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ref.read(activeIndexProvider.notifier).state = 0;
      },
      child: Scaffold(
        backgroundColor: bgColor,
        extendBody: true,
        drawer: const FluxNavigationDrawer(),
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
