import 'package:foot_rdc/features/news/domain/entities/article.dart';
import 'package:foot_rdc/features/news/domain/repositories/article_repository.dart';

class SaveArticle {
  final ArticleRepository repository;

  SaveArticle(this.repository);

  Future<void> call(Article article) async {
    await repository.saveArticle(article);
  }
}
