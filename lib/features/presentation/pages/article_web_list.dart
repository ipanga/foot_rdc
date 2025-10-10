import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/domain/entities/article.dart';
import 'package:foot_rdc/features/presentation/pages/article_details_page.dart';
import 'package:foot_rdc/main.dart';
import 'package:foot_rdc/features/presentation/widgets/article_list_item.dart';
import 'package:foot_rdc/features/presentation/widgets/app_drawer.dart';

/// A page that shows a list of articles fetched via a Riverpod provider.
class ArticleWebList extends ConsumerStatefulWidget {
  const ArticleWebList({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ArticleListState();
}

class _ArticleListState extends ConsumerState<ArticleWebList> {
  // State management for pagination
  int _currentPage = 1;
  final int _perPage = 15;
  List<Article> _allArticles = [];
  bool _isLoadingMore = false;
  bool _hasReachedEnd = false;
  final ScrollController _scrollController = ScrollController();

  // Load-more error flag to show inline retry at bottom
  bool _loadMoreError = false;

  @override
  void initState() {
    super.initState();
    // Add scroll listener to detect when user reaches bottom
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_hasReachedEnd &&
        !_loadMoreError) {
      _loadMoreArticles();
    }
  }

  void _loadMoreArticles() async {
    if (_isLoadingMore || _hasReachedEnd) return;

    setState(() {
      _isLoadingMore = true;
      _loadMoreError = false;
    });

    try {
      final nextPage = _currentPage + 1;
      final input = "page=$nextPage&per_page=$_perPage";
      final newArticles = await ref.read(fetchArticlesProvider(input).future);

      setState(() {
        if (newArticles.isEmpty) {
          _hasReachedEnd = true;
        } else {
          _allArticles.addAll(newArticles);
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
    try {
      // Reset pagination state
      setState(() {
        _currentPage = 1;
        _hasReachedEnd = false;
        _isLoadingMore = false;
        _loadMoreError = false;
        _allArticles = []; // Clear the articles to trigger provider reload
      });

      // Invalidate the provider to force a fresh fetch
      ref.invalidate(fetchArticlesProvider);

      // Fetch fresh data from the first page
      final input = "page=1&per_page=$_perPage";
      final newArticles = await ref.read(fetchArticlesProvider(input).future);

      setState(() {
        _allArticles = newArticles;
      });
    } catch (error) {
      if (mounted) {
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
    return 'Impossible de charger plus d’articles.';
  }

  IconData _friendlyIcon(Object error) {
    if (_isNoInternet(error)) return Icons.wifi_off_rounded;
    if (_isTimeout(error)) return Icons.schedule_rounded;
    return Icons.error_outline_rounded;
  }

  AppBar _buildAppBar() {
    return AppBar(
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Only watch the provider for the first page load when _allArticles is empty
    if (_allArticles.isEmpty) {
      final input = "page=1&per_page=$_perPage";
      final articlesAsync = ref.watch(fetchArticlesProvider(input));

      return Scaffold(
        appBar: _buildAppBar(),
        drawer: const AppDrawer(),
        body: articlesAsync.when(
          data: (articles) {
            if (articles.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _allArticles = articles;
                  });
                }
              });
            }

            if (articles.isEmpty) {
              return Center(
                child: Text(
                  'Aucun article trouvé',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              );
            }

            return RefreshIndicator(
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
                itemCount: articles.length,
                separatorBuilder: (context, index) => const SizedBox(height: 0),
                itemBuilder: (context, index) {
                  final article = articles[index];
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
            );
          },
          loading: () => Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          ),
          error: (error, stack) {
            final title = _friendlyTitle(error);
            final message = _friendlyGenericMessage(error);
            final icon = _friendlyIcon(error);

            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer.withOpacity(0.35),
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
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Retry loading more articles
                        _loadMoreArticles();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    // Once we have articles loaded, render them independently of the provider
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.surface,
        edgeOffset: 8,
        child: ListView.separated(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: _allArticles.length + (_isLoadingMore ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox(height: 0),
          itemBuilder: (context, index) {
            if (index == _allArticles.length) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final article = _allArticles[index];
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
}
