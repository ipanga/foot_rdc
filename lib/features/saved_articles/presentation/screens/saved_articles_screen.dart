import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/news/domain/entities/article.dart';
import 'package:foot_rdc/features/news/presentation/screens/article_detail_screen.dart';
import 'package:foot_rdc/features/news/presentation/providers/article_provider.dart';
import 'package:foot_rdc/features/saved_articles/presentation/widgets/saved_article_item.dart';
import 'package:foot_rdc/core/constants/ad_constants.dart';
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
      appBar: AppBar(
        title: const Text(
          '|  ARTICLES ENREGISTRÉS',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            fontFamily: 'Oswald',
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: false,
        elevation: 4.0,
        shadowColor: theme.brightness == Brightness.light
            ? Colors.black26
            : Colors.white24,
      ),
      body: _listItems.isEmpty
          ? const Center(child: Text('Aucun article enregistré'))
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: _listItems.length,
              itemBuilder: (context, index) {
                final item = _listItems[index];

                if (item is NativeAd) {
                  final isLoaded = _nativeAdLoaded[item] == true;
                  if (!isLoaded) {
                    return Container(
                      height: 320,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 10.0,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  }
                  return Container(
                    height: 320,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 10.0,
                    ),
                    child: AdWidget(ad: item),
                  );
                }

                final article = item as Article;

                return Dismissible(
                  key: ValueKey('saved-${article.imageUrl}-${article.title}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: Icon(
                      Icons.delete_forever_rounded,
                      size: 28,
                      color: colorScheme.onError,
                    ),
                  ),
                  onDismissed: (_) async {
                    await ref
                        .read(articleSavedListNotifierProvider.notifier)
                        .removeArticle(article);

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Article supprimé'),
                        backgroundColor: colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 2),
                        action: SnackBarAction(
                          label: 'Annuler',
                          textColor: colorScheme.onError,
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
          ? SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          : const SizedBox.shrink(),
    );
  }
}
