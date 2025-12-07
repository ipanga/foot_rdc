import 'package:flutter/material.dart';
import 'package:foot_rdc/core/theme/app_colors.dart';
import 'package:foot_rdc/core/theme/app_design_system.dart';

/// Modern card component with consistent styling
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final bool showBorder;
  final Gradient? gradient;
  final double? width;
  final double? height;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.boxShadow,
    this.onTap,
    this.showBorder = true,
    this.gradient,
    this.width,
    this.height,
  });

  /// Elevated card with shadow
  const AppCard.elevated({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.onTap,
    this.width,
    this.height,
  })  : showBorder = false,
        borderColor = null,
        boxShadow = null,
        gradient = null;

  /// Outlined card with border only
  const AppCard.outlined({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
    this.width,
    this.height,
  })  : showBorder = true,
        boxShadow = const [],
        gradient = null;

  /// Gradient highlight card
  factory AppCard.gradient({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? borderRadius,
    required Color primaryColor,
    VoidCallback? onTap,
    double? width,
    double? height,
  }) {
    return AppCard(
      key: key,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      onTap: onTap,
      showBorder: true,
      gradient: AppGradients.cardHighlight(primaryColor),
      width: width,
      height: height,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = borderRadius ?? AppDesignSystem.radiusLg;

    final effectiveBackgroundColor = backgroundColor ??
        (isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight);

    final effectiveBorderColor = borderColor ??
        (isDark ? AppColors.borderDark : AppColors.borderLight);

    final effectiveShadow = boxShadow ??
        (isDark ? AppShadows.cardDark : AppShadows.cardLight);

    Widget cardContent = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(AppDesignSystem.space16),
      decoration: BoxDecoration(
        color: gradient == null ? effectiveBackgroundColor : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: showBorder
            ? Border.all(color: effectiveBorderColor, width: 1)
            : null,
        boxShadow: effectiveShadow,
      ),
      child: child,
    );

    if (margin != null) {
      cardContent = Padding(padding: margin!, child: cardContent);
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

/// Image card with overlay text
class ImageCard extends StatelessWidget {
  final String imageUrl;
  final Widget? overlayContent;
  final double height;
  final double? width;
  final double borderRadius;
  final VoidCallback? onTap;
  final BoxFit imageFit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool showGradientOverlay;

  const ImageCard({
    super.key,
    required this.imageUrl,
    this.overlayContent,
    this.height = 200,
    this.width,
    this.borderRadius = AppDesignSystem.radiusXl,
    this.onTap,
    this.imageFit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.showGradientOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        width: width ?? double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            Image.network(
              imageUrl,
              fit: imageFit,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return placeholder ??
                    Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                        ),
                      ),
                    );
              },
              errorBuilder: (context, error, stackTrace) =>
                  errorWidget ??
                  Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: theme.colorScheme.outline,
                      size: 40,
                    ),
                  ),
            ),

            // Gradient overlay
            if (showGradientOverlay)
              Container(
                decoration: BoxDecoration(
                  gradient: AppGradients.imageOverlay(),
                ),
              ),

            // Overlay content
            if (overlayContent != null)
              Positioned.fill(child: overlayContent!),

            // Tap handler
            if (onTap != null)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    splashColor: theme.colorScheme.primary.withAlpha(30),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Status badge/chip
class StatusBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool isSmall;

  const StatusBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.isSmall = false,
  });

  /// Live match indicator
  const StatusBadge.live({
    super.key,
    this.label = 'LIVE',
    this.icon = Icons.circle,
  })  : backgroundColor = AppColors.matchLive,
        textColor = Colors.white,
        isSmall = false;

  /// Finished match indicator
  const StatusBadge.finished({
    super.key,
    this.label = 'FT',
  })  : backgroundColor = AppColors.matchFinished,
        textColor = Colors.white,
        icon = Icons.check_circle_outline,
        isSmall = false;

  /// Upcoming match indicator
  const StatusBadge.upcoming({
    super.key,
    this.label = 'A venir',
  })  : backgroundColor = AppColors.matchUpcoming,
        textColor = Colors.white,
        icon = Icons.schedule,
        isSmall = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = backgroundColor ??
        (isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceContainerLight);
    final fgColor = textColor ?? theme.colorScheme.onSurface;

    final horizontalPadding = isSmall ? 6.0 : 10.0;
    final verticalPadding = isSmall ? 3.0 : 5.0;
    final fontSize = isSmall ? 10.0 : 11.0;
    final iconSize = isSmall ? 10.0 : 12.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: fgColor),
            SizedBox(width: isSmall ? 3 : 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: fgColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Category tag
class CategoryTag extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const CategoryTag({
    super.key,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.space10,
          vertical: AppDesignSystem.space4,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.primaryContainerDark
              : AppColors.primaryContainerLight,
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isDark
                ? AppColors.onPrimaryContainerDark
                : AppColors.onPrimaryContainerLight,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
