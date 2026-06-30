import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/storage_category_icon.dart';
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
          padding: EdgeInsets.fromLTRB(24.0.w, 24.0.h, 24.0.w, 12.0.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Access',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18.0.sp,
                  fontWeight: FontWeight.w700,
                  color: headerColor,
                ),
              ),
              GestureDetector(
                onTap: () {
                  context.push('/browser');
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
        SizedBox(height: 8.0.h),
        SizedBox(
          height: 110.0.h,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 24.0.w),
            child: Row(
              children: [
                _buildFolderCard(context, ref, 'Images', '9,128 Items', StorageCategoryIcon.images, isDark),
                SizedBox(width: 14.0.w),
                _buildFolderCard(context, ref, 'Videos', '823 Items', StorageCategoryIcon.videos, isDark),
                SizedBox(width: 14.0.w),
                _buildFolderCard(context, ref, 'Docs', '135 Items', StorageCategoryIcon.documents, isDark),
                SizedBox(width: 14.0.w),
                _buildFolderCard(context, ref, 'Audio', '12 Items', StorageCategoryIcon.audio, isDark),
                SizedBox(width: 14.0.w),
                _buildFolderCard(context, ref, 'Archives', '42 Items', StorageCategoryIcon.archives, isDark),
                SizedBox(width: 14.0.w),
                _buildFolderCard(context, ref, 'APKs', '8 Items', StorageCategoryIcon.apks, isDark),
                SizedBox(width: 14.0.w),
                _buildFolderCard(context, ref, 'Shared', '15 Items', StorageCategoryIcon.shared, isDark),
                SizedBox(width: 14.0.w),
                _buildFolderCard(context, ref, 'More', 'Browse', StorageCategoryIcon.more, isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFolderCard(
    BuildContext context,
    WidgetRef ref,
    String title,
    String count,
    StorageCategoryIcon categoryIcon,
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
        if (title == 'Images') {
          context.push('/all_files?title=Photos&category=Photos');
        } else if (title == 'Videos') {
          context.push('/all_files?title=Videos&category=Videos');
        } else if (title == 'Docs') {
          context.push('/all_files?title=Documents&category=Documents');
        } else if (title == 'Audio') {
          context.push('/all_files?title=Audio&category=Audio');
        } else if (title == 'Archives') {
          context.push('/all_files?title=Archives&category=Others');
        } else if (title == 'APKs') {
          context.push('/all_files?title=Applications&category=Application');
        } else {
          context.push('/browser');
        }
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
                    StorageCategoryIconWidget(
                      icon: categoryIcon,
                      size: 30.0.r,
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
