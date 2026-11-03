import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:foot_rdc/core/theme/app_colors.dart';
import 'package:foot_rdc/core/theme/app_design_system.dart';

/// The app's bottom tabs: icon in a pill when selected, label always shown, announced as a selected tab.
/// Labels keep readable contrast in light and dark, and shrink rather than wrap at large text sizes.
class PremiumBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<PremiumNavItem> items;
  final bool enableHaptics;

  const PremiumBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.enableHaptics = true,
  });

  static const barHeight = 64.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: barHeight,
          child: Row(
            children: [
              for (final (index, item) in items.indexed)
                Expanded(
                  child: _NavItem(
                    item: item,
                    selected: index == currentIndex,
                    position: (index + 1, items.length),
                    onTap: () {
                      if (enableHaptics && index != currentIndex) HapticFeedback.selectionClick();
                      onTap(index);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PremiumNavItem {
  final String iconPath;
  final String activeIconPath;
  final String label;
  final IconData? iconData;
  final IconData? activeIconData;

  const PremiumNavItem.svg({required this.iconPath, required this.activeIconPath, required this.label})
    : iconData = null,
      activeIconData = null;

  const PremiumNavItem.icon({required IconData icon, required IconData activeIcon, required this.label})
    : iconData = icon,
      activeIconData = activeIcon,
      iconPath = '',
      activeIconPath = '';
}

class _NavItem extends StatelessWidget {
  final PremiumNavItem item;
  final bool selected;
  final (int, int) position;
  final VoidCallback onTap;
  const _NavItem({required this.item, required this.selected, required this.position, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Brand red at a shade that keeps 4.5:1 text contrast on the bar (the main brand red is 4.1:1 on white).
    final active = isDark ? AppColors.brandPrimaryLight : AppColors.brandPrimaryDark;
    final idle = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final color = selected ? active : idle;
    final icon = item.iconData != null
        ? Icon(selected ? (item.activeIconData ?? item.iconData) : item.iconData, size: 24, color: color)
        : SvgPicture.asset(
            selected ? item.activeIconPath : item.iconPath,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          );
    final (index, count) = position;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      hint: 'Onglet $index sur $count',
      excludeSemantics: true,
      onTap: onTap,
      child: InkResponse(
        onTap: onTap,
        containedInkWell: true,
        highlightShape: BoxShape.rectangle,
        splashColor: active.withAlpha(30),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: AppDesignSystem.durationNormal,
              curve: Curves.easeOutCubic,
              width: selected ? 56 : 40,
              height: 30,
              decoration: BoxDecoration(
                color: selected ? active.withAlpha(isDark ? 46 : 28) : Colors.transparent,
                borderRadius: AppDesignSystem.borderRadiusFull,
              ),
              alignment: Alignment.center,
              child: icon,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              // Up to 1.3× system text; beyond that the label shrinks to its slot instead of wrapping.
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.1,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
