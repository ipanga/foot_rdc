import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/domain/entities/match.dart';
import 'package:foot_rdc/features/presentation/widgets/match_list_item.dart';
import 'package:foot_rdc/main.dart';

/// A page that shows a list of matches fetched via a Riverpod provider.
class MatchsList extends ConsumerStatefulWidget {
  const MatchsList({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MatchsListState();
}

class _MatchsListState extends ConsumerState<MatchsList> {
  // State management for pagination
  int _currentPage = 1;
  final int _perPage = 10;
  List<Match> _allMatches = [];
  bool _isLoadingMore = false;
  bool _hasReachedEnd = false;
  bool _isRefreshing = false;
  bool _hasInitialLoaded = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  // Inline load-more error flag + retry
  bool _loadMoreError = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_hasReachedEnd &&
        !_isRefreshing &&
        !_loadMoreError) {
      // Debounce rapid scroll events
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 200), () {
        _loadMore();
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _hasReachedEnd || _isRefreshing) return;

    setState(() {
      _isLoadingMore = true;
      _loadMoreError = false;
    });

    try {
      final nextPage = _currentPage + 1;
      final input = "leagues=552&seasons=553&page=$nextPage&per_page=$_perPage";
      final newMatches = await ref.read(fetchMatchesProvider(input).future);

      setState(() {
        if (newMatches.isEmpty || newMatches.length < _perPage) {
          _hasReachedEnd = true;
        }
        if (newMatches.isNotEmpty) {
          _allMatches.addAll(newMatches);
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
        _currentPage = 1;
        _hasReachedEnd = false;
        _isLoadingMore = false;
        _loadMoreError = false;
        _hasInitialLoaded = false;
        _allMatches = []; // Clear to trigger provider reload
      });

      // Invalidate the provider to force a fresh fetch
      ref.invalidate(fetchMatchesProvider);
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
    final input = "leagues=552&seasons=553&page=1&per_page=$_perPage";
    final matchesAsync = ref.watch(fetchMatchesProvider(input));

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
      body: matchesAsync.when(
        data: (matches) {
          // Only update _allMatches if we haven't loaded initial data yet or if refreshing
          if (!_hasInitialLoaded || _isRefreshing) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _allMatches = matches;
                  _hasInitialLoaded = true;
                });
              }
            });
          }

          return _buildMatchesList(colorScheme);
        },
        loading: () {
          if (!_hasInitialLoaded) {
            return Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            );
          }
          return _buildMatchesList(colorScheme);
        },
        error: (error, stackTrace) {
          if (!_hasInitialLoaded) {
            final title = _friendlyTitle(error);
            final message = _friendlyGenericMessage(error);
            final icon = _friendlyIcon(error);

            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16,
                ),
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
                        ref.invalidate(fetchMatchesProvider(input));
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }
          return _buildMatchesList(colorScheme);
        },
      ),
    );
  }

  Widget _buildMatchesList(ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      child: _allMatches.isEmpty && !_isLoadingMore
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
                  _allMatches.length +
                  ((_isLoadingMore || _loadMoreError) ? 1 : 0),
              separatorBuilder: (context, index) => const SizedBox(height: 0),
              itemBuilder: (context, index) {
                // Bottom loading/error row
                if (index == _allMatches.length) {
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

                final match = _allMatches[index];
                return MatchListItem(match: match, onTap: () {});
              },
            ),
    );
  }
}
