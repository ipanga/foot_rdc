import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/news/domain/entities/article.dart';
import 'package:foot_rdc/features/news/presentation/providers/article_provider.dart';
import 'package:foot_rdc/core/utils/date_utils.dart';

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
    final tileColor = Color.alphaBlend(
      (isDark ? Colors.white : Colors.black).withAlpha(10),
      colorScheme.surface,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant.withAlpha(153)),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(color: tileColor),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                _buildArticleImage(context),
                const SizedBox(width: 12),
                Expanded(child: _buildArticleContent(context, ref)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArticleImage(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 112,
        height: 84,
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
                    color: colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image,
                    size: 36,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              Container(
                color: colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.image,
                  size: 36,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

            // Subtle gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withAlpha(46),
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

  Widget _buildArticleContent(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                article.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildDeleteButton(context, ref),
          ],
        ),
        const SizedBox(height: 6),

        Row(
          children: [
            Icon(Icons.event, size: 16, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              formatArticleDate(article.dateGmt),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                letterSpacing: .3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeleteButton(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.error.withAlpha(20),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          tooltip: 'Supprimer',
          icon: Icon(Icons.delete_outline, color: colorScheme.error),
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);

            try {
              await ref
                  .read(articleSavedListNotifierProvider.notifier)
                  .removeArticle(article);

              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'Article supprimé',
                    style: TextStyle(
                      color: colorScheme.onError,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 2),
                  action: SnackBarAction(
                    label: 'OK',
                    textColor: colorScheme.onError,
                    onPressed: messenger.hideCurrentSnackBar,
                  ),
                ),
              );
            } catch (err) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'Échec de la suppression',
                    style: TextStyle(
                      color: colorScheme.onError,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  backgroundColor: colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 3),
                  action: SnackBarAction(
                    label: 'Fermer',
                    textColor: colorScheme.onError,
                    onPressed: messenger.hideCurrentSnackBar,
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
