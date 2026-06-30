import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../navigation/providers/navigation_provider.dart';
import '../../providers/storage_status_provider.dart';

class StorageBar extends ConsumerStatefulWidget {
  const StorageBar({Key? key}) : super(key: key);

  @override
  ConsumerState<StorageBar> createState() => _StorageBarState();
}

class _StorageBarState extends ConsumerState<StorageBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _getSegmentProgress(
    double animationValue,
    double start,
    double duration,
  ) {
    if (animationValue < start) return 0.0;
    if (animationValue > start + duration) return 1.0;
    return (animationValue - start) / duration;
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBgColor = isDark
        ? AppColors.neutral900.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.95);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    final usedTextColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final totalTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.neutral400;

    final storageAsync = ref.watch(storageStatusProvider);

    return storageAsync.when(
      loading: () => Container(
        height: 160.h,
        margin: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 12.0.h),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: AppColors.mintAccent),
      ),
      error: (err, stack) => const SizedBox.shrink(),
      data: (data) {
        final totalStorage = data['totalStorage'] as int? ?? 128 * 1024 * 1024 * 1024;
        final totalUsed = data['totalUsed'] as int? ?? 0;
        final freeStorage = data['freeStorage'] as int? ?? (totalStorage - totalUsed);
        final photos = data['Photos'] as int? ?? 0;
        final videos = data['Videos'] as int? ?? 0;
        final audio = data['Audio'] as int? ?? 0;
        final docs = data['Documents'] as int? ?? 0;
        final apps = data['Application'] as int? ?? 0;
        final others = data['Others'] as int? ?? 0;

        int getFlex(int bytes) {
          if (bytes <= 0) return 0;
          final pct = (bytes / totalStorage * 100).round();
          return pct > 0 ? pct : 1;
        }

        final fApps = getFlex(apps);
        final fVideos = getFlex(videos);
        final fOthers = getFlex(others);
        final fImages = getFlex(photos);
        final fDocs = getFlex(docs);
        final fAudio = getFlex(audio);
        
        final sumFlex = fApps + fVideos + fOthers + fImages + fDocs + fAudio;
        final fFree = sumFlex >= 100 ? 10 : (100 - sumFlex);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 12.0.h),
          child: GestureDetector(
            onTap: () {
              ref.read(activeIndexProvider.notifier).state = 1;
            },
            behavior: HitTestBehavior.opaque,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28.0.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                child: Container(
                  padding: EdgeInsets.all(24.0.r),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(28.0.r),
                    border: Border.all(color: borderColor, width: 1.5.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: e.g. 48 GB of 120 GB Used
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(fontFamily: 'Inter'),
                          children: [
                            TextSpan(
                              text: '${_formatSize(totalUsed)} ',
                              style: TextStyle(
                                fontSize: 24.0.sp,
                                fontWeight: FontWeight.w700,
                                color: usedTextColor,
                              ),
                            ),
                            TextSpan(
                              text: 'of ${_formatSize(totalStorage)} Used',
                              style: TextStyle(
                                fontSize: 14.0.sp,
                                fontWeight: FontWeight.w400,
                                color: totalTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 18.0.h),
                      // Animated Segmented Horizontal Progress Bar
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          final val = _progressAnimation.value;

                          // Compute proportional staggered grows
                          final p1 = _getSegmentProgress(val, 0.0, 0.15);
                          final p2 = _getSegmentProgress(val, 0.15, 0.10);
                          final p3 = _getSegmentProgress(val, 0.25, 0.10);
                          final p4 = _getSegmentProgress(val, 0.35, 0.08);
                          final p5 = _getSegmentProgress(val, 0.43, 0.05);
                          final p6 = _getSegmentProgress(val, 0.48, 0.02);
                          final p7 = _getSegmentProgress(val, 0.50, 0.50);

                          final freeSegmentColor = isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.06);

                          return Row(
                            children: [
                              if (fApps > 0)
                                Expanded(
                                  flex: fApps,
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: p1,
                                    child: Container(
                                      height: 10.0.h,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF4D4D),
                                        borderRadius: BorderRadius.circular(5.0.r),
                                      ),
                                    ),
                                  ),
                                ),
                              if (fApps > 0 && fVideos > 0) SizedBox(width: 4.0.w),
                              if (fVideos > 0)
                                Expanded(
                                  flex: fVideos,
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: p2,
                                    child: Container(
                                      height: 10.0.h,
                                      decoration: BoxDecoration(
                                        color: AppColors.mintAccent,
                                        borderRadius: BorderRadius.circular(5.0.r),
                                      ),
                                    ),
                                  ),
                                ),
                              if (fVideos > 0 && fOthers > 0) SizedBox(width: 4.0.w),
                              if (fOthers > 0)
                                Expanded(
                                  flex: fOthers,
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: p3,
                                    child: Container(
                                      height: 10.0.h,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF9E9E9E),
                                        borderRadius: BorderRadius.circular(5.0.r),
                                      ),
                                    ),
                                  ),
                                ),
                              if (fOthers > 0 && fImages > 0) SizedBox(width: 4.0.w),
                              if (fImages > 0)
                                Expanded(
                                  flex: fImages,
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: p4,
                                    child: Container(
                                      height: 10.0.h,
                                      decoration: BoxDecoration(
                                        color: AppColors.storageSkyBlue,
                                        borderRadius: BorderRadius.circular(5.0.r),
                                      ),
                                    ),
                                  ),
                                ),
                              if (fImages > 0 && fDocs > 0) SizedBox(width: 4.0.w),
                              if (fDocs > 0)
                                Expanded(
                                  flex: fDocs,
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: p5,
                                    child: Container(
                                      height: 10.0.h,
                                      decoration: BoxDecoration(
                                        color: AppColors.storageYellow,
                                        borderRadius: BorderRadius.circular(5.0.r),
                                      ),
                                    ),
                                  ),
                                ),
                              if (fDocs > 0 && fAudio > 0) SizedBox(width: 4.0.w),
                              if (fAudio > 0)
                                Expanded(
                                  flex: fAudio,
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: p6,
                                    child: Container(
                                      height: 10.0.h,
                                      decoration: BoxDecoration(
                                        color: AppColors.storageOrange,
                                        borderRadius: BorderRadius.circular(5.0.r),
                                      ),
                                    ),
                                  ),
                                ),
                              SizedBox(width: 4.0.w),
                              Expanded(
                                flex: fFree,
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: p7,
                                  child: Container(
                                    height: 10.0.h,
                                    decoration: BoxDecoration(
                                      color: freeSegmentColor,
                                      borderRadius: BorderRadius.circular(5.0.r),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 24.0.h),
                      // Bottom grid of Legends
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _buildLegendItem(
                                  isDark,
                                  'Apps',
                                  _formatSize(apps),
                                  const Color(0xFFFF4D4D),
                                ),
                                SizedBox(height: 6.0.h),
                                _buildLegendItem(
                                  isDark,
                                  'Others',
                                  _formatSize(others),
                                  const Color(0xFF9E9E9E),
                                ),
                                SizedBox(height: 6.0.h),
                                _buildLegendItem(
                                  isDark,
                                  'Docs',
                                  _formatSize(docs),
                                  AppColors.storageYellow,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.0.w),
                          Expanded(
                            child: Column(
                              children: [
                                _buildLegendItem(
                                  isDark,
                                  'Videos',
                                  _formatSize(videos),
                                  AppColors.mintAccent,
                                ),
                                SizedBox(height: 6.0.h),
                                _buildLegendItem(
                                  isDark,
                                  'Images',
                                  _formatSize(photos),
                                  AppColors.storageSkyBlue,
                                ),
                                SizedBox(height: 6.0.h),
                                _buildLegendItem(
                                  isDark,
                                  'Audio',
                                  _formatSize(audio),
                                  AppColors.storageOrange,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 18.0.h),
                      Divider(color: borderColor, height: 1.0.r),
                      SizedBox(height: 12.0.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatDetail('Scanned Files', '${data['fileCount'] ?? 0}'),
                          _buildStatDetail('Scan Duration', '${data['scanDurationMs'] ?? 0} ms'),
                          _buildStatDetail('9-Index Build', '${data['indexDurationMs'] ?? 0} ms'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.0.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.mintAccent,
          ),
        ),
        SizedBox(height: 3.0.h),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 9.0.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    bool isDark,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.0.w, vertical: 6.0.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12.0.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          width: 1.0.r,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6.0.r,
            height: 6.0.r,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 8.0.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.0.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.pureWhite : AppColors.neutral900,
                  ),
                ),
                SizedBox(height: 1.0.h),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.0.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
