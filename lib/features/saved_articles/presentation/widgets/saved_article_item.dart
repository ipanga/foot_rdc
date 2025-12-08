import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/news/domain/entities/article.dart';
import 'package:foot_rdc/features/news/presentation/providers/article_provider.dart';
import 'package:foot_rdc/core/utils/date_utils.dart';
import 'package:foot_rdc/core/utils/string_utils.dart';
import 'package:foot_rdc/core/theme/app_colors.dart';
import 'package:foot_rdc/core/theme/app_design_system.dart';
import 'package:foot_rdc/shared/widgets/app_snackbar.dart';

/// A reusable widget that displays a single saved article item.
class SavedArticleItem extends ConsumerWidget {
  final Article article;
  final VoidCallback? onTap;

  const SavedArticleItem({super.key, required this.article, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

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
                _buildArticleImage(context, isDark),
                const SizedBox(width: AppDesignSystem.space12),
                Expanded(child: _buildArticleContent(context, ref, isDark)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArticleImage(BuildContext context, bool isDark) {
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
            if (article.imageUrl.isNotEmpty)
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
                errorBuilder: (context, error, stackTrace) => Container(
                  color: isDark
                      ? AppColors.surfaceContainerDark
                      : AppColors.surfaceContainerLight,
                  child: Icon(
                    Icons.image_outlined,
                    size: 32,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
              )
            else
              Container(
                color: isDark
                    ? AppColors.surfaceContainerDark
                    : AppColors.surfaceContainerLight,
                child: Icon(
                  Icons.image_outlined,
                  size: 32,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
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

            // Bookmark indicator
            Positioned(
              left: AppDesignSystem.space8,
              bottom: AppDesignSystem.space8,
              child: Container(
                padding: const EdgeInsets.all(AppDesignSystem.space6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(230),
                  borderRadius: AppDesignSystem.borderRadiusSm,
                ),
                child: const Icon(
                  Icons.bookmark_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleContent(BuildContext context, WidgetRef ref, bool isDark) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppDesignSystem.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title with delete button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(width: AppDesignSystem.space8),
              _buildDeleteButton(context, ref, isDark),
            ],
          ),

          // Date row
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: AppDesignSystem.iconXs,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
              const SizedBox(width: AppDesignSystem.space6),
              Flexible(
                child: Text(
                  formatArticleDate(article.dateGmt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context, WidgetRef ref, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colorScheme.error.withAlpha(isDark ? 30 : 20),
          borderRadius: AppDesignSystem.borderRadiusSm,
        ),
        child: IconButton(
          tooltip: 'Supprimer',
          padding: EdgeInsets.zero,
          iconSize: 20,
          icon: Icon(
            Icons.delete_outline_rounded,
            color: colorScheme.error,
          ),
          onPressed: () async {
            try {
              await ref
                  .read(articleSavedListNotifierProvider.notifier)
                  .removeArticle(article);

              if (context.mounted) {
                AppSnackbar.showSuccess(
                  context,
                  message: 'Article supprimé',
                  icon: Icons.delete_outline_rounded,
                );
              }
            } catch (err) {
              if (context.mounted) {
                AppSnackbar.showError(
                  context,
                  message: 'Échec de la suppression',
                );
              }
            }
          },
        ),
      ),
    );
  }
}
