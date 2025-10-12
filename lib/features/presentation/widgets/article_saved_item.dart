// Flutter framework imports
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Internal app imports
import 'package:foot_rdc/features/domain/entities/article.dart';
import 'package:foot_rdc/features/presentation/providers/article_provider.dart';
import 'package:foot_rdc/utils/date_utils.dart';

/// A reusable widget that displays a single saved article item.
///
/// This widget shows an article's image, title, formatted date, and provides
/// a delete action. It's designed to be used in lists and supports tap handling
/// for navigation to article details.
///
/// The widget displays:
/// - Article image (with loading and error states)
/// - Article title (max 2 lines with ellipsis)
/// - Formatted publish date
/// - Delete button with confirmation feedback
class ArticleSavedItem extends ConsumerWidget {
  /// The article data to display
  final Article article;

  /// Optional callback for when the item is tapped
  final VoidCallback? onTap;

  const ArticleSavedItem({super.key, required this.article, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final tileColor = Color.alphaBlend(
      (isDark ? Colors.white : Colors.black).withOpacity(0.04),
      colorScheme.surface,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 3, // subtle depth
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant.withOpacity(.6)),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(color: tileColor),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Article image section
                _buildArticleImage(context),
                const SizedBox(width: 12),
                // Article content section (title, date, actions)
                Expanded(child: _buildArticleContent(context, ref)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the article image with loading and error states
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
                // Show loading indicator while image loads
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: colorScheme.surfaceVariant,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                  );
                },
                // Show broken image icon on error
                errorBuilder: (context, error, stackTrace) => Container(
                  color: colorScheme.surfaceVariant,
                  child: Icon(
                    Icons.broken_image,
                    size: 36,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              Container(
                color: colorScheme.surfaceVariant,
                child: Icon(
                  Icons.image,
                  size: 36,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

            // Subtle gradient overlay for depth
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.18),
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

  /// Builds the article content (title, date) and actions (delete button)
  Widget _buildArticleContent(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and delete button row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article title
            Expanded(
              child: Text(
                article.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: .2,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Delete action button
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

  /// Builds the delete button with async delete handling
  Widget _buildDeleteButton(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.error.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          tooltip: 'Supprimer',
          icon: Icon(Icons.delete_outline, color: colorScheme.error),
          onPressed: () async {
            // Capture messenger before async operation to avoid context issues
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
