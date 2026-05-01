import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/news/presentation/screens/article_detail_screen.dart';
import 'package:foot_rdc/features/news/presentation/providers/article_cache_provider.dart';
import 'package:foot_rdc/features/news/presentation/providers/news_providers.dart';
import 'package:foot_rdc/features/news/presentation/widgets/article_list_item.dart';
import 'package:foot_rdc/features/news/domain/entities/article.dart';
import 'package:foot_rdc/shared/widgets/app_drawer.dart';
import 'package:foot_rdc/shared/widgets/app_snackbar.dart';
import 'package:foot_rdc/shared/widgets/news_app_bar.dart';
import 'package:foot_rdc/features/search/presentation/screens/search_screen.dart';
import 'package:foot_rdc/core/theme/app_colors.dart';
import 'package:foot_rdc/core/theme/app_design_system.dart';
import 'package:foot_rdc/core/network/network_exceptions.dart' as network;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:foot_rdc/core/constants/ad_constants.dart';

class NewsListScreen extends ConsumerStatefulWidget {
  const NewsListScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends ConsumerState<NewsListScreen>
    with AutomaticKeepAliveClientMixin {
  final int _perPage = 15;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  bool _loadMoreError = false;
  bool _isFetching = false;
  Object? _initialLoadError;
  static const Duration _cacheValidDuration = Duration(minutes: 15);
  bool _hasInitialized = false;

  final List<Object> _listItems = [];
  static const int _adFrequency = 9;
  final Map<NativeAd, bool> _nativeAdLoaded = {};

  final String _nativeAdUnitId = AdConstants.nativeAdUnitId;

  final List<Map<String, String>> _carouselImages = [
    {
      'image': 'https://footrdc.com/image-sponsor-01',
      'link': 'https://footrdc.com/sponsor-n01',
    },
    {
      'image': 'https://footrdc.com/image-sponsor-02',
      'link': 'https://footrdc.com/sponsor-n02',
    },
    {
      'image': 'https://footrdc.com/image-sponsor-03',
      'link': 'https://footrdc.com/sponsor-n03',
    },
  ];
  int _currentCarouselIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasInitialized) {
      _checkCacheOnTabSwitch();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  void _updateListWithAds(List<Article> articles) {
    _disposeNativeAds();
    _listItems.clear();
    for (int i = 0; i < articles.length; i++) {
      _listItems.add(articles[i]);
      if ((i + 1) % _adFrequency == 0 && i >= 4 && i < articles.length - 1) {
        final nativeAd = NativeAd(
          adUnitId: _nativeAdUnitId,
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

  void _checkCacheOnTabSwitch() {
    final cacheState = ref.read(articleCacheProvider);
    if (cacheState.articles.isNotEmpty &&
        !cacheState.isCacheValid(validDuration: _cacheValidDuration)) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _forceRefresh();
        }
      });
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          message: 'Impossible d\'ouvrir le lien',
        );
      }
    }
  }

  Widget _buildCarousel() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(
        top: AppDesignSystem.space8,
        bottom: AppDesignSystem.space12,
      ),
      child: Column(
        children: [
          CarouselSlider(
            carouselController: _carouselController,
            options: CarouselOptions(
              height: 140,
              viewportFraction: 0.92,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayAnimationDuration: AppDesignSystem.durationSlow,
              autoPlayCurve: AppDesignSystem.curveEmphasized,
              enlargeCenterPage: true,
              enlargeFactor: 0.15,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentCarouselIndex = index;
                });
              },
            ),
            items: _carouselImages.map((imageData) {
              return Builder(
                builder: (BuildContext context) {
                  return GestureDetector(
                    onTap: () => _launchURL(imageData['link']!),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppDesignSystem.space4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: AppDesignSystem.borderRadiusXl,
                        boxShadow: isDark
                            ? AppShadows.cardDark
                            : AppShadows.cardLight,
                      ),
                      child: ClipRRect(
                        borderRadius: AppDesignSystem.borderRadiusXl,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              imageData['image']!,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: isDark
                                      ? AppColors.surfaceContainerDark
                                      : AppColors.surfaceContainerLight,
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
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: isDark
                                      ? AppColors.surfaceContainerDark
                                      : AppColors.surfaceContainerLight,
                                  child: Center(
                                    child: Icon(
                                      Icons.image_outlined,
                                      size: 40,
                                      color: isDark
                                          ? AppColors.textTertiaryDark
                                          : AppColors.textTertiaryLight,
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Subtle gradient overlay for better visual depth
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withAlpha(30),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppDesignSystem.space12),
          // Modern dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _carouselImages.asMap().entries.map((entry) {
              final isActive = _currentCarouselIndex == entry.key;
              return AnimatedContainer(
                duration: AppDesignSystem.durationFast,
                curve: AppDesignSystem.curveDefault,
                width: isActive ? 24.0 : 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(horizontal: 3.0),
                decoration: BoxDecoration(
                  borderRadius: AppDesignSystem.borderRadiusFull,
                  color: isActive
                      ? colorScheme.primary
                      : (isDark
                          ? AppColors.neutral600
                          : AppColors.neutral300),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final cacheState = ref.watch(articleCacheProvider);

    if (cacheState.articles.isNotEmpty &&
        (_listItems.isEmpty ||
            _listItems.where((e) => e is! NativeAd).length !=
                cacheState.articles.length)) {
      _updateListWithAds(cacheState.articles);
    }

    if (cacheState.articles.isEmpty &&
        _hasInitialized &&
        !_isFetching &&
        _initialLoadError == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInitialData();
      });
    }

    if (_listItems.isNotEmpty) {
      return Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        appBar: _buildAppBar(),
        drawer: const AppDrawer(),
        onDrawerChanged: (isOpen) {
          if (!isOpen) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }
        },
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          color: colorScheme.primary,
          backgroundColor: isDark
              ? AppColors.surfaceElevatedDark
              : AppColors.surfaceLight,
          edgeOffset: AppDesignSystem.space8,
          displacement: 50,
          strokeWidth: 2.5,
          child: ListView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.only(
              bottom: AppDesignSystem.space16,
            ),
            itemCount:
                _listItems.length +
                1 +
                (_isLoadingMore ? 1 : 0) +
                (_loadMoreError ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildCarousel();
              }

              final adjustedIndex = index - 1;

              if (adjustedIndex == _listItems.length && _isLoadingMore) {
                return _buildLoadingMore();
              }

              if (adjustedIndex == _listItems.length && _loadMoreError) {
                return _buildLoadMoreError();
              }

              final item = _listItems[adjustedIndex];

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
        ),
      );
    }

    if (_isFetching) {
      return Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        appBar: _buildAppBar(),
        drawer: const AppDrawer(),
        onDrawerChanged: (isOpen) {
          if (!isOpen) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }
        },
        body: Center(
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
        ),
      );
    }

    if (_initialLoadError != null) {
      return _buildErrorState(isDark, colorScheme, theme);
    }

    return _buildEmptyState(isDark, colorScheme, theme);
  }

  Widget _buildLoadingMore() {
    final colorScheme = Theme.of(context).colorScheme;

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

  Widget _buildLoadMoreError() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

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
              setState(() {
                _loadMoreError = false;
              });
              _loadMoreArticles();
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Réessayer'),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesignSystem.space16,
                vertical: AppDesignSystem.space8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNativeAdItem(NativeAd item, bool isDark) {
    final isLoaded = _nativeAdLoaded[item] == true;
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
      clipBehavior: Clip.antiAlias,
      child: isLoaded
          ? AdWidget(ad: item)
          : Center(
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

  Widget _buildErrorState(bool isDark, ColorScheme colorScheme, ThemeData theme) {
    final title = _friendlyTitle(_initialLoadError!);
    final message = _friendlyGenericMessage(_initialLoadError!);
    final icon = _friendlyIcon(_initialLoadError!);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: _buildAppBar(),
      drawer: const AppDrawer(),
      body: Center(
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
                onPressed: _loadInitialData,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Reessayer'),
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
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, ColorScheme colorScheme, ThemeData theme) {
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: _buildAppBar(),
      drawer: const AppDrawer(),
      onDrawerChanged: (isOpen) {
        if (!isOpen) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
      },
      body: Center(
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
                  Icons.article_outlined,
                  size: 48,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
              ),
              const SizedBox(height: AppDesignSystem.space20),
              Text(
                'Aucun article trouve',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: AppDesignSystem.space8),
              Text(
                'Les articles seront affiches ici',
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
                  side: BorderSide(
                    color: colorScheme.primary.withAlpha(128),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadInitialDataWithCacheCheck() async {
    final cacheState = ref.read(articleCacheProvider);
    if (cacheState.articles.isNotEmpty &&
        cacheState.isCacheValid(validDuration: _cacheValidDuration)) {
      return;
    }
    await _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (_isFetching) return;

    setState(() {
      _isFetching = true;
      _initialLoadError = null;
    });

    try {
      final input = "page=1&per_page=$_perPage";
      final articles = await ref.read(fetchArticlesProvider(input).future);

      if (mounted) {
        ref
            .read(articleCacheProvider.notifier)
            .updateArticles(articles, isFirstPage: true);

        _updateListWithAds(articles);

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

  void _onScroll() {
    final cacheState = ref.read(articleCacheProvider);

    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !cacheState.hasReachedEnd &&
        !_loadMoreError &&
        !_isFetching) {
      _loadMoreArticles();
    }
  }

  void _loadMoreArticles() async {
    final cacheState = ref.read(articleCacheProvider);

    if (_isLoadingMore || cacheState.hasReachedEnd || _isFetching) return;

    setState(() {
      _isLoadingMore = true;
      _loadMoreError = false;
    });

    try {
      final nextPage = cacheState.currentPage + 1;
      final input = "page=$nextPage&per_page=$_perPage";
      final newArticles = await ref.read(fetchArticlesProvider(input).future);

      if (mounted) {
        final currentArticles = ref.read(articleCacheProvider).articles;
        ref
            .read(articleCacheProvider.notifier)
            .updateArticles(newArticles, isFirstPage: false);

        _updateListWithAds(currentArticles + newArticles);

        setState(() {
          _isLoadingMore = false;
          _loadMoreError = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _loadMoreError = true;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _forceRefresh();
  }

  Future<void> _forceRefresh() async {
    if (_isFetching) return;

    try {
      setState(() {
        _isFetching = true;
        _isLoadingMore = false;
        _loadMoreError = false;
        _initialLoadError = null;
      });

      ref.invalidate(fetchArticlesProvider);

      final input = "page=1&per_page=$_perPage";
      final newArticles = await ref.read(fetchArticlesProvider(input).future);

      if (mounted) {
        ref
            .read(articleCacheProvider.notifier)
            .updateArticles(newArticles, isFirstPage: true);

        _updateListWithAds(newArticles);

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

  bool _isNoInternet(Object error) =>
      error is network.NoInternetException ||
      error is SocketException ||
      error.toString().toLowerCase().contains('socketexception') ||
      error.toString().toLowerCase().contains('failed host lookup') ||
      error.toString().toLowerCase().contains('network is unreachable') ||
      error.toString().toLowerCase().contains('connection error');

  bool _isTimeout(Object error) =>
      error is network.TimeoutException ||
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

  IconData _friendlyIcon(Object error) {
    if (_isNoInternet(error)) return Icons.wifi_off_rounded;
    if (_isTimeout(error)) return Icons.schedule_rounded;
    return Icons.error_outline_rounded;
  }

  PreferredSizeWidget _buildAppBar() {
    return NewsAppBar(
      onSearchPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SearchScreen(),
          ),
        );
      },
    );
  }
}
