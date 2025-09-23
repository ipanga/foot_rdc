import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/domain/entities/article.dart';
import 'package:foot_rdc/features/presentation/providers/article_provider.dart';
import 'package:foot_rdc/utils/date_utils.dart';
import 'package:foot_rdc/utils/string_utils.dart';

class ArticleDetailsPage extends ConsumerWidget {
  final Article article;

  const ArticleDetailsPage({super.key, required this.article});

  String? _imageUrl() => article.imageUrl;

  String _dateText() => formatArticleDate(article.dateGmt);

  String _categoryText() => article.category;

  String _contentText() => article.content;

  String _titleText() => article.title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = _imageUrl();
    final date = _dateText();
    final category = _categoryText();
    final content = _contentText();
    final title = _titleText();

    final theme = Theme.of(context);

    // allow the top content to extend under the status bar
    final double topPadding = MediaQuery.of(context).padding.top;
    // add the top inset to the image height so it visually covers the status bar
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      body: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top image with overlayed action buttons
              Stack(
                children: [
                  // Image with rounded bottom corners
                  ClipRRect(
                    child: (imageUrl != null && imageUrl.isNotEmpty)
                        ? Image.network(
                            imageUrl,
                            height: 250 + topPadding,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(height: 320, color: Colors.grey),
                          )
                        : Container(
                            height: 250 + topPadding,
                            width: double.infinity,
                            color: Colors.grey.shade300,
                          ),
                  ),

                  // Back button (left)
                  Positioned(
                    left: 12,
                    top: topPadding + 12,
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white.withOpacity(0.85),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        color: Colors.black87,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),

                  // Bookmark and share buttons (right)
                  Positioned(
                    right: 12,
                    top: topPadding + 12,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white.withOpacity(0.85),
                          child: IconButton(
                            icon: const Icon(Icons.bookmark_border),
                            color: Colors.black87,
                            onPressed: () async {
                              // Save article into database using provider
                              await ref
                                  .read(
                                    articleSavedListNotifierProvider.notifier,
                                  )
                                  .addNewArticle(article);

                              // Show confirmation
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Article saved successfully!'),
                                ),
                              );
                            },

                            // After onPressed, change icon to filled bookmark
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white.withOpacity(0.85),
                          child: IconButton(
                            icon: const Icon(Icons.share),
                            color: Colors.black87,
                            onPressed: () {
                              // TODO: show actions
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Card placed below the image (no overlap) and no border radius
              Container(
                //margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                decoration: const BoxDecoration(color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Source row: avatar + source name
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // meta row: date • read time • category
                              Row(
                                children: [
                                  if (category.isNotEmpty)
                                    Text(
                                      '${formatCategory(category)}  -',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  // static read time placeholder (replace if you have read time)
                                  if (category.isNotEmpty)
                                    const SizedBox(width: 8),
                                  if (date.isNotEmpty)
                                    Text(
                                      date,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  if (date.isNotEmpty) const SizedBox(width: 8),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Title
                    Text(
                      title.isEmpty ? 'Article details' : title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.18,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Excerpt / content preview
                    Text(
                      content.isEmpty ? 'No content available.' : content,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),

                    const SizedBox(height: 12),

                    // Additional long content section (keeps white background)
                    // If your article content includes HTML, render accordingly.
                    // For now we just repeat the content or show placeholder paragraphs.
                    const SizedBox(height: 6),
                  ],
                ),
              ),

              // Add spacing at bottom so content isn't clipped by phone home indicator
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
