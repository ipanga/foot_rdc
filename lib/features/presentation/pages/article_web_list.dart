import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:foot_rdc/features/domain/entities/article.dart';
import 'package:foot_rdc/features/presentation/pages/article_details_page.dart';
import 'package:foot_rdc/main.dart';
import 'package:foot_rdc/features/presentation/widgets/article_list_item.dart';

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
          SnackBar(content: Text('Failed to load more articles: $error')),
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
          SnackBar(content: Text('Failed to refresh articles: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only watch the provider for the first page load when _allArticles is empty
    if (_allArticles.isEmpty) {
      // Query string passed to the provider to fetch the first page of articles.
      const input = "page=1&per_page=15";

      // Watch the provider that returns an AsyncValue<List<Article>>.
      // The UI will rebuild when the provider's state changes.
      final articlesAsync = ref.watch(fetchArticlesProvider(input));

      return Scaffold(
        appBar: AppBar(
          title: SvgPicture.asset(
            'assets/images/footrdc_header_cropped.svg',
            height: 24,
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(Colors.red, BlendMode.srcIn),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _onRefresh),
          ],
          elevation: 4.0,
          shadowColor: Colors.black26,
        ),
        // Use AsyncValue.when to handle loading, data and error states cleanly.
        body: articlesAsync.when(
          data: (articles) {
            // Update _allArticles with the first page
            if (articles.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _allArticles = articles;
                  });
                }
              });
            }

            // If the list is empty show a placeholder message.
            if (articles.isEmpty) {
              return const Center(child: Text('No articles'));
            }

            // Build a scrollable list of articles.
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: articles.length,
                itemBuilder: (context, index) {
                  final article = articles[index];
                  // Navigate to ArticleDetailsPage when tapping an item.
                  return InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ArticleDetailsPage(article: article),
                        ),
                      );
                    },
                    child: ArticleListItem(article: article),
                  );
                },
              ),
            );
          },
          // Show a spinner while loading.
          loading: () => const Center(child: CircularProgressIndicator()),
          // Render a simple error message on failure.
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      );
    }

    // Once we have articles loaded, render them independently of the provider
    return Scaffold(
      appBar: AppBar(
        title: SvgPicture.asset(
          'assets/images/footrdc_header_cropped.svg',
          height: 24,
          fit: BoxFit.contain,
          colorFilter: const ColorFilter.mode(Colors.red, BlendMode.srcIn),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _onRefresh),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _allArticles.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            // Show loading indicator at the bottom
            if (index == _allArticles.length) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final article = _allArticles[index];
            // Navigate to ArticleDetailsPage when tapping an item.
            return InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ArticleDetailsPage(article: article),
                  ),
                );
              },
              child: ArticleListItem(article: article),
            );
          },
        ),
      ),
    );
  }
}
