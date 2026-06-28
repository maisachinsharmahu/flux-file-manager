import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';

class FluxForYouCard extends StatelessWidget {
  const FluxForYouCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBgGradient = isDark
        ? const LinearGradient(
            colors: [
              Color(0xFF1E1B4B), // Deep indigo
              Color(0xFF0F172A), // Deep slate
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [
              Color(0xFFEEF2F6), // Light greyish blue
              Color(0xFFF8FAFC), // Off-white slate
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    final titleColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final accentColor = isDark ? AppColors.mintAccent : const Color(0xFF059669);
    final descColor = isDark ? AppColors.textSecondaryLight.withValues(alpha: 0.7) : AppColors.textSecondaryLight;
    final badgeBgColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04);
    final badgeTextColor = isDark ? AppColors.pureWhite : AppColors.neutral800;

    return Padding(
      padding: EdgeInsets.fromLTRB(24.0.w, 24.0.h, 24.0.w, 16.0.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 12.0.h),
            child: Text(
              'Flux For You',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18.0.sp,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
          ),
          Container(
            height: 180.0.h,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: cardBgGradient,
              borderRadius: BorderRadius.circular(28.0.r),
              border: Border.all(color: borderColor, width: 1.5.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 20.0.r,
                  offset: Offset(0, 8.h),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28.0.r),
              child: Stack(
                children: [
                  // Overlapping organic background blob shapes
                  Positioned(
                    top: -40.0.h,
                    left: -40.0.w,
                    child: Container(
                      width: 140.0.r,
                      height: 140.0.r,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.04),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      // Left Column: Branding Details
                      Expanded(
                        flex: 6,
                        child: Padding(
                          padding: EdgeInsets.all(24.0.r),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Flux For You',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 22.0.sp,
                                  fontWeight: FontWeight.w900,
                                  color: titleColor,
                                ),
                              ),
                              SizedBox(height: 2.0.h),
                              Text(
                                'your one stop',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14.0.sp,
                                  fontWeight: FontWeight.w700,
                                  color: accentColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 12.0.h),
                              Text(
                                'Complete programmatic index search, vector analytics, and file relationships.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w500,
                                  color: descColor,
                                  height: 1.4,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.0.w, vertical: 4.0.h),
                                decoration: BoxDecoration(
                                  color: badgeBgColor,
                                  borderRadius: BorderRadius.circular(10.0.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '✨ AI Core Active',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 9.5.sp,
                                        fontWeight: FontWeight.w700,
                                        color: badgeTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Right Column: Programmatic Connection Art
                      Expanded(
                        flex: 4,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SizedBox(
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                              child: CustomPaint(
                                painter: _FluxForYouPainter(isDark),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FluxForYouPainter extends CustomPainter {
  final bool isDark;
  _FluxForYouPainter(this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.45, size.height * 0.5);

    // Primary core paint (Mint Green)
    final corePaint = Paint()
      ..color = isDark ? const Color(0xFF10B981) : const Color(0xFF059669)
      ..style = PaintingStyle.fill;

    // Glowing circle paint
    final glowPaint = Paint()
      ..color = (isDark ? const Color(0xFF10B981) : const Color(0xFF059669)).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10.0.r);

    // Draw glowing core
    canvas.drawCircle(center, 16.0.r, glowPaint);
    canvas.drawCircle(center, 10.0.r, corePaint);

    // Center dot
    canvas.drawCircle(center, 3.5.r, Paint()..color = Colors.white);

    // Orbit paths (translucent circles)
    final orbitPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0.r;

    canvas.drawCircle(center, 34.0.r, orbitPaint);
    canvas.drawCircle(center, 54.0.r, orbitPaint);

    // Connecting branches
    final linePaint = Paint()
      ..color = (isDark ? const Color(0xFF10B981) : const Color(0xFF059669)).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25.r;

    // Orbits math
    final node1 = Offset(center.dx + 34.0 * cos(0.8), center.dy + 34.0 * sin(0.8));
    canvas.drawLine(center, node1, linePaint);
    canvas.drawCircle(node1, 5.0.r, Paint()..color = const Color(0xFF6366F1)); // Indigo Node

    final node2 = Offset(center.dx - 54.0 * cos(0.4), center.dy + 54.0 * sin(0.4));
    canvas.drawLine(center, node2, linePaint);
    canvas.drawCircle(node2, 6.0.r, Paint()..color = const Color(0xFFF59E0B)); // Orange Node

    final node3 = Offset(center.dx + 54.0 * cos(1.4), center.dy - 54.0 * sin(1.4));
    canvas.drawLine(center, node3, linePaint);
    canvas.drawCircle(node3, 4.0.r, Paint()..color = const Color(0xFFEC4899)); // Pink Node
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
