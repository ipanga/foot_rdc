import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:foot_rdc/core/theme/app_colors.dart';
import 'package:foot_rdc/core/theme/app_design_system.dart';

/// A premium, modern bottom navigation bar with Material 3 design.
/// Features smooth animations, glassmorphism effect, and pill-shaped indicators.
class PremiumBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<PremiumNavItem> items;
  final bool enableHaptics;
  final bool showLabels;
  final double height;
  final double iconSize;

  const PremiumBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.enableHaptics = true,
    this.showLabels = true,
    this.height = 70,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        // Subtle gradient background
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  AppColors.surfaceDark.withAlpha(245),
                  AppColors.surfaceDark,
                ]
              : [
                  AppColors.surfaceLight.withAlpha(250),
                  AppColors.surfaceLight,
                ],
        ),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(60)
                : Colors.black.withAlpha(15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: height,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                  items.length,
                  (index) => Expanded(
                    child: _NavItemWidget(
                      item: items[index],
                      isSelected: currentIndex == index,
                      onTap: () {
                        if (enableHaptics) {
                          HapticFeedback.selectionClick();
                        }
                        onTap(index);
                      },
                      iconSize: iconSize,
                      showLabel: showLabels,
                      colorScheme: colorScheme,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Data class for navigation items
class PremiumNavItem {
  final String iconPath;
  final String activeIconPath;
  final String label;
  final IconData? iconData;
  final IconData? activeIconData;

  const PremiumNavItem({
    this.iconPath = '',
    this.activeIconPath = '',
    required this.label,
    this.iconData,
    this.activeIconData,
  });

  /// Create from SVG asset paths
  const PremiumNavItem.svg({
    required this.iconPath,
    required this.activeIconPath,
    required this.label,
  })  : iconData = null,
        activeIconData = null;

  /// Create from IconData
  const PremiumNavItem.icon({
    required IconData icon,
    required IconData activeIcon,
    required this.label,
  })  : iconData = icon,
        activeIconData = activeIcon,
        iconPath = '',
        activeIconPath = '';
}

/// Individual navigation item widget with animations
class _NavItemWidget extends StatefulWidget {
  final PremiumNavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final double iconSize;
  final bool showLabel;
  final ColorScheme colorScheme;
  final bool isDark;

  const _NavItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.iconSize,
    required this.showLabel,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  State<_NavItemWidget> createState() => _NavItemWidgetState();
}

class _NavItemWidgetState extends State<_NavItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppDesignSystem.durationFast,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = widget.colorScheme.primary;
    final unselectedColor = widget.isDark
        ? AppColors.textTertiaryDark
        : AppColors.textTertiaryLight;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesignSystem.space4,
            vertical: AppDesignSystem.space8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with pill background when selected
              AnimatedContainer(
                duration: AppDesignSystem.durationNormal,
                curve: AppDesignSystem.curveEmphasized,
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isSelected
                      ? AppDesignSystem.space16
                      : AppDesignSystem.space12,
                  vertical: AppDesignSystem.space6,
                ),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? selectedColor.withAlpha(widget.isDark ? 35 : 25)
                      : Colors.transparent,
                  borderRadius: AppDesignSystem.borderRadiusFull,
                ),
                child: _buildIcon(selectedColor, unselectedColor),
              ),

              if (widget.showLabel) ...[
                const SizedBox(height: AppDesignSystem.space4),
                // Label
                AnimatedDefaultTextStyle(
                  duration: AppDesignSystem.durationFast,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: widget.isSelected ? selectedColor : unselectedColor,
                    letterSpacing: widget.isSelected ? 0.2 : 0,
                  ),
                  child: Text(
                    widget.item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(Color selectedColor, Color unselectedColor) {
    final color = widget.isSelected ? selectedColor : unselectedColor;

    // If using IconData
    if (widget.item.iconData != null) {
      return AnimatedSwitcher(
        duration: AppDesignSystem.durationFast,
        child: Icon(
          widget.isSelected
              ? (widget.item.activeIconData ?? widget.item.iconData)
              : widget.item.iconData,
          key: ValueKey(widget.isSelected),
          size: widget.iconSize,
          color: color,
        ),
      );
    }

    // If using SVG paths
    final iconPath =
        widget.isSelected ? widget.item.activeIconPath : widget.item.iconPath;

    return AnimatedSwitcher(
      duration: AppDesignSystem.durationFast,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: SvgPicture.asset(
        iconPath,
        key: ValueKey(iconPath),
        height: widget.iconSize,
        width: widget.iconSize,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}

/// A floating variant of the bottom navigation bar
class FloatingBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<PremiumNavItem> items;
  final bool enableHaptics;
  final double iconSize;
  final double horizontalMargin;
  final double bottomMargin;

  const FloatingBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.enableHaptics = true,
    this.iconSize = 24,
    this.horizontalMargin = 16,
    this.bottomMargin = 16,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: horizontalMargin,
        right: horizontalMargin,
        bottom: bottomMargin + MediaQuery.of(context).padding.bottom,
      ),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceElevatedDark.withAlpha(240)
              : AppColors.surfaceLight.withAlpha(245),
          borderRadius: AppDesignSystem.borderRadiusXl,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withAlpha(80)
                  : Colors.black.withAlpha(20),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: colorScheme.primary.withAlpha(isDark ? 15 : 10),
              blurRadius: 40,
              spreadRadius: -5,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppDesignSystem.borderRadiusXl,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                items.length,
                (index) => _FloatingNavItem(
                  item: items[index],
                  isSelected: currentIndex == index,
                  onTap: () {
                    if (enableHaptics) {
                      HapticFeedback.selectionClick();
                    }
                    onTap(index);
                  },
                  iconSize: iconSize,
                  colorScheme: colorScheme,
                  isDark: isDark,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating nav bar item (icon only, no label)
class _FloatingNavItem extends StatefulWidget {
  final PremiumNavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final double iconSize;
  final ColorScheme colorScheme;
  final bool isDark;

  const _FloatingNavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.iconSize,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  State<_FloatingNavItem> createState() => _FloatingNavItemState();
}

class _FloatingNavItemState extends State<_FloatingNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = widget.colorScheme.primary;
    final unselectedColor = widget.isDark
        ? AppColors.textTertiaryDark
        : AppColors.textTertiaryLight;
    final color = widget.isSelected ? selectedColor : unselectedColor;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: AppDesignSystem.durationNormal,
          curve: AppDesignSystem.curveEmphasized,
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? selectedColor.withAlpha(widget.isDark ? 40 : 25)
                : Colors.transparent,
            borderRadius: AppDesignSystem.borderRadiusLg,
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: AppDesignSystem.durationFast,
              child: widget.item.iconData != null
                  ? Icon(
                      widget.isSelected
                          ? (widget.item.activeIconData ?? widget.item.iconData)
                          : widget.item.iconData,
                      key: ValueKey(widget.isSelected),
                      size: widget.iconSize,
                      color: color,
                    )
                  : SvgPicture.asset(
                      widget.isSelected
                          ? widget.item.activeIconPath
                          : widget.item.iconPath,
                      key: ValueKey(widget.isSelected),
                      height: widget.iconSize,
                      width: widget.iconSize,
                      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
