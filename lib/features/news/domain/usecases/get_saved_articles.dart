import 'package:dartz/dartz.dart';
import 'package:foot_rdc/core/errors/failures.dart';
import 'package:foot_rdc/features/news/domain/entities/article.dart';
import 'package:foot_rdc/features/news/domain/repositories/article_repository.dart';

class GetSavedArticles {
  final ArticleRepository repository;

  GetSavedArticles(this.repository);

  Future<Either<Failure, List<Article>>> call() async {
    return await repository.getSavedArticles();
  }
}
