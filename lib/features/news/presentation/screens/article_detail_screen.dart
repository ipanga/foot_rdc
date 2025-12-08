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
import 'package:foot_rdc/core/theme/app_colors.dart';
import 'package:foot_rdc/core/theme/app_design_system.dart';
import 'package:foot_rdc/shared/widgets/app_snackbar.dart';
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
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final savedArticles = ref.watch(articleSavedListNotifierProvider);
    final isSaved = savedArticles.any((a) => a.id == widget.article.id);

    final double topPadding = MediaQuery.of(context).padding.top;

    final Color overlayBg = isDark
        ? Colors.black.withAlpha(140)
        : Colors.white.withAlpha(217);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
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
                                  AppSnackbar.showSuccess(
                                    context,
                                    message: message,
                                    icon: icon,
                                    duration: const Duration(seconds: 2),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Builder(
                            builder: (buttonContext) {
                              return CircleAvatar(
                                radius: 22,
                                backgroundColor: overlayBg,
                                child: IconButton(
                                  icon: const Icon(Icons.share),
                                  color: theme.colorScheme.onSurface,
                                  onPressed: () {
                                    final box = buttonContext.findRenderObject() as RenderBox?;
                                    final sharePositionOrigin = box != null
                                        ? box.localToGlobal(Offset.zero) & box.size
                                        : null;
                                    _handleShare(context, theme, sharePositionOrigin);
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.fromLTRB(
                  AppDesignSystem.space20,
                  AppDesignSystem.space16,
                  AppDesignSystem.space20,
                  AppDesignSystem.space24,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category and date row
                    Row(
                      children: [
                        if (category.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDesignSystem.space8,
                              vertical: AppDesignSystem.space4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withAlpha(20),
                              borderRadius: AppDesignSystem.borderRadiusSm,
                            ),
                            child: Text(
                              formatCategory(category).toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDesignSystem.space10),
                        ],
                        if (date.isNotEmpty)
                          Text(
                            date,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiaryLight,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: AppDesignSystem.space16),

                    // Title
                    Text(
                      title.isEmpty
                          ? 'Détails de l\'article'
                          : decodeHtmlEntities(title),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontFamily: 'OpenSans',
                        fontWeight: FontWeight.w800,
                        height: 1.22,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),

                    const SizedBox(height: AppDesignSystem.space20),

                    // HTML Content with improved styling
                    Html(
                      data: content.isEmpty
                          ? '<p>Aucun contenu disponible</p>'
                          : _preprocessHtmlContent(content),
                      style: {
                        "body": Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          fontSize: FontSize(16.5),
                          lineHeight: const LineHeight(1.7),
                          fontFamily: 'OpenSans',
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        "p": Style(
                          margin: Margins.only(bottom: 18),
                          fontSize: FontSize(16.5),
                          lineHeight: const LineHeight(1.7),
                        ),
                        "h1": Style(
                          fontFamily: 'OpenSans',
                          fontWeight: FontWeight.w800,
                          fontSize: FontSize(26),
                          margin: Margins.only(top: 28, bottom: 14),
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        "h2": Style(
                          fontFamily: 'OpenSans',
                          fontWeight: FontWeight.w700,
                          fontSize: FontSize(22),
                          margin: Margins.only(top: 24, bottom: 12),
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        "h3": Style(
                          fontFamily: 'OpenSans',
                          fontWeight: FontWeight.w700,
                          fontSize: FontSize(19),
                          margin: Margins.only(top: 20, bottom: 10),
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        "h4, h5, h6": Style(
                          fontFamily: 'OpenSans',
                          fontWeight: FontWeight.w600,
                          fontSize: FontSize(17),
                          margin: Margins.only(top: 18, bottom: 8),
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        "a": Style(
                          fontFamily: 'OpenSans',
                          color: colorScheme.primary,
                          textDecoration: TextDecoration.underline,
                          textDecorationColor: colorScheme.primary.withAlpha(100),
                        ),
                        "strong, b": Style(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        "em, i": Style(
                          fontStyle: FontStyle.italic,
                        ),
                        "blockquote": Style(
                          margin: Margins.only(
                            left: 0,
                            right: 0,
                            top: 16,
                            bottom: 16,
                          ),
                          padding: HtmlPaddings.only(
                            left: 16,
                            top: 12,
                            bottom: 12,
                          ),
                          border: Border(
                            left: BorderSide(
                              color: colorScheme.primary,
                              width: 4,
                            ),
                          ),
                          backgroundColor: isDark
                              ? AppColors.surfaceContainerDark
                              : AppColors.surfaceContainerLight,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        "ul, ol": Style(
                          margin: Margins.only(bottom: 16, left: 8),
                          padding: HtmlPaddings.only(left: 16),
                        ),
                        "li": Style(
                          margin: Margins.only(bottom: 8),
                          lineHeight: const LineHeight(1.6),
                        ),
                        "img": Style(
                          width: Width(double.infinity),
                          margin: Margins.only(top: 16, bottom: 16),
                        ),
                        "figure": Style(
                          margin: Margins.only(top: 20, bottom: 20),
                        ),
                        "figcaption": Style(
                          fontSize: FontSize(13),
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                          textAlign: TextAlign.center,
                          margin: Margins.only(top: 8),
                          fontStyle: FontStyle.italic,
                        ),
                        "pre": Style(
                          backgroundColor: isDark
                              ? AppColors.surfaceContainerDark
                              : AppColors.surfaceContainerLight,
                          padding: HtmlPaddings.all(16),
                          margin: Margins.only(top: 16, bottom: 16),
                          fontFamily: 'monospace',
                          fontSize: FontSize(14),
                        ),
                        "code": Style(
                          backgroundColor: isDark
                              ? AppColors.surfaceContainerDark
                              : AppColors.surfaceContainerLight,
                          padding: HtmlPaddings.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          fontFamily: 'monospace',
                          fontSize: FontSize(14),
                        ),
                        "hr": Style(
                          margin: Margins.only(top: 24, bottom: 24),
                          border: Border(
                            bottom: BorderSide(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                              width: 1,
                            ),
                          ),
                        ),
                        "table": Style(
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                          margin: Margins.only(top: 16, bottom: 16),
                        ),
                        "th": Style(
                          backgroundColor: isDark
                              ? AppColors.surfaceContainerDark
                              : AppColors.surfaceContainerLight,
                          padding: HtmlPaddings.all(12),
                          fontWeight: FontWeight.w600,
                        ),
                        "td": Style(
                          padding: HtmlPaddings.all(12),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                            width: 0.5,
                          ),
                        ),
                      },
                      extensions: [
                        // Custom image rendering with loading placeholder
                        TagExtension(
                          tagsToExtend: {"img"},
                          builder: (extensionContext) {
                            final src = extensionContext.attributes['src'];
                            if (src == null || src.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppDesignSystem.space12,
                              ),
                              child: ClipRRect(
                                borderRadius: AppDesignSystem.borderRadiusMd,
                                child: Image.network(
                                  src,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 200,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.surfaceContainerDark
                                            : AppColors.surfaceContainerLight,
                                        borderRadius:
                                            AppDesignSystem.borderRadiusMd,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                          strokeWidth: 2,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 120,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.surfaceContainerDark
                                            : AppColors.surfaceContainerLight,
                                        borderRadius:
                                            AppDesignSystem.borderRadiusMd,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.broken_image_outlined,
                                            size: 32,
                                            color: isDark
                                                ? AppColors.textTertiaryDark
                                                : AppColors.textTertiaryLight,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Image non disponible',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? AppColors.textTertiaryDark
                                                  : AppColors.textTertiaryLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        // Custom iframe rendering for YouTube and Twitter
                        TagExtension(
                          tagsToExtend: {"iframe"},
                          builder: (extensionContext) {
                            final src = extensionContext.attributes['src'] ?? '';
                            return _buildEmbedWidget(src, isDark, colorScheme);
                          },
                        ),
                        // Twitter blockquote embeds
                        TagExtension(
                          tagsToExtend: {"blockquote"},
                          child: null,
                          builder: (extensionContext) {
                            final className =
                                extensionContext.attributes['class'] ?? '';
                            if (className.contains('twitter')) {
                              return _buildTwitterEmbed(
                                extensionContext,
                                isDark,
                                colorScheme,
                              );
                            }
                            // Return default styled blockquote for non-Twitter content
                            return _buildDefaultBlockquote(
                              extensionContext,
                              isDark,
                              colorScheme,
                            );
                          },
                        ),
                      ],
                      onLinkTap: (url, attributes, element) async {
                        if (url != null) {
                          await _handleLinkTap(url, context, theme);
                        }
                      },
                    ),

                    const SizedBox(height: AppDesignSystem.space24),

                    if (_isNativeAdLoaded && _nativeAd != null)
                      Container(
                        height: 320,
                        margin: const EdgeInsets.symmetric(
                          vertical: AppDesignSystem.space16,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: AppDesignSystem.borderRadiusMd,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: AdWidget(ad: _nativeAd!),
                      ),

                    const SizedBox(height: AppDesignSystem.space8),
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

  /// Preprocess HTML content to handle common issues and improve display
  String _preprocessHtmlContent(String html) {
    // Remove empty paragraphs
    String processed = html.replaceAll(RegExp(r'<p>\s*</p>'), '');
    processed = processed.replaceAll(RegExp(r'<p>&nbsp;</p>'), '');

    // Fix double line breaks
    processed = processed.replaceAll(RegExp(r'<br\s*/?>\s*<br\s*/?>'), '<br>');

    // Handle WordPress-style image captions
    processed = processed.replaceAll(
      RegExp(r'\[caption[^\]]*\](.*?)\[/caption\]'),
      r'<figure>$1</figure>',
    );

    return processed;
  }

  /// Build embed widget for YouTube, Twitter, and other iframe content
  Widget _buildEmbedWidget(
    String src,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    // YouTube embed detection
    if (src.contains('youtube.com') || src.contains('youtu.be')) {
      final videoId = _extractYouTubeVideoId(src);
      if (videoId != null) {
        return _buildYouTubeEmbed(videoId, isDark, colorScheme);
      }
    }

    // Twitter embed detection
    if (src.contains('twitter.com') || src.contains('x.com')) {
      return _buildGenericEmbed(
        src,
        isDark,
        colorScheme,
        icon: Icons.alternate_email,
        label: 'Voir sur X (Twitter)',
      );
    }

    // Instagram embed
    if (src.contains('instagram.com')) {
      return _buildGenericEmbed(
        src,
        isDark,
        colorScheme,
        icon: Icons.camera_alt,
        label: 'Voir sur Instagram',
      );
    }

    // Facebook embed
    if (src.contains('facebook.com')) {
      return _buildGenericEmbed(
        src,
        isDark,
        colorScheme,
        icon: Icons.facebook,
        label: 'Voir sur Facebook',
      );
    }

    // Generic iframe - show link to open externally
    return _buildGenericEmbed(
      src,
      isDark,
      colorScheme,
      icon: Icons.open_in_new,
      label: 'Ouvrir le contenu externe',
    );
  }

  /// Extract YouTube video ID from various URL formats
  String? _extractYouTubeVideoId(String url) {
    // youtube.com/watch?v=VIDEO_ID
    final watchRegex = RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]+)');
    final watchMatch = watchRegex.firstMatch(url);
    if (watchMatch != null) return watchMatch.group(1);

    // youtube.com/embed/VIDEO_ID
    final embedRegex = RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]+)');
    final embedMatch = embedRegex.firstMatch(url);
    if (embedMatch != null) return embedMatch.group(1);

    // youtu.be/VIDEO_ID
    final shortRegex = RegExp(r'youtu\.be/([a-zA-Z0-9_-]+)');
    final shortMatch = shortRegex.firstMatch(url);
    if (shortMatch != null) return shortMatch.group(1);

    return null;
  }

  /// Build YouTube embed widget with thumbnail and play button
  Widget _buildYouTubeEmbed(
    String videoId,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    final videoUrl = 'https://www.youtube.com/watch?v=$videoId';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDesignSystem.space16),
      child: GestureDetector(
        onTap: () => _openUrl(videoUrl),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppDesignSystem.borderRadiusMd,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Thumbnail
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  thumbnailUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: isDark
                          ? AppColors.surfaceContainerDark
                          : AppColors.surfaceContainerLight,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: isDark
                          ? AppColors.surfaceContainerDark
                          : AppColors.surfaceContainerLight,
                      child: const Center(
                        child: Icon(Icons.play_circle_outline, size: 48),
                      ),
                    );
                  },
                ),
              ),
              // Play button overlay
              Container(
                width: 68,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              // YouTube branding
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(180),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_circle, color: Colors.red, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'YouTube',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build generic embed widget for other platforms
  Widget _buildGenericEmbed(
    String url,
    bool isDark,
    ColorScheme colorScheme, {
    required IconData icon,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDesignSystem.space12),
      child: GestureDetector(
        onTap: () => _openUrl(url),
        child: Container(
          padding: const EdgeInsets.all(AppDesignSystem.space16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceContainerDark
                : AppColors.surfaceContainerLight,
            borderRadius: AppDesignSystem.borderRadiusMd,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDesignSystem.space10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(20),
                  borderRadius: AppDesignSystem.borderRadiusSm,
                ),
                child: Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppDesignSystem.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Appuyez pour ouvrir',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new,
                size: 20,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build default blockquote widget
  Widget _buildDefaultBlockquote(
    ExtensionContext extensionContext,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    // Extract text content from the blockquote
    final text = extensionContext.element?.text ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppDesignSystem.space12),
      padding: const EdgeInsets.only(
        left: AppDesignSystem.space16,
        top: AppDesignSystem.space12,
        bottom: AppDesignSystem.space12,
        right: AppDesignSystem.space12,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceContainerLight,
        border: Border(
          left: BorderSide(
            color: colorScheme.primary,
            width: 4,
          ),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(AppDesignSystem.radiusSm),
          bottomRight: Radius.circular(AppDesignSystem.radiusSm),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontStyle: FontStyle.italic,
          fontSize: 15,
          height: 1.6,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
    );
  }

  /// Build Twitter/X embed widget
  Widget _buildTwitterEmbed(
    ExtensionContext extensionContext,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    // Try to extract the tweet URL from the blockquote
    final dataSource = extensionContext.attributes['data-source'] ?? '';
    String? tweetUrl;

    if (dataSource.isNotEmpty) {
      tweetUrl = dataSource;
    }

    // If we found a tweet URL, show a nice card to open it
    if (tweetUrl != null && tweetUrl.isNotEmpty) {
      return _buildGenericEmbed(
        tweetUrl,
        isDark,
        colorScheme,
        icon: Icons.alternate_email,
        label: 'Voir le tweet sur X',
      );
    }

    // Show generic Twitter embed
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDesignSystem.space12),
      child: Container(
        padding: const EdgeInsets.all(AppDesignSystem.space16),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainerLight,
          borderRadius: AppDesignSystem.borderRadiusMd,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.space10),
              decoration: BoxDecoration(
                color: const Color(0xFF1DA1F2).withAlpha(20),
                borderRadius: AppDesignSystem.borderRadiusSm,
              ),
              child: const Icon(
                Icons.alternate_email,
                color: Color(0xFF1DA1F2),
                size: 24,
              ),
            ),
            const SizedBox(width: AppDesignSystem.space12),
            Expanded(
              child: Text(
                'Contenu Twitter/X',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle link taps - detect special URLs and handle them appropriately
  Future<void> _handleLinkTap(
    String url,
    BuildContext context,
    ThemeData theme,
  ) async {
    // Check for YouTube links
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      await _openUrl(url);
      return;
    }

    // Check for Twitter/X links
    if (url.contains('twitter.com') || url.contains('x.com')) {
      await _openUrl(url);
      return;
    }

    // Default: open in browser
    await _openUrl(url);
  }

  /// Open URL in external browser
  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error opening URL: $e');
    }
  }

  Future<void> _handleShare(BuildContext context, ThemeData theme, [Rect? sharePositionOrigin]) async {
    final String shareText =
        '${decodeHtmlEntities(widget.article.title)}\n\n${widget.article.link}';

    // For desktop platforms that don't support native sharing
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      await _copyToClipboard(context, theme, shareText);
      return;
    }

    // Use Share.share for native share sheet on mobile devices
    // sharePositionOrigin is required for iPad to position the share popover
    await Share.share(
      shareText,
      subject: decodeHtmlEntities(widget.article.title),
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  Future<void> _copyToClipboard(BuildContext context, ThemeData theme, [String? text]) async {
    try {
      final clipboardText = text ?? '${decodeHtmlEntities(widget.article.title)}\n\n${widget.article.link}';
      await Clipboard.setData(
        ClipboardData(text: clipboardText),
      );
      if (context.mounted) {
        AppSnackbar.showSuccess(
          context,
          message: 'Lien copie dans le presse-papiers',
          icon: Icons.content_copy,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (_) {
      if (context.mounted) {
        AppSnackbar.showError(
          context,
          message: 'Impossible de copier le lien',
          duration: const Duration(seconds: 2),
        );
      }
    }
  }
}
