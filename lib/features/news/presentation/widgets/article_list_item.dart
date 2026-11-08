import 'package:flutter/material.dart';
import 'package:foot_rdc/shared/widgets/category_label.dart';
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
            // Grows with system text size, so a title is never cut through a line.
            height: MediaQuery.textScalerOf(context).scale(AppDesignSystem.articleCardHeight),
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
                            decodeHtmlEntities(article.title),
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

          ],
        ),
      ),
    );
  }

  /// « RDC · 10:45 »: the category as a kicker in the date's colour, then the time.
  Widget _buildMetaRow(BuildContext context, bool isDark) {
    final textColor = isDark
        ? AppColors.textTertiaryDark
        : AppColors.textTertiaryLight;
    final category = formatCategory(article.category);
    final date = Text(
      formatArticleDate(article.dateGmt),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: textColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );

    return Row(
      children: [
        if (category.isNotEmpty) ...[
          Flexible(child: CategoryLabel(category, fontSize: 10.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDesignSystem.space6),
            child: Text('·', style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
        Flexible(child: date),
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
                    if (category.isNotEmpty)
                      CategoryLabel(category, color: Colors.white.withAlpha(180)),
                    const SizedBox(height: AppDesignSystem.space10),

                    // Title
                    Text(
                      decodeHtmlEntities(article.title),
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
