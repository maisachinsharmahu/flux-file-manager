import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/widgets/flux_icon.dart';
import '../../../../core/theme/app_colors.dart';
import 'file_detail_sheet.dart';

class RecentsList extends StatelessWidget {
  const RecentsList({Key? key}) : super(key: key);

  // ── Static data (mirrors what was here before + adds detail fields)
  static final List<RecentFileInfo> _files = [
    RecentFileInfo(
      name: 'Quarterly_Report.pptx',
      type: 'PowerPoint Presentation',
      size: '2.4 MB',
      modified: '2 hours ago',
      path: '/Documents/Reports/',
      iconColor: AppColors.pptIcon,
      iconBg: AppColors.pptLightBg,
      fallbackIcon: Icons.slideshow_outlined,
    ),
    RecentFileInfo(
      name: 'Project_Design_Brief.pdf',
      type: 'PDF Document',
      size: '4.8 MB',
      modified: '5 hours ago',
      path: '/Documents/Projects/',
      iconColor: AppColors.pdfIcon,
      iconBg: AppColors.pdfBackground,
      fluxIcon: FluxIconType.adobeReader,
      fallbackIcon: Icons.picture_as_pdf_outlined,
    ),
    RecentFileInfo(
      name: 'Revenue_Model_2026.xlsx',
      type: 'Excel Spreadsheet',
      size: '1.1 MB',
      modified: 'Yesterday',
      path: '/Documents/Finance/',
      iconColor: AppColors.excelIcon,
      iconBg: AppColors.excelLightBg,
      fluxIcon: FluxIconType.documentColor,
      fallbackIcon: Icons.table_chart_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final headerColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24.0.w, 24.0.h, 24.0.w, 12.0.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Uploaded',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18.0.sp,
                  fontWeight: FontWeight.w700,
                  color: headerColor,
                ),
              ),
              GestureDetector(
                onTap: () {},
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
        ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 24.0.w),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _files.length,
          separatorBuilder: (context, index) =>
              Divider(color: dividerColor, height: 1.0.h, thickness: 1.0.r),
          itemBuilder: (context, index) {
            return _RecentItemRow(
              file: _files[index],
              onTap: () {
                HapticFeedback.lightImpact();
                showFileDetailSheet(context, _files[index]);
              },
            );
          },
        ),
      ],
    );
  }
}

class _RecentItemRow extends StatefulWidget {
  final RecentFileInfo file;
  final VoidCallback onTap;

  const _RecentItemRow({
    Key? key,
    required this.file,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_RecentItemRow> createState() => _RecentItemRowState();
}

class _RecentItemRowState extends State<_RecentItemRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final titleColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final subtitleColor = isDark
        ? AppColors.textSecondaryLight.withValues(alpha: 0.6)
        : AppColors.neutral400;

    final file = widget.file;
    final bgColor = isDark ? _darkBgFor(file) : file.iconBg;

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.0.h),
          child: Row(
            children: [
              Container(
                width: 44.0.r,
                height: 44.0.r,
                decoration: BoxDecoration(
                  color: bgColor.withValues(alpha: isDark ? 0.35 : 0.8),
                  borderRadius: BorderRadius.circular(12.0.r),
                  border: Border.all(
                    color: file.iconColor.withValues(alpha: 0.15),
                    width: 1.0.r,
                  ),
                ),
                child: Center(
                  child: file.fluxIcon != null
                      ? FluxIcon(file.fluxIcon!, size: 20.0.r)
                      : Icon(file.fallbackIcon, color: file.iconColor, size: 20.0.r),
                ),
              ),
              SizedBox(width: 16.0.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15.0.sp,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.0.h),
                    Text(
                      '${file.type} • ${file.size} • ${file.modified}',
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
              Icon(
                Icons.chevron_right_rounded,
                size: 20.0.r,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _darkBgFor(RecentFileInfo file) {
    if (file.iconColor == AppColors.pptIcon) return AppColors.pptDarkBg;
    if (file.iconColor == AppColors.pdfIcon) return AppColors.pdfDarkBg;
    if (file.iconColor == AppColors.excelIcon) return AppColors.excelDarkBg;
    return AppColors.neutral800;
  }
}
