import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ============================================
  // BRAND COLORS
  // ============================================
  static const Color brandPrimary = Color(0xFFEC3535);
  static const Color brandPrimaryLight = Color(0xFFFF6B6B);
  static const Color brandPrimaryDark = Color(0xFFD32F2F);
  static const Color brandSecondary = Color(0xFF7A1E1E);
  static const Color brandAccent = Color(0xFFFF8A80);

  // ============================================
  // NEUTRAL PALETTE - Refined slate scale
  // ============================================
  static const Color neutral50 = Color(0xFFF8FAFC);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);
  static const Color neutral950 = Color(0xFF020617);

  // ============================================
  // BACKGROUNDS
  // ============================================
  static const Color backgroundLight = Color(0xFFFAFAFB);
  static const Color backgroundDark = Color(0xFF0A0C10);

  // ============================================
  // SURFACES - Layered for depth
  // ============================================
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF12151A);

  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedDark = Color(0xFF1A1D23);

  static const Color surfaceContainerLight = Color(0xFFF5F6F8);
  static const Color surfaceContainerDark = Color(0xFF1F2329);

  // ============================================
  // TEXT COLORS
  // ============================================
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textTertiaryLight = Color(0xFF94A3B8);
  static const Color textDisabledLight = Color(0xFFCBD5E1);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color textTertiaryDark = Color(0xFF94A3B8);
  static const Color textDisabledDark = Color(0xFF475569);

  // ============================================
  // BORDERS & DIVIDERS
  // ============================================
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderSubtleLight = Color(0xFFF1F5F9);
  static const Color borderDark = Color(0xFF2A303A);
  static const Color borderSubtleDark = Color(0xFF1F242B);

  static const Color dividerLight = Color(0xFFE2E8F0);
  static const Color dividerDark = Color(0xFF2A303A);

  // ============================================
  // PRIMARY CONTAINERS
  // ============================================
  static const Color primaryContainerLight = Color(0xFFFEE2E2);
  static const Color primaryContainerDark = Color(0xFF3B1515);
  static const Color onPrimaryContainerLight = Color(0xFF991B1B);
  static const Color onPrimaryContainerDark = Color(0xFFFECACA);

  // ============================================
  // SEMANTIC COLORS
  // ============================================
  // Success
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color successDark = Color(0xFF059669);
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color onSuccessContainer = Color(0xFF065F46);

  // Warning
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningDark = Color(0xFFD97706);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color onWarningContainer = Color(0xFF92400E);

  // Error
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorDark = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onErrorContainer = Color(0xFF991B1B);

  // Info
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);
  static const Color infoDark = Color(0xFF2563EB);
  static const Color infoContainer = Color(0xFFDBEAFE);
  static const Color onInfoContainer = Color(0xFF1E40AF);

  // ============================================
  // SPORT-SPECIFIC COLORS
  // ============================================
  static const Color matchLive = Color(0xFFEF4444);
  static const Color matchUpcoming = Color(0xFF3B82F6);
  static const Color matchFinished = Color(0xFF10B981);
  static const Color scoreHighlight = Color(0xFFF59E0B);

  // Team position colors
  static const Color positionGold = Color(0xFFEAB308);
  static const Color positionSilver = Color(0xFF94A3B8);
  static const Color positionBronze = Color(0xFFD97706);
  static const Color positionPromotion = Color(0xFF10B981);
  static const Color positionRelegation = Color(0xFFEF4444);

  // ============================================
  // OVERLAY COLORS
  // ============================================
  static Color get overlayLight => Colors.black.withAlpha(10);
  static Color get overlayMedium => Colors.black.withAlpha(25);
  static Color get overlayDark => Colors.black.withAlpha(50);
  static Color get overlayHeavy => Colors.black.withAlpha(128);

  static Color get scrimLight => Colors.black.withAlpha(77);
  static Color get scrimDark => Colors.black.withAlpha(153);

  // ============================================
  // SHIMMER COLORS
  // ============================================
  static const Color shimmerBaseLight = Color(0xFFE2E8F0);
  static const Color shimmerHighlightLight = Color(0xFFF8FAFC);
  static const Color shimmerBaseDark = Color(0xFF1F242B);
  static const Color shimmerHighlightDark = Color(0xFF2A303A);

  // ============================================
  // HELPER METHODS
  // ============================================
  static Color adaptiveText(BuildContext context, {bool secondary = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (secondary) {
      return isDark ? textSecondaryDark : textSecondaryLight;
    }
    return isDark ? textPrimaryDark : textPrimaryLight;
  }

  static Color adaptiveSurface(BuildContext context, {bool elevated = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (elevated) {
      return isDark ? surfaceElevatedDark : surfaceElevatedLight;
    }
    return isDark ? surfaceDark : surfaceLight;
  }

  static Color adaptiveBorder(BuildContext context, {bool subtle = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (subtle) {
      return isDark ? borderSubtleDark : borderSubtleLight;
    }
    return isDark ? borderDark : borderLight;
  }
}
