import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

class ShareHelper {
  static void showShareSheet(BuildContext context, List<String> fileNames) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark 
        ? AppColors.neutral950.withValues(alpha: 0.85) 
        : Colors.white.withValues(alpha: 0.85);
    final textColor = isDark ? Colors.white : AppColors.neutral900;
    final subtitleColor = isDark ? Colors.white70 : AppColors.neutral500;
    final borderColor = isDark 
        ? Colors.white.withValues(alpha: 0.08) 
        : Colors.black.withValues(alpha: 0.05);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.0.r)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30.0.r)),
                border: Border(
                  top: BorderSide(color: borderColor, width: 1.5.r),
                ),
              ),
              padding: EdgeInsets.fromLTRB(24.0.w, 16.0.h, 24.0.w, 40.0.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40.0.w,
                    height: 5.0.h,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2.5.r),
                    ),
                  ),
                  SizedBox(height: 24.0.h),
                  // Title
                  Text(
                    fileNames.length == 1 
                        ? 'Share File' 
                        : 'Share ${fileNames.length} Files',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18.0.sp,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 8.0.h),
                  Text(
                    fileNames.length == 1 
                        ? fileNames.first 
                        : '${fileNames.take(3).join(", ")}${fileNames.length > 3 ? '...' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.0.sp,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                    ),
                  ),
                  SizedBox(height: 28.0.h),
                  // Share Apps Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildShareOption(
                        icon: Icons.send_rounded,
                        label: 'Quick Share',
                        color: const Color(0xFF4A90E2),
                        onTap: () => _handleShare(context, 'Quick Share', fileNames),
                      ),
                      _buildShareOption(
                        icon: Icons.forum_rounded,
                        label: 'WhatsApp',
                        color: const Color(0xFF25D366),
                        onTap: () => _handleShare(context, 'WhatsApp', fileNames),
                      ),
                      _buildShareOption(
                        icon: Icons.telegram_rounded,
                        label: 'Telegram',
                        color: const Color(0xFF0088CC),
                        onTap: () => _handleShare(context, 'Telegram', fileNames),
                      ),
                      _buildShareOption(
                        icon: Icons.mail_outline_rounded,
                        label: 'Gmail',
                        color: const Color(0xFFD44638),
                        onTap: () => _handleShare(context, 'Gmail', fileNames),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54.0.r,
            height: 54.0.r,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 26.0.r,
              color: color,
            ),
          ),
          SizedBox(height: 10.0.h),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.0.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }

  static void _handleShare(BuildContext context, String platform, List<String> fileNames) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          fileNames.length == 1
              ? 'Shared "${fileNames.first}" via $platform'
              : 'Shared ${fileNames.length} files via $platform',
          style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500),
        ),
        backgroundColor: AppColors.neutral900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0.r)),
        margin: EdgeInsets.all(16.0.r),
      ),
    );
  }
}
