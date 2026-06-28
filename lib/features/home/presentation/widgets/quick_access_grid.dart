import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../navigation/providers/navigation_provider.dart';

class QuickAccessGrid extends ConsumerWidget {
  const QuickAccessGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final headerColor = isDark ? AppColors.pureWhite : AppColors.neutral900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 8.0.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18.0.sp,
                  fontWeight: FontWeight.w700,
                  color: headerColor,
                ),
              ),
              GestureDetector(
                onTap: () {
                  ref.read(activeIndexProvider.notifier).state = 3; // Navigates to Browser
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.0.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mintAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.0.h),
        SizedBox(
          height: 120.0.h,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 24.0.w),
            child: Row(
              children: [
                _buildFolderCard(ref, 'Images', '9,128 Items', Icons.image_outlined, isDark),
                SizedBox(width: 14.0.w),
                _buildFolderCard(ref, 'Videos', '823 Items', Icons.play_circle_outline, isDark),
                SizedBox(width: 14.0.w),
                _buildFolderCard(ref, 'Docs', '135 Items', Icons.description_outlined, isDark),
                SizedBox(width: 14.0.w),
                _buildFolderCard(ref, 'Audio', '12 Items', Icons.music_note_outlined, isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFolderCard(
    WidgetRef ref,
    String title,
    String count,
    IconData materialIcon,
    bool isDark,
  ) {
    // Achromatic glassmorphic colors
    final cardBgColor = isDark 
        ? AppColors.neutral900.withValues(alpha: 0.6) 
        : Colors.white.withValues(alpha: 0.6);

    // Uniform subtle border for all folders (no selection border highlight)
    final borderColor = isDark 
        ? Colors.white.withValues(alpha: 0.08) 
        : Colors.black.withValues(alpha: 0.05);

    final titleColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final subtitleColor = isDark ? AppColors.textSecondaryLight : AppColors.neutral400;
    final iconColor = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: () {
        ref.read(activeIndexProvider.notifier).state = 3; // Navigates to Browser
      },
      child: SizedBox(
        width: 140.0.w,
        height: 105.0.h,
        child: CustomPaint(
          painter: FolderCardPainter(
            fillColor: cardBgColor,
            borderColor: borderColor,
            isDark: isDark,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(14.0.w, 20.0.h, 14.0.w, 14.0.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 28.0.r,
                      height: 28.0.r,
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.white.withValues(alpha: 0.06) 
                            : Colors.black.withValues(alpha: 0.04),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          materialIcon,
                          size: 16.0.r,
                          color: iconColor,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.more_vert,
                      size: 16.0.r,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.0.sp,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                SizedBox(height: 2.0.h),
                Text(
                  count,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FolderCardPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final bool isDark;
  final double borderWidth;

  FolderCardPainter({
    required this.fillColor,
    required this.borderColor,
    required this.isDark,
    this.borderWidth = 1.2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Shape proportions
    final r = 16.0.r; // corner radius of the main body
    final tabH = 12.0.h; // tab height
    final tabW = w * 0.38; // tab width
    final slopeW = 10.0.w; // slope width of the tab transition
    final tabR = 6.0.r; // corner radius of the tab top-left

    final path = Path();
    
    // Start at bottom-left corner
    path.moveTo(r, h);
    
    // Bottom-right corner
    path.lineTo(w - r, h);
    path.quadraticBezierTo(w, h, w, h - r);
    
    // Top-right corner (main body starts at y = tabH)
    path.lineTo(w, tabH + r);
    path.quadraticBezierTo(w, tabH, w - r, tabH);
    
    // Main body top edge up to the tab slope end
    path.lineTo(tabW + slopeW, tabH);
    
    // Curve/Slope up to the tab top
    // Cubic bezier starting at (tabW + slopeW, tabH) going up to (tabW, 0)
    path.cubicTo(
      tabW + slopeW * 0.4, tabH,
      tabW + slopeW * 0.1, 0,
      tabW, 0,
    );
    
    // Tab top edge to the left
    path.lineTo(tabR, 0);
    
    // Tab top-left corner
    path.quadraticBezierTo(0, 0, 0, tabR);
    
    // Left edge down to the bottom-left corner
    path.lineTo(0, h - r);
    path.quadraticBezierTo(0, h, r, h);
    
    path.close();

    // 1. Draw subtle shadow
    final shadowColor = isDark 
        ? Colors.black.withValues(alpha: 0.15) 
        : Colors.black.withValues(alpha: 0.04);
    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0.r);
    canvas.drawPath(path, shadowPaint);

    // 2. Draw Folder Fill
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 3. Draw Folder Border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant FolderCardPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.isDark != isDark;
  }
}
