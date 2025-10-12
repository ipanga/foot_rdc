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

    // Get theme data for color adaptation
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
        elevation: 4.0,
        shadowColor: theme.brightness == Brightness.light
            ? Colors.black26
            : Colors.white24,
      ),

      // Main body content
      body: savedArticles.isEmpty
          // Show empty state when no articles are saved
          ? const Center(child: Text('Aucun article enregistré'))
          // Display articles in a scrollable list
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: savedArticles.length,
              itemBuilder: (context, index) {
                final article = savedArticles[index];

                return Dismissible(
                  key: ValueKey('saved-${article.imageUrl}-${article.title}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: Icon(
                      Icons.delete_forever_rounded,
                      size: 28,
                      color: colorScheme.onError,
                    ),
                  ),
                  onDismissed: (_) async {
                    await ref
                        .read(articleSavedListNotifierProvider.notifier)
                        .removeArticle(article);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Article supprimé'),
                        backgroundColor: colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 2),
                        action: SnackBarAction(
                          label: 'Annuler',
                          textColor: colorScheme.onError,
                          onPressed: () {
                            // Optional: re-add if you keep history elsewhere
                          },
                        ),
                      ),
                    );
                  },
                  child: ArticleSavedItem(
                    article: article,
                    // Handle tap to navigate to article details
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ArticleDetailsPage(article: article),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
