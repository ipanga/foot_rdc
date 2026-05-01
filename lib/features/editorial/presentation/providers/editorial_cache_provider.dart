import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/news/domain/entities/article.dart';

/// Holds the paginated list of editorial articles plus pagination state.
/// Mirrors [ArticleCacheState] for the news feed but stays isolated so the
/// two streams don't interfere with each other.
class EditorialCacheState {
  final List<Article> articles;
  final DateTime? lastRefreshTime;
  final int currentPage;
  final bool hasReachedEnd;

  const EditorialCacheState({
    required this.articles,
    this.lastRefreshTime,
    required this.currentPage,
    required this.hasReachedEnd,
  });

  EditorialCacheState copyWith({
    List<Article>? articles,
    DateTime? lastRefreshTime,
    int? currentPage,
    bool? hasReachedEnd,
  }) {
    return EditorialCacheState(
      articles: articles ?? this.articles,
      lastRefreshTime: lastRefreshTime ?? this.lastRefreshTime,
      currentPage: currentPage ?? this.currentPage,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
    );
  }

  bool get isEmpty => articles.isEmpty;

  bool isCacheValid({Duration validDuration = const Duration(minutes: 2)}) {
    if (lastRefreshTime == null) return false;
    return DateTime.now().difference(lastRefreshTime!) < validDuration;
  }
}

class EditorialCacheNotifier extends StateNotifier<EditorialCacheState> {
  EditorialCacheNotifier()
      : super(
          const EditorialCacheState(
            articles: [],
            currentPage: 1,
            hasReachedEnd: false,
          ),
        );

  void updateArticles(
    List<Article> articles, {
    required int perPage,
    bool isFirstPage = true,
  }) {
    if (isFirstPage) {
      state = state.copyWith(
        articles: articles,
        lastRefreshTime: DateTime.now(),
        currentPage: 1,
        hasReachedEnd: articles.length < perPage,
      );
    } else {
      final updated = [...state.articles, ...articles];
      state = state.copyWith(
        articles: updated,
        currentPage: state.currentPage + 1,
        hasReachedEnd: articles.isEmpty || articles.length < perPage,
      );
    }
  }

  void clearCache() {
    state = const EditorialCacheState(
      articles: [],
      currentPage: 1,
      hasReachedEnd: false,
    );
  }
}

final editorialCacheProvider =
    StateNotifierProvider<EditorialCacheNotifier, EditorialCacheState>((ref) {
  return EditorialCacheNotifier();
});
