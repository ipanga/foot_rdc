// Flutter framework imports
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Internal app imports
import 'package:foot_rdc/features/presentation/pages/article_details_page.dart';
import 'package:foot_rdc/features/presentation/providers/article_provider.dart';
import 'package:foot_rdc/features/presentation/widgets/article_saved_item.dart';
import 'package:foot_rdc/l10n/app_localizations.dart';

/// A page that displays a list of saved articles.
///
/// This widget uses Riverpod to watch for changes in the saved articles list
/// and displays them in a scrollable list. Each article is rendered using
/// the [ArticleSavedItem] widget.
class ArticleSavedList extends ConsumerWidget {
  const ArticleSavedList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get localization instance
    final l10n = AppLocalizations.of(context)!;

    // Watch the saved articles list from the provider
    // This will rebuild the widget when the list changes
    final savedArticles = ref.watch(articleSavedListNotifierProvider);

    return Scaffold(
      // App bar with simple title
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          '|  ${l10n.savedArticles}',
          style: const TextStyle(
            color: Color(0xFFec3535),
            fontSize: 20,
            fontWeight: FontWeight.w500,
            fontFamily: 'Oswald',
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: false,
        elevation: 4.0,
        shadowColor: Colors.black26,
      ),

      // Main body content
      body: savedArticles.isEmpty
          // Show empty state when no articles are saved
          ? Center(child: Text(l10n.noSavedArticles))
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
