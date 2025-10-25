// Flutter framework imports
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/domain/entities/article.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Internal app imports
import 'package:foot_rdc/features/presentation/pages/article_details_page.dart';
import 'package:foot_rdc/features/presentation/providers/article_provider.dart';
import 'package:foot_rdc/features/presentation/widgets/article_saved_item.dart';
import 'package:foot_rdc/features/presentation/widgets/custom_app_bar.dart';

/// A page that displays a list of saved articles.
///
/// This widget uses Riverpod to watch for changes in the saved articles list
/// and displays them in a scrollable list. Each article is rendered using
/// the [ArticleSavedItem] widget.
class ArticleSavedList extends ConsumerStatefulWidget {
  const ArticleSavedList({super.key});

  @override
  ConsumerState<ArticleSavedList> createState() => _ArticleSavedListState();
}

class _ArticleSavedListState extends ConsumerState<ArticleSavedList> {
  // Admob state
  BannerAd? _bannerAd;
  final List<Object> _listItems = [];
  static const int _adFrequency = 9;
  bool _isAdLoaded = false;
  // Track native ad load state
  final Map<NativeAd, bool> _nativeAdLoaded = {};

  final String _bannerAdUnitId = kReleaseMode
      ? (Platform.isAndroid
            ? 'ca-app-pub-8433726715962091/9671028035'
            : 'ca-app-pub-8433726715962091/6360777917')
      : (Platform.isAndroid
            ? 'ca-app-pub-3940256099942544/6300978111'
            : 'ca-app-pub-3940256099942544/2934735716');

  final String _nativeAdUnitId = kReleaseMode
      ? (Platform.isAndroid
            ? 'ca-app-pub-8433726715962091/5762012110'
            : 'ca-app-pub-8433726715962091/8196603768')
      : (Platform.isAndroid
            ? 'ca-app-pub-3940256099942544/2247696110'
            : 'ca-app-pub-3940256099942544/3986624511');

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    // Initialize list with current saved articles after first frame
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
      adUnitId: _bannerAdUnitId,
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
          adUnitId: _nativeAdUnitId,
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
    // Get theme data for color adaptation
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Listen to changes in saved articles and update list with ads accordingly
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
      // App bar with French title
      appBar: const CustomAppBar(
        icon: Icons.bookmark_rounded,
        title: 'ARTICLES ENREGISTRÉS',
        subtitle: 'Vos articles sauvegardés',
      ),

      // Main body content
      body: _listItems.isEmpty
          // Show empty state when no articles are saved
          ? const Center(child: Text('Aucun article enregistré'))
          // Display articles in a scrollable list
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
                        color: Theme.of(context).colorScheme.surfaceVariant,
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
                  child: ArticleSavedItem(
                    article: article,
                    // Handle tap to navigate to article details
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ArticleDetailsPage(article: article),
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
