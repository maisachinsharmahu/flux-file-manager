import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../navigation/providers/navigation_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../home/providers/storage_status_provider.dart';
import '../../../../core/providers/file_filter_provider.dart';

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
  
  // Stacking deck tracking variables
  int _activeIndex = 5; // Start with the top tab (Others) active.
  final Map<String, double> _dragOffsets = {};
  final Map<String, double> _baseOffsets = {};

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

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    // Perform a real file index scan/refresh in the background
    await ref.read(allFilesProvider.notifier).initAndLoad(force: true);
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
    final pBin = getPercentage(bin);
    final pGames = getPercentage(games);
    final pSystem = getPercentage(system);

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

    // Define all 9 tabs in our static back-to-front stacking deck
    final List<_TabItemData> allTabs = [
      _TabItemData(
        name: 'Photos',
        child: _StackedFolderTab(
          title: 'Photos',
          icon: Icons.image,
          color: const Color(0xFF38BDF8),
          isDark: isDark,
          sizeString: _formatSize(photos),
          onTap: () {
            context.push('/all_files?title=Photos&category=Photos');
          },
        ),
      ),
      _TabItemData(
        name: 'Videos',
        child: _StackedFolderTab(
          title: 'Videos',
          icon: Icons.play_arrow,
          color: const Color(0xFF10B981),
          isDark: isDark,
          sizeString: _formatSize(videos),
          onTap: () {
            context.push('/all_files?title=Videos&category=Videos');
          },
        ),
      ),
      _TabItemData(
        name: 'Documents',
        child: _StackedFolderTab(
          title: 'Documents',
          icon: Icons.description_outlined,
          color: const Color(0xFFFBBF24),
          isDark: isDark,
          sizeString: _formatSize(docs),
          onTap: () {
            context.push('/all_files?title=Documents&category=Documents');
          },
        ),
      ),
      _TabItemData(
        name: 'Audio',
        child: _StackedFolderTab(
          title: 'Audio',
          icon: Icons.music_note,
          color: const Color(0xFFF97316),
          isDark: isDark,
          sizeString: _formatSize(audio),
          onTap: () {
            context.push('/all_files?title=Audio&category=Audio');
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
            context.push('/all_files?title=Application&category=Application');
          },
        ),
      ),
      _TabItemData(
        name: 'Bin',
        child: _StackedFolderTab(
          title: 'Bin',
          icon: Icons.delete_outline,
          color: const Color(0xFF607D8B),
          isDark: isDark,
          sizeString: _formatSize(bin),
          onTap: () {
            context.push('/all_files?title=Bin&category=Bin');
          },
        ),
      ),
      _TabItemData(
        name: 'Games',
        child: _StackedFolderTab(
          title: 'Games',
          icon: Icons.sports_esports_outlined,
          color: const Color(0xFF4CAF50),
          isDark: isDark,
          sizeString: _formatSize(games),
          onTap: () {
            context.push('/all_files?title=Games&category=Games');
          },
        ),
      ),
      _TabItemData(
        name: 'System',
        child: _StackedFolderTab(
          title: 'System',
          icon: Icons.settings_system_daydream_outlined,
          color: const Color(0xFF9C27B0),
          isDark: isDark,
          sizeString: _formatSize(system),
          onTap: () {
            context.push('/all_files?title=System&category=System');
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
            context.push('/all_files?title=Others&category=Others');
          },
        ),
      ),
    ];

    // Static back-to-front stacking order: lower folders overlap the upper ones, forming a clean tabbed deck.
    final List<Widget> positionedWidgets = [];
    final List<double> topOffsets = List.generate(allTabs.length, (i) => i * 52.0.h);

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

                            // Custom Donut Progress Chart
                           Center(
                            child: SizedBox(
                              width: 180.0.r,
                              height: 180.0.r,
                              child: CustomPaint(
                                painter: StorageDonutPainter(
                                  isDark: isDark,
                                  animation: _controller,
                                  values: [
                                    photos.toDouble(),
                                    videos.toDouble(),
                                    docs.toDouble(),
                                    audio.toDouble(),
                                    apps.toDouble(),
                                    bin.toDouble(),
                                    games.toDouble(),
                                    system.toDouble(),
                                    others.toDouble(),
                                  ],
                                  colors: const [
                                    Color(0xFF38BDF8), // Images
                                    Color(0xFF10B981), // Videos
                                    Color(0xFFFBBF24), // Docs
                                    Color(0xFFF97316), // Audio
                                    Color(0xFFFF4D4D), // Application
                                    Color(0xFF607D8B), // Bin
                                    Color(0xFF4CAF50), // Games
                                    Color(0xFF9C27B0), // System
                                    Color(0xFF9E9E9E), // Others
                                  ],
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
                          SizedBox(height: 28.0.h),

                          // Legend category details grid (featuring all 9 storage types)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildLegendRow(textColor, subtitleColor, borderColor, 'Images', _formatSize(photos), getPctString(photos), const Color(0xFF38BDF8)),
                                    SizedBox(height: 16.0.h),
                                    _buildLegendRow(textColor, subtitleColor, borderColor, 'Docs', _formatSize(docs), getPctString(docs), const Color(0xFFFBBF24)),
                                    SizedBox(height: 16.0.h),
                                    _buildLegendRow(textColor, subtitleColor, borderColor, 'Apps', _formatSize(apps), getPctString(apps), const Color(0xFFFF4D4D)),
                                    SizedBox(height: 16.0.h),
                                    _buildLegendRow(textColor, subtitleColor, borderColor, 'Games', _formatSize(games), getPctString(games), const Color(0xFF4CAF50)),
                                    SizedBox(height: 16.0.h),
                                    _buildLegendRow(textColor, subtitleColor, borderColor, 'Others', _formatSize(others), getPctString(others), const Color(0xFF9E9E9E)),
                                  ],
                                ),
                              ),
                              SizedBox(width: 20.0.w),
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildLegendRow(textColor, subtitleColor, borderColor, 'Videos', _formatSize(videos), getPctString(videos), const Color(0xFF10B981)),
                                    SizedBox(height: 16.0.h),
                                    _buildLegendRow(textColor, subtitleColor, borderColor, 'Audio', _formatSize(audio), getPctString(audio), const Color(0xFFF97316)),
                                    SizedBox(height: 16.0.h),
                                    _buildLegendRow(textColor, subtitleColor, borderColor, 'Bin', _formatSize(bin), getPctString(bin), const Color(0xFF607D8B)),
                                    SizedBox(height: 16.0.h),
                                    _buildLegendRow(textColor, subtitleColor, borderColor, 'System', _formatSize(system), getPctString(system), const Color(0xFF9C27B0)),
                                  ],
                                ),
                              ),
                            ],
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

                    // Overlapping Stack (Height increased to 520.h to display all 9 tabs)
                    SizedBox(
                      height: 520.0.h,
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
class StorageDonutPainter extends CustomPainter {
  final bool isDark;
  final Animation<double> animation;
  final List<double> values;
  final List<Color> colors;

  StorageDonutPainter({
    required this.isDark,
    required this.animation,
    required this.values,
    required this.colors,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10.0.r;

    // Draw background track ring
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0.r
      ..color = isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05);
    canvas.drawCircle(center, radius, trackPaint);

    // Sum total values
    final total = values.fold<double>(0, (sum, val) => sum + val);
    if (total <= 0) return;

    // Calculate segments with a minimum visible angle (to prevent small parts from disappearing)
    final double minAngle = 0.14; // in radians (~8 degrees)
    final double gapAngle = 0.035; // in radians (~2 degrees) between segments
    
    // Find active segments
    int activeCount = 0;
    for (var val in values) {
      if (val > 0) activeCount++;
    }

    if (activeCount == 0) return;

    // Total gaps angle
    final double totalGaps = activeCount * gapAngle;
    final double availableAngle = 2 * math.pi - totalGaps;

    // Compute min angles sum
    final double minAnglesSum = activeCount * minAngle;

    List<double> segmentAngles = List.filled(values.length, 0.0);

    if (minAnglesSum >= availableAngle) {
      // If we have too many segments, just distribute equally
      final double equalAngle = availableAngle / activeCount;
      for (int i = 0; i < values.length; i++) {
        if (values[i] > 0) segmentAngles[i] = equalAngle;
      }
    } else {
      // Allocate minimum angles first, then distribute the remaining angle proportionally
      final double remainingAngle = availableAngle - minAnglesSum;
      double remainingValuesSum = 0.0;
      for (var val in values) {
        if (val > 0) remainingValuesSum += val;
      }

      for (int i = 0; i < values.length; i++) {
        if (values[i] > 0) {
          final double proportionalShare = (values[i] / remainingValuesSum) * remainingAngle;
          segmentAngles[i] = minAngle + proportionalShare;
        }
      }
    }

    // Draw the segments with animations
    double startAngle = -math.pi / 2; // Start from top (12 o'clock)

    for (int i = 0; i < values.length; i++) {
      if (segmentAngles[i] <= 0) continue;

      final sweepAngle = segmentAngles[i] * animation.value;

      final fillPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14.0.r
        ..strokeCap = StrokeCap.round
        ..color = colors[i];

      // Draw active arc segment
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + (gapAngle / 2),
        sweepAngle - gapAngle,
        false,
        fillPaint,
      );

      startAngle += segmentAngles[i];
    }
  }

  @override
  bool shouldRepaint(covariant StorageDonutPainter oldDelegate) {
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
