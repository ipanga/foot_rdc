import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/domain/entities/article.dart';
import 'package:foot_rdc/features/presentation/pages/article_details_page.dart';
import 'package:foot_rdc/features/presentation/providers/theme_provider.dart';
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
        !_hasReachedEnd) {
      _loadMoreArticles();
    }
  }

  void _loadMoreArticles() async {
    if (_isLoadingMore || _hasReachedEnd) return;

    setState(() {
      _isLoadingMore = true;
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
      });
    } catch (error) {
      setState(() {
        _isLoadingMore = false;
      });
      // Handle error silently or show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Échec du chargement d\'articles supplémentaires: $error',
            ),
          ),
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
        _allArticles = []; // Clear the articles to trigger provider reload
      });

      // Invalidate the provider to force a fresh fetch
      ref.invalidate(fetchArticlesProvider);

      // Fetch fresh data from the first page
      const input = "page=1&per_page=15";
      final newArticles = await ref.read(fetchArticlesProvider(input).future);

      setState(() {
        _allArticles = newArticles;
      });
    } catch (error) {
      // Handle error silently or show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec de l\'actualisation des articles: $error'),
          ),
        );
      }
    }
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
    // Only watch the provider for the first page load when _allArticles is empty
    if (_allArticles.isEmpty) {
      const input = "page=1&per_page=15";
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
              return Center(child: Text('Aucun article trouvé'));
            }

            return RefreshIndicator(
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Erreur: $error')),
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
