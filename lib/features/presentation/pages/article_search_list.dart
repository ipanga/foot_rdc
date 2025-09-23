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

  @override
  void dispose() {
    // Dispose the controller to avoid memory leaks.
    _controller.dispose();
    super.dispose();
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
          // Build the query exactly as the provider expects.
          _query = "page=1&per_page=15&search=$encoded";
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
      appBar: AppBar(title: const Text('Search Articles')),
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
                    // If the list is empty show a placeholder message.
                    if (articles.isEmpty) {
                      return const Center(child: Text('No articles'));
                    }
                    // Build a scrollable list of articles.
                    return ListView.builder(
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
