import 'package:foot_rdc/features/data/models/article_model.dart';
import 'package:hive/hive.dart';

class ArticleLocalDataSource {
  final Box<ArticleModel> articleBox;

  ArticleLocalDataSource(this.articleBox);

  List<ArticleModel> getArticles() {
    return articleBox.values.toList();
  }

  // Store the article using its domain 'id' as the Hive key. This ensures
  // we can later delete by the same id and avoid duplicates for the same
  // article.
  Future<void> addArticle(ArticleModel article) async {
    await articleBox.put(article.id, article);
  }

  // Delete the article. First try deleting by the article.id key (the
  // preferred approach). If that fails (older entries may have been stored
  // with auto-generated keys), fall back to searching the box values for a
  // matching article id and delete that key.
  Future<void> deleteArticle(ArticleModel article) async {
    // Preferred: delete by key equal to article.id
    try {
      if (articleBox.containsKey(article.id)) {
        await articleBox.delete(article.id);
        return;
      }

      // Fallback: find the key whose stored ArticleModel has the same id
      dynamic targetKey;
      for (final key in articleBox.keys) {
        final stored = articleBox.get(key);
        if (stored != null && stored.id == article.id) {
          targetKey = key;
          break;
        }
      }

      if (targetKey != null) {
        await articleBox.delete(targetKey);
      }
    } catch (_) {
      // Silently ignore Hive errors here; callers can handle errors if
      // needed. Keeping this resilient avoids crashing the app on delete.
    }
  }
}
