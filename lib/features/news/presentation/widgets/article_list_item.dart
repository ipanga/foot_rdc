import 'package:flutter/material.dart';
import 'package:foot_rdc/features/news/domain/entities/article.dart';
import 'package:foot_rdc/core/theme/app_colors.dart';
import 'package:foot_rdc/core/theme/app_design_system.dart';
import 'package:foot_rdc/core/utils/date_utils.dart';
import 'package:foot_rdc/core/utils/string_utils.dart';

class ArticleListItem extends StatelessWidget {
  final Article article;
  final VoidCallback? onTap;

  const ArticleListItem({super.key, required this.article, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.space16,
        vertical: AppDesignSystem.space6,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppDesignSystem.borderRadiusXl,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: colorScheme.primary.withAlpha(20),
          highlightColor: colorScheme.primary.withAlpha(8),
          borderRadius: AppDesignSystem.borderRadiusXl,
          child: AnimatedContainer(
            duration: AppDesignSystem.durationFast,
            height: AppDesignSystem.articleCardHeight,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceElevatedDark
                  : AppColors.surfaceLight,
              borderRadius: AppDesignSystem.borderRadiusXl,
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
              boxShadow: isDark ? AppShadows.softDark : AppShadows.cardLight,
            ),
            child: Row(
              children: [
                // Thumbnail
                _buildThumbnail(context, isDark),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDesignSystem.space12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title
                        Expanded(
                          child: Text(
                            article.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),

                        const SizedBox(height: AppDesignSystem.space6),

                        // Meta info row
                        _buildMetaRow(context, isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;
    final category = formatCategory(article.category);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppDesignSystem.radiusXl),
        bottomLeft: Radius.circular(AppDesignSystem.radiusXl),
      ),
      child: SizedBox(
        width: 130,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            Image.network(
              article.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: isDark
                      ? AppColors.surfaceContainerDark
                      : AppColors.surfaceContainerLight,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary.withAlpha(128),
                      ),
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                color: isDark
                    ? AppColors.surfaceContainerDark
                    : AppColors.surfaceContainerLight,
                child: Icon(
                  Icons.image_outlined,
                  color: colorScheme.outline,
                  size: 32,
                ),
              ),
            ),

            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.black.withAlpha(100),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Category badge
            if (category.isNotEmpty)
              Positioned(
                left: AppDesignSystem.space8,
                bottom: AppDesignSystem.space8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.space8,
                    vertical: AppDesignSystem.space4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primaryContainerDark.withAlpha(230)
                        : AppColors.primaryContainerLight.withAlpha(240),
                    borderRadius: AppDesignSystem.borderRadiusSm,
                    border: Border.all(
                      color: colorScheme.primary.withAlpha(40),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    category.toUpperCase(),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.onPrimaryContainerDark
                          : AppColors.onPrimaryContainerLight,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(BuildContext context, bool isDark) {
    final textColor = isDark
        ? AppColors.textTertiaryDark
        : AppColors.textTertiaryLight;

    return Row(
      children: [
        Icon(
          Icons.schedule_rounded,
          size: AppDesignSystem.iconXs,
          color: textColor,
        ),
        const SizedBox(width: AppDesignSystem.space6),
        Flexible(
          child: Text(
            formatArticleDate(article.dateGmt),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Featured article card for hero sections
class ArticleFeaturedCard extends StatelessWidget {
  final Article article;
  final VoidCallback? onTap;
  final double height;

  const ArticleFeaturedCard({
    super.key,
    required this.article,
    this.onTap,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = formatCategory(article.category);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.space16,
        vertical: AppDesignSystem.space8,
      ),
      child: ClipRRect(
        borderRadius: AppDesignSystem.borderRadius2xl,
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              Image.network(
                article.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
              ),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withAlpha(220),
                      Colors.black.withAlpha(60),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),

              // Content
              Positioned(
                left: AppDesignSystem.space16,
                right: AppDesignSystem.space16,
                bottom: AppDesignSystem.space16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Category badge
                    if (category.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDesignSystem.space10,
                          vertical: AppDesignSystem.space4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: AppDesignSystem.borderRadiusSm,
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),

                    const SizedBox(height: AppDesignSystem.space10),

                    // Title
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        letterSpacing: -0.3,
                      ),
                    ),

                    const SizedBox(height: AppDesignSystem.space8),

                    // Date
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: Colors.white.withAlpha(180),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formatArticleDate(article.dateGmt),
                          style: TextStyle(
                            color: Colors.white.withAlpha(180),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tap handler
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
      ),
    );
  }
}
