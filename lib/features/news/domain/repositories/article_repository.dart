import 'package:dartz/dartz.dart';
import 'package:foot_rdc/core/errors/failures.dart';
import 'package:foot_rdc/features/news/domain/entities/article.dart';

abstract class ArticleRepository {
  Future<Either<Failure, List<Article>>> getSavedArticles();
  Future<Either<Failure, void>> saveArticle(Article article);
  Future<Either<Failure, void>> deleteArticle(Article article);
  bool isArticleSaved(int articleId);
}
