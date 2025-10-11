import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/domain/entities/match.dart';
import 'package:foot_rdc/features/presentation/widgets/match_list_item.dart';
import 'package:foot_rdc/features/presentation/providers/match_cache_provider.dart';
import 'package:foot_rdc/main.dart';

/// A page that shows a list of matches fetched via a Riverpod provider.
class MatchsList extends ConsumerStatefulWidget {
  const MatchsList({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MatchsListState();
}

class _MatchsListState extends ConsumerState<MatchsList> {
  // State management for pagination
  final int _perPage = 10;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  bool _hasInitialLoaded = false;
  bool _isBackgroundRefreshing = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  // Inline load-more error flag + retry
  bool _loadMoreError = false;

  // Track previous cache state to detect when cache is cleared
  MatchCacheState? _previousCacheState;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Check if we should load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadInitialData();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _checkAndLoadInitialData() {
    final cacheState = ref.read(matchCacheProvider);

    // Only fetch if cache is empty or invalid
    if (cacheState.isEmpty || !cacheState.isCacheValid()) {
      _loadInitialData();
    } else {
      // Use cached data
      setState(() {
        _hasInitialLoaded = true;
      });
    }
  }

  void _checkForCacheCleared(MatchCacheState currentCache) {
    // If we had data before but now cache is empty, trigger reload
    if (_previousCacheState != null &&
        _previousCacheState!.isNotEmpty &&
        currentCache.isEmpty &&
        _hasInitialLoaded &&
        !_isRefreshing &&
        !_isBackgroundRefreshing &&
        mounted) {
      // Add mounted check here
      // Cache was cleared from outside (likely from HomePage), reload data
      _loadInitialData(isBackgroundRefresh: true);
    }

    _previousCacheState = currentCache;
  }

  Future<void> _loadInitialData({bool isBackgroundRefresh = false}) async {
    try {
      if (isBackgroundRefresh && mounted) {
        // Add mounted check
        setState(() {
          _isBackgroundRefreshing = true;
        });
      }

      final input = "leagues=552&seasons=553&page=1&per_page=$_perPage";
      final matches = await ref.read(fetchMatchesProvider(input).future);

      if (mounted) {
        // Add mounted check before updating state
        ref.read(matchCacheProvider.notifier).updateMatches(matches);

        setState(() {
          _hasInitialLoaded = true;
          if (isBackgroundRefresh) {
            _isBackgroundRefreshing = false;
          }
        });
      }
    } catch (error) {
      if (mounted) {
        // Add mounted check
        setState(() {
          _hasInitialLoaded = true;
          if (isBackgroundRefresh) {
            _isBackgroundRefreshing = false;
          }
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_friendlyGenericMessage(error))));
      }
    }
  }

  void _onScroll() {
    if (!mounted) return; // Add mounted check at the beginning

    final cacheState = ref.read(matchCacheProvider);

    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !cacheState.hasReachedEnd &&
        !_isRefreshing &&
        !_loadMoreError) {
      // Debounce rapid scroll events
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted) {
          // Add mounted check in timer callback
          _loadMore();
        }
      });
    }
  }

  Future<void> _loadMore() async {
    if (!mounted) return; // Add mounted check at the beginning

    final cacheState = ref.read(matchCacheProvider);

    if (_isLoadingMore || cacheState.hasReachedEnd || _isRefreshing) return;

    if (mounted) {
      // Add mounted check
      setState(() {
        _isLoadingMore = true;
        _loadMoreError = false;
      });
    }

    try {
      final nextPage = cacheState.currentPage + 1;
      final input = "leagues=552&seasons=553&page=$nextPage&per_page=$_perPage";
      final newMatches = await ref.read(fetchMatchesProvider(input).future);

      if (mounted) {
        // Add mounted check before updating state
        ref
            .read(matchCacheProvider.notifier)
            .updateMatches(newMatches, isLoadMore: true);

        setState(() {
          _isLoadingMore = false;
          _loadMoreError = false;
        });
      }
    } catch (error) {
      if (mounted) {
        // Add mounted check
        setState(() {
          _isLoadingMore = false;
          _loadMoreError = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyLoadMoreMessage(error))),
        );
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
      });

      // Clear cache and reload
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

  // Friendly helpers (no URLs exposed)
  bool _isNoInternet(Object error) => error is SocketException;
  bool _isTimeout(Object error) => error is TimeoutException;

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
    return 'Impossible de charger les matchs. Veuillez réessayer.';
  }

  String _friendlyLoadMoreMessage(Object error) {
    if (_isNoInternet(error)) return 'Connexion absente. Réessayez.';
    if (_isTimeout(error)) return 'Délai dépassé. Réessayez.';
    return 'Impossible de charger plus de matchs.';
  }

  IconData _friendlyIcon(Object error) {
    if (_isNoInternet(error)) return Icons.wifi_off_rounded;
    if (_isTimeout(error)) return Icons.schedule_rounded;
    return Icons.error_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cacheState = ref.watch(matchCacheProvider);

    // Check if cache was cleared from outside
    _checkForCacheCleared(cacheState);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '|  RÉSULTATS MATCHS',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            fontFamily: 'Oswald',
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: false,
        elevation: 4.0,
        shadowColor: Theme.of(context).brightness == Brightness.light
            ? Colors.black26
            : Colors.white24,
      ),
      body: _buildBody(colorScheme, cacheState),
    );
  }

  Widget _buildBody(ColorScheme colorScheme, MatchCacheState cacheState) {
    // Show loading only for initial load when cache is empty AND not background refreshing
    if (!_hasInitialLoaded && cacheState.isEmpty && !_isBackgroundRefreshing) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    // Show error only for initial load when cache is empty AND not background refreshing
    if (!_hasInitialLoaded && cacheState.isEmpty && !_isBackgroundRefreshing) {
      return _buildErrorState(colorScheme);
    }

    // If background refreshing and cache is empty, show loading
    if (_isBackgroundRefreshing && cacheState.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    return _buildMatchesList(colorScheme, cacheState.matches);
  }

  Widget _buildErrorState(ColorScheme colorScheme) {
    // This will only show if initial load fails and cache is empty
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
                Icons.error_outline_rounded,
                size: 36,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Oups, un problème est survenu',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Impossible de charger les matchs. Veuillez réessayer.',
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
              label: const Text('Réessayer'),
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
      child: matches.isEmpty && !_isLoadingMore && !_isBackgroundRefreshing
          ? Center(
              child: Text(
                'Aucun match trouvé',
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
                  matches.length + ((_isLoadingMore || _loadMoreError) ? 1 : 0),
              separatorBuilder: (context, index) => const SizedBox(height: 0),
              itemBuilder: (context, index) {
                // Bottom loading/error row
                if (index == matches.length) {
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
                            Icon(
                              Icons.wifi_off_rounded,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Impossible de charger plus de matchs',
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
                              label: const Text('Réessayer'),
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

                final match = matches[index];
                return MatchListItem(match: match, onTap: () {});
              },
            ),
    );
  }
}
