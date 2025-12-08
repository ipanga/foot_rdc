import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:foot_rdc/core/theme/app_colors.dart';
import 'package:foot_rdc/core/theme/app_design_system.dart';

/// A modern, premium AppBar widget for the news section.
/// Features Material 3 design with smooth animations and scroll effects.
class NewsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onNotificationPressed;
  final bool showSearch;
  final bool showNotification;
  final int? notificationCount;
  final Widget? trailing;

  const NewsAppBar({
    super.key,
    this.onMenuPressed,
    this.onSearchPressed,
    this.onNotificationPressed,
    this.showSearch = true,
    this.showNotification = false,
    this.notificationCount,
    this.trailing,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    // Set status bar style based on theme
    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.borderSubtleDark
                : AppColors.borderSubtleLight,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesignSystem.space12,
            vertical: AppDesignSystem.space8,
          ),
          child: Row(
            children: [
              // Menu Button
              _AppBarIconButton(
                icon: SvgPicture.asset(
                  'assets/images/menu-icon.svg',
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    BlendMode.srcIn,
                  ),
                ),
                onPressed: onMenuPressed ??
                    () => Scaffold.of(context).openDrawer(),
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
                isDark: isDark,
              ),

              const SizedBox(width: AppDesignSystem.space8),

              // Logo and Title - Centered
              Expanded(
                child: _LogoTitle(
                  isDark: isDark,
                  colorScheme: colorScheme,
                ),
              ),

              const SizedBox(width: AppDesignSystem.space8),

              // Trailing Actions
              if (trailing != null)
                trailing!
              else if (showSearch)
                _AppBarIconButton(
                  icon: Icon(
                    Icons.search_rounded,
                    size: 22,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  onPressed: onSearchPressed,
                  tooltip: 'Rechercher',
                  isDark: isDark,
                )
              else if (showNotification)
                _NotificationButton(
                  onPressed: onNotificationPressed,
                  count: notificationCount,
                  isDark: isDark,
                )
              else
                const SizedBox(width: 40), // Spacer for balance
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated logo and title section
class _LogoTitle extends StatelessWidget {
  final bool isDark;
  final ColorScheme colorScheme;

  const _LogoTitle({
    required this.isDark,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo - clean without shadow
          Image.asset(
            'assets/images/logo_splash_footrdc.png',
            height: 38,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: AppDesignSystem.space8),
          // Title with gradient effect
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                colorScheme.primary,
                Color.lerp(colorScheme.primary, Colors.orange, 0.3)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: const Text(
              'FOOTRDC',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable icon button with consistent styling
class _AppBarIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool isDark;

  const _AppBarIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppDesignSystem.borderRadiusMd,
          splashColor: Theme.of(context).colorScheme.primary.withAlpha(30),
          highlightColor: Theme.of(context).colorScheme.primary.withAlpha(15),
          child: AnimatedContainer(
            duration: AppDesignSystem.durationFast,
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceContainerDark
                  : AppColors.surfaceContainerLight,
              borderRadius: AppDesignSystem.borderRadiusMd,
              border: Border.all(
                color: isDark
                    ? AppColors.borderSubtleDark
                    : AppColors.borderSubtleLight,
                width: 0.5,
              ),
            ),
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }
}

/// Notification button with badge
class _NotificationButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final int? count;
  final bool isDark;

  const _NotificationButton({
    this.onPressed,
    this.count,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        _AppBarIconButton(
          icon: Icon(
            Icons.notifications_outlined,
            size: 22,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
          onPressed: onPressed,
          tooltip: 'Notifications',
          isDark: isDark,
        ),
        if (count != null && count! > 0)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.error,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight,
                  width: 1.5,
                ),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                count! > 9 ? '9+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

/// A SliverAppBar variant for scroll-aware behavior
class NewsSliverAppBar extends StatelessWidget {
  final VoidCallback? onMenuPressed;
  final VoidCallback? onSearchPressed;
  final bool floating;
  final bool pinned;
  final bool snap;

  const NewsSliverAppBar({
    super.key,
    this.onMenuPressed,
    this.onSearchPressed,
    this.floating = true,
    this.pinned = false,
    this.snap = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      floating: floating,
      pinned: pinned,
      snap: snap,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: isDark ? Colors.black54 : Colors.black12,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppDesignSystem.space8),
        child: Center(
          child: _AppBarIconButton(
            icon: SvgPicture.asset(
              'assets/images/menu-icon.svg',
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                BlendMode.srcIn,
              ),
            ),
            onPressed: onMenuPressed ?? () => Scaffold.of(context).openDrawer(),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            isDark: isDark,
          ),
        ),
      ),
      centerTitle: true,
      title: _LogoTitle(
        isDark: isDark,
        colorScheme: colorScheme,
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppDesignSystem.space8),
          child: _AppBarIconButton(
            icon: Icon(
              Icons.search_rounded,
              size: 22,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
            onPressed: onSearchPressed,
            tooltip: 'Rechercher',
            isDark: isDark,
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 0.5,
          color: isDark
              ? AppColors.borderSubtleDark
              : AppColors.borderSubtleLight,
        ),
      ),
    );
  }
}
