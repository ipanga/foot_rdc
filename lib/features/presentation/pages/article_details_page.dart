import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
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

    // Overlay chip background for both light/dark
    final Color overlayBg = theme.brightness == Brightness.dark
        ? Colors.black.withOpacity(0.55)
        : Colors.white.withOpacity(0.85);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top image with overlayed action buttons
              AnnotatedRegion<SystemUiOverlayStyle>(
                value: theme.brightness == Brightness.dark
                    ? SystemUiOverlayStyle.light
                    : SystemUiOverlayStyle.dark,
                child: Stack(
                  children: [
                    // Image with rounded bottom corners
                    ClipRRect(
                      child: (imageUrl != null && imageUrl.isNotEmpty)
                          ? Image.network(
                              imageUrl,
                              height: 250 + topPadding,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 250 + topPadding,
                                width: double.infinity,
                                color: theme.colorScheme.surfaceVariant,
                              ),
                            )
                          : Container(
                              height: 250 + topPadding,
                              width: double.infinity,
                              color: theme.colorScheme.surfaceVariant,
                            ),
                    ),

                    // Back button (left)
                    Positioned(
                      left: 12,
                      top: topPadding + 12,
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: overlayBg,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          color: theme.colorScheme.onSurface,
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
                            backgroundColor: overlayBg,
                            child: IconButton(
                              icon: const Icon(Icons.bookmark_border),
                              color: theme.colorScheme.onSurface,
                              onPressed: () async {
                                try {
                                  // Save article into database using provider
                                  await ref
                                      .read(
                                        articleSavedListNotifierProvider
                                            .notifier,
                                      )
                                      .addNewArticle(article);

                                  // Show confirmation
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(
                                              Icons.bookmark_added,
                                              color: theme
                                                  .colorScheme
                                                  .onSecondaryContainer,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'Article sauvegardé avec succès',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: theme
                                            .colorScheme
                                            .secondaryContainer,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        margin: const EdgeInsets.all(16),
                                        duration: const Duration(seconds: 2),
                                        elevation: 6,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Échec de la sauvegarde de l\'article: ${e.toString()}',
                                          style: TextStyle(
                                            color: theme.colorScheme.onError,
                                          ),
                                        ),
                                        backgroundColor:
                                            theme.colorScheme.error,
                                      ),
                                    );
                                  }
                                }
                              },

                              // After onPressed, change icon to filled bookmark
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: overlayBg,
                            child: IconButton(
                              icon: const Icon(Icons.share),
                              color: theme.colorScheme.onSurface,
                              onPressed: () async {
                                try {
                                  // Check if we're on a supported platform
                                  if (defaultTargetPlatform ==
                                          TargetPlatform.windows ||
                                      defaultTargetPlatform ==
                                          TargetPlatform.linux) {
                                    // For unsupported platforms, show a message
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                color: theme
                                                    .colorScheme
                                                    .onSecondaryContainer,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'Le partage n\'est pas pris en charge sur cette plateforme',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 15,
                                                    color: theme
                                                        .colorScheme
                                                        .onSecondaryContainer,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: theme
                                              .colorScheme
                                              .secondaryContainer,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          margin: const EdgeInsets.all(16),
                                          duration: const Duration(seconds: 4),
                                          elevation: 6,
                                        ),
                                      );
                                    }
                                    return;
                                  }

                                  final String shareText =
                                      '${article.title}\n\n${article.link}';

                                  // Use Share.share with better error handling
                                  await Share.share(
                                    shareText,
                                    subject: article.title,
                                  );
                                  // No SnackBar shown on successful share
                                } catch (e) {
                                  if (context.mounted) {
                                    // Handle specific share_plus errors
                                    String errorMessage =
                                        'Échec du partage de l\'article';

                                    if (e.toString().contains(
                                      'No implementation found',
                                    )) {
                                      errorMessage =
                                          'Fonction de partage non disponible sur cet appareil. Veuillez essayer de copier le lien à la place.';
                                    } else {
                                      errorMessage =
                                          'Échec du partage: ${e.toString()}';
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(
                                              Icons.error_outline,
                                              color: theme.colorScheme.onError,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                errorMessage,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 15,
                                                  color:
                                                      theme.colorScheme.onError,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor:
                                            theme.colorScheme.error,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        margin: const EdgeInsets.all(16),
                                        duration: const Duration(seconds: 4),
                                        elevation: 6,
                                        action: SnackBarAction(
                                          label: 'Copier le lien',
                                          textColor: theme.colorScheme.onError,
                                          onPressed: () async {
                                            // Copy to clipboard as fallback
                                            try {
                                              await Clipboard.setData(
                                                ClipboardData(
                                                  text:
                                                      '${article.title}\n\n${article.link}',
                                                ),
                                              );
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Row(
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .check_circle_outline,
                                                          color: theme
                                                              .colorScheme
                                                              .onSecondaryContainer,
                                                          size: 20,
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Text(
                                                          'Lien de l\'article copié dans le presse-papiers',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontSize: 15,
                                                            color: theme
                                                                .colorScheme
                                                                .onSecondaryContainer,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    backgroundColor: theme
                                                        .colorScheme
                                                        .secondaryContainer,
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    margin:
                                                        const EdgeInsets.all(
                                                          16,
                                                        ),
                                                    duration: const Duration(
                                                      seconds: 2,
                                                    ),
                                                    elevation: 6,
                                                  ),
                                                );
                                              }
                                            } catch (_) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.error_outline,
                                                          color: theme
                                                              .colorScheme
                                                              .onError,
                                                          size: 20,
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Text(
                                                          'Impossible de copier le lien',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontSize: 15,
                                                            color: theme
                                                                .colorScheme
                                                                .onError,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    backgroundColor:
                                                        theme.colorScheme.error,
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    margin:
                                                        const EdgeInsets.all(
                                                          16,
                                                        ),
                                                    duration: const Duration(
                                                      seconds: 2,
                                                    ),
                                                    elevation: 6,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Card placed below the image (no overlap) and no border radius
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                decoration: BoxDecoration(color: theme.colorScheme.surface),
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
                                      '${formatCategory(category).toUpperCase()}  -',
                                      style: theme.textTheme.bodySmall,
                                    ),
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
                      title.isEmpty ? 'Détails de l\'article' : title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontFamily: 'OpenSans',
                        fontWeight: FontWeight.w800,
                        height: 1.18,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Content
                    Html(
                      data: content.isEmpty
                          ? '<p>Aucun contenu disponible</p>'
                          : content,
                      style: {
                        "body": Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          fontSize: FontSize(
                            theme.textTheme.bodyLarge?.fontSize ?? 16,
                          ),
                          lineHeight: LineHeight(1.5),
                          fontFamily: 'OpenSans',
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                        "p": Style(margin: Margins.only(bottom: 16)),
                        "h1, h2, h3, h4, h5, h6": Style(
                          fontFamily: 'OpenSans',
                          fontWeight: FontWeight.bold,
                          margin: Margins.only(top: 16, bottom: 8),
                        ),
                        "a": Style(
                          fontFamily: 'OpenSans',
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
