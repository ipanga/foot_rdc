import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/core/network/network_exceptions.dart' as network;
import 'package:foot_rdc/core/theme/app_colors.dart';
import 'package:foot_rdc/core/theme/app_design_system.dart';
import 'package:foot_rdc/features/editorial/presentation/providers/editorial_cache_provider.dart';
import 'package:foot_rdc/features/editorial/presentation/providers/editorial_providers.dart';
import 'package:foot_rdc/features/news/domain/entities/article.dart';
import 'package:foot_rdc/features/news/presentation/screens/article_detail_screen.dart';
import 'package:foot_rdc/features/news/presentation/widgets/article_list_item.dart';

/// Editorial feed for the WordPress category `bon-a-savoir`.
/// Slim sibling to [NewsListScreen] — same article entity and list item
/// widget, but no carousel and no native-ad insertion (lower ad density for
/// long-form content).
class EditorialListScreen extends ConsumerStatefulWidget {
  const EditorialListScreen({super.key});

  @override
  ConsumerState<EditorialListScreen> createState() =>
      EditorialListScreenState();
}

class EditorialListScreenState extends ConsumerState<EditorialListScreen>
    with AutomaticKeepAliveClientMixin {
  static const int _perPage = 15;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  final ScrollController _scrollController = ScrollController();
  bool _isFetching = false;
  bool _isLoadingMore = false;
  bool _loadMoreError = false;
  bool _hasInitialized = false;
  Object? _initialLoadError;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialDataWithCacheCheck();
      _hasInitialized = true;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Public entry point so [HomeScreen] can refresh the feed when this tab
  /// becomes visible after a long pause (lifecycle resume).
  void checkAndRefreshIfNeeded() {
    final cacheState = ref.read(editorialCacheProvider);
    if (cacheState.articles.isNotEmpty &&
        !cacheState.isCacheValid(validDuration: _cacheValidDuration)) {
      ref.read(editorialCacheProvider.notifier).clearCache();
    }
  }

  Future<void> _loadInitialDataWithCacheCheck() async {
    final cacheState = ref.read(editorialCacheProvider);
    if (cacheState.articles.isNotEmpty &&
        cacheState.isCacheValid(validDuration: _cacheValidDuration)) {
      return;
    }
    await _loadInitialData();
  }

  Future<int?> _resolveCategoryId() {
    return ref.read(editorialCategoryIdProvider.future);
  }

  Future<void> _loadInitialData() async {
    if (_isFetching) return;
    setState(() {
      _isFetching = true;
      _initialLoadError = null;
    });

    try {
      final categoryId = await _resolveCategoryId();
      if (categoryId == null) {
        if (mounted) {
          setState(() {
            _isFetching = false;
            _initialLoadError = const _MissingCategoryError();
          });
        }
        return;
      }

      final request = EditorialPageRequest(
        categoryId: categoryId,
        page: 1,
        perPage: _perPage,
      );
      final articles =
          await ref.read(fetchEditorialArticlesProvider(request).future);

      if (mounted) {
        ref
            .read(editorialCacheProvider.notifier)
            .updateArticles(articles, perPage: _perPage, isFirstPage: true);
        setState(() {
          _isFetching = false;
          _initialLoadError = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isFetching = false;
          _initialLoadError = error;
        });
      }
    }
  }

  Future<void> _loadMoreArticles() async {
    final cacheState = ref.read(editorialCacheProvider);
    if (_isLoadingMore || cacheState.hasReachedEnd || _isFetching) return;

    setState(() {
      _isLoadingMore = true;
      _loadMoreError = false;
    });

    try {
      final categoryId = await _resolveCategoryId();
      if (categoryId == null) {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
            _loadMoreError = true;
          });
        }
        return;
      }

      final nextPage = cacheState.currentPage + 1;
      final request = EditorialPageRequest(
        categoryId: categoryId,
        page: nextPage,
        perPage: _perPage,
      );
      final newArticles =
          await ref.read(fetchEditorialArticlesProvider(request).future);

      if (mounted) {
        ref
            .read(editorialCacheProvider.notifier)
            .updateArticles(newArticles, perPage: _perPage, isFirstPage: false);
        setState(() {
          _isLoadingMore = false;
          _loadMoreError = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _loadMoreError = true;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    if (_isFetching) return;
    ref.read(editorialCacheProvider.notifier).clearCache();
    ref.invalidate(editorialCategoryIdProvider);
    await _loadInitialData();
  }

  void _onScroll() {
    final cacheState = ref.read(editorialCacheProvider);
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !cacheState.hasReachedEnd &&
        !_loadMoreError &&
        !_isFetching) {
      _loadMoreArticles();
    }
  }

  bool _isNoInternet(Object error) =>
      error is network.NoInternetException ||
      error is SocketException ||
      error.toString().toLowerCase().contains('socketexception') ||
      error.toString().toLowerCase().contains('failed host lookup') ||
      error.toString().toLowerCase().contains('network is unreachable');

  bool _isTimeout(Object error) =>
      error is network.TimeoutException ||
      error is TimeoutException ||
      error.toString().toLowerCase().contains('timeout');

  String _friendlyTitle(Object error) {
    if (error is _MissingCategoryError) return 'Contenu indisponible';
    if (_isNoInternet(error)) return 'Pas de connexion internet';
    return 'Oups, un problème est survenu';
  }

  String _friendlyMessage(Object error) {
    if (error is _MissingCategoryError) {
      return 'La catégorie À Savoir n\'a pas été trouvée. Réessayez plus tard.';
    }
    if (_isNoInternet(error)) {
      return 'Vérifiez votre connexion et réessayez.';
    }
    if (_isTimeout(error)) {
      return 'Le serveur met trop de temps à répondre. Réessayez.';
    }
    return 'Impossible de charger les articles. Veuillez réessayer.';
  }

  IconData _friendlyIcon(Object error) {
    if (error is _MissingCategoryError) return Icons.search_off_rounded;
    if (_isNoInternet(error)) return Icons.wifi_off_rounded;
    if (_isTimeout(error)) return Icons.schedule_rounded;
    return Icons.error_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final cacheState = ref.watch(editorialCacheProvider);
    final articles = cacheState.articles;

    // Trigger a fetch if cache was cleared externally (e.g. via lifecycle).
    if (articles.isEmpty &&
        _hasInitialized &&
        !_isFetching &&
        _initialLoadError == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInitialData();
      });
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: _buildAppBar(theme, isDark, colorScheme),
      body: _buildBody(articles, theme, isDark, colorScheme, cacheState),
    );
  }

  PreferredSizeWidget _buildAppBar(
      ThemeData theme, bool isDark, ColorScheme colorScheme) {
    return AppBar(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      surfaceTintColor: Colors.transparent,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: AppDesignSystem.borderRadiusFull,
            ),
          ),
          const SizedBox(width: AppDesignSystem.space10),
          Text(
            'À SAVOIR',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFamily: 'Oswald',
              letterSpacing: 1.2,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: isDark ? Colors.black45 : Colors.black12,
    );
  }

  Widget _buildBody(
    List<Article> articles,
    ThemeData theme,
    bool isDark,
    ColorScheme colorScheme,
    EditorialCacheState cacheState,
  ) {
    if (articles.isNotEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        color: colorScheme.primary,
        backgroundColor:
            isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
        edgeOffset: AppDesignSystem.space8,
        displacement: 50,
        strokeWidth: 2.5,
        child: ListView.builder(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.only(
            top: AppDesignSystem.space8,
            bottom: AppDesignSystem.space16,
          ),
          itemCount: articles.length +
              (_isLoadingMore ? 1 : 0) +
              (_loadMoreError ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == articles.length && _isLoadingMore) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppDesignSystem.space24),
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: colorScheme.primary.withAlpha(180),
                    ),
                  ),
                ),
              );
            }
            if (index == articles.length && _loadMoreError) {
              return _buildLoadMoreError(theme, isDark, colorScheme);
            }
            final article = articles[index];
            return ArticleListItem(
              article: article,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ArticleDetailScreen(article: article),
                  ),
                );
              },
            );
          },
        ),
      );
    }

    if (_isFetching) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: colorScheme.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: AppDesignSystem.space16),
            Text(
              'Chargement des articles...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    if (_initialLoadError != null) {
      return _buildErrorState(theme, isDark, colorScheme, _initialLoadError!);
    }

    return _buildEmptyState(theme, isDark, colorScheme);
  }

  Widget _buildLoadMoreError(
      ThemeData theme, bool isDark, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(AppDesignSystem.space20),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 32,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
          const SizedBox(height: AppDesignSystem.space8),
          Text(
            'Erreur de chargement',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppDesignSystem.space12),
          TextButton.icon(
            onPressed: () {
              setState(() => _loadMoreError = false);
              _loadMoreArticles();
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Réessayer'),
            style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    ThemeData theme,
    bool isDark,
    ColorScheme colorScheme,
    Object error,
  ) {
    final title = _friendlyTitle(error);
    final message = _friendlyMessage(error);
    final icon = _friendlyIcon(error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.space32,
          vertical: AppDesignSystem.space20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.space20),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withAlpha(isDark ? 40 : 60),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: colorScheme.error),
            ),
            const SizedBox(height: AppDesignSystem.space20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppDesignSystem.space8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppDesignSystem.space24),
            FilledButton.icon(
              onPressed: _loadInitialData,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Réessayer'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDesignSystem.space24,
                  vertical: AppDesignSystem.space12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppDesignSystem.borderRadiusMd,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      ThemeData theme, bool isDark, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.space32,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.space20),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceContainerDark
                    : AppColors.surfaceContainerLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lightbulb_outline_rounded,
                size: 48,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
            const SizedBox(height: AppDesignSystem.space20),
            Text(
              'Aucun article pour le moment',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppDesignSystem.space8),
            Text(
              'Les analyses et focus paraîtront ici',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppDesignSystem.space24),
            OutlinedButton.icon(
              onPressed: _loadInitialData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Recharger'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDesignSystem.space20,
                  vertical: AppDesignSystem.space10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppDesignSystem.borderRadiusMd,
                ),
                side: BorderSide(color: colorScheme.primary.withAlpha(128)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingCategoryError implements Exception {
  const _MissingCategoryError();

  @override
  String toString() => 'editorial category not found';
}
