import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/news/domain/entities/article.dart';
import 'package:foot_rdc/features/news/presentation/screens/article_detail_screen.dart';
import 'package:foot_rdc/features/news/presentation/widgets/article_list_item.dart';
import 'package:foot_rdc/features/news/presentation/providers/news_providers.dart';
import 'package:foot_rdc/shared/widgets/custom_search_bar.dart';
import 'package:foot_rdc/core/constants/ad_constants.dart';
import 'dart:async';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();
  String? _query;

  int _currentPage = 1;
  final int _perPage = 15;
  final List<Object> _listItems = [];
  bool _isLoadingMore = false;
  bool _hasReachedEnd = false;
  final ScrollController _scrollController = ScrollController();
  String? _currentSearchTerm;

  bool _loadMoreError = false;

  BannerAd? _bannerAd;
  static const int _adFrequency = 9;
  bool _isAdLoaded = false;
  final Map<NativeAd, bool> _nativeAdLoaded = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadBannerAd();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
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

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_hasReachedEnd &&
        !_loadMoreError &&
        _currentSearchTerm != null) {
      _loadMoreArticles();
    }
  }

  void _loadMoreArticles() async {
    if (_isLoadingMore || _hasReachedEnd || _currentSearchTerm == null) return;

    setState(() {
      _isLoadingMore = true;
      _loadMoreError = false;
    });

    try {
      final nextPage = _currentPage + 1;
      final encoded = Uri.encodeQueryComponent(_currentSearchTerm!);
      final input = "page=$nextPage&per_page=$_perPage&search=$encoded";
      final newArticles = await ref.read(searchArticlesProvider(input).future);

      setState(() {
        if (newArticles.isEmpty) {
          _hasReachedEnd = true;
        } else {
          final currentArticles = _listItems.whereType<Article>().toList(
            growable: false,
          );
          _updateListWithAds(currentArticles + newArticles);
          _currentPage = nextPage;
        }
        _isLoadingMore = false;
        _loadMoreError = false;
      });
    } catch (error) {
      setState(() {
        _isLoadingMore = false;
        _loadMoreError = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyLoadMoreMessage(error))),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    if (_currentSearchTerm == null) return;

    try {
      setState(() {
        _currentPage = 1;
        _hasReachedEnd = false;
        _isLoadingMore = false;
        _loadMoreError = false;
      });

      final encoded = Uri.encodeQueryComponent(_currentSearchTerm!);
      final input = "page=1&per_page=$_perPage&search=$encoded";
      final newArticles = await ref.read(searchArticlesProvider(input).future);

      setState(() {
        _updateListWithAds(newArticles);
        _query = input;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_friendlyGenericMessage(error))));
      }
    }
  }

  void _submitSearch() {
    if (_formKey.currentState?.validate() ?? false) {
      final term = _controller.text;
      if (term.isNotEmpty) {
        final encoded = Uri.encodeQueryComponent(term);
        setState(() {
          _currentPage = 1;
          _hasReachedEnd = false;
          _isLoadingMore = false;
          _loadMoreError = false;
          _listItems.clear();
          _currentSearchTerm = term;
          _query = "page=1&per_page=$_perPage&search=$encoded";
        });
      }
    }
  }

  bool _isNoInternet(Object error) => error is SocketException;
  bool _isTimeout(Object error) => error is TimeoutException;

  String _friendlyTitle(Object error) {
    if (_isNoInternet(error)) return 'Pas de connexion internet';
    return 'Oups, un problème est survenu';
  }

  String _friendlyGenericMessage(Object error) {
    if (_isNoInternet(error)) {
      return 'Vérifiez votre connexion et réessayez.';
    }
    if (_isTimeout(error)) {
      return 'Le serveur met trop de temps à répondre. Réessayez.';
    }
    return 'Impossible de charger les articles. Veuillez réessayer.';
  }

  String _friendlyLoadMoreMessage(Object error) {
    if (_isNoInternet(error)) return 'Connexion absente. Réessayez.';
    if (_isTimeout(error)) return 'Délai dépassé. Réessayez.';
    return 'Impossible de charger plus d\'articles.';
  }

  IconData _friendlyIcon(Object error) {
    if (_isNoInternet(error)) return Icons.wifi_off_rounded;
    if (_isTimeout(error)) return Icons.schedule_rounded;
    return Icons.error_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '|  RECHERCHER DES ARTICLES',
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Form(
              key: _formKey,
              child: CustomSearchBar(
                controller: _controller,
                hintText: 'Saisir les termes de recherche...',
                onSubmitted: _submitSearch,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Veuillez saisir un terme de recherche';
                  }
                  return null;
                },
              ),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_query == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 64,
                          color: colorScheme.outline.withAlpha(128),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Rechercher des articles',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Saisissez un terme de recherche ci-dessus\npour commencer',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorScheme.onSurface.withAlpha(179),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final searchArticlesAsync = ref.watch(
                  searchArticlesProvider(_query!),
                );

                return searchArticlesAsync.when(
                  data: (articles) {
                    if (articles.isNotEmpty && _listItems.isEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _updateListWithAds(articles);
                          });
                        }
                      });
                    }

                    if (_listItems.isNotEmpty) {
                      return RefreshIndicator(
                        onRefresh: _onRefresh,
                        color: colorScheme.primary,
                        backgroundColor: colorScheme.surface,
                        child: ListView.separated(
                          controller: _scrollController,
                          itemCount:
                              _listItems.length +
                              ((_isLoadingMore || _loadMoreError) ? 1 : 0),
                          separatorBuilder: (context, index) {
                            if (index == _listItems.length - 1 &&
                                (_isLoadingMore || _loadMoreError)) {
                              return const SizedBox.shrink();
                            }
                            return Container(
                              height: 1,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.outline.withAlpha(77),
                                    colorScheme.outline.withAlpha(153),
                                    colorScheme.outline.withAlpha(77),
                                  ],
                                ),
                              ),
                            );
                          },
                          itemBuilder: (context, index) {
                            if (index == _listItems.length) {
                              if (_isLoadingMore) {
                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                );
                              }
                              if (_loadMoreError) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 12.0,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: colorScheme.outline,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.wifi_off_rounded,
                                          color: colorScheme.error,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Impossible de charger plus d\'articles',
                                            style: TextStyle(
                                              color: colorScheme.onSurface,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          onPressed: _loadMoreArticles,
                                          icon: const Icon(
                                            Icons.refresh_rounded,
                                            size: 18,
                                          ),
                                          label: const Text('Réessayer'),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            }

                            final item = _listItems[index];

                            if (item is NativeAd) {
                              final isLoaded = _nativeAdLoaded[item] == true;
                              if (!isLoaded) {
                                return Container(
                                  height: 320,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8.0,
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
                                  vertical: 8.0,
                                ),
                                child: AdWidget(ad: item),
                              );
                            }

                            final article = item as Article;
                            return InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ArticleDetailScreen(article: article),
                                  ),
                                );
                              },
                              child: ArticleListItem(article: article),
                            );
                          },
                        ),
                      );
                    }

                    if (articles.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 64,
                              color: colorScheme.outline.withAlpha(128),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun article trouvé',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Essayez avec d\'autres termes de recherche',
                              style: TextStyle(
                                color: colorScheme.onSurface.withAlpha(179),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _onRefresh,
                      color: colorScheme.primary,
                      backgroundColor: colorScheme.surface,
                      child: ListView.separated(
                        controller: _scrollController,
                        itemCount: _listItems.length,
                        separatorBuilder: (context, index) => Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 16.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.outline.withAlpha(77),
                                colorScheme.outline.withAlpha(153),
                                colorScheme.outline.withAlpha(77),
                              ],
                            ),
                          ),
                        ),
                        itemBuilder: (context, index) {
                          final item = _listItems[index];

                          if (item is NativeAd) {
                            final isLoaded = _nativeAdLoaded[item] == true;
                            if (!isLoaded) {
                              return Container(
                                height: 320,
                                margin: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              );
                            }
                            return Container(
                              height: 320,
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: AdWidget(ad: item),
                            );
                          }

                          final article = item as Article;
                          return InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ArticleDetailScreen(article: article),
                                ),
                              );
                            },
                            child: ArticleListItem(article: article),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  ),
                  error: (error, stack) {
                    final title = _friendlyTitle(error);
                    final message = _friendlyGenericMessage(error);
                    final icon = _friendlyIcon(error);

                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 16.0,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer
                                    .withAlpha(89),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                icon,
                                size: 36,
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colorScheme.onSurface.withAlpha(204),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (_query != null) {
                                  ref.invalidate(
                                    searchArticlesProvider(_query!),
                                  );
                                }
                              },
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
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
