import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart'; // Add this import
import 'package:foot_rdc/features/domain/entities/article.dart';
import 'package:foot_rdc/features/presentation/providers/article_provider.dart';
import 'package:foot_rdc/utils/date_utils.dart';
import 'package:foot_rdc/utils/string_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
      backgroundColor: Colors.white,
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
                            onPressed: () async {
                              try {
                                // Check if we're on a supported platform
                                if (defaultTargetPlatform ==
                                        TargetPlatform.windows ||
                                    defaultTargetPlatform ==
                                        TargetPlatform.linux) {
                                  // For unsupported platforms, show a message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Share not supported on this platform',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }

                                final String shareText =
                                    '${article.title}\n\n${article.link}';

                                // Use Share.share with better error handling
                                await Share.share(
                                  shareText,
                                  subject: article.title,
                                );
                              } catch (e) {
                                // Handle specific share_plus errors
                                String errorMessage = 'Failed to share article';

                                if (e.toString().contains(
                                  'No implementation found',
                                )) {
                                  errorMessage =
                                      'Share feature not available on this device. Please try copying the link instead.';
                                } else {
                                  errorMessage =
                                      'Failed to share: ${e.toString()}';
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(errorMessage),
                                    backgroundColor: const Color(0xFFec3535),
                                    duration: const Duration(seconds: 4),
                                    action: SnackBarAction(
                                      label: 'Copy Link',
                                      textColor: Colors.white,
                                      onPressed: () async {
                                        // Copy to clipboard as fallback
                                        try {
                                          await Clipboard.setData(
                                            ClipboardData(
                                              text:
                                                  '${article.title}\n\n${article.link}',
                                            ),
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Article link copied to clipboard!',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } catch (_) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Unable to copy link',
                                              ),
                                              backgroundColor: Color(
                                                0xFFec3535,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                );
                              }
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
                    Html(
                      data: content.isEmpty
                          ? '<p>No content available.</p>'
                          : content,
                      style: {
                        "body": Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          fontSize: FontSize(
                            theme.textTheme.bodyLarge?.fontSize ?? 16,
                          ),
                          lineHeight: LineHeight(1.5),
                          fontFamily: theme.textTheme.bodyLarge?.fontFamily,
                        ),
                        "p": Style(margin: Margins.only(bottom: 16)),
                        "h1, h2, h3, h4, h5, h6": Style(
                          fontWeight: FontWeight.bold,
                          margin: Margins.only(top: 16, bottom: 8),
                        ),
                        "a": Style(
                          color: theme.colorScheme.primary,
                          textDecoration: TextDecoration.underline,
                        ),
                        "img": Style(
                          width: Width(double.infinity),
                          margin: Margins.only(top: 8, bottom: 8),
                        ),
                      },
                      onLinkTap: (url, attributes, element) async {
                        if (url != null) {
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        }
                      },
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
