import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../navigation/providers/navigation_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../home/providers/storage_status_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    // Simulate a network refresh delay
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      _controller.forward(from: 0.0);
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    final double kb = bytes / 1000.0;
    if (kb < 1.0) return '$bytes B';
    final double mb = kb / 1000.0;
    if (mb < 1.0) return '${kb.toStringAsFixed(1)} KB';
    final double gb = mb / 1000.0;
    if (gb < 1.0) return '${mb.toStringAsFixed(1)} MB';
    return '${gb.toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    // Detect visibility changes inside IndexedStack (AnalyticsScreen is at index 1)
    final isActive = ref.watch(activeIndexProvider) == 1;
    if (isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_controller.isAnimating && _controller.value == 0.0) {
          _controller.forward();
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.value > 0.0) {
          _controller.reset();
        }
      });
    }

    final storageAsync = ref.watch(storageStatusProvider);
    final storageData = storageAsync.maybeWhen(
      data: (data) => data,
      orElse: () => <String, dynamic>{},
    );

    final totalStorage = storageData['totalStorage'] as int? ?? 256 * 1000 * 1000 * 1000;
    final totalUsed = storageData['totalUsed'] as int? ?? 0;
    final photos = storageData['Photos'] as int? ?? 0;
    final videos = storageData['Videos'] as int? ?? 0;
    final audio = storageData['Audio'] as int? ?? 0;
    final docs = storageData['Documents'] as int? ?? 0;
    final apps = storageData['Application'] as int? ?? 0;
    final bin = storageData['Bin'] as int? ?? 0;
    final games = storageData['Games'] as int? ?? 0;
    final system = storageData['System'] as int? ?? 0;
    final others = storageData['Others'] as int? ?? 0;

    double getPercentage(int bytes) {
      if (totalStorage <= 0) return 0.0;
      return bytes / totalStorage;
    }

    final pPhotos = getPercentage(photos);
    final pVideos = getPercentage(videos);
    final pDocs = getPercentage(docs);
    final pAudio = getPercentage(audio);
    final pApps = getPercentage(apps);

    String getPctString(int bytes) {
      if (totalStorage <= 0) return '0%';
      final pct = (bytes / totalStorage * 100).toStringAsFixed(0);
      return '$pct%';
    }

    final usedPctString = totalStorage > 0 ? '${(totalUsed / totalStorage * 100).toStringAsFixed(0)}%' : '0%';

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

    // Define all 6 tabs in our static back-to-front stacking deck
    final List<_TabItemData> allTabs = [
      _TabItemData(
        name: 'Photos',
        child: _StackedFolderTab(
          title: 'Photos',
          icon: Icons.image,
          color: const Color(0xFFFFD020),
          isDark: isDark,
          sizeString: _formatSize(photos),
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
          sizeString: _formatSize(videos),
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
          sizeString: _formatSize(docs),
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
          sizeString: _formatSize(audio),
          onTap: () {
            ref.read(selectedAnalyticsCategoryProvider.notifier).state =
                'Audio';
            ref.read(selectedBrowserCategoryProvider.notifier).state = 'Audio';
            ref.read(activeIndexProvider.notifier).state = 3;
          },
        ),
      ),
      _TabItemData(
        name: 'Application',
        child: _StackedFolderTab(
          title: 'Application',
          icon: Icons.apps,
          color: const Color(0xFFFF4D4D),
          isDark: isDark,
          sizeString: _formatSize(apps),
          onTap: () {
            ref.read(selectedAnalyticsCategoryProvider.notifier).state =
                'Application';
            ref.read(selectedBrowserCategoryProvider.notifier).state =
                'Application';
            ref.read(activeIndexProvider.notifier).state = 3;
          },
        ),
      ),
      _TabItemData(
        name: 'Others',
        child: _StackedFolderTab(
          title: 'Others',
          icon: Icons.folder_open,
          color: const Color(0xFF9E9E9E),
          isDark: isDark,
          sizeString: _formatSize(others),
          onTap: () {
            ref.read(selectedAnalyticsCategoryProvider.notifier).state =
                'Others';
            ref.read(selectedBrowserCategoryProvider.notifier).state = 'Others';
            ref.read(activeIndexProvider.notifier).state = 3;
          },
        ),
      ),
    ];

    // Static back-to-front stacking order: lower folders overlap the upper ones, forming a clean tabbed deck.
    // Photos is at the back, followed by Videos, Documents, Audio, Application, and Others on top.
    final List<Widget> positionedWidgets = [];
    final List<double> topOffsets = [0, 52.0.h, 104.0.h, 156.0.h, 208.0.h, 260.0.h];

    for (int i = 0; i < allTabs.length; i++) {
      positionedWidgets.add(
        Positioned(
          top: topOffsets[i],
          left: 0,
          right: 0,
          child: allTabs[i].child,
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.mintAccent,
          backgroundColor: isDark ? AppColors.neutral900 : Colors.white,
          displacement: 20.h,
          onRefresh: _handleRefresh,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
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
                          // Top Info
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatSize(totalUsed),
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 24.0.sp,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                              SizedBox(height: 4.0.h),
                              Text(
                                'of ${_formatSize(totalStorage)} Used',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13.0.sp,
                                  fontWeight: FontWeight.w500,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24.0.h),

                          // Concentric Circular Progress Chart (now displaying 5 rings)
                          Center(
                            child: SizedBox(
                              width: 180.0.r,
                              height: 180.0.r,
                              child: CustomPaint(
                                painter: ConcentricRingsPainter(
                                  isDark: isDark,
                                  animation: _controller,
                                  percentages: [pPhotos, pVideos, pDocs, pAudio, pApps],
                                ),
                                child: Center(
                                  child: Text(
                                    usedPctString,
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

                          // Legend category details list (featuring all 6 storage types)
                          _buildLegendRow(
                            textColor,
                            subtitleColor,
                            borderColor,
                            'Images',
                            _formatSize(photos),
                            getPctString(photos),
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
                            _formatSize(videos),
                            getPctString(videos),
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
                            _formatSize(docs),
                            getPctString(docs),
                            const Color(0xFFA020F0),
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
                            'Audio',
                            _formatSize(audio),
                            getPctString(audio),
                            const Color(0xFFFF40A0),
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
                            'Apps',
                            _formatSize(apps),
                            getPctString(apps),
                            const Color(0xFFFF4D4D),
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
                            'Others',
                            _formatSize(others),
                            getPctString(others),
                            const Color(0xFF9E9E9E),
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

                    // Overlapping Stack (Height increased to 360.h to display 6 tabs)
                    SizedBox(
                      height: 360.0.h,
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

// Data holder classes
class _TabItemData {
  final String name;
  final Widget child;
  _TabItemData({required this.name, required this.child});
}

// Concentric Circular Rings custom painter (displaying 5 rings)
class ConcentricRingsPainter extends CustomPainter {
  final bool isDark;
  final Animation<double> animation;
  final List<double> percentages;

  ConcentricRingsPainter({
    required this.isDark,
    required this.animation,
    required this.percentages,
  }) : super(repaint: animation);

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

    // Radii of concentric circles (5 rings)
    final radii = [82.0.r, 70.0.r, 58.0.r, 46.0.r, 34.0.r];
    final colors = [
      const Color(0xFFFFD020), // Photos Yellow
      const Color(0xFFFF9010), // Videos Orange
      const Color(0xFFA020F0), // Docs Purple
      const Color(0xFFFF40A0), // Audio Pink
      const Color(0xFFFF4D4D), // Application Red
    ];

    final startAngles = [
      math.pi * 0.65,
      math.pi * 0.8,
      math.pi * 0.95,
      math.pi * 1.1,
      math.pi * 1.25,
    ];
    final sweepProgress = [
      percentages[0] * animation.value,
      percentages[1] * animation.value,
      percentages[2] * animation.value,
      percentages[3] * animation.value,
      percentages[4] * animation.value,
    ];

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0.r
      ..color = isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05);

    for (int i = 0; i < radii.length; i++) {
      final r = radii[i];
      canvas.drawCircle(center, r, trackPaint);

      final fillPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9.0.r
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
  bool shouldRepaint(covariant ConcentricRingsPainter oldDelegate) {
    return oldDelegate.animation.value != animation.value ||
        oldDelegate.isDark != isDark;
  }
}

// Overlapping folder shape tab widget
class _StackedFolderTab extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isDark;
  final String sizeString;
  final VoidCallback onTap;

  const _StackedFolderTab({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.sizeString,
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
              // Right side size text and chevron: Placed high up in the visible region
              Positioned(
                top: 18.0.h,
                right: 20.0.w,
                child: Row(
                  children: [
                    Text(
                      sizeString,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.0.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF171717).withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(width: 8.0.w),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: const Color(0xFF171717),
                      size: 13.0.r,
                    ),
                  ],
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
