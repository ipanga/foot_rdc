import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
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
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('ArticleRepository.getSavedArticles failed: $e\n$st');
      }
      return Left(
        SomeSpecificError('Impossible de récupérer les articles enregistrés.'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> saveArticle(Article article) async {
    try {
      final articleModel = ArticleModel.fromEntity(article);
      await localDataSource.addArticle(articleModel);
      return const Right(null);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('ArticleRepository.saveArticle failed: $e\n$st');
      }
      return Left(SomeSpecificError('Impossible d\'enregistrer l\'article.'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteArticle(Article article) async {
    try {
      final articleModel = ArticleModel.fromEntity(article);
      await localDataSource.deleteArticle(articleModel);
      return const Right(null);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('ArticleRepository.deleteArticle failed: $e\n$st');
      }
      return Left(SomeSpecificError('Impossible de supprimer l\'article.'));
    }
  }

  @override
  bool isArticleSaved(int articleId) {
    return localDataSource.isArticleSaved(articleId);
  }
}
