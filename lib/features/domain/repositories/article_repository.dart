import 'package:dartz/dartz.dart';
import 'package:foot_rdc/core_error/failures.dart';
import 'package:foot_rdc/features/domain/entities/article.dart';

abstract class ArticleRepository {
  Future<Either<Failure, List<Article>>> getSavedArticles();
  Future<void> addSavedArticle(Article article);
  Future<void> deleteSavedArticle(Article article);
}
