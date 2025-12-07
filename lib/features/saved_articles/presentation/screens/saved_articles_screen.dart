import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/news/domain/entities/article.dart';
import 'package:foot_rdc/features/news/presentation/screens/article_detail_screen.dart';
import 'package:foot_rdc/features/news/presentation/providers/article_provider.dart';
import 'package:foot_rdc/features/saved_articles/presentation/widgets/saved_article_item.dart';
import 'package:foot_rdc/core/constants/ad_constants.dart';
import 'package:foot_rdc/core/theme/app_colors.dart';
import 'package:foot_rdc/core/theme/app_design_system.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class SavedArticlesScreen extends ConsumerStatefulWidget {
  const SavedArticlesScreen({super.key});

  @override
  ConsumerState<SavedArticlesScreen> createState() => _SavedArticlesScreenState();
}

class _SavedArticlesScreenState extends ConsumerState<SavedArticlesScreen> {
  BannerAd? _bannerAd;
  final List<Object> _listItems = [];
  static const int _adFrequency = 9;
  bool _isAdLoaded = false;
  final Map<NativeAd, bool> _nativeAdLoaded = {};

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final savedArticles = ref.read(articleSavedListNotifierProvider);
      final sortedArticles = List<Article>.from(savedArticles)
        ..sort((a, b) => b.dateGmt.compareTo(a.dateGmt));
      _updateListWithAds(sortedArticles);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _disposeNativeAds();
    super.dispose();
  }

  void _disposeNativeAds() {
    for (var item in _listItems) {
      if (item is NativeAd) {
        item.dispose();
      }
    }
    _nativeAdLoaded.clear();
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
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  void _updateListWithAds(List<Article> articles) {
    _disposeNativeAds();
    _listItems.clear();
    for (int i = 0; i < articles.length; i++) {
      _listItems.add(articles[i]);
      if ((i + 1) % _adFrequency == 0 && i < articles.length - 1) {
        final nativeAd = NativeAd(
          adUnitId: AdConstants.nativeAdUnitId,
          listener: NativeAdListener(
            onAdLoaded: (ad) {
              if (mounted) {
                _nativeAdLoaded[ad as NativeAd] = true;
                setState(() {});
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
        _nativeAdLoaded[nativeAd] = false;
        _listItems.insert(i + 1, nativeAd);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    // Listen to changes in saved articles
    ref.listen<List<Article>>(articleSavedListNotifierProvider, (
      previous,
      next,
    ) {
      if (!mounted) return;
      final sorted = List<Article>.from(next)
        ..sort((a, b) => b.dateGmt.compareTo(a.dateGmt));
      _updateListWithAds(sorted);
      setState(() {});
    });

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: AppDesignSystem.borderRadiusFull,
              ),
            ),
            const SizedBox(width: AppDesignSystem.space10),
            Text(
              'ARTICLES ENREGISTRÉS',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFamily: 'Oswald',
                letterSpacing: 1.2,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: isDark ? Colors.black45 : Colors.black12,
      ),
      body: _listItems.isEmpty
          ? _buildEmptyState(isDark, theme)
          : ListView.builder(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.only(
                top: AppDesignSystem.space8,
                bottom: AppDesignSystem.space16,
              ),
              itemCount: _listItems.length,
              itemBuilder: (context, index) {
                final item = _listItems[index];

                if (item is NativeAd) {
                  return _buildNativeAdItem(item, isDark);
                }

                final article = item as Article;

                return Dismissible(
                  key: ValueKey('saved-${article.imageUrl}-${article.title}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppDesignSystem.space16,
                      vertical: AppDesignSystem.space6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.error.withAlpha(180),
                          colorScheme.error,
                        ],
                      ),
                      borderRadius: AppDesignSystem.borderRadiusXl,
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppDesignSystem.space24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.delete_forever_rounded,
                          size: 28,
                          color: Colors.white,
                        ),
                        const SizedBox(height: AppDesignSystem.space4),
                        Text(
                          'Supprimer',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onDismissed: (_) async {
                    await ref
                        .read(articleSavedListNotifierProvider.notifier)
                        .removeArticle(article);

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: AppDesignSystem.space10),
                            Text(
                              'Article supprimé',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppDesignSystem.borderRadiusMd,
                        ),
                        margin: const EdgeInsets.all(AppDesignSystem.space16),
                        duration: const Duration(seconds: 3),
                        action: SnackBarAction(
                          label: 'Annuler',
                          textColor: Colors.white,
                          onPressed: () {
                            ref
                                .read(articleSavedListNotifierProvider.notifier)
                                .addNewArticle(article);
                          },
                        ),
                      ),
                    );
                  },
                  child: SavedArticleItem(
                    article: article,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ArticleDetailScreen(article: article),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      bottomNavigationBar: _isAdLoaded && _bannerAd != null
          ? Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark
                    : AppColors.surfaceLight,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildEmptyState(bool isDark, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.space32,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.space24),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceContainerDark
                    : AppColors.surfaceContainerLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_outline_rounded,
                size: 56,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
            const SizedBox(height: AppDesignSystem.space24),
            Text(
              'Aucun article enregistré',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppDesignSystem.space8),
            Text(
              'Les articles que vous enregistrez\napparaîtront ici',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNativeAdItem(NativeAd item, bool isDark) {
    final isLoaded = _nativeAdLoaded[item] == true;
    if (!isLoaded) {
      return Container(
        height: 320,
        margin: const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.space16,
          vertical: AppDesignSystem.space8,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainerLight,
          borderRadius: AppDesignSystem.borderRadiusLg,
        ),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary.withAlpha(128),
            ),
          ),
        ),
      );
    }
    return Container(
      height: 320,
      margin: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.space16,
        vertical: AppDesignSystem.space8,
      ),
      decoration: BoxDecoration(
        borderRadius: AppDesignSystem.borderRadiusLg,
      ),
      clipBehavior: Clip.antiAlias,
      child: AdWidget(ad: item),
    );
  }
}
