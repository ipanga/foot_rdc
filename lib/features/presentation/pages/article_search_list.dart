import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/presentation/pages/article_details_page.dart';
import 'package:foot_rdc/features/presentation/widgets/article_list_item.dart';
import 'package:foot_rdc/features/presentation/widgets/custom_search_bar.dart';
import 'package:foot_rdc/main.dart';
import 'dart:async';
import 'dart:io';

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

  // Indicates bottom "load more" failed and offers retry action.
  bool _loadMoreError = false;

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
      // Optional: you can still show a lightweight snackbar
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
      // Reset pagination state
      setState(() {
        _currentPage = 1;
        _hasReachedEnd = false;
        _isLoadingMore = false;
        _loadMoreError = false;
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_friendlyGenericMessage(error))));
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
          _loadMoreError = false;
          _allArticles = [];
          _currentSearchTerm = term;
          // Build the query exactly as the provider expects.
          _query = "page=1&per_page=$_perPage&search=$encoded";
        });
      }
    }
  }

  // Friendly messages (no URLs exposed)
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

  @override
  Widget build(BuildContext context) {
    // Get theme data for color adaptation
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
          // Search input area with validation and submit button.
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

          // Results area
          Expanded(
            child: Builder(
              builder: (context) {
                // Prior to searching we show an empty state message.
                if (_query == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 64,
                          color: colorScheme.outline.withOpacity(0.5),
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
                            color: colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Only watch the provider AFTER a search has been submitted.
                final searchArticlesAsync = ref.watch(
                  searchArticlesProvider(_query!),
                );

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
                        color: colorScheme.primary,
                        backgroundColor: colorScheme.surface,
                        child: ListView.separated(
                          controller: _scrollController,
                          itemCount:
                              _allArticles.length +
                              ((_isLoadingMore || _loadMoreError) ? 1 : 0),
                          separatorBuilder: (context, index) {
                            // Don't show separator before the loading/error indicator
                            if (index == _allArticles.length - 1 &&
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
                                    colorScheme.outline.withOpacity(0.3),
                                    colorScheme.outline.withOpacity(0.6),
                                    colorScheme.outline.withOpacity(0.3),
                                  ],
                                ),
                              ),
                            );
                          },
                          itemBuilder: (context, index) {
                            // Show loading or error indicator at the bottom
                            if (index == _allArticles.length) {
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
                              // Load-more error row with retry
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
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surface,
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

                    // If the search returned no results
                    if (articles.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 64,
                              color: colorScheme.outline.withOpacity(0.5),
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
                                color: colorScheme.onSurface.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Build a scrollable list of articles (initial load).
                    return RefreshIndicator(
                      onRefresh: _onRefresh,
                      color: colorScheme.primary,
                      backgroundColor: colorScheme.surface,
                      child: ListView.separated(
                        controller: _scrollController,
                        itemCount: articles.length,
                        separatorBuilder: (context, index) => Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 16.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.outline.withOpacity(0.3),
                                colorScheme.outline.withOpacity(0.6),
                                colorScheme.outline.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
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
                                    .withOpacity(0.35),
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
                                color: colorScheme.onSurface.withOpacity(0.8),
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
    );
  }
}
