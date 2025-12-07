import 'package:hive/hive.dart';
import 'package:foot_rdc/features/news/data/models/article_model.dart';

class ArticleLocalDataSource {
  final Box<ArticleModel> articleBox;

  ArticleLocalDataSource(this.articleBox);

  Future<List<ArticleModel>> getArticles() async {
    return articleBox.values.toList();
  }

  Future<void> addArticle(ArticleModel article) async {
    await articleBox.put(article.id, article);
  }

  Future<void> deleteArticle(ArticleModel article) async {
    // Try deleting by ID first (new entries use article.id as key)
    if (articleBox.containsKey(article.id)) {
      await articleBox.delete(article.id);
      return;
    }

    // Fallback: delete by matching ID (for legacy entries stored with auto-generated keys)
    final entries = articleBox.toMap().entries;
    for (final entry in entries) {
      if (entry.value.id == article.id) {
        await articleBox.delete(entry.key);
        return;
      }
    }
  }

  bool isArticleSaved(int articleId) {
    if (articleBox.containsKey(articleId)) {
      return true;
    }
    // Check by value for legacy entries
    return articleBox.values.any((article) => article.id == articleId);
  }
}
