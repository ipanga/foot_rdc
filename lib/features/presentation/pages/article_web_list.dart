import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  @override
  Widget build(BuildContext context) {
    // Query string passed to the provider to fetch the first page of articles.
    const input = "page=1&per_page=15";

    // Watch the provider that returns an AsyncValue<List<Article>>.
    // The UI will rebuild when the provider's state changes.
    final articlesAsync = ref.watch(fetchArticlesProvider(input));

    return Scaffold(
      appBar: AppBar(title: const Text('Articles')),
      // Use AsyncValue.when to handle loading, data and error states cleanly.
      body: articlesAsync.when(
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
                      builder: (_) => ArticleDetailsPage(article: article),
                    ),
                  );
                },
                child: ArticleListItem(article: article),
              );
            },
          );
        },
        // Show a spinner while loading.
        loading: () => const Center(child: CircularProgressIndicator()),
        // Render a simple error message on failure.
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
