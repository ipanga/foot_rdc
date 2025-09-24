import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/presentation/pages/article_details_page.dart';
import 'package:foot_rdc/features/presentation/widgets/article_list_item.dart';
import 'package:foot_rdc/features/presentation/widgets/custom_search_bar.dart';
import 'package:foot_rdc/main.dart';

class ArticleSearchList extends ConsumerStatefulWidget {
  const ArticleSearchList({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ArticleSearchState();
}

class _ArticleSearchState extends ConsumerState<ArticleSearchList> {
  // Form key to validate the search field.
  final _formKey = GlobalKey<FormState>();

  // Controller for the search TextField.
  final TextEditingController _controller = TextEditingController();

  // Holds the encoded query string passed to the provider after submit.
  // Null means "no search yet" so UI shows an empty list state.
  String? _query;

  // State management for pagination
  int _currentPage = 1;
  final int _perPage = 15;
  List<dynamic> _allArticles = [];
  bool _isLoadingMore = false;
  bool _hasReachedEnd = false;
  final ScrollController _scrollController = ScrollController();
  String? _currentSearchTerm;

  @override
  void initState() {
    super.initState();
    // Add scroll listener to detect when user reaches bottom
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    // Dispose the controller to avoid memory leaks.
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_hasReachedEnd &&
        _currentSearchTerm != null) {
      _loadMoreArticles();
    }
  }

  void _loadMoreArticles() async {
    if (_isLoadingMore || _hasReachedEnd || _currentSearchTerm == null) return;

    setState(() {
      _isLoadingMore = true;
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
    if (_currentSearchTerm == null) return;

    try {
      // Reset pagination state
      setState(() {
        _currentPage = 1;
        _hasReachedEnd = false;
        _isLoadingMore = false;
      });

      // Fetch fresh data from the first page
      final encoded = Uri.encodeQueryComponent(_currentSearchTerm!);
      final input = "page=1&per_page=$_perPage&search=$encoded";
      final newArticles = await ref.read(searchArticlesProvider(input).future);

      setState(() {
        _allArticles = newArticles;
        _query = input; // Update query to trigger UI refresh
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

  // Called when user taps the Go button or submits via the keyboard.
  // Validates the form and sets _query which triggers watching the provider.
  void _submitSearch() {
    if (_formKey.currentState?.validate() ?? false) {
      final term = _controller.text;
      if (term.isNotEmpty) {
        // Encode the search term for safe inclusion in a query string.
        final encoded = Uri.encodeQueryComponent(term);
        setState(() {
          // Reset pagination for new search
          _currentPage = 1;
          _hasReachedEnd = false;
          _isLoadingMore = false;
          _allArticles = [];
          _currentSearchTerm = term;
          // Build the query exactly as the provider expects.
          _query = "page=1&per_page=$_perPage&search=$encoded";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only watch the provider after a search has been submitted.
    // When _query is null, we intentionally do not call ref.watch so the
    // provider is not invoked and the UI shows the prior-empty state.
    final searchArticlesAsync = _query != null
        ? ref.watch(searchArticlesProvider(_query!))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('|  SEARCH ARTICLES'),
        centerTitle: false,
        //backgroundColor: Colors.white,
        elevation: 4.0,
        shadowColor: Colors.black26,
      ),
      body: Column(
        children: [
          // Search input area with validation and submit button.
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Form(
              key: _formKey,
              child: CustomSearchBar(
                controller: _controller,
                hintText: 'Type keywords (e.g. jackson muleka)',
                onSubmitted: _submitSearch,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter a search term';
                  }
                  return null;
                },
              ),
            ),
          ),
          // Results area:
          // - If no search has been performed yet, show an empty-message.
          // - Otherwise use AsyncValue.when to render loading/error/data.
          Expanded(
            child: Builder(
              builder: (context) {
                // Prior to searching we show an empty list (friendly message).
                if (searchArticlesAsync == null) {
                  return const Center(child: Text('No articles'));
                }

                // Handle provider states.
                return searchArticlesAsync.when(
                  data: (articles) {
                    // Update _allArticles with the first page if we don't have any articles yet
                    if (articles.isNotEmpty && _allArticles.isEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _allArticles = articles;
                          });
                        }
                      });
                    }

                    // If we have paginated articles, show them
                    if (_allArticles.isNotEmpty) {
                      return RefreshIndicator(
                        onRefresh: _onRefresh,
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount:
                              _allArticles.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Show loading indicator at the bottom
                            if (index == _allArticles.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final article = _allArticles[index];
                            // Navigate to ArticleDetailsPage when tapping an item.
                            return InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ArticleDetailsPage(article: article),
                                  ),
                                );
                              },
                              child: ArticleListItem(article: article),
                            );
                          },
                        ),
                      );
                    }

                    // If the list is empty show a placeholder message.
                    if (articles.isEmpty) {
                      return const Center(child: Text('No articles'));
                    }

                    // Build a scrollable list of articles (initial load).
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
                                  builder: (_) =>
                                      ArticleDetailsPage(article: article),
                                ),
                              );
                            },
                            child: ArticleListItem(article: article),
                          );
                        },
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
