import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/domain/entities/match.dart';
import 'package:foot_rdc/features/presentation/widgets/match_list_item.dart';
import 'package:foot_rdc/l10n/app_localizations.dart';
import 'package:foot_rdc/main.dart';
import 'dart:async';

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
  String? _lastError;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

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
        !_isRefreshing) {
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
      _lastError = null;
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
      });
    } catch (error) {
      setState(() {
        _isLoadingMore = false;
        _lastError = error.toString();
      });
      // Handle error silently or show a snackbar
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToLoadMoreMatches(error.toString())),
            action: SnackBarAction(label: l10n.retry, onPressed: _loadMore),
          ),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;

    try {
      setState(() {
        _isRefreshing = true;
        _lastError = null;
      });

      // Reset pagination state
      setState(() {
        _currentPage = 1;
        _hasReachedEnd = false;
        _isLoadingMore = false;
        _allMatches = []; // Clear the matches to trigger provider reload
      });

      // Invalidate the provider to force a fresh fetch
      ref.invalidate(fetchMatchesProvider);

      // Fetch fresh data from the first page
      const input = "leagues=552&seasons=553&page=1&per_page=10";
      final newMatches = await ref.read(fetchMatchesProvider(input).future);

      setState(() {
        _allMatches = newMatches;
        _isRefreshing = false;
      });
    } catch (error) {
      setState(() {
        _isRefreshing = false;
        _lastError = error.toString();
      });
      // Handle error silently or show a snackbar
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToRefreshMatches(error.toString())),
            action: SnackBarAction(label: l10n.retry, onPressed: _onRefresh),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Only watch the provider for the first page load when _allMatches is empty
    if (_allMatches.isEmpty && !_isLoadingMore) {
      // Query string passed to the provider to fetch the first page of matches.
      const input = "leagues=552&seasons=553&page=1&per_page=10";

      // Watch the provider that returns an AsyncValue<List<Match>>.
      // The UI will rebuild when the provider's state changes.
      final matchesAsync = ref.watch(fetchMatchesProvider(input));

      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text('|  ${l10n.matchResults}'),
          centerTitle: false,
          elevation: 4.0,
          shadowColor: Colors.black26,
        ),
        body: matchesAsync.when(
          data: (matches) {
            _allMatches = matches;
            return _buildMatchesList();
          },
          loading: () => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(l10n.loadingMatches),
              ],
            ),
          ),
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  l10n.failedToLoadMatches,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // If we already have matches, just build the list without watching the provider
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            '|  ${l10n.matchResults}',
            style: const TextStyle(
              color: Color(0xFFec3535),
              fontSize: 20,
              fontWeight: FontWeight.w500,
              fontFamily: 'Oswald',
              letterSpacing: 1.5,
            ),
          ),
          centerTitle: false,
          elevation: 4.0,
          shadowColor: Colors.black26,
        ),
        body: _buildMatchesList(),
      );
    }
  }

  Widget _buildMatchesList() {
    final l10n = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: Column(
        children: [
          // Show error banner if there's a persistent error
          if (_lastError != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade50,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.connectionProblem,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                  TextButton(onPressed: _onRefresh, child: Text(l10n.retry)),
                ],
              ),
            ),
          Expanded(
            child: _allMatches.isEmpty && !_isLoadingMore
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.sports_soccer,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(l10n.noMatchesFound),
                        const SizedBox(height: 8),
                        Text(l10n.pullToRefresh),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount:
                        _allMatches.length +
                        (_isLoadingMore ? 1 : 0) +
                        (!_hasReachedEnd &&
                                !_isLoadingMore &&
                                _allMatches.isNotEmpty
                            ? 1
                            : 0),
                    itemBuilder: (context, index) {
                      if (index < _allMatches.length) {
                        return MatchListItem(
                          match: _allMatches[index],
                          onTap: () {
                            // Navigate to match details if needed
                            // Navigator.of(context).push(
                            //   MaterialPageRoute(
                            //     builder: (context) => MatchDetailsPage(match: _allMatches[index]),
                            //   ),
                            // );
                          },
                        );
                      } else if (_isLoadingMore) {
                        // Loading indicator at the bottom
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                l10n.loadingMoreMatches,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // "Load more" hint at the bottom
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              l10n.scrollForMoreMatches,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[500]),
                            ),
                          ),
                        );
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
