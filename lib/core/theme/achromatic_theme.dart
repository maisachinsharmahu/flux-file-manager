import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class FluxTheme {
  static ThemeData get light {
    final baseTheme = ThemeData(brightness: Brightness.light);
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      cardColor: AppColors.neutral100,
      dividerColor: AppColors.neutral200,
      colorScheme: const ColorScheme.light(
        background: AppColors.pureWhite,
        surface: AppColors.neutral100,
        onBackground: AppColors.neutral900,
        onSurface: AppColors.textSecondaryLight,
        primary: AppColors.neutral900,
        error: AppColors.errorRed,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.neutral900),
        displayMedium: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.neutral900),
        titleLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.neutral900),
        titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.neutral900),
        bodyLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.neutral900),
        bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.neutral900),
        labelLarge: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondaryLight),
        labelSmall: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.neutral400),
      ),
    );
  }

  static ThemeData get dark {
    final baseTheme = ThemeData(brightness: Brightness.dark);
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      cardColor: AppColors.neutral900,
      dividerColor: AppColors.neutral800,
      colorScheme: const ColorScheme.dark(
        background: AppColors.pureBlack,
        surface: AppColors.neutral900,
        onBackground: AppColors.neutral50,
        onSurface: AppColors.textSecondaryDark,
        primary: AppColors.neutral50,
        error: AppColors.errorRed,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.neutral50),
        displayMedium: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.neutral50),
        titleLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.neutral50),
        titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.neutral50),
        bodyLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.neutral50),
        bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.neutral50),
        labelLarge: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondaryDark),
        labelSmall: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textSecondaryLight),
      ),
    );
  }
}
