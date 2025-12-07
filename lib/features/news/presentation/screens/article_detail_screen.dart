import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:foot_rdc/features/news/domain/entities/article.dart';
import 'package:foot_rdc/features/news/presentation/providers/article_provider.dart';
import 'package:foot_rdc/core/utils/date_utils.dart';
import 'package:foot_rdc/core/utils/string_utils.dart';
import 'package:foot_rdc/core/constants/ad_constants.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ArticleDetailScreen extends ConsumerStatefulWidget {
  final Article article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  ConsumerState<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends ConsumerState<ArticleDetailScreen> {
  BannerAd? _bannerAd;
  NativeAd? _nativeAd;
  bool _isBannerAdLoaded = false;
  bool _isNativeAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _loadNativeAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _nativeAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdConstants.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isBannerAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: AdConstants.nativeAdUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isNativeAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
      ),
    )..load();
  }

  String? _imageUrl() => widget.article.imageUrl;
  String _dateText() => formatArticleDate(widget.article.dateGmt);
  String _categoryText() => widget.article.category;
  String _contentText() => widget.article.content;
  String _titleText() => widget.article.title;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl();
    final date = _dateText();
    final category = _categoryText();
    final content = _contentText();
    final title = _titleText();

    final theme = Theme.of(context);

    final savedArticles = ref.watch(articleSavedListNotifierProvider);
    final isSaved = savedArticles.any((a) => a.id == widget.article.id);

    final double topPadding = MediaQuery.of(context).padding.top;

    final Color overlayBg = theme.brightness == Brightness.dark
        ? Colors.black.withOpacity(0.55)
        : Colors.white.withOpacity(0.85);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              AnnotatedRegion<SystemUiOverlayStyle>(
                value: theme.brightness == Brightness.dark
                    ? SystemUiOverlayStyle.light
                    : SystemUiOverlayStyle.dark,
                child: Stack(
                  children: [
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
                                color: theme.colorScheme.surfaceContainerHighest,
                              ),
                            )
                          : Container(
                              height: 250 + topPadding,
                              width: double.infinity,
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                    ),

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

                    Positioned(
                      right: 12,
                      top: topPadding + 12,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: overlayBg,
                            child: IconButton(
                              icon: Icon(
                                isSaved
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                              ),
                              color: theme.colorScheme.onSurface,
                              onPressed: () async {
                                final notifier = ref.read(
                                  articleSavedListNotifierProvider.notifier,
                                );
                                String message;
                                IconData icon;

                                if (isSaved) {
                                  await notifier.removeArticle(widget.article);
                                  message = 'Article retire des favoris';
                                  icon = Icons.bookmark_remove;
                                } else {
                                  await notifier.addNewArticle(widget.article);
                                  message = 'Article sauvegarde avec succes';
                                  icon = Icons.bookmark_added;
                                }

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(
                                            icon,
                                            color: theme
                                                .colorScheme
                                                .onSecondaryContainer,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            message,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor:
                                          theme.colorScheme.secondaryContainer,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      margin: const EdgeInsets.all(16),
                                      duration: const Duration(seconds: 2),
                                      elevation: 6,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: overlayBg,
                            child: IconButton(
                              icon: const Icon(Icons.share),
                              color: theme.colorScheme.onSurface,
                              onPressed: () => _handleShare(context, theme),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                decoration: BoxDecoration(color: theme.colorScheme.surface),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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

                    Text(
                      title.isEmpty ? 'Details de l\'article' : title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontFamily: 'OpenSans',
                        fontWeight: FontWeight.w800,
                        height: 1.18,
                      ),
                    ),

                    const SizedBox(height: 12),

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

                    const SizedBox(height: 24),

                    if (_isNativeAdLoaded && _nativeAd != null)
                      Container(
                        height: 320,
                        margin: const EdgeInsets.symmetric(vertical: 16.0),
                        child: AdWidget(ad: _nativeAd!),
                      ),

                    const SizedBox(height: 6),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _isBannerAdLoaded && _bannerAd != null
          ? SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          : const SizedBox.shrink(),
    );
  }

  Future<void> _handleShare(BuildContext context, ThemeData theme) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onSecondaryContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Le partage n\'est pas pris en charge sur cette plateforme',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: theme.colorScheme.secondaryContainer,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
          '${widget.article.title}\n\n${widget.article.link}';

      await Share.share(
        shareText,
        subject: widget.article.title,
      );
    } catch (e) {
      if (context.mounted) {
        _showShareError(context, theme, e);
      }
    }
  }

  void _showShareError(BuildContext context, ThemeData theme, Object error) {
    String errorMessage = 'Echec du partage de l\'article';

    if (error.toString().contains('No implementation found')) {
      errorMessage =
          'Fonction de partage non disponible sur cet appareil.';
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
                  color: theme.colorScheme.onError,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        elevation: 6,
        action: SnackBarAction(
          label: 'Copier le lien',
          textColor: theme.colorScheme.onError,
          onPressed: () => _copyToClipboard(context, theme),
        ),
      ),
    );
  }

  Future<void> _copyToClipboard(BuildContext context, ThemeData theme) async {
    try {
      await Clipboard.setData(
        ClipboardData(
          text: '${widget.article.title}\n\n${widget.article.link}',
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: theme.colorScheme.onSecondaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Lien copie dans le presse-papiers',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            backgroundColor: theme.colorScheme.secondaryContainer,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
            elevation: 6,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
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
                Text(
                  'Impossible de copier le lien',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: theme.colorScheme.onError,
                  ),
                ),
              ],
            ),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
            elevation: 6,
          ),
        );
      }
    }
  }
}
