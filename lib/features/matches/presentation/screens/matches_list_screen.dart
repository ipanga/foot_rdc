import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/matches/domain/entities/match.dart';
import 'package:foot_rdc/features/matches/presentation/widgets/match_list_item.dart';
import 'package:foot_rdc/features/matches/presentation/providers/match_cache_provider.dart';
import 'package:foot_rdc/features/matches/presentation/providers/match_providers.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:foot_rdc/core/constants/ad_constants.dart';

class MatchesListScreen extends ConsumerStatefulWidget {
  const MatchesListScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MatchesListScreenState();
}

class _MatchesListScreenState extends ConsumerState<MatchesListScreen> {
  final int _perPage = 10;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  bool _hasInitialLoaded = false;
  bool _isBackgroundRefreshing = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  bool _loadMoreError = false;
  Object? _loadMoreErrorDetails;
  MatchCacheState? _previousCacheState;
  Object? _initialLoadError;

  BannerAd? _bannerAd;
  final List<Object> _listItems = [];
  static const int _adFrequency = 10;
  bool _isAdLoaded = false;
  final Map<NativeAd, bool> _nativeAdLoaded = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadBannerAd();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadInitialData();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounceTimer?.cancel();
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

  void _updateListWithAds(List<Match> matches) {
    _disposeNativeAds();
    _listItems.clear();
    for (int i = 0; i < matches.length; i++) {
      _listItems.add(matches[i]);
      if ((i + 1) % _adFrequency == 0 && i < matches.length - 1) {
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

  void _checkAndLoadInitialData() {
    final cacheState = ref.read(matchCacheProvider);

    if (cacheState.isEmpty || !cacheState.isCacheValid()) {
      _loadInitialData();
    } else {
      setState(() {
        _hasInitialLoaded = true;
        _initialLoadError = null;
      });
    }
  }

  void _checkForCacheCleared(MatchCacheState currentCache) {
    if (_previousCacheState != null &&
        _previousCacheState!.isNotEmpty &&
        currentCache.isEmpty &&
        _hasInitialLoaded &&
        !_isRefreshing &&
        !_isBackgroundRefreshing &&
        mounted) {
      _loadInitialData(isBackgroundRefresh: true);
    }

    _previousCacheState = currentCache;
  }

  Future<void> _loadInitialData({bool isBackgroundRefresh = false}) async {
    if (mounted && !isBackgroundRefresh) {
      setState(() {
        _initialLoadError = null;
      });
    }

    try {
      if (isBackgroundRefresh && mounted) {
        setState(() {
          _isBackgroundRefreshing = true;
        });
      }

      final input = "seasons=821&page=1&per_page=$_perPage";
      final matches = await ref.read(fetchMatchesProvider(input).future);

      if (mounted) {
        ref.read(matchCacheProvider.notifier).updateMatches(matches);
        _updateListWithAds(matches);

        setState(() {
          _hasInitialLoaded = true;
          if (isBackgroundRefresh) {
            _isBackgroundRefreshing = false;
          }
          _initialLoadError = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _hasInitialLoaded = true;
          if (isBackgroundRefresh) {
            _isBackgroundRefreshing = false;
          } else {
            _initialLoadError = error;
          }
        });
      }
    }
  }

  void _onScroll() {
    if (!mounted) return;

    final cacheState = ref.read(matchCacheProvider);

    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !cacheState.hasReachedEnd &&
        !_isRefreshing &&
        !_loadMoreError) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted) {
          _loadMore();
        }
      });
    }
  }

  Future<void> _loadMore() async {
    if (!mounted) return;

    final cacheState = ref.read(matchCacheProvider);

    if (_isLoadingMore || cacheState.hasReachedEnd || _isRefreshing) return;

    if (mounted) {
      setState(() {
        _isLoadingMore = true;
        _loadMoreError = false;
        _loadMoreErrorDetails = null;
      });
    }

    try {
      final nextPage = cacheState.currentPage + 1;
      final input = "seasons=821&page=$nextPage&per_page=$_perPage";
      final newMatches = await ref.read(fetchMatchesProvider(input).future);

      if (mounted) {
        final currentMatches = ref.read(matchCacheProvider).matches;
        ref
            .read(matchCacheProvider.notifier)
            .updateMatches(newMatches, isLoadMore: true);
        _updateListWithAds(currentMatches + newMatches);

        setState(() {
          _isLoadingMore = false;
          _loadMoreError = false;
          _loadMoreErrorDetails = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _loadMoreError = true;
          _loadMoreErrorDetails = error;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;

    try {
      setState(() {
        _isRefreshing = true;
        _isLoadingMore = false;
        _loadMoreError = false;
        _loadMoreErrorDetails = null;
      });

      ref.read(matchCacheProvider.notifier).clearCache();
      await _loadInitialData();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_friendlyGenericMessage(error))));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  bool _isNoInternet(Object error) => error is SocketException;
  bool _isTimeout(Object error) => error is TimeoutException;

  String _friendlyTitle(Object error) {
    if (_isNoInternet(error)) return 'Pas de connexion internet';
    return 'Oups, un probleme est survenu';
  }

  String _friendlyGenericMessage(Object error) {
    if (_isNoInternet(error)) {
      return 'Verifiez votre connexion et reessayez.';
    }
    if (_isTimeout(error)) {
      return 'Le serveur met trop de temps a repondre. Reessayez.';
    }
    return 'Impossible de charger les matchs. Veuillez reessayer.';
  }

  String _friendlyLoadMoreMessage(Object error) {
    if (_isNoInternet(error)) return 'Connexion absente. Reessayez.';
    if (_isTimeout(error)) return 'Delai depasse. Reessayez.';
    return 'Impossible de charger plus de matchs.';
  }

  IconData _friendlyIcon(Object error) {
    if (_isNoInternet(error)) return Icons.wifi_off_rounded;
    if (_isTimeout(error)) return Icons.schedule_rounded;
    return Icons.error_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cacheState = ref.watch(matchCacheProvider);

    _checkForCacheCleared(cacheState);

    if (cacheState.matches.isNotEmpty &&
        (_listItems.isEmpty ||
            _listItems.where((e) => e is! NativeAd).length !=
                cacheState.matches.length)) {
      _updateListWithAds(cacheState.matches);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '|  RESULTATS MATCHS',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            fontFamily: 'Oswald',
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: false,
        elevation: 4.0,
        shadowColor: theme.brightness == Brightness.light
            ? const Color.fromARGB(66, 63, 56, 56)
            : Colors.white24,
      ),
      body: _buildBody(colorScheme, cacheState),
      bottomNavigationBar: _isAdLoaded && _bannerAd != null
          ? SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildBody(ColorScheme colorScheme, MatchCacheState cacheState) {
    if (cacheState.isEmpty) {
      if (_isBackgroundRefreshing || _isRefreshing) {
        return Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        );
      }

      if (!_hasInitialLoaded) {
        return Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        );
      }

      if (_initialLoadError != null) {
        return _buildErrorState(colorScheme, _initialLoadError!);
      }
    }

    return _buildMatchesList(colorScheme, cacheState.matches);
  }

  Widget _buildErrorState(ColorScheme colorScheme, Object error) {
    final title = _friendlyTitle(error);
    final message = _friendlyGenericMessage(error);
    final icon = _friendlyIcon(error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withOpacity(0.35),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _loadInitialData();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesList(ColorScheme colorScheme, List<Match> matches) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      child: _listItems.isEmpty && !_isLoadingMore && !_isBackgroundRefreshing
          ? Center(
              child: Text(
                'Aucun match trouve',
                style: TextStyle(color: colorScheme.onSurface),
              ),
            )
          : ListView.separated(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount:
                  _listItems.length +
                  ((_isLoadingMore || _loadMoreError) ? 1 : 0),
              separatorBuilder: (context, index) => const SizedBox(height: 0),
              itemBuilder: (context, index) {
                if (index == _listItems.length) {
                  if (_isLoadingMore) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      ),
                    );
                  }
                  if (_loadMoreError) {
                    final error = _loadMoreErrorDetails;
                    final icon = error != null
                        ? _friendlyIcon(error)
                        : Icons.error_outline_rounded;
                    final message = error != null
                        ? _friendlyLoadMoreMessage(error)
                        : 'Impossible de charger plus de matchs.';

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outline),
                        ),
                        child: Row(
                          children: [
                            Icon(icon, color: colorScheme.error),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                message,
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: _loadMore,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Reessayer'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                }

                final item = _listItems[index];

                if (item is NativeAd) {
                  final isLoaded = _nativeAdLoaded[item] == true;
                  if (!isLoaded) {
                    return Container(
                      height: 320,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  }
                  return Container(
                    height: 320,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: AdWidget(ad: item),
                  );
                }

                final match = item as Match;
                return MatchListItem(match: match, onTap: () {});
              },
            ),
    );
  }
}
