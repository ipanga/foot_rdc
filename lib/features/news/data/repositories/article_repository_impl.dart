import 'package:dartz/dartz.dart';
import 'package:foot_rdc/core/errors/failures.dart';
import 'package:foot_rdc/features/news/data/datasources/article_local_datasource.dart';
import 'package:foot_rdc/features/news/data/models/article_model.dart';
import 'package:foot_rdc/features/news/domain/entities/article.dart';
import 'package:foot_rdc/features/news/domain/repositories/article_repository.dart';

class ArticleRepositoryImpl implements ArticleRepository {
  final ArticleLocalDataSource localDataSource;

  ArticleRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<Article>>> getSavedArticles() async {
    try {
      final articleModels = await localDataSource.getArticles();
      final articles = articleModels.map((model) => model.toEntity()).toList();
      return Right(articles);
    } catch (e) {
      return Left(SomeSpecificError('Failed to get saved articles: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveArticle(Article article) async {
    try {
      final articleModel = ArticleModel.fromEntity(article);
      await localDataSource.addArticle(articleModel);
      return const Right(null);
    } catch (e) {
      return Left(SomeSpecificError('Failed to save article: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteArticle(Article article) async {
    try {
      final articleModel = ArticleModel.fromEntity(article);
      await localDataSource.deleteArticle(articleModel);
      return const Right(null);
    } catch (e) {
      return Left(SomeSpecificError('Failed to delete article: $e'));
    }
  }

  @override
  bool isArticleSaved(int articleId) {
    return localDataSource.isArticleSaved(articleId);
  }
}
