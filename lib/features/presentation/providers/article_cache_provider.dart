import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/domain/entities/article.dart';

class ArticleCacheState {
  final List<Article> articles;
  final DateTime? lastRefreshTime;
  final int currentPage;
  final bool hasReachedEnd;

  const ArticleCacheState({
    required this.articles,
    this.lastRefreshTime,
    required this.currentPage,
    required this.hasReachedEnd,
  });

  ArticleCacheState copyWith({
    List<Article>? articles,
    DateTime? lastRefreshTime,
    int? currentPage,
    bool? hasReachedEnd,
  }) {
    return ArticleCacheState(
      articles: articles ?? this.articles,
      lastRefreshTime: lastRefreshTime ?? this.lastRefreshTime,
      currentPage: currentPage ?? this.currentPage,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
    );
  }

  bool get isEmpty => articles.isEmpty;

  bool isCacheValid({Duration validDuration = const Duration(minutes: 2)}) {
    if (lastRefreshTime == null) return false;
    final now = DateTime.now();
    final timeSinceLastRefresh = now.difference(lastRefreshTime!);
    return timeSinceLastRefresh < validDuration;
  }
}

class ArticleCacheNotifier extends StateNotifier<ArticleCacheState> {
  ArticleCacheNotifier()
    : super(
        const ArticleCacheState(
          articles: [],
          currentPage: 1,
          hasReachedEnd: false,
        ),
      );

  void updateArticles(List<Article> articles, {bool isFirstPage = true}) {
    if (isFirstPage) {
      state = state.copyWith(
        articles: articles,
        lastRefreshTime: DateTime.now(),
        currentPage: 1,
        hasReachedEnd: articles.length < 15, // Assuming 15 per page
      );
    } else {
      final updatedArticles = [...state.articles, ...articles];
      state = state.copyWith(
        articles: updatedArticles,
        currentPage: state.currentPage + 1,
        hasReachedEnd: articles.isEmpty || articles.length < 15,
      );
    }
  }

  void clearCache() {
    state = const ArticleCacheState(
      articles: [],
      currentPage: 1,
      hasReachedEnd: false,
    );
  }
}

final articleCacheProvider =
    StateNotifierProvider<ArticleCacheNotifier, ArticleCacheState>((ref) {
      return ArticleCacheNotifier();
    });
