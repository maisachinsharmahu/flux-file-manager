import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

class ShimmerPlaceholder extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const ShimmerPlaceholder({
    Key? key,
    required this.child,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color baseColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);

    final Color highlightColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.1);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

class ShimmerContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;

  const ShimmerContainer({
    Key? key,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.shape = BoxShape.rectangle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShimmerPlaceholder(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: shape,
          borderRadius: shape == BoxShape.circle
              ? null
              : BorderRadius.circular(borderRadius.r),
        ),
      ),
    );
  }
}

/// A premium list tile shimmer loader helper.
class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0.h, horizontal: 16.0.w),
      child: Row(
        children: [
          ShimmerContainer(
            width: 44.0.r,
            height: 44.0.r,
            shape: BoxShape.circle,
          ),
          SizedBox(width: 16.0.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerContainer(
                  width: 140.0.w,
                  height: 14.0.h,
                  borderRadius: 6,
                ),
                SizedBox(height: 8.0.h),
                ShimmerContainer(
                  width: 80.0.w,
                  height: 10.0.h,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A premium grid card shimmer loader helper.
class ShimmerGridCard extends StatelessWidget {
  const ShimmerGridCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.0.r),
      ),
      padding: EdgeInsets.all(12.0.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: ShimmerContainer(
                width: 64.0.r,
                height: 64.0.r,
                borderRadius: 16,
              ),
            ),
          ),
          SizedBox(height: 12.0.h),
          ShimmerContainer(
            width: 100.0.w,
            height: 12.0.h,
            borderRadius: 6,
          ),
          SizedBox(height: 6.0.h),
          ShimmerContainer(
            width: 60.0.w,
            height: 10.0.h,
            borderRadius: 4,
          ),
        ],
      ),
    );
  }
}
