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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Add scroll listener to detect when user reaches bottom
    _scrollController.addListener(_onScroll);

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
    super.dispose();
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

    // If cache is empty but we were initialized, reload data
    if (cacheState.articles.isEmpty && _hasInitialized && !_isFetching) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInitialData();
      });
    }

    // Show cached data if available
    if (cacheState.articles.isNotEmpty) {
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
                cacheState.articles.length +
                (_isLoadingMore ? 1 : 0) +
                (_loadMoreError ? 1 : 0),
            separatorBuilder: (context, index) => const SizedBox(height: 0),
            itemBuilder: (context, index) {
              // Loading indicator at the bottom
              if (index == cacheState.articles.length && _isLoadingMore) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              // Error retry button at the bottom
              if (index == cacheState.articles.length && _loadMoreError) {
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

              final article = cacheState.articles[index];
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
        // Update cache through provider
        ref
            .read(articleCacheProvider.notifier)
            .updateArticles(newArticles, isFirstPage: false);

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
