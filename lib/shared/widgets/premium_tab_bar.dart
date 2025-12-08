import 'package:flutter/material.dart';
import 'package:foot_rdc/core/theme/app_colors.dart';
import 'package:foot_rdc/core/theme/app_design_system.dart';

/// A premium, modern tab bar with pill-style indicators and smooth animations.
/// Follows Material 3 design principles with excellent light/dark theme support.
class PremiumTabBar extends StatelessWidget {
  final TabController controller;
  final List<PremiumTabItem> tabs;
  final void Function(int)? onTap;
  final double height;
  final EdgeInsetsGeometry? margin;

  const PremiumTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.onTap,
    this.height = 48,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Container(
      margin: margin ??
          const EdgeInsets.symmetric(
            horizontal: AppDesignSystem.space12,
            vertical: AppDesignSystem.space8,
          ),
      padding: const EdgeInsets.all(AppDesignSystem.space4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceContainerLight,
        borderRadius: AppDesignSystem.borderRadiusLg,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: controller,
        onTap: onTap,
        indicator: _PremiumTabIndicator(
          color: colorScheme.primary,
          radius: AppDesignSystem.radiusMd,
          isDark: isDark,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor:
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          fontFamily: 'Oswald',
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
          fontFamily: 'Oswald',
          letterSpacing: 0.3,
        ),
        labelPadding: const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.space4,
        ),
        splashFactory: InkSparkle.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return colorScheme.primary.withAlpha(20);
          }
          if (states.contains(WidgetState.hovered)) {
            return colorScheme.primary.withAlpha(10);
          }
          return Colors.transparent;
        }),
        tabs: tabs
            .map((tab) => _PremiumTab(
                  icon: tab.icon,
                  label: tab.label,
                  height: height,
                ))
            .toList(),
      ),
    );
  }
}

/// Data class for tab items
class PremiumTabItem {
  final IconData? icon;
  final String label;

  const PremiumTabItem({
    this.icon,
    required this.label,
  });
}

/// Individual tab widget with optional icon and label
class _PremiumTab extends StatelessWidget {
  final IconData? icon;
  final String label;
  final double height;

  const _PremiumTab({
    this.icon,
    required this.label,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: height,
      child: icon != null
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16),
                const SizedBox(width: AppDesignSystem.space6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            )
          : Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
    );
  }
}

/// Custom decoration for the tab indicator with gradient and shadow
class _PremiumTabIndicator extends Decoration {
  final Color color;
  final double radius;
  final bool isDark;

  const _PremiumTabIndicator({
    required this.color,
    required this.radius,
    required this.isDark,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _PremiumTabIndicatorPainter(
      color: color,
      radius: radius,
      isDark: isDark,
    );
  }
}

class _PremiumTabIndicatorPainter extends BoxPainter {
  final Color color;
  final double radius;
  final bool isDark;

  _PremiumTabIndicatorPainter({
    required this.color,
    required this.radius,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final rect = offset & configuration.size!;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // Draw shadow
    final shadowPaint = Paint()
      ..color = color.withAlpha(isDark ? 80 : 50)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(rrect.shift(const Offset(0, 2)), shadowPaint);

    // Draw gradient background
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color,
        Color.lerp(color, Colors.black, 0.15)!,
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rrect, paint);

    // Draw subtle top highlight for 3D effect
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withAlpha(40),
          Colors.white.withAlpha(0),
        ],
        stops: const [0.0, 0.5],
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    final highlightRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.5),
      Radius.circular(radius),
    );
    canvas.drawRRect(highlightRRect, highlightPaint);
  }
}

/// Animated tab bar that smoothly transitions between states
class AnimatedPremiumTabBar extends StatefulWidget {
  final TabController controller;
  final List<PremiumTabItem> tabs;
  final void Function(int)? onTap;
  final double height;
  final EdgeInsetsGeometry? margin;

  const AnimatedPremiumTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.onTap,
    this.height = 44,
    this.margin,
  });

  @override
  State<AnimatedPremiumTabBar> createState() => _AnimatedPremiumTabBarState();
}

class _AnimatedPremiumTabBarState extends State<AnimatedPremiumTabBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          margin: widget.margin ??
              const EdgeInsets.symmetric(
                horizontal: AppDesignSystem.space12,
                vertical: AppDesignSystem.space8,
              ),
          padding: const EdgeInsets.all(AppDesignSystem.space4),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceContainerDark
                : AppColors.surfaceContainerLight,
            borderRadius: AppDesignSystem.borderRadiusLg,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 20 : 8),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: widget.controller,
            onTap: widget.onTap,
            indicator: _AnimatedPremiumTabIndicator(
              color: colorScheme.primary,
              radius: AppDesignSystem.radiusMd,
              isDark: isDark,
              glowIntensity: _glowAnimation.value,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              fontFamily: 'Oswald',
              letterSpacing: 0.5,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              fontFamily: 'Oswald',
              letterSpacing: 0.3,
            ),
            labelPadding: const EdgeInsets.symmetric(
              horizontal: AppDesignSystem.space4,
            ),
            splashFactory: InkSparkle.splashFactory,
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return colorScheme.primary.withAlpha(20);
              }
              if (states.contains(WidgetState.hovered)) {
                return colorScheme.primary.withAlpha(10);
              }
              return Colors.transparent;
            }),
            tabs: widget.tabs
                .map((tab) => _PremiumTab(
                      icon: tab.icon,
                      label: tab.label,
                      height: widget.height,
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}

/// Animated indicator with subtle glow effect
class _AnimatedPremiumTabIndicator extends Decoration {
  final Color color;
  final double radius;
  final bool isDark;
  final double glowIntensity;

  const _AnimatedPremiumTabIndicator({
    required this.color,
    required this.radius,
    required this.isDark,
    required this.glowIntensity,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _AnimatedPremiumTabIndicatorPainter(
      color: color,
      radius: radius,
      isDark: isDark,
      glowIntensity: glowIntensity,
    );
  }
}

class _AnimatedPremiumTabIndicatorPainter extends BoxPainter {
  final Color color;
  final double radius;
  final bool isDark;
  final double glowIntensity;

  _AnimatedPremiumTabIndicatorPainter({
    required this.color,
    required this.radius,
    required this.isDark,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final rect = offset & configuration.size!;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // Draw animated glow shadow
    final glowAlpha = ((isDark ? 80 : 50) * glowIntensity).toInt();
    final shadowPaint = Paint()
      ..color = color.withAlpha(glowAlpha)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * glowIntensity);
    canvas.drawRRect(rrect.shift(const Offset(0, 2)), shadowPaint);

    // Draw gradient background
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color,
        Color.lerp(color, Colors.black, 0.15)!,
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rrect, paint);

    // Draw subtle top highlight for 3D effect
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withAlpha((40 * glowIntensity).toInt()),
          Colors.white.withAlpha(0),
        ],
        stops: const [0.0, 0.5],
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    final highlightRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.5),
      Radius.circular(radius),
    );
    canvas.drawRRect(highlightRRect, highlightPaint);
  }
}
