import 'package:flutter/material.dart';
import 'package:foot_rdc/core/theme/app_colors.dart';

class AppTextStyles {
  static const String fontFamily = 'Poppins';

  static TextTheme get lightTextTheme => TextTheme(
    displayLarge: const TextStyle(
      fontFamily: fontFamily,
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimaryLight,
      height: 1.2,
    ),
    displayMedium: const TextStyle(
      fontFamily: fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimaryLight,
      height: 1.2,
    ),
    displaySmall: const TextStyle(
      fontFamily: fontFamily,
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimaryLight,
      height: 1.2,
    ),
    headlineLarge: const TextStyle(
      fontFamily: fontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimaryLight,
    ),
    headlineMedium: const TextStyle(
      fontFamily: fontFamily,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryLight,
    ),
    headlineSmall: const TextStyle(
      fontFamily: fontFamily,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryLight,
    ),
    titleLarge: const TextStyle(
      fontFamily: fontFamily,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryLight,
    ),
    titleMedium: const TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryLight,
    ),
    titleSmall: const TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryLight,
    ),
    bodyLarge: const TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondaryLight,
      height: 1.5,
    ),
    bodyMedium: const TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondaryLight,
      height: 1.5,
    ),
    bodySmall: const TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.textTertiaryLight,
      height: 1.5,
    ),
    labelLarge: const TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryLight,
    ),
    labelMedium: const TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondaryLight,
    ),
    labelSmall: const TextStyle(
      fontFamily: fontFamily,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.textTertiaryLight,
      letterSpacing: 0.5,
    ),
  );

  static TextTheme get darkTextTheme => TextTheme(
    displayLarge: lightTextTheme.displayLarge?.copyWith(
      color: AppColors.textPrimaryDark,
    ),
    displayMedium: lightTextTheme.displayMedium?.copyWith(
      color: AppColors.textPrimaryDark,
    ),
    displaySmall: lightTextTheme.displaySmall?.copyWith(
      color: AppColors.textPrimaryDark,
    ),
    headlineLarge: lightTextTheme.headlineLarge?.copyWith(
      color: AppColors.textPrimaryDark,
    ),
    headlineMedium: lightTextTheme.headlineMedium?.copyWith(
      color: AppColors.textPrimaryDark,
    ),
    headlineSmall: lightTextTheme.headlineSmall?.copyWith(
      color: AppColors.textPrimaryDark,
    ),
    titleLarge: lightTextTheme.titleLarge?.copyWith(
      color: AppColors.textPrimaryDark,
    ),
    titleMedium: lightTextTheme.titleMedium?.copyWith(
      color: AppColors.textPrimaryDark,
    ),
    titleSmall: lightTextTheme.titleSmall?.copyWith(
      color: AppColors.textPrimaryDark,
    ),
    bodyLarge: lightTextTheme.bodyLarge?.copyWith(
      color: AppColors.textSecondaryDark,
    ),
    bodyMedium: lightTextTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondaryDark,
    ),
    bodySmall: lightTextTheme.bodySmall?.copyWith(
      color: AppColors.textTertiaryDark,
    ),
    labelLarge: lightTextTheme.labelLarge?.copyWith(
      color: AppColors.textPrimaryDark,
    ),
    labelMedium: lightTextTheme.labelMedium?.copyWith(
      color: AppColors.textSecondaryDark,
    ),
    labelSmall: lightTextTheme.labelSmall?.copyWith(
      color: AppColors.textTertiaryDark,
    ),
  );
}
