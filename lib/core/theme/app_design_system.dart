import 'package:flutter/material.dart';

/// Design System Constants for consistent UI across the app
class AppDesignSystem {
  AppDesignSystem._();

  // ============================================
  // SPACING - Based on 4pt grid system
  // ============================================
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space14 = 14.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space28 = 28.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space56 = 56.0;
  static const double space64 = 64.0;

  // ============================================
  // BORDER RADIUS
  // ============================================
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radius2xl = 24.0;
  static const double radius3xl = 28.0;
  static const double radiusFull = 999.0;

  static BorderRadius get borderRadiusXs => BorderRadius.circular(radiusXs);
  static BorderRadius get borderRadiusSm => BorderRadius.circular(radiusSm);
  static BorderRadius get borderRadiusMd => BorderRadius.circular(radiusMd);
  static BorderRadius get borderRadiusLg => BorderRadius.circular(radiusLg);
  static BorderRadius get borderRadiusXl => BorderRadius.circular(radiusXl);
  static BorderRadius get borderRadius2xl => BorderRadius.circular(radius2xl);
  static BorderRadius get borderRadius3xl => BorderRadius.circular(radius3xl);
  static BorderRadius get borderRadiusFull => BorderRadius.circular(radiusFull);

  // ============================================
  // ANIMATION DURATIONS
  // ============================================
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 350);
  static const Duration durationVerySlow = Duration(milliseconds: 500);

  // ============================================
  // ANIMATION CURVES
  // ============================================
  static const Curve curveDefault = Curves.easeInOut;
  static const Curve curveEmphasized = Curves.easeOutCubic;
  static const Curve curveDecelerate = Curves.decelerate;
  static const Curve curveBounce = Curves.elasticOut;
  static const Curve curveSnappy = Curves.easeOutBack;

  // ============================================
  // ICON SIZES
  // ============================================
  static const double iconXs = 14.0;
  static const double iconSm = 18.0;
  static const double iconMd = 22.0;
  static const double iconLg = 26.0;
  static const double iconXl = 32.0;
  static const double icon2xl = 40.0;
  static const double icon3xl = 48.0;

  // ============================================
  // COMPONENT HEIGHTS
  // ============================================
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 44.0;
  static const double buttonHeightLg = 52.0;
  static const double inputHeight = 52.0;
  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 64.0;
  static const double tabBarHeight = 48.0;

  // ============================================
  // CARD DIMENSIONS
  // ============================================
  static const double cardMinHeight = 80.0;
  static const double articleCardHeight = 110.0;
  static const double matchCardHeight = 100.0;
  static const double featuredCardHeight = 200.0;

  // ============================================
  // IMAGE SIZES
  // ============================================
  static const double avatarXs = 24.0;
  static const double avatarSm = 32.0;
  static const double avatarMd = 40.0;
  static const double avatarLg = 56.0;
  static const double avatarXl = 72.0;

  static const double thumbnailSm = 60.0;
  static const double thumbnailMd = 80.0;
  static const double thumbnailLg = 120.0;
}

/// Shadow definitions for elevation effects
class AppShadows {
  AppShadows._();

  // Light Theme Shadows
  static List<BoxShadow> get softLight => [
        BoxShadow(
          color: Colors.black.withAlpha(8),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get cardLight => [
        BoxShadow(
          color: Colors.black.withAlpha(10),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withAlpha(5),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get elevatedLight => [
        BoxShadow(
          color: Colors.black.withAlpha(15),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withAlpha(8),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get floatingLight => [
        BoxShadow(
          color: Colors.black.withAlpha(20),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];

  // Dark Theme Shadows
  static List<BoxShadow> get softDark => [
        BoxShadow(
          color: Colors.black.withAlpha(30),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get cardDark => [
        BoxShadow(
          color: Colors.black.withAlpha(40),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevatedDark => [
        BoxShadow(
          color: Colors.black.withAlpha(50),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  // Primary Color Glow
  static List<BoxShadow> primaryGlow(Color primary) => [
        BoxShadow(
          color: primary.withAlpha(40),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}

/// Gradient definitions
class AppGradients {
  AppGradients._();

  static LinearGradient get primaryLight => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFEC3535),
          Color(0xFFD32F2F),
        ],
      );

  static LinearGradient get primaryDark => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFEF5350),
          Color(0xFFEC3535),
        ],
      );

  static LinearGradient shimmer(bool isDark) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                const Color(0xFF1F242B),
                const Color(0xFF2A2F36),
                const Color(0xFF1F242B),
              ]
            : [
                const Color(0xFFF1F5F9),
                const Color(0xFFE2E8F0),
                const Color(0xFFF1F5F9),
              ],
      );

  static LinearGradient imageOverlay({bool fromBottom = true}) => LinearGradient(
        begin: fromBottom ? Alignment.bottomCenter : Alignment.topCenter,
        end: fromBottom ? Alignment.topCenter : Alignment.bottomCenter,
        colors: [
          Colors.black.withAlpha(180),
          Colors.black.withAlpha(60),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      );

  static LinearGradient cardHighlight(Color primary) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary.withAlpha(25),
          primary.withAlpha(8),
        ],
      );
}
