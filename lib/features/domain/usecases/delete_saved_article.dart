import 'package:foot_rdc/features/domain/entities/article.dart';
import 'package:foot_rdc/features/domain/repositories/article_repository.dart';

class DeleteSavedArticle {
  final ArticleRepository repository;

  DeleteSavedArticle(this.repository);

  // This function will be called automatically when the class is instantiated
  Future<void> call(Article article) {
    return repository.deleteSavedArticle(article);
  }
}
