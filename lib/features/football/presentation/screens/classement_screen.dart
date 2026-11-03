import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../football_routes.dart';
import '../providers.dart';
import '../widgets/football_widgets.dart';
import '../widgets/season_widgets.dart';
import 'clubs_screen.dart';

/// Classement tab: one view per table of the selected season (Groupe A, Groupe B, Play-offs…), then its clubs.
class ClassementScreen extends ConsumerWidget {
  const ClassementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final season = ref.watch(activeSeasonProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Classement'), actions: const [SeasonButton()]),
      body: season.when(
        loading: () => const ListSkeleton(),
        error: (error, _) => MessageState(
          icon: Icons.cloud_off_outlined,
          title: failureMessage(error),
          onRetry: () => ref.invalidate(seasonsProvider),
        ),
        data: (s) => Column(
          children: [
            PastSeasonBanner(season: s),
            Expanded(
              child: _SeasonTables(key: ValueKey(s.id), season: s),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeasonTables extends ConsumerWidget {
  final Season season;
  const _SeasonTables({super.key, required this.season});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = standingsProvider(season.id);
    return LoadedView<List<StandingTable>>(
      value: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
      builder: (tables) {
        final tabs = [if (tables.isEmpty) 'Classement' else ...tables.map(standingTableName), 'Clubs'];
        return DefaultTabController(
          // A new set of tables (another season, a new phase) starts on the first one.
          key: ValueKey(tabs.join('|')),
          length: tabs.length,
          child: Column(
            children: [
              Material(
                color: Theme.of(context).colorScheme.surface,
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [for (final t in tabs) Tab(text: t)],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    if (tables.isEmpty)
                      const MessageState(icon: Icons.leaderboard_outlined, title: 'Aucun classement pour cette saison')
                    else
                      for (final t in tables) _TableView(table: t, onRefresh: () async => ref.invalidate(provider)),
                    ClubsDirectory(season: season),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TableView extends StatefulWidget {
  final StandingTable table;
  final Future<void> Function() onRefresh;
  const _TableView({required this.table, required this.onRefresh});
  @override
  State<_TableView> createState() => _TableViewState();
}

class _TableViewState extends State<_TableView> with AutomaticKeepAliveClientMixin {
  var _full = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _full = !_full),
              child: Text(_full ? 'Vue compacte' : 'Tableau complet'),
            ),
          ),
          StandingsTableView(rows: widget.table.rows, full: _full, onClub: (id) => openClub(context, id)),
          ProvisionalNote(verified: widget.table.verified),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
