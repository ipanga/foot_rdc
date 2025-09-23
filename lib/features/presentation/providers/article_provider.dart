import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/data/datasources/article_local_datasource.dart';
import 'package:foot_rdc/features/data/models/article_model.dart';
import 'package:foot_rdc/features/data/repositories/article_repository_impl.dart';
import 'package:foot_rdc/features/domain/entities/article.dart';
import 'package:foot_rdc/features/domain/repositories/article_repository.dart';
import 'package:foot_rdc/features/domain/usecases/save_article.dart';
import 'package:foot_rdc/features/domain/usecases/delete_saved_article.dart';
import 'package:foot_rdc/features/domain/usecases/get_saved_articles.dart';
import 'package:hive/hive.dart';

final articleLocalDataSourceProvider = Provider<ArticleLocalDataSource>((ref) {
  final Box<ArticleModel> articleBox = Hive.box('articles');
  return ArticleLocalDataSource(articleBox);
});

// Provider for article repository
// Implements repository pattern by connecting to local data source
final articleSavedRepositoryProvider = Provider<ArticleRepository>((ref) {
  final localDataSource = ref.read(articleLocalDataSourceProvider);
  return ArticleRepositoryImpl(localDataSource);
});

// Provider for adding new articles
// Provides use case for adding articles through the repository
final saveArticleProvider = Provider<SaveArticle>((ref) {
  final repository = ref.read(articleSavedRepositoryProvider);
  return SaveArticle(repository);
});

// Provider for retrieving articles
// Provides use case for getting all articles through the repository
final getSavedArticlesProvider = Provider<GetSavedArticles>((ref) {
  final repository = ref.read(articleSavedRepositoryProvider);
  return GetSavedArticles(repository);
});

// Provider for deleting articles
// Provides use case for deleting articles through the repository
final deleteArticleProvider = Provider<DeleteSavedArticle>((ref) {
  final repository = ref.read(articleSavedRepositoryProvider);
  return DeleteSavedArticle(repository);
});

final articleSavedListNotifierProvider =
    StateNotifierProvider<ArticleSavedListNotifier, List<Article>>((ref) {
      final getArticles = ref.read(getSavedArticlesProvider);
      final addArticle = ref.read(saveArticleProvider);
      final deleteArticle = ref.read(deleteArticleProvider);

      final notifier = ArticleSavedListNotifier(
        getArticles,
        addArticle,
        deleteArticle,
      );

      // Load saved articles when the notifier is created.
      // Use a microtask to avoid synchronous side-effects during provider init.
      Future.microtask(() => notifier.loadArticles());

      return notifier;
    });

class ArticleSavedListNotifier extends StateNotifier<List<Article>> {
  final GetSavedArticles _getArticles;
  final SaveArticle _addArticle;
  final DeleteSavedArticle _deleteArticle;

  ArticleSavedListNotifier(
    this._getArticles,
    this._addArticle,
    this._deleteArticle,
  ) : super([]);

  Future<void> addNewArticle(Article article) async {
    await _addArticle(article);
    // Refresh in-memory state after saving to the DB so the UI updates.
    await loadArticles();
  }

  Future<void> removeArticle(Article article) async {
    await _deleteArticle(article);
    await loadArticles();
  }

  Future<void> loadArticles() async {
    final articlesOrFailure = await _getArticles();
    articlesOrFailure.fold(
      (error) => state = [],
      (articles) => state = articles,
    );
  }
}
