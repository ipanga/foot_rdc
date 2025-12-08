import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/news/domain/entities/article.dart';
import 'package:foot_rdc/features/news/presentation/screens/article_detail_screen.dart';
import 'package:foot_rdc/features/news/presentation/widgets/article_list_item.dart';
import 'package:foot_rdc/features/news/presentation/providers/news_providers.dart';
import 'package:foot_rdc/shared/widgets/custom_search_bar.dart';
import 'package:foot_rdc/core/constants/ad_constants.dart';
import 'package:foot_rdc/core/theme/app_colors.dart';
import 'package:foot_rdc/core/theme/app_design_system.dart';
import 'package:foot_rdc/shared/widgets/app_snackbar.dart';
import 'dart:async';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();
  String? _query;

  int _currentPage = 1;
  final int _perPage = 15;
  final List<Object> _listItems = [];
  bool _isLoadingMore = false;
  bool _hasReachedEnd = false;
  final ScrollController _scrollController = ScrollController();
  String? _currentSearchTerm;

  bool _loadMoreError = false;

  BannerAd? _bannerAd;
  static const int _adFrequency = 9;
  bool _isAdLoaded = false;
  final Map<NativeAd, bool> _nativeAdLoaded = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadBannerAd();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _bannerAd?.dispose();
    _disposeNativeAds();
    super.dispose();
  }

  void _disposeNativeAds() {
    for (var item in _listItems) {
      if (item is NativeAd) {
        item.dispose();
      }
    }
    _nativeAdLoaded.clear();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdConstants.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  void _updateListWithAds(List<Article> articles) {
    _disposeNativeAds();
    _listItems.clear();
    for (int i = 0; i < articles.length; i++) {
      _listItems.add(articles[i]);
      if ((i + 1) % _adFrequency == 0 && i < articles.length - 1) {
        final nativeAd = NativeAd(
          adUnitId: AdConstants.nativeAdUnitId,
          listener: NativeAdListener(
            onAdLoaded: (ad) {
              if (mounted) {
                _nativeAdLoaded[ad as NativeAd] = true;
                setState(() {});
              }
            },
            onAdFailedToLoad: (ad, error) {
              ad.dispose();
            },
          ),
          request: const AdRequest(),
          nativeTemplateStyle: NativeTemplateStyle(
            templateType: TemplateType.medium,
          ),
        )..load();
        _nativeAdLoaded[nativeAd] = false;
        _listItems.insert(i + 1, nativeAd);
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_hasReachedEnd &&
        !_loadMoreError &&
        _currentSearchTerm != null) {
      _loadMoreArticles();
    }
  }

  void _loadMoreArticles() async {
    if (_isLoadingMore || _hasReachedEnd || _currentSearchTerm == null) return;

    setState(() {
      _isLoadingMore = true;
      _loadMoreError = false;
    });

    try {
      final nextPage = _currentPage + 1;
      final encoded = Uri.encodeQueryComponent(_currentSearchTerm!);
      final input = "page=$nextPage&per_page=$_perPage&search=$encoded";
      final newArticles = await ref.read(searchArticlesProvider(input).future);

      setState(() {
        if (newArticles.isEmpty) {
          _hasReachedEnd = true;
        } else {
          final currentArticles = _listItems.whereType<Article>().toList(
            growable: false,
          );
          _updateListWithAds(currentArticles + newArticles);
          _currentPage = nextPage;
        }
        _isLoadingMore = false;
        _loadMoreError = false;
      });
    } catch (error) {
      setState(() {
        _isLoadingMore = false;
        _loadMoreError = true;
      });
      if (mounted) {
        AppSnackbar.showError(
          context,
          message: _friendlyLoadMoreMessage(error),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    if (_currentSearchTerm == null) return;

    try {
      setState(() {
        _currentPage = 1;
        _hasReachedEnd = false;
        _isLoadingMore = false;
        _loadMoreError = false;
      });

      final encoded = Uri.encodeQueryComponent(_currentSearchTerm!);
      final input = "page=1&per_page=$_perPage&search=$encoded";
      final newArticles = await ref.read(searchArticlesProvider(input).future);

      setState(() {
        _updateListWithAds(newArticles);
        _query = input;
      });
    } catch (error) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          message: _friendlyGenericMessage(error),
        );
      }
    }
  }

  void _submitSearch() {
    if (_formKey.currentState?.validate() ?? false) {
      final term = _controller.text;
      if (term.isNotEmpty) {
        final encoded = Uri.encodeQueryComponent(term);
        setState(() {
          _currentPage = 1;
          _hasReachedEnd = false;
          _isLoadingMore = false;
          _loadMoreError = false;
          _listItems.clear();
          _currentSearchTerm = term;
          _query = "page=1&per_page=$_perPage&search=$encoded";
        });
      }
    }
  }

  bool _isNoInternet(Object error) =>
      error is SocketException ||
      error.toString().toLowerCase().contains('socketexception') ||
      error.toString().toLowerCase().contains('failed host lookup') ||
      error.toString().toLowerCase().contains('network is unreachable');

  bool _isTimeout(Object error) =>
      error is TimeoutException ||
      error.toString().toLowerCase().contains('timeout');

  String _friendlyTitle(Object error) {
    if (_isNoInternet(error)) return 'Pas de connexion internet';
    return 'Oups, un problème est survenu';
  }

  String _friendlyGenericMessage(Object error) {
    if (_isNoInternet(error)) {
      return 'Vérifiez votre connexion et réessayez.';
    }
    if (_isTimeout(error)) {
      return 'Le serveur met trop de temps à répondre. Réessayez.';
    }
    return 'Impossible de charger les articles. Veuillez réessayer.';
  }

  String _friendlyLoadMoreMessage(Object error) {
    if (_isNoInternet(error)) return 'Connexion absente. Réessayez.';
    if (_isTimeout(error)) return 'Délai dépassé. Réessayez.';
    return 'Impossible de charger plus d\'articles.';
  }

  IconData _friendlyIcon(Object error) {
    if (_isNoInternet(error)) return Icons.wifi_off_rounded;
    if (_isTimeout(error)) return Icons.schedule_rounded;
    return Icons.error_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
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
              'RECHERCHER',
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
      ),
      body: Column(
        children: [
          // Search bar container
          Container(
            padding: const EdgeInsets.all(AppDesignSystem.space16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDark
                  : AppColors.surfaceLight,
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? AppColors.borderSubtleDark
                      : AppColors.borderSubtleLight,
                  width: 1,
                ),
              ),
            ),
            child: Form(
              key: _formKey,
              child: CustomSearchBar(
                controller: _controller,
                hintText: 'Saisir les termes de recherche...',
                onSubmitted: _submitSearch,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Veuillez saisir un terme de recherche';
                  }
                  return null;
                },
              ),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_query == null) {
                  return _buildEmptySearchState(isDark, theme);
                }

                final searchArticlesAsync = ref.watch(
                  searchArticlesProvider(_query!),
                );

                return searchArticlesAsync.when(
                  data: (articles) {
                    if (articles.isNotEmpty && _listItems.isEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _updateListWithAds(articles);
                          });
                        }
                      });
                    }

                    if (_listItems.isNotEmpty) {
                      return _buildSearchResults(isDark, colorScheme);
                    }

                    if (articles.isEmpty) {
                      return _buildNoResultsState(isDark, theme);
                    }

                    return _buildSearchResults(isDark, colorScheme);
                  },
                  loading: () => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: AppDesignSystem.space16),
                        Text(
                          'Recherche en cours...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  error: (error, stack) => _buildErrorState(
                    error,
                    isDark,
                    colorScheme,
                    theme,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isAdLoaded && _bannerAd != null
          ? Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark
                    : AppColors.surfaceLight,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildEmptySearchState(bool isDark, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.space32,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.space24),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceContainerDark
                    : AppColors.surfaceContainerLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_rounded,
                size: 56,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
            const SizedBox(height: AppDesignSystem.space24),
            Text(
              'Rechercher des articles',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppDesignSystem.space8),
            Text(
              'Saisissez un terme de recherche ci-dessus\npour commencer',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(bool isDark, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.space32,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.space24),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceContainerDark
                    : AppColors.surfaceContainerLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 56,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
            const SizedBox(height: AppDesignSystem.space24),
            Text(
              'Aucun article trouvé',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppDesignSystem.space8),
            Text(
              'Essayez avec d\'autres termes de recherche',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(bool isDark, ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: colorScheme.primary,
      backgroundColor: isDark
          ? AppColors.surfaceElevatedDark
          : AppColors.surfaceLight,
      strokeWidth: 2.5,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: AppDesignSystem.space16),
        itemCount: _listItems.length + ((_isLoadingMore || _loadMoreError) ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _listItems.length) {
            if (_isLoadingMore) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppDesignSystem.space24,
                ),
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
            if (_loadMoreError) {
              return _buildLoadMoreError(isDark, colorScheme);
            }
          }

          final item = _listItems[index];

          if (item is NativeAd) {
            return _buildNativeAdItem(item, isDark);
          }

          final article = item as Article;
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

  Widget _buildLoadMoreError(bool isDark, ColorScheme colorScheme) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppDesignSystem.space16),
      child: Container(
        padding: const EdgeInsets.all(AppDesignSystem.space16),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceElevatedDark
              : AppColors.surfaceLight,
          borderRadius: AppDesignSystem.borderRadiusLg,
          border: Border.all(
            color: isDark
                ? AppColors.borderDark
                : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.space8),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withAlpha(isDark ? 40 : 60),
                borderRadius: AppDesignSystem.borderRadiusSm,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                color: colorScheme.error,
                size: 20,
              ),
            ),
            const SizedBox(width: AppDesignSystem.space12),
            Expanded(
              child: Text(
                'Erreur de chargement',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _loadMoreArticles,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réessayer'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDesignSystem.space12,
                  vertical: AppDesignSystem.space8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNativeAdItem(NativeAd item, bool isDark) {
    final isLoaded = _nativeAdLoaded[item] == true;
    if (!isLoaded) {
      return Container(
        height: 320,
        margin: const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.space16,
          vertical: AppDesignSystem.space8,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainerLight,
          borderRadius: AppDesignSystem.borderRadiusLg,
        ),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary.withAlpha(128),
            ),
          ),
        ),
      );
    }
    return Container(
      height: 320,
      margin: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.space16,
        vertical: AppDesignSystem.space8,
      ),
      decoration: BoxDecoration(
        borderRadius: AppDesignSystem.borderRadiusLg,
      ),
      clipBehavior: Clip.antiAlias,
      child: AdWidget(ad: item),
    );
  }

  Widget _buildErrorState(
    Object error,
    bool isDark,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final title = _friendlyTitle(error);
    final message = _friendlyGenericMessage(error);
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
              child: Icon(
                icon,
                size: 40,
                color: colorScheme.error,
              ),
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
              onPressed: () {
                if (_query != null) {
                  ref.invalidate(searchArticlesProvider(_query!));
                }
              },
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
}
