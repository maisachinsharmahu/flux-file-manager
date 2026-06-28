import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../navigation/providers/navigation_provider.dart';
import '../../../../core/theme/app_colors.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Slide transition: Slide up from bottom (offset 0.25 on Y axis)
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Fade transition: Fade in from transparent to opaque
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = ref.watch(activeIndexProvider);

    // Safely trigger the slide-up animation after the build phase completes
    if (activeIndex == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_controller.isAnimating && _controller.value == 0.0) {
          _controller.forward();
        }
      });
    } else {
      // Reset the animation value when the screen is not active, so it is ready to slide up next time
      _controller.reset();
    }

    final selectedCategory = ref.watch(selectedAnalyticsCategoryProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.pureBlack : AppColors.pureWhite;
    final textColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final subtitleColor = isDark
        ? AppColors.textSecondaryLight.withValues(alpha: 0.6)
        : AppColors.neutral400;
    final cardBgColor = isDark
        ? AppColors.neutral900.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.6);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    // Define all 4 tabs with their names and Positions
    final List<_TabItemData> allTabs = [
      _TabItemData(
        name: 'Photos',
        child: _StackedFolderTab(
          title: 'Photos',
          icon: Icons.image,
          color: const Color(0xFFFFD020),
          isDark: isDark,
          onTap: () {
            ref.read(selectedAnalyticsCategoryProvider.notifier).state =
                'Photos';
            ref.read(selectedBrowserCategoryProvider.notifier).state = 'Photos';
            ref.read(activeIndexProvider.notifier).state = 3; // Go to browser
          },
        ),
      ),
      _TabItemData(
        name: 'Videos',
        child: _StackedFolderTab(
          title: 'Videos',
          icon: Icons.play_arrow,
          color: const Color(0xFFFF9010),
          isDark: isDark,
          onTap: () {
            ref.read(selectedAnalyticsCategoryProvider.notifier).state =
                'Videos';
            ref.read(selectedBrowserCategoryProvider.notifier).state = 'Videos';
            ref.read(activeIndexProvider.notifier).state = 3;
          },
        ),
      ),
      _TabItemData(
        name: 'Documents',
        child: _StackedFolderTab(
          title: 'Documents',
          icon: Icons.description_outlined,
          color: const Color(0xFFA020F0),
          isDark: isDark,
          onTap: () {
            ref.read(selectedAnalyticsCategoryProvider.notifier).state =
                'Documents';
            ref.read(selectedBrowserCategoryProvider.notifier).state =
                'Documents';
            ref.read(activeIndexProvider.notifier).state = 3;
          },
        ),
      ),
      _TabItemData(
        name: 'Audio',
        child: _StackedFolderTab(
          title: 'Audio',
          icon: Icons.music_note,
          color: const Color(0xFFFF40A0),
          isDark: isDark,
          onTap: () {
            ref.read(selectedAnalyticsCategoryProvider.notifier).state =
                'Audio';
            ref.read(selectedBrowserCategoryProvider.notifier).state = 'Audio';
            ref.read(activeIndexProvider.notifier).state = 3;
          },
        ),
      ),
    ];

    // Reorder: Render the selected tab last in the children list of Stack so it is painted on top!
    // Non-selected tabs will keep their normal stacking positions, but the selected tab rises to the front.
    final List<Widget> positionedWidgets = [];

    // We want to map static visual offsets: top positions should still be indices: 0, 1, 2, 3
    // Photos: top: 0
    // Videos: top: 52.h
    // Documents: top: 104.h
    // Audio: top: 156.h
    final List<double> topOffsets = [0, 52.0.h, 104.0.h, 156.0.h];

    // Map each tab to its original visual index
    final List<_TabWithOffset> tabsWithOffsets = [];
    for (int i = 0; i < allTabs.length; i++) {
      tabsWithOffsets.add(
        _TabWithOffset(
          name: allTabs[i].name,
          topOffset: topOffsets[i],
          child: allTabs[i].child,
        ),
      );
    }

    // Sort: any tab whose name matches selectedCategory goes to the end of the list (so it paints last and overlaps others)
    tabsWithOffsets.sort((a, b) {
      if (a.name == selectedCategory) return 1;
      if (b.name == selectedCategory) return -1;
      return 0; // maintain relative layout
    });

    for (final item in tabsWithOffsets) {
      positionedWidgets.add(
        Positioned(top: item.topOffset, left: 0, right: 0, child: item.child),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: 24.0.w,
                vertical: 16.0.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          ref.read(activeIndexProvider.notifier).state =
                              0; // Back to Home
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.0.r),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 20.0.r,
                            color: textColor,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.0.w),
                      Text(
                        'My Storage',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24.0.sp,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.0.h),

                  // Concentric Donut Analytics Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.0.r),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(24.0.r),
                      border: Border.all(color: borderColor, width: 1.2.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '48 GB',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 24.0.sp,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                                SizedBox(height: 4.0.h),
                                Text(
                                  'of 120 GB Used',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13.0.sp,
                                    fontWeight: FontWeight.w500,
                                    color: subtitleColor,
                                  ),
                                ),
                              ],
                            ),
                            // Upgrade Button
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.0.w,
                                vertical: 8.0.h,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.neutral900,
                                borderRadius: BorderRadius.circular(20.0.r),
                              ),
                              child: Text(
                                'Upgrade Plan',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.0.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.black : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24.0.h),

                        // Concentric Circular Progress Chart
                        Center(
                          child: SizedBox(
                            width: 180.0.r,
                            height: 180.0.r,
                            child: CustomPaint(
                              painter: ConcentricRingsPainter(isDark: isDark),
                              child: Center(
                                child: Text(
                                  '86%',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 26.0.sp,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24.0.h),

                        // Legend category details
                        _buildLegendRow(
                          textColor,
                          subtitleColor,
                          borderColor,
                          'Images',
                          '601 MB',
                          '28%',
                          const Color(0xFFFFD020),
                        ),
                        Divider(
                          color: borderColor,
                          height: 24.0.h,
                          thickness: 1.0.r,
                        ),
                        _buildLegendRow(
                          textColor,
                          subtitleColor,
                          borderColor,
                          'Videos',
                          '123 MB',
                          '15%',
                          const Color(0xFFFF9010),
                        ),
                        Divider(
                          color: borderColor,
                          height: 24.0.h,
                          thickness: 1.0.r,
                        ),
                        _buildLegendRow(
                          textColor,
                          subtitleColor,
                          borderColor,
                          'Docs',
                          '674 MB',
                          '32%',
                          const Color(0xFFA020F0),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.0.h),

                  // Categories Header
                  Text(
                    'Categories',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18.0.sp,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 16.0.h),

                  // Overlapping Stack with dynamic painter index sorting
                  SizedBox(
                    height: 260.0.h,
                    width: double.infinity,
                    child: Stack(children: positionedWidgets),
                  ),
                  SizedBox(height: 20.0.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendRow(
    Color textColor,
    Color subtitleColor,
    Color borderColor,
    String title,
    String size,
    String percent,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 4.0.w,
          height: 24.0.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.0.r),
          ),
        ),
        SizedBox(width: 12.0.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15.0.sp,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              SizedBox(height: 2.0.h),
              Text(
                size,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.0.sp,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ),
        Text(
          percent,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15.0.sp,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

// Data holder classes for dynamic reordering
class _TabItemData {
  final String name;
  final Widget child;
  _TabItemData({required this.name, required this.child});
}

class _TabWithOffset {
  final String name;
  final double topOffset;
  final Widget child;
  _TabWithOffset({
    required this.name,
    required this.topOffset,
    required this.child,
  });
}

// Concentric Circular Rings custom painter
class ConcentricRingsPainter extends CustomPainter {
  final bool isDark;

  ConcentricRingsPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Tiny deterministic starry background matching mockup
    final rand = math.Random(42);
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 40; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height;
      starPaint.color = Colors.white.withValues(
        alpha: rand.nextDouble() * 0.25,
      );
      canvas.drawCircle(Offset(x, y), rand.nextDouble() * 1.5, starPaint);
    }

    // Radii of concentric circles
    final radii = [76.0.r, 62.0.r, 48.0.r];
    final colors = [
      const Color(0xFFFFD020),
      const Color(0xFFFF9010),
      const Color(0xFFA020F0),
    ];

    final startAngles = [math.pi * 0.65, math.pi * 0.8, math.pi * 0.95];
    final sweepProgress = [0.72, 0.45, 0.65];

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0.r
      ..color = isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05);

    for (int i = 0; i < radii.length; i++) {
      final r = radii[i];
      canvas.drawCircle(center, r, trackPaint);

      final fillPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10.0.r
        ..strokeCap = StrokeCap.round
        ..color = colors[i];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        startAngles[i],
        sweepProgress[i] * 2 * math.pi,
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Overlapping folder shape tab widget
class _StackedFolderTab extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _StackedFolderTab({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipPath(
        clipper: FolderTabClipper(),
        child: Container(
          width: double.infinity,
          height: 100.0.h,
          color: color,
          child: Stack(
            children: [
              // Left side circle icon and title: Placed high up in the Tab area (visible region)
              Positioned(
                top: 6.0.h,
                left: 20.0.w,
                child: Row(
                  children: [
                    Container(
                      width: 38.0.r,
                      height: 38.0.r,
                      decoration: const BoxDecoration(
                        color: Color(0xFF171717),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(icon, color: color, size: 20.0.r),
                      ),
                    ),
                    SizedBox(width: 14.0.w),
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16.0.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF171717),
                      ),
                    ),
                  ],
                ),
              ),
              // Right side outward diagonal arrow: Placed lower in the body area below the tab curve
              Positioned(
                top: 28.0.h,
                right: 20.0.w,
                child: Container(
                  width: 38.0.r,
                  height: 38.0.r,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_outward,
                      color: const Color(0xFF171717),
                      size: 20.0.r,
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
}

// Custom Clipper path for rounded overlapping horizontal folder shapes
class FolderTabClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final tabW = size.width * 0.42;
    const slopeW = 60.0;
    const tabH = 22.0;
    const r = 16.0; // Rounded corners radius matching mockup exactly

    // Start at left edge, below top-left corner
    path.moveTo(0, r);

    // Round top-left corner of the tab
    path.quadraticBezierTo(0, 0, r, 0);

    // Line to start of tab flat top edge
    path.lineTo(tabW - r, 0);

    // Round tab outer corner down into the slope transition
    path.quadraticBezierTo(tabW, 0, tabW + 8, 4);

    // S-curve slope down to the folder body top edge
    path.cubicTo(
      tabW + slopeW * 0.4,
      4,
      tabW + slopeW * 0.1,
      tabH,
      tabW + slopeW,
      tabH,
    );

    // Line to top-right corner of body (before corner curve)
    path.lineTo(size.width - r, tabH);

    // Round top-right corner of the folder body
    path.quadraticBezierTo(size.width, tabH, size.width, tabH + r);

    // Line to bottom-right corner of body (before corner curve)
    path.lineTo(size.width, size.height - r);

    // Round bottom-right corner of the folder body
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - r,
      size.height,
    );

    // Line to bottom-left corner of body (before corner curve)
    path.lineTo(r, size.height);

    // Round bottom-left corner of the folder body
    path.quadraticBezierTo(0, size.height, 0, size.height - r);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
