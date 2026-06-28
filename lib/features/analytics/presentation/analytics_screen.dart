import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../navigation/providers/navigation_provider.dart';
import '../../../../core/theme/app_colors.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 16.0.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Header Row with Back Button and Title
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
                    // Card Top Row: Capacity & Upgrade button
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
                            color: isDark ? Colors.white : AppColors.neutral900,
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

              // Overlapping Curved Category Stack
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

              // Stacking folder shapes with negative margin offset translations
              _StackedFolderTab(
                title: 'Photos',
                icon: Icons.image,
                color: const Color(0xFFFFD020),
                isDark: isDark,
                onTap: () {
                  ref.read(activeIndexProvider.notifier).state =
                      3; // Navigate to browser
                },
              ),
              Transform.translate(
                offset: Offset(0, -20.0.h),
                child: _StackedFolderTab(
                  title: 'Videos',
                  icon: Icons.play_arrow,
                  color: const Color(0xFFFF9010),
                  isDark: isDark,
                  onTap: () {
                    ref.read(activeIndexProvider.notifier).state = 3;
                  },
                ),
              ),
              Transform.translate(
                offset: Offset(0, -40.0.h),
                child: _StackedFolderTab(
                  title: 'Documents',
                  icon: Icons.description_outlined,
                  color: const Color(0xFFA020F0),
                  isDark: isDark,
                  onTap: () {
                    ref.read(activeIndexProvider.notifier).state = 3;
                  },
                ),
              ),
              Transform.translate(
                offset: Offset(0, -60.0.h),
                child: _StackedFolderTab(
                  title: 'Audio',
                  icon: Icons.music_note,
                  color: const Color(0xFFFF40A0),
                  isDark: isDark,
                  onTap: () {
                    ref.read(activeIndexProvider.notifier).state = 3;
                  },
                ),
              ),
              SizedBox(height: 20.0.h),
            ],
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
          width: 3.0.w,
          height: 24.0.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.5.r),
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

// Concentric Circular Rings custom painter
class ConcentricRingsPainter extends CustomPainter {
  final bool isDark;

  ConcentricRingsPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Radii of concentric circles
    final radii = [76.0.r, 62.0.r, 48.0.r];
    final colors = [
      const Color(0xFFFFD020),
      const Color(0xFFFF9010),
      const Color(0xFFA020F0),
    ];
    // Arc fills (sweep angles in radians)
    final progress = [0.72, 0.45, 0.65];

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0.r
      ..color = isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05);

    for (int i = 0; i < radii.length; i++) {
      final r = radii[i];
      // Draw background track arc
      canvas.drawCircle(center, r, trackPaint);

      // Draw progress arc
      final fillPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0.r
        ..strokeCap = StrokeCap.round
        ..color = colors[i];

      // Starting sweep angle from top (-pi / 2)
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        -math.pi / 2,
        progress[i] * 2 * math.pi,
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
          height: 90.0.h,
          color: color,
          padding: EdgeInsets.symmetric(horizontal: 20.0.w),
          child: Align(
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.only(
                top: 14.0.h,
              ), // Offset content down slightly below the tab slope
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side Circle with monochrome icon inside
                  Row(
                    children: [
                      Container(
                        width: 38.0.r,
                        height: 38.0.r,
                        decoration: const BoxDecoration(
                          color: Color(0xFF171717),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            icon,
                            color:
                                color, // Matching tab color inside dark circle
                            size: 20.0.r,
                          ),
                        ),
                      ),
                      SizedBox(width: 14.0.w),
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16.0.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(
                            0xFF171717,
                          ), // Contrast dark color matching screenshot text
                        ),
                      ),
                    ],
                  ),
                  // Right side Translucent arrow outwards button
                  Container(
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Clipper path for horizontal folder shape
class FolderTabClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final tabW = size.width * 0.42;
    const slopeW = 60.0;
    const tabH = 22.0;

    path.moveTo(0, 0);
    path.lineTo(tabW, 0);
    path.cubicTo(
      tabW + slopeW * 0.4,
      0,
      tabW + slopeW * 0.1,
      tabH,
      tabW + slopeW,
      tabH,
    );
    path.lineTo(size.width, tabH);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
