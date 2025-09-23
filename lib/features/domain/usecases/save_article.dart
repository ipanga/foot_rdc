import 'package:foot_rdc/features/domain/entities/article.dart';
import 'package:foot_rdc/features/domain/repositories/article_repository.dart';

class SaveArticle {
  final ArticleRepository repository;

  SaveArticle(this.repository);

  // This function will be called automatically when the class is instantiated
  Future<void> call(Article article) {
    return repository.addSavedArticle(article);
  }
}
