// Flutter framework imports
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/domain/entities/article.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Internal app imports
import 'package:foot_rdc/features/presentation/pages/article_details_page.dart';
import 'package:foot_rdc/features/presentation/providers/article_provider.dart';
import 'package:foot_rdc/features/presentation/widgets/article_saved_item.dart';

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
  static const int _adFrequency = 10;
  bool _isAdLoaded = false;

  final String _bannerAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-8433726715962091/9671028035'
      // iOS Banner Ad ID
      : 'ca-app-pub-8433726715962091/6360777917';

  final String _nativeAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-8433726715962091/5762012110'
      // iOS Native Ad ID
      : 'ca-app-pub-8433726715962091/8196603768';

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
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
        _listItems.insert(i + 1, nativeAd);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the saved articles list from the provider
    // This will rebuild the widget when the list changes
    final savedArticles = ref.watch(articleSavedListNotifierProvider);

    // Get theme data for color adaptation
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // When the saved articles list changes, update our list that includes ads
    _updateListWithAds(savedArticles);

    return Scaffold(
      // App bar with French title
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
