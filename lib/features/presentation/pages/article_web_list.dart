import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/presentation/pages/article_details_page.dart';
import 'package:foot_rdc/features/presentation/providers/article_cache_provider.dart';
import 'package:foot_rdc/main.dart';
import 'package:foot_rdc/features/presentation/widgets/article_list_item.dart';
import 'package:foot_rdc/features/presentation/widgets/app_drawer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// A page that shows a list of articles fetched via a Riverpod provider.
class ArticleWebList extends ConsumerStatefulWidget {
  const ArticleWebList({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ArticleListState();
}

class _ArticleListState extends ConsumerState<ArticleWebList>
    with AutomaticKeepAliveClientMixin {
  // State management for pagination
  final int _perPage = 15;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  // Load-more error flag to show inline retry at bottom
  bool _loadMoreError = false;

  // Track if we're currently fetching to prevent multiple simultaneous requests
  bool _isFetching = false;

  static const Duration _cacheValidDuration = Duration(minutes: 15);

  // Track if this is the first time the widget is being built
  bool _hasInitialized = false;

  // Admob state
  BannerAd? _bannerAd;
  final List<Object> _listItems = [];
  static const int _adFrequency = 9;
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
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Add scroll listener to detect when user reaches bottom
    _scrollController.addListener(_onScroll);

    _loadBannerAd();

    // Load initial data with cache check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialDataWithCacheCheck();
      _hasInitialized = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This is called when the widget becomes visible
    if (_hasInitialized) {
      _checkCacheOnTabSwitch();
    }
  }

  @override
  void dispose() {
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
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  void _updateListWithAds(List<dynamic> articles) {
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

  // Check cache when user switches back to this tab
  void _checkCacheOnTabSwitch() {
    final cacheState = ref.read(articleCacheProvider);

    // If cache has expired, refresh automatically
    if (cacheState.articles.isNotEmpty &&
        !cacheState.isCacheValid(validDuration: _cacheValidDuration)) {
      // Add a small delay to ensure the tab switch is complete
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _forceRefresh();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final colorScheme = Theme.of(context).colorScheme;
    final cacheState = ref.watch(articleCacheProvider);

    if (cacheState.articles.isNotEmpty &&
        (_listItems.isEmpty ||
            _listItems.where((e) => e is! NativeAd).length !=
                cacheState.articles.length)) {
      _updateListWithAds(cacheState.articles);
    }

    // If cache is empty but we were initialized, reload data
    if (cacheState.articles.isEmpty && _hasInitialized && !_isFetching) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInitialData();
      });
    }

    // Show cached data if available
    if (_listItems.isNotEmpty) {
      return Scaffold(
        appBar: _buildAppBar(),
        drawer: const AppDrawer(),
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          color: colorScheme.primary,
          backgroundColor: colorScheme.surface,
          edgeOffset: 8,
          child: ListView.separated(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount:
                _listItems.length +
                (_isLoadingMore ? 1 : 0) +
                (_loadMoreError ? 1 : 0),
            separatorBuilder: (context, index) => const SizedBox(height: 0),
            itemBuilder: (context, index) {
              // Loading indicator at the bottom
              if (index == _listItems.length && _isLoadingMore) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              // Error retry button at the bottom
              if (index == _listItems.length && _loadMoreError) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _loadMoreError = false;
                        });
                        _loadMoreArticles();
                      },
                      child: const Text('Réessayer'),
                    ),
                  ),
                );
              }

              final item = _listItems[index];

              if (item is NativeAd) {
                return Container(
                  height: 320,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: AdWidget(ad: item),
                );
              }

              final article = item as dynamic;
              return ArticleListItem(
                article: article,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ArticleDetailsPage(article: article),
                    ),
                  );
                },
              );
            },
          ),
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

    // Show loading state when fetching
    if (_isFetching) {
      return Scaffold(
        appBar: _buildAppBar(),
        drawer: const AppDrawer(),
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    // Show empty state if no articles
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: const AppDrawer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Aucun article trouvé',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInitialData,
              child: const Text('Recharger'),
            ),
          ],
        ),
      ),
    );
  }

  // New method to check cache validity before loading
  Future<void> _loadInitialDataWithCacheCheck() async {
    final cacheState = ref.read(articleCacheProvider);

    // If we have cached data and it's still valid, don't refresh
    if (cacheState.articles.isNotEmpty &&
        cacheState.isCacheValid(validDuration: _cacheValidDuration)) {
      return;
    }

    // Otherwise, load fresh data
    await _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (_isFetching) return;

    setState(() {
      _isFetching = true;
    });

    try {
      final input = "page=1&per_page=$_perPage";
      final articles = await ref.read(fetchArticlesProvider(input).future);

      if (mounted) {
        // Update cache through provider
        ref
            .read(articleCacheProvider.notifier)
            .updateArticles(articles, isFirstPage: true);

        _updateListWithAds(articles);

        setState(() {
          _isFetching = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isFetching = false;
        });
      }
    }
  }

  void _onScroll() {
    final cacheState = ref.read(articleCacheProvider);

    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !cacheState.hasReachedEnd &&
        !_loadMoreError &&
        !_isFetching) {
      _loadMoreArticles();
    }
  }

  void _loadMoreArticles() async {
    final cacheState = ref.read(articleCacheProvider);

    if (_isLoadingMore || cacheState.hasReachedEnd || _isFetching) return;

    setState(() {
      _isLoadingMore = true;
      _loadMoreError = false;
    });

    try {
      final nextPage = cacheState.currentPage + 1;
      final input = "page=$nextPage&per_page=$_perPage";
      final newArticles = await ref.read(fetchArticlesProvider(input).future);

      if (mounted) {
        final currentArticles = ref.read(articleCacheProvider).articles;
        // Update cache through provider
        ref
            .read(articleCacheProvider.notifier)
            .updateArticles(newArticles, isFirstPage: false);

        _updateListWithAds(currentArticles + newArticles);

        setState(() {
          _isLoadingMore = false;
          _loadMoreError = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _loadMoreError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyLoadMoreMessage(error))),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    await _forceRefresh();
  }

  Future<void> _forceRefresh() async {
    if (_isFetching) return;

    try {
      setState(() {
        _isFetching = true;
        _isLoadingMore = false;
        _loadMoreError = false;
      });

      // Invalidate the provider to force a fresh fetch
      ref.invalidate(fetchArticlesProvider);

      // Fetch fresh data from the first page
      final input = "page=1&per_page=$_perPage";
      final newArticles = await ref.read(fetchArticlesProvider(input).future);

      if (mounted) {
        // Update cache through provider
        ref
            .read(articleCacheProvider.notifier)
            .updateArticles(newArticles, isFirstPage: true);

        _updateListWithAds(newArticles);

        setState(() {
          _isFetching = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isFetching = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_friendlyGenericMessage(error))));
      }
    }
  }

  // Friendly helpers (no URLs exposed)
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

  AppBar _buildAppBar() {
    final scheme = Theme.of(context).colorScheme;

    return AppBar(
      leading: Builder(
        builder: (context) => IconButton(
          tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: SvgPicture.asset(
            'assets/images/menu-icon.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(scheme.onSurface, BlendMode.srcIn),
          ),
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Image.asset(
            'assets/images/logo_splash_footrdc.png',
            height: 50,
            fit: BoxFit.contain,
          ),
          Text(
            'FOOTRDC.COM',
            style: Theme.of(context).appBarTheme.titleTextStyle,
          ),
        ],
      ),
    );
  }
}
