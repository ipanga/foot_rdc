import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/football_client.dart';
import '../../data/football_repository.dart';
import '../../domain/models.dart';
import '../football_routes.dart';
import '../providers.dart';
import 'football_widgets.dart';

typedef MatchPageLoader = Future<PageResult<Match>> Function(FootballRepository repo, int page, CachePolicy policy);

/// An endless match list under day headers. The saved first page shows at once, then the fresh one replaces it.
class PagedMatchList extends ConsumerStatefulWidget {
  final Object identity;
  final MatchPageLoader load;
  final String emptyTitle;
  final String? emptyDetail;
  const PagedMatchList({
    super.key,
    required this.identity,
    required this.load,
    required this.emptyTitle,
    this.emptyDetail,
  });
  @override
  ConsumerState<PagedMatchList> createState() => _PagedMatchListState();
}

class _PagedMatchListState extends ConsumerState<PagedMatchList> {
  final _rows = <Match>[];
  var _page = 0;
  var _hasMore = true;
  var _loading = false;
  var _stale = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _first();
  }

  @override
  void didUpdateWidget(PagedMatchList old) {
    super.didUpdateWidget(old);
    if (old.identity != widget.identity) {
      _rows.clear();
      _first();
    }
  }

  Future<void> _first({bool force = false}) async {
    final identity = widget.identity;
    setState(() {
      _loading = true;
      _error = null;
      _page = 0;
      _hasMore = true;
    });
    try {
      final repo = await ref.read(footballRepositoryProvider.future);
      if (force) {
        final fresh = await widget.load(repo, 1, CachePolicy.network);
        _apply(identity, fresh, stale: false);
        return;
      }
      await for (final state in staleWhileRevalidate((policy) => widget.load(repo, 1, policy))) {
        _apply(identity, state.value, stale: state.stale);
      }
    } catch (error) {
      if (mounted && identity == widget.identity) {
        setState(() {
          _error = error;
          _loading = false;
        });
      }
    }
  }

  void _apply(Object identity, PageResult<Match> page, {required bool stale}) {
    if (!mounted || identity != widget.identity) return;
    setState(() {
      _rows
        ..clear()
        ..addAll(page.rows);
      _page = 1;
      _hasMore = page.hasMore;
      _stale = stale;
      _loading = false;
      _error = null;
    });
  }

  Future<void> _more() async {
    if (_loading || !_hasMore || _rows.isEmpty) return;
    final identity = widget.identity;
    setState(() => _loading = true);
    try {
      final repo = await ref.read(footballRepositoryProvider.future);
      final next = await widget.load(repo, _page + 1, CachePolicy.preferCache);
      if (!mounted || identity != widget.identity) return;
      final known = _rows.map((m) => m.id).toSet();
      setState(() {
        _rows.addAll(next.rows.where((m) => !known.contains(m.id)));
        _page++;
        _hasMore = next.hasMore;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_rows.isEmpty) {
      if (_error != null) {
        return MessageState(icon: Icons.cloud_off_outlined, title: failureMessage(_error), onRetry: _first);
      }
      if (_loading) return const ListSkeleton();
      return RefreshIndicator(
        onRefresh: () => _first(force: true),
        child: ListView(
          children: [
            SizedBox(
              height: 320,
              child: MessageState(
                icon: Icons.event_busy_outlined,
                title: widget.emptyTitle,
                detail: widget.emptyDetail,
              ),
            ),
          ],
        ),
      );
    }
    final items = groupByDay(_rows);
    return Column(
      children: [
        if (_stale) const StaleNotice(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _first(force: true),
            child: ListView.builder(
              itemCount: items.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= items.length) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _more());
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  );
                }
                final item = items[index];
                if (item is String) return DayHeader(item);
                final match = item as Match;
                return MatchRow(match: match, onTap: () => openMatch(context, match.id));
              },
            ),
          ),
        ),
      ],
    );
  }
}
