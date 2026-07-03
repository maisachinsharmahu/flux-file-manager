import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/presentation/home_screen.dart';
import '../../home/presentation/widgets/copy_progress_overlay.dart';
import 'widgets/navigation_drawer.dart';
import '../../../core/theme/app_colors.dart';

class MainNavigationShell extends ConsumerWidget {
  const MainNavigationShell({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.pureBlack : AppColors.pureWhite;

    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
      drawer: const FluxNavigationDrawer(),
      body: const HomeScreen(),
    );
  }
}
