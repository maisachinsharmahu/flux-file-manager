import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/achromatic_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/search/presentation/search_screen.dart';
import 'features/browser/presentation/all_files_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/analytics/presentation/analytics_screen.dart';
import 'features/browser/presentation/browser_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/trash/presentation/trash_screen.dart';
import 'features/trash/presentation/junk_cleaner_screen.dart';
import 'features/trash/presentation/duplicates_pruner_screen.dart';
import 'features/navigation/presentation/main_navigation_shell.dart';
import 'features/home/presentation/widgets/copy_progress_overlay.dart';

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (BuildContext context, GoRouterState state) {
        return const OnboardingScreen();
      },
    ),
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const MainNavigationShell();
      },
    ),
    GoRoute(
      path: '/search',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: const SearchScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/all_files',
      builder: (BuildContext context, GoRouterState state) {
        final title = state.uri.queryParameters['title'] ?? 'All Files';
        final category = state.uri.queryParameters['category'];
        return AllFilesScreen(title: title, category: category);
      },
    ),
    GoRoute(
      path: '/analytics',
      builder: (BuildContext context, GoRouterState state) {
        return const AnalyticsScreen();
      },
    ),
    GoRoute(
      path: '/browser',
      builder: (BuildContext context, GoRouterState state) {
        return const BrowserScreen();
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) {
        return const SettingsScreen();
      },
    ),
    GoRoute(
      path: '/trash',
      builder: (BuildContext context, GoRouterState state) {
        return const TrashScreen();
      },
    ),
    GoRoute(
      path: '/cleaner',
      builder: (BuildContext context, GoRouterState state) {
        return const JunkCleanerScreen();
      },
    ),
    GoRoute(
      path: '/duplicates',
      builder: (BuildContext context, GoRouterState state) {
        return const DuplicatesPrunerScreen();
      },
    ),
  ],
);

class FluxApp extends ConsumerWidget {
  const FluxApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return ScreenUtilInit(
      designSize: const Size(
        412,
        892,
      ), // Android QHD flagship device viewport (e.g. 1440x3120 physical)
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'FLUX',
          theme: FluxTheme.light,
          darkTheme: FluxTheme.dark,
          themeMode: themeMode,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return Stack(
              children: [if (child != null) child, const CopyProgressOverlay()],
            );
          },
        );
      },
    );
  }
}
