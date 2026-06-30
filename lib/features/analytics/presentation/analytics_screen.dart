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
  int _selectedIndex = -1;
  bool _isGridView = true;

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
      if (bytes <= 0) return '0%';
      if (totalStorage <= 0) return '0%';
      final double pctValue = (bytes / totalStorage * 100);
      if (pctValue < 1.0) {
        return '< 1%';
      }
      final pct = pctValue.toStringAsFixed(0);
      return '$pct%';
    }

    final usedPctString = totalStorage > 0 ? '${(totalUsed / totalStorage * 100).toStringAsFixed(0)}%' : '0%';

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final values = [
      photos.toDouble(),
      videos.toDouble(),
      docs.toDouble(),
      audio.toDouble(),
      apps.toDouble(),
      bin.toDouble(),
      games.toDouble(),
      system.toDouble(),
      others.toDouble(),
      (totalStorage - totalUsed).toDouble(), // Free Space
    ];

    final colors = [
      const Color(0xFF38BDF8), // Images
      const Color(0xFF10B981), // Videos
      const Color(0xFFFBBF24), // Docs
      const Color(0xFFF97316), // Audio
      const Color(0xFFFF4D4D), // Application
      const Color(0xFF607D8B), // Bin
      const Color(0xFF4CAF50), // Games
      const Color(0xFF9C27B0), // System
      const Color(0xFF9E9E9E), // Others
      isDark
          ? Colors.white.withValues(alpha: 0.15)
          : Colors.black.withValues(alpha: 0.08), // Free Space
    ];

    const segmentNames = [
      'Images',
      'Videos',
      'Docs',
      'Audio',
      'Apps',
      'Bin',
      'Games',
      'System',
      'Others',
      'Free Space',
    ];

    // Compute segment angles for tap collision checking and CustomPainter layout consistency
    final double minAngle = 0.14; // in radians (~8 degrees)
    final double gapAngle = 0.035; // in radians (~2 degrees) between segments
    
    int activeCount = 0;
    for (var val in values) {
      if (val > 0) activeCount++;
    }
    
    final double totalGaps = activeCount * gapAngle;
    final double availableAngle = 2 * math.pi - totalGaps;
    final double minAnglesSum = activeCount * minAngle;
    
    List<double> segmentAngles = List.filled(values.length, 0.0);
    if (activeCount > 0) {
      if (minAnglesSum >= availableAngle) {
        final double equalAngle = availableAngle / activeCount;
        for (int i = 0; i < values.length; i++) {
          if (values[i] > 0) segmentAngles[i] = equalAngle;
        }
      } else {
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
    }

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

    // Define all 9 categories for the modern grid layout
    final List<Map<String, dynamic>> categoryCardsData = [
      {
        'title': 'Photos',
        'icon': Icons.image_outlined,
        'color': const Color(0xFF38BDF8),
        'size': _formatSize(photos),
        'percentage': getPctString(photos),
        'ratio': getPercentage(photos),
        'route': '/all_files?title=Photos&category=Photos',
      },
      {
        'title': 'Videos',
        'icon': Icons.play_circle_outline,
        'color': const Color(0xFF10B981),
        'size': _formatSize(videos),
        'percentage': getPctString(videos),
        'ratio': getPercentage(videos),
        'route': '/all_files?title=Videos&category=Videos',
      },
      {
        'title': 'Docs',
        'icon': Icons.description_outlined,
        'color': const Color(0xFFFBBF24),
        'size': _formatSize(docs),
        'percentage': getPctString(docs),
        'ratio': getPercentage(docs),
        'route': '/all_files?title=Documents&category=Documents',
      },
      {
        'title': 'Audio',
        'icon': Icons.music_note_outlined,
        'color': const Color(0xFFF97316),
        'size': _formatSize(audio),
        'percentage': getPctString(audio),
        'ratio': getPercentage(audio),
        'route': '/all_files?title=Audio&category=Audio',
      },
      {
        'title': 'Application',
        'icon': Icons.apps_outlined,
        'color': const Color(0xFFFF4D4D),
        'size': _formatSize(apps),
        'percentage': getPctString(apps),
        'ratio': getPercentage(apps),
        'route': '/all_files?title=Application&category=Application',
      },
      {
        'title': 'Bin',
        'icon': Icons.delete_outline_rounded,
        'color': const Color(0xFF607D8B),
        'size': _formatSize(bin),
        'percentage': getPctString(bin),
        'ratio': getPercentage(bin),
        'route': '/all_files?title=Bin&category=Bin',
      },
      {
        'title': 'Games',
        'icon': Icons.sports_esports_outlined,
        'color': const Color(0xFF4CAF50),
        'size': _formatSize(games),
        'percentage': getPctString(games),
        'ratio': getPercentage(games),
        'route': '/all_files?title=Games&category=Games',
      },
      {
        'title': 'System',
        'icon': Icons.settings_system_daydream_outlined,
        'color': const Color(0xFF9C27B0),
        'size': _formatSize(system),
        'percentage': getPctString(system),
        'ratio': getPercentage(system),
        'route': '/all_files?title=System&category=System',
      },
      {
        'title': 'Others',
        'icon': Icons.folder_open_outlined,
        'color': const Color(0xFF9E9E9E),
        'size': _formatSize(others),
        'percentage': getPctString(others),
        'ratio': getPercentage(others),
        'route': '/all_files?title=Others&category=Others',
      },
    ];

    // Compute overlapping positioned tabs only when Stack View is active to save resources
    final List<Widget> positionedWidgets = [];
    if (!_isGridView) {
      final List<double> topOffsets = List.generate(categoryCardsData.length, (i) => i * 52.0.h);
      for (int i = 0; i < categoryCardsData.length; i++) {
        final data = categoryCardsData[i];
        
        // Convert outlined icons to standard filled icons for folder tabs styling
        IconData stackedIcon = data['icon'] as IconData;
        if (stackedIcon == Icons.image_outlined) stackedIcon = Icons.image;
        if (stackedIcon == Icons.play_circle_outline) stackedIcon = Icons.play_arrow;
        if (stackedIcon == Icons.description_outlined) stackedIcon = Icons.description;
        if (stackedIcon == Icons.music_note_outlined) stackedIcon = Icons.music_note;
        if (stackedIcon == Icons.apps_outlined) stackedIcon = Icons.apps;
        if (stackedIcon == Icons.delete_outline_rounded) stackedIcon = Icons.delete_outline;
        if (stackedIcon == Icons.folder_open_outlined) stackedIcon = Icons.folder_open;

        positionedWidgets.add(
          Positioned(
            top: topOffsets[i],
            left: 0,
            right: 0,
            child: _StackedFolderTab(
              title: data['title'] as String,
              icon: stackedIcon,
              color: data['color'] as Color,
              isDark: isDark,
              sizeString: data['size'] as String,
              onTap: () {
                context.push(data['route'] as String);
              },
            ),
          ),
        );
      }
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
                              child: GestureDetector(
                                onTapUp: (details) {
                                  // Local position of touch
                                  final double width = 180.0.r;
                                  final center = Offset(width / 2, width / 2);
                                  final touchPosition = details.localPosition;
                                  final dx = touchPosition.dx - center.dx;
                                  final dy = touchPosition.dy - center.dy;
                                  
                                  // Distance from center
                                  final distance = math.sqrt(dx * dx + dy * dy);
                                  
                                  // Donut base radius
                                  final baseRadius = width / 2 - 10.0.r;
                                  final innerRadius = baseRadius - 16.0.r;
                                  final outerRadius = baseRadius + 16.0.r;
                                  
                                  if (distance >= innerRadius && distance <= outerRadius) {
                                    // Touch is on the donut ring
                                    double angle = math.atan2(dy, dx);
                                    double normalizedAngle = angle + math.pi / 2;
                                    if (normalizedAngle < 0) {
                                      normalizedAngle += 2 * math.pi;
                                    }
                                    
                                    // Match against segmentAngles
                                    double currentSum = 0.0;
                                    int tappedIndex = -1;
                                    for (int i = 0; i < segmentAngles.length; i++) {
                                      final start = currentSum;
                                      final end = currentSum + segmentAngles[i];
                                      if (normalizedAngle >= start && normalizedAngle <= end) {
                                        tappedIndex = i;
                                        break;
                                      }
                                      currentSum += segmentAngles[i];
                                    }
                                    
                                    if (tappedIndex != -1) {
                                      setState(() {
                                        if (_selectedIndex == tappedIndex) {
                                          _selectedIndex = -1; // Toggle off
                                        } else {
                                          _selectedIndex = tappedIndex;
                                        }
                                      });
                                    }
                                  } else {
                                    // Tapped inside the hole or outside the donut ring
                                    setState(() {
                                      _selectedIndex = -1;
                                    });
                                  }
                                },
                                child: CustomPaint(
                                  painter: StorageDonutPainter(
                                    isDark: isDark,
                                    animation: _controller,
                                    values: values,
                                    colors: colors,
                                    segmentAngles: segmentAngles,
                                    selectedIndex: _selectedIndex,
                                  ),
                                  child: Center(
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 250),
                                      transitionBuilder: (child, animation) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: ScaleTransition(
                                            scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: _selectedIndex != -1
                                          ? Column(
                                              key: ValueKey<int>(_selectedIndex),
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  segmentNames[_selectedIndex],
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 12.0.sp,
                                                    fontWeight: FontWeight.w700,
                                                    color: colors[_selectedIndex],
                                                  ),
                                                ),
                                                SizedBox(height: 2.0.h),
                                                Text(
                                                  _formatSize(values[_selectedIndex].toInt()),
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 18.0.sp,
                                                    fontWeight: FontWeight.w800,
                                                    color: textColor,
                                                  ),
                                                ),
                                                SizedBox(height: 2.0.h),
                                                Text(
                                                  _selectedIndex == 9
                                                      ? '${((totalStorage - totalUsed) / totalStorage * 100).toStringAsFixed(0)}%'
                                                      : getPctString(values[_selectedIndex].toInt()),
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 11.0.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color: subtitleColor,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Column(
                                              key: const ValueKey<int>(-1),
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  usedPctString,
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 26.0.sp,
                                                    fontWeight: FontWeight.w800,
                                                    color: textColor,
                                                  ),
                                                ),
                                                Text(
                                                  'Used',
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
                                    _buildLegendRow(textColor, subtitleColor, borderColor, 'Images', _formatSize(photos), getPctString(photos), const Color(0xFF38BDF8), 0),
                                    SizedBox(height: 16.0.h),
                                    _buildLegendRow(textColor, subtitleColor, borderColor, 'Docs', _formatSize(docs), getPctString(docs), const Color(0xFFFBBF24), 2),
                                    SizedBox(height: 16.0.h),
                                    _buildLegendRow(textColor, subtitleColor, borderColor, 'Apps', _formatSize(apps), getPctString(apps), const Color(0xFFFF4D4D), 4),
                                    SizedBox(height: 16.0.h),
                                    _buildLegendRow(textColor, subtitleColor, borderColor, 'Games', _formatSize(games), getPctString(games), const Color(0xFF4CAF50), 6),
                                    SizedBox(height: 16.0.h),
                                    _buildLegendRow(textColor, subtitleColor, borderColor, 'Others', _formatSize(others), getPctString(others), const Color(0xFF9E9E9E), 8),
                                  ],
                                ),
                              ),
                              SizedBox(width: 20.0.w),
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildLegendRow(textColor, subtitleColor, borderColor, 'Videos', _formatSize(videos), getPctString(videos), const Color(0xFF10B981), 1),
                                    SizedBox(height: 16.0.h),
                                    _buildLegendRow(textColor, subtitleColor, borderColor, 'Audio', _formatSize(audio), getPctString(audio), const Color(0xFFF97316), 3),
                                    SizedBox(height: 16.0.h),
                                    _buildLegendRow(textColor, subtitleColor, borderColor, 'Bin', _formatSize(bin), getPctString(bin), const Color(0xFF607D8B), 5),
                                    SizedBox(height: 16.0.h),
                                    _buildLegendRow(textColor, subtitleColor, borderColor, 'System', _formatSize(system), getPctString(system), const Color(0xFF9C27B0), 7),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.0.h),

                    // Categories Header Row with Toggle Switch on the right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Categories',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18.0.sp,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        // Layout Selection Toggle
                        Container(
                          padding: EdgeInsets.all(2.0.r),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(10.0.r),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                              width: 1.0.r,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isGridView = true;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10.0.w, vertical: 6.0.h),
                                  decoration: BoxDecoration(
                                    color: _isGridView 
                                        ? (isDark ? AppColors.neutral800 : Colors.white) 
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8.0.r),
                                    boxShadow: _isGridView ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 4.r,
                                        offset: const Offset(0, 2),
                                      )
                                    ] : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.grid_view_rounded,
                                        size: 14.0.r,
                                        color: _isGridView 
                                            ? AppColors.mintAccent 
                                            : subtitleColor.withValues(alpha: 0.6),
                                      ),
                                      if (_isGridView) ...[
                                        SizedBox(width: 4.0.w),
                                        Text(
                                          'Grid',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 11.0.sp,
                                            fontWeight: FontWeight.w700,
                                            color: textColor,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isGridView = false;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10.0.w, vertical: 6.0.h),
                                  decoration: BoxDecoration(
                                    color: !_isGridView 
                                        ? (isDark ? AppColors.neutral800 : Colors.white) 
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8.0.r),
                                    boxShadow: !_isGridView ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 4.r,
                                        offset: const Offset(0, 2),
                                      )
                                    ] : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.layers_outlined,
                                        size: 14.0.r,
                                        color: !_isGridView 
                                            ? AppColors.mintAccent 
                                            : subtitleColor.withValues(alpha: 0.6),
                                      ),
                                      if (!_isGridView) ...[
                                        SizedBox(width: 4.0.w),
                                        Text(
                                          'Stack',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 11.0.sp,
                                            fontWeight: FontWeight.w700,
                                            color: textColor,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.0.h),

                    // Dynamically toggle between the modern Grid view and classic Stacked folders deck view
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      child: _isGridView
                          ? GridView.builder(
                              key: const ValueKey<String>('grid_categories'),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 14.0.h,
                                crossAxisSpacing: 14.0.w,
                                childAspectRatio: 1.15.r,
                              ),
                              itemCount: categoryCardsData.length,
                              itemBuilder: (context, idx) {
                                final data = categoryCardsData[idx];
                                return CategoryCard(
                                  title: data['title'] as String,
                                  icon: data['icon'] as IconData,
                                  color: data['color'] as Color,
                                  size: data['size'] as String,
                                  percentage: data['percentage'] as String,
                                  ratio: data['ratio'] as double,
                                  isDark: isDark,
                                  onTap: () {
                                    context.push(data['route'] as String);
                                  },
                                );
                              },
                            )
                          : SizedBox(
                              key: const ValueKey<String>('stack_categories'),
                              height: 520.0.h,
                              width: double.infinity,
                              child: Stack(children: positionedWidgets),
                            ),
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
    int index,
  ) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedIndex == index) {
            _selectedIndex = -1;
          } else {
            _selectedIndex = index;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 8.0.w, vertical: 6.0.h),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withOpacity(0.08) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10.0.r),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
            width: 1.0.r,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4.0.w,
              height: 24.0.h,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2.0.r),
              ),
            ),
            SizedBox(width: 10.0.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.0.sp,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 2.0.h),
                  Text(
                    size,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.0.sp,
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
                fontSize: 14.0.sp,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Data holder classes
class _TabItemData {
  final String name;
  final Widget child;
  _TabItemData({required this.name, required this.child});
}

// Interactive storage segments donut chart painter
class StorageDonutPainter extends CustomPainter {
  final bool isDark;
  final Animation<double> animation;
  final List<double> values;
  final List<Color> colors;
  final List<double> segmentAngles;
  final int selectedIndex;

  StorageDonutPainter({
    required this.isDark,
    required this.animation,
    required this.values,
    required this.colors,
    required this.segmentAngles,
    required this.selectedIndex,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2 - 10.0.r;

    // Draw background track ring
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0.r
      ..color = isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05);
    canvas.drawCircle(center, baseRadius, trackPaint);

    double startAngle = -math.pi / 2; // Start from top (12 o'clock)
    final double gapAngle = 0.035; // gap angle between segments

    for (int i = 0; i < values.length; i++) {
      if (segmentAngles[i] <= 0) continue;

      final sweepAngle = segmentAngles[i] * animation.value;
      final isSelected = selectedIndex == i;
      
      // If something is selected, make other segments semi-transparent to highlight selection
      final double opacityMultiplier = (selectedIndex != -1 && !isSelected) ? 0.35 : 1.0;
      final Color segmentColor = colors[i].withOpacity(colors[i].opacity * opacityMultiplier);
      
      final fillPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 18.0.r : 14.0.r
        ..strokeCap = StrokeCap.round
        ..color = segmentColor;

      // Pop-out radius highlight
      final currentRadius = isSelected ? baseRadius + 3.0.r : baseRadius;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: currentRadius),
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
        oldDelegate.isDark != isDark ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

// Premium Grid Category Card representation
class CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String size;
  final String percentage;
  final double ratio; // size / totalStorage
  final VoidCallback onTap;
  final bool isDark;

  const CategoryCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    required this.size,
    required this.percentage,
    required this.ratio,
    required this.onTap,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark
        ? AppColors.neutral900.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.8);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    final textColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final subColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.0.r),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20.0.r),
          border: Border.all(color: borderColor, width: 1.0.r),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isDark ? 0.03 : 0.06),
              blurRadius: 10.0.r,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Icon and Arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(8.0.r),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 18.0.r,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: subColor.withOpacity(0.5),
                  size: 10.0.r,
                ),
              ],
            ),
            SizedBox(height: 8.0.h),
            // Middle: Title and Size
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.0.sp,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 2.0.h),
                Text(
                  size,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.0.sp,
                    fontWeight: FontWeight.w600,
                    color: subColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.0.h),
            // Bottom: Progress Bar and Percentage
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ratio',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9.0.sp,
                        fontWeight: FontWeight.w500,
                        color: subColor.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      percentage,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10.0.sp,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.0.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.0.r),
                  child: LinearProgressIndicator(
                    value: ratio.clamp(0.0, 1.0),
                    minHeight: 4.0.h,
                    backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
