import 'package:dartz/dartz.dart';
import 'package:foot_rdc/core_error/failures.dart';
import 'package:foot_rdc/features/domain/entities/article.dart';
import 'package:foot_rdc/features/domain/repositories/article_repository.dart';

class GetSavedArticles {
  final ArticleRepository repository;

  GetSavedArticles(this.repository);

  // This function will be called automatically when the class is instantiated
  Future<Either<Failure, List<Article>>> call() {
    return repository.getSavedArticles();
  }
}
