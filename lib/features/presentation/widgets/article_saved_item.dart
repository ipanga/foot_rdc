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
    return GestureDetector(
      // Handle tap events (e.g., navigation to details)
      onTap: onTap,
      child: Card(
        // Card styling with rounded corners and elevation
        color: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Article image section
              _buildArticleImage(),
              const SizedBox(width: 12),

              // Article content section (title, date, actions)
              Expanded(child: _buildArticleContent(context, ref)),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the article image with loading and error states
  Widget _buildArticleImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 96,
        height: 72,
        child: article.imageUrl.isNotEmpty
            ? Image.network(
                article.imageUrl,
                fit: BoxFit.cover,
                // Show loading indicator while image loads
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                // Show broken image icon on error
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.broken_image,
                    size: 36,
                    color: Colors.grey,
                  ),
                ),
              )
            // Show placeholder when no image URL
            : Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image, size: 36, color: Colors.grey),
              ),
      ),
    );
  }

  /// Builds the article content (title, date) and actions (delete button)
  Widget _buildArticleContent(BuildContext context, WidgetRef ref) {
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
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),

            // Delete action button
            _buildDeleteButton(context, ref),
          ],
        ),
        const SizedBox(height: 6),

        // Formatted publication date
        Text(
          formatArticleDate(article.dateGmt), // Uses project's date utility
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Builds the delete button with async delete handling
  Widget _buildDeleteButton(BuildContext context, WidgetRef ref) {
    return Material(
      type: MaterialType.transparency,
      child: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
        tooltip: 'Delete',
        onPressed: () async {
          // Capture messenger before async operation to avoid context issues
          final messenger = ScaffoldMessenger.of(context);

          try {
            // Remove article from saved list via provider
            await ref
                .read(articleSavedListNotifierProvider.notifier)
                .removeArticle(article);

            // Show success feedback
            messenger.showSnackBar(
              SnackBar(
                content: const Text(
                  'Article deleted',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 2),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {
                    messenger.hideCurrentSnackBar();
                  },
                ),
              ),
            );
          } catch (err) {
            // Show error feedback
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  'Delete failed: $err',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: Colors.red[700],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'RETRY',
                  textColor: Colors.white,
                  onPressed: () {
                    messenger.hideCurrentSnackBar();
                  },
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
