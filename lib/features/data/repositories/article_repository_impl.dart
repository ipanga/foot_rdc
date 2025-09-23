import 'package:dartz/dartz.dart';
import 'package:foot_rdc/core_error/failures.dart';
import 'package:foot_rdc/features/data/datasources/article_local_datasource.dart';
import 'package:foot_rdc/features/data/models/article_model.dart';
import 'package:foot_rdc/features/domain/entities/article.dart';
import 'package:foot_rdc/features/domain/repositories/article_repository.dart';

class ArticleRepositoryImpl implements ArticleRepository {
  final ArticleLocalDataSource localDataSource;

  ArticleRepositoryImpl(this.localDataSource);

  @override
  Future<void> addSavedArticle(Article article) async {
    final articleModel = ArticleModel.fromEntity(
      article,
    ); // Convert Article entity to ArticleModel for database storage
    await localDataSource.addArticle(articleModel);
  }

  @override
  Future<void> deleteSavedArticle(Article article) async {
    final articleModel = ArticleModel.fromEntity(
      article,
    ); // Convert Article entity to ArticleModel
    await localDataSource.deleteArticle(articleModel);
  }

  @override
  Future<Either<Failure, List<Article>>> getSavedArticles() async {
    try {
      final articleModels = localDataSource.getArticles();

      // Convert List<ArticleModel> from database to List<Article> entity class
      List<Article> res = articleModels
          .map((model) => model.toEntity())
          .toList();
      return Right(
        res,
      ); // Return the list of Article entities wrapped in Right of Either type
    } catch (err) {
      return Left(
        SomeSpecificError(err.toString()),
      ); // Handle specific error and return as Left of Either type
    }
  }
}
