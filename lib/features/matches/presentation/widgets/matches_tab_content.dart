import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/core/constants/api_constants.dart';
import 'package:foot_rdc/core/network/network_exceptions.dart';
import 'package:foot_rdc/features/matches/domain/entities/match.dart';
import 'package:foot_rdc/features/matches/presentation/widgets/match_list_item.dart';
import 'package:foot_rdc/features/matches/presentation/providers/match_cache_provider.dart';
import 'package:foot_rdc/features/matches/presentation/providers/match_providers.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:foot_rdc/core/constants/ad_constants.dart';

class MatchesTabContent extends ConsumerStatefulWidget {
  final int leagueId;
  final String tabName;

  const MatchesTabContent({
    super.key,
    required this.leagueId,
    required this.tabName,
  });

  @override
  ConsumerState<MatchesTabContent> createState() => _MatchesTabContentState();
}

class _MatchesTabContentState extends ConsumerState<MatchesTabContent>
    with AutomaticKeepAliveClientMixin {
  final int _perPage = 10;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  bool _hasInitialLoaded = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  bool _loadMoreError = false;
  Object? _loadMoreErrorDetails;
  Object? _initialLoadError;

  final List<Object> _listItems = [];
  static const int _adFrequency = 10;
  final Map<NativeAd, bool> _nativeAdLoaded = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadInitialData();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounceTimer?.cancel();
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
    final leagueCache = cacheState.getLeagueCache(widget.leagueId);

    if (leagueCache.isEmpty ||
        !leagueCache.isCacheValid(validDuration: const Duration(minutes: 2))) {
      _loadInitialData();
    } else {
      _updateListWithAds(leagueCache.matches);
      setState(() {
        _hasInitialLoaded = true;
        _initialLoadError = null;
      });
    }
  }

  Future<void> _loadInitialData({bool isBackgroundRefresh = false}) async {
    if (mounted && !isBackgroundRefresh) {
      setState(() {
        _initialLoadError = null;
      });
    }

    try {
      final input =
          "leagues=${widget.leagueId}&seasons=${ApiConstants.currentSeasonId}&page=1&per_page=$_perPage";
      final matches = await ref.read(fetchMatchesProvider(input).future);

      if (mounted) {
        ref
            .read(matchCacheProvider.notifier)
            .updateMatchesForLeague(widget.leagueId, matches);
        _updateListWithAds(matches);

        setState(() {
          _hasInitialLoaded = true;
          _initialLoadError = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _hasInitialLoaded = true;
          _initialLoadError = error;
        });
      }
    }
  }

  void _onScroll() {
    if (!mounted) return;

    final cacheState = ref.read(matchCacheProvider);
    final leagueCache = cacheState.getLeagueCache(widget.leagueId);

    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !leagueCache.hasReachedEnd &&
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
    final leagueCache = cacheState.getLeagueCache(widget.leagueId);

    if (_isLoadingMore || leagueCache.hasReachedEnd || _isRefreshing) return;

    if (mounted) {
      setState(() {
        _isLoadingMore = true;
        _loadMoreError = false;
        _loadMoreErrorDetails = null;
      });
    }

    try {
      final nextPage = leagueCache.currentPage + 1;
      final input =
          "leagues=${widget.leagueId}&seasons=${ApiConstants.currentSeasonId}&page=$nextPage&per_page=$_perPage";
      final newMatches = await ref.read(fetchMatchesProvider(input).future);

      if (mounted) {
        ref.read(matchCacheProvider.notifier).updateMatchesForLeague(
              widget.leagueId,
              newMatches,
              isLoadMore: true,
            );

        final updatedCache =
            ref.read(matchCacheProvider).getLeagueCache(widget.leagueId);
        _updateListWithAds(updatedCache.matches);

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

      ref.read(matchCacheProvider.notifier).clearCacheForLeague(widget.leagueId);
      await _loadInitialData();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyGenericMessage(error))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  bool _isNoInternet(Object error) =>
      error is NoInternetException ||
      error.toString().toLowerCase().contains('socketexception');

  bool _isTimeout(Object error) =>
      error is TimeoutException ||
      error.toString().toLowerCase().contains('timeout');

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
    super.build(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cacheState = ref.watch(matchCacheProvider);
    final leagueCache = cacheState.getLeagueCache(widget.leagueId);

    // Update list items if cache changed externally
    if (leagueCache.matches.isNotEmpty &&
        (_listItems.isEmpty ||
            _listItems.whereType<Match>().length != leagueCache.matches.length)) {
      _updateListWithAds(leagueCache.matches);
    }

    return _buildBody(colorScheme, leagueCache);
  }

  Widget _buildBody(ColorScheme colorScheme, LeagueMatchCacheState leagueCache) {
    if (leagueCache.isEmpty) {
      if (_isRefreshing) {
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

    return _buildMatchesList(colorScheme, leagueCache.matches, leagueCache);
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
                color: colorScheme.secondaryContainer.withAlpha(89),
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
                color: colorScheme.onSurface.withAlpha(204),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _loadInitialData(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesList(
    ColorScheme colorScheme,
    List<Match> matches,
    LeagueMatchCacheState leagueCache,
  ) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      child: _listItems.isEmpty && !_isLoadingMore
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
              itemCount: _listItems.length +
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
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
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
