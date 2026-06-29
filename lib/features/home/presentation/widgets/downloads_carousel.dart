import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/flux_icon.dart';
import '../../../../core/theme/app_colors.dart';
import 'file_detail_sheet.dart';

class DownloadsCarousel extends StatefulWidget {
  const DownloadsCarousel({Key? key}) : super(key: key);

  @override
  State<DownloadsCarousel> createState() => _DownloadsCarouselState();
}

class _DownloadsCarouselState extends State<DownloadsCarousel> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  final List<Map<String, dynamic>> _mockDownloads = [
    {
      'title': 'invoice_flux.docx',
      'subtitle': 'Word • 240 KB • 1h ago',
      'category': 'Documents',
      'size': '240 KB',
      'date': '2026-06-29',
      'icon': FluxIconType.documentColor,
      'color': AppColors.excelLightBg,
      'darkColor': AppColors.excelDarkBg,
      'fallbackIcon': Icons.description_outlined,
    },
    {
      'title': 'resume_sachin.pdf',
      'subtitle': 'PDF • 1.2 MB • 3h ago',
      'category': 'Documents',
      'size': '1.2 MB',
      'date': '2026-06-29',
      'icon': FluxIconType.adobeReader,
      'color': AppColors.pdfBackground,
      'darkColor': AppColors.pdfDarkBg,
      'fallbackIcon': Icons.picture_as_pdf_outlined,
    },
    {
      'title': 'tutorial_flutter.mov',
      'subtitle': 'Video • 125 MB • 6h ago',
      'category': 'Videos',
      'size': '125 MB',
      'date': '2026-06-29',
      'icon': FluxIconType.videoFileColor,
      'color': AppColors.pptLightBg,
      'darkColor': AppColors.pptDarkBg,
      'fallbackIcon': Icons.play_circle_outline,
    },
    {
      'title': 'vacation_pic_1.jpg',
      'subtitle': 'Image • 2.4 MB • 12h ago',
      'category': 'Images',
      'size': '2.4 MB',
      'date': '2026-06-29',
      'icon': FluxIconType.imageFileColor,
      'color': AppColors.excelLightBg,
      'darkColor': AppColors.excelDarkBg,
      'fallbackIcon': Icons.image_outlined,
    },
    {
      'title': 'flux_file_manager.apk',
      'subtitle': 'App • 18 MB • Yesterday',
      'category': 'Apps',
      'size': '18 MB',
      'date': '2026-06-28',
      'icon': FluxIconType.apk,
      'color': AppColors.pdfBackground,
      'darkColor': AppColors.pdfDarkBg,
      'fallbackIcon': Icons.android_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    }
  }

  // Snaps the carousel on scroll release
  void _snapToItem(double totalWidth, double cardStep) {
    if (!_scrollController.hasClients) return;
    final double target = (_scrollOffset / cardStep).round() * cardStep;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final double safeTarget = target.clamp(0.0, maxScroll);
    
    Future.microtask(() {
      _scrollController.animateTo(
        safeTarget,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final headerColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final subtitleColor = isDark
        ? AppColors.textSecondaryLight.withValues(alpha: 0.6)
        : AppColors.neutral400;
    final cardBg = isDark
        ? AppColors.neutral900.withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.9);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double horizontalPadding = 48.0.w;
        final double availableWidth = constraints.maxWidth - horizontalPadding;

        // Proportional space configurations (60% / 30% / 10% widths)
        final double W1 = availableWidth * 0.60;
        final double W2 = availableWidth * 0.30;
        final double W3 = availableWidth * 0.10;

        final double spacing = 12.0.w;
        final double cardStep = W1 + spacing;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title Header
            Padding(
              padding: EdgeInsets.fromLTRB(24.0.w, 24.0.h, 24.0.w, 12.0.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Downloads',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18.0.sp,
                      fontWeight: FontWeight.w700,
                      color: headerColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/all_files'),
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

            // Horizontal Scroll Carousel
            Listener(
              onPointerUp: (_) => _snapToItem(availableWidth, cardStep),
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 8.0.h),
                child: Row(
                  children: List.generate(_mockDownloads.length, (index) {
                    final item = _mockDownloads[index];

                    // Calculate proportional width based on distance from scroll center
                    final double fractionalIndex = _scrollOffset / cardStep;
                    final double rel = index - fractionalIndex;
                    double width = 0.0;

                    if (rel <= -1.0) {
                      // Scrolled off to the left (fade/shrink out)
                      width = W1 * (1.0 + rel).clamp(0.0, 1.0);
                    } else if (rel > -1.0 && rel <= 0.0) {
                      // Transitioning from 1st active to scrolled off left
                      final double t = -rel; 
                      width = W1 + (0.0 - W1) * t; 
                    } else if (rel > 0.0 && rel <= 1.0) {
                      // Transitioning from 2nd card to 1st active
                      final double t = rel;
                      width = W1 + (W2 - W1) * t;
                    } else if (rel > 1.0 && rel <= 2.0) {
                      // Transitioning from 3rd card to 2nd card
                      final double t = rel - 1.0;
                      width = W2 + (W3 - W2) * t;
                    } else if (rel > 2.0 && rel <= 3.0) {
                      // Transitioning from hidden to 3rd card
                      final double t = rel - 2.0;
                      width = W3 + (0.0 - W3) * t;
                    } else {
                      width = 0.0;
                    }

                    // Keep width bounded/positive
                    width = width.clamp(0.0, W1);

                    // Skip rendering collapsed cards to save layout performance
                    if (width < 2.0) {
                      return const SizedBox.shrink();
                    }

                    final bool isMainCard = width > (W1 + W2) / 2;
                    final bool isSecondCard = width > (W2 + W3) / 2 && !isMainCard;

                    final itemThemeColor = isDark ? item['darkColor'] as Color : item['color'] as Color;

                    return Container(
                      width: width,
                      height: 125.0.h,
                      margin: EdgeInsets.only(right: spacing),
                      child: GestureDetector(
                        onTap: () {
                          final detail = FileDetail(
                            name: item['title'] as String,
                            size: item['size'] as String,
                            createdDate: 'June 28, 2026, 12:14 PM',
                            modifiedDate: item['date'] as String,
                            type: item['category'] as String,
                            themeColor: itemThemeColor,
                            fallbackIcon: item['fallbackIcon'] as IconData,
                            fluxIcon: item['icon'] as FluxIconType,
                          );
                          FileDetailSheet.show(context, detail);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20.0.r),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(20.0.r),
                                border: Border.all(
                                  color: isMainCard
                                      ? AppColors.mintAccent.withValues(alpha: 0.4)
                                      : borderColor,
                                  width: isMainCard ? 1.5.r : 1.0.r,
                                ),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 14.0.h),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 150),
                                child: isMainCard
                                    // 60% Width Premium detailed layout
                                    ? Row(
                                        key: const ValueKey('detailLayout'),
                                        children: [
                                          Container(
                                            width: 44.0.r,
                                            height: 44.0.r,
                                            decoration: BoxDecoration(
                                              color: itemThemeColor.withValues(alpha: isDark ? 0.2 : 0.8),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: FluxIcon(item['icon'] as FluxIconType, size: 22.0.r),
                                            ),
                                          ),
                                          SizedBox(width: 12.0.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  item['title'] as String,
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 14.0.sp,
                                                    fontWeight: FontWeight.w700,
                                                    color: theme.textTheme.titleMedium?.color,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 4.0.h),
                                                Text(
                                                  item['subtitle'] as String,
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 11.0.sp,
                                                    fontWeight: FontWeight.w500,
                                                    color: subtitleColor,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : isSecondCard
                                        // 30% Width Intermediate mini layout (Icon only, centered)
                                        ? Center(
                                            key: const ValueKey('iconOnlyLayout'),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 40.0.r,
                                                  height: 40.0.r,
                                                  decoration: BoxDecoration(
                                                    color: itemThemeColor.withValues(alpha: isDark ? 0.2 : 0.8),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Center(
                                                    child: FluxIcon(item['icon'] as FluxIconType, size: 18.0.r),
                                                  ),
                                                ),
                                                SizedBox(height: 6.0.h),
                                                Text(
                                                  item['category'] as String,
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 9.0.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color: subtitleColor,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.clip,
                                                ),
                                              ],
                                            ),
                                          )
                                        // 10% Width Muted peek border layout
                                        : Container(
                                            key: const ValueKey('peekLayout'),
                                            decoration: BoxDecoration(
                                              color: itemThemeColor.withValues(alpha: 0.15),
                                              shape: BoxShape.circle,
                                            ),
                                            width: 12.0.r,
                                            height: 12.0.r,
                                          ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
