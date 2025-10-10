// Flutter framework imports
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Internal app imports
import 'package:foot_rdc/features/presentation/pages/article_details_page.dart';
import 'package:foot_rdc/features/presentation/providers/article_provider.dart';
import 'package:foot_rdc/features/presentation/widgets/article_saved_item.dart';

/// A page that displays a list of saved articles.
///
/// This widget uses Riverpod to watch for changes in the saved articles list
/// and displays them in a scrollable list. Each article is rendered using
/// the [ArticleSavedItem] widget.
class ArticleSavedList extends ConsumerWidget {
  const ArticleSavedList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the saved articles list from the provider
    // This will rebuild the widget when the list changes
    final savedArticles = ref.watch(articleSavedListNotifierProvider);

    return Scaffold(
      // App bar with French title
      appBar: AppBar(
        title: const Text(
          '|  ARTICLES ENREGISTRÉS',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            fontFamily: 'Oswald',
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: false,
      ),

      // Main body content
      body: savedArticles.isEmpty
          // Show empty state when no articles are saved
          ? const Center(child: Text('Aucun article enregistré'))
          // Display articles in a scrollable list
          : ListView.builder(
              itemCount: savedArticles.length,
              itemBuilder: (context, index) {
                final article = savedArticles[index];

                // Use the custom ArticleSavedItem widget for each article
                return ArticleSavedItem(
                  article: article,
                  // Handle tap to navigate to article details
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
  }
}
