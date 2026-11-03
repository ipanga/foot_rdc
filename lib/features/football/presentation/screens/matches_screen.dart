import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../football_routes.dart';
import '../providers.dart';
import '../widgets/football_widgets.dart';
import '../widgets/season_widgets.dart';

/// Matchs tab: today and live (always the current season), then the calendar and results of the selected season,
/// filtered by phase or group. Club fixtures and results are on each club's page.
class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentSeasonProvider);
    final season = ref.watch(activeSeasonProvider);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Matchs'),
          actions: const [SeasonButton()],
          bottom: const TabBar(
            tabs: [
              Tab(text: "Aujourd'hui"),
              Tab(text: 'Calendrier'),
              Tab(text: 'Résultats'),
            ],
          ),
        ),
        body: season.when(
          loading: () => const ListSkeleton(),
          error: (error, _) => MessageState(
            icon: Icons.cloud_off_outlined,
            title: failureMessage(error),
            onRetry: () => ref.invalidate(seasonsProvider),
          ),
          data: (s) => TabBarView(
            children: [
              switch (current.valueOrNull) {
                final c? => _Today(season: c.id),
                null => const ListSkeleton(),
              },
              Column(
                children: [
                  PastSeasonBanner(season: s),
                  Expanded(
                    child: SeasonMatchList(key: ValueKey('f${s.id}'), season: s, view: 'fixtures'),
                  ),
                ],
              ),
              Column(
                children: [
                  PastSeasonBanner(season: s),
                  Expanded(
                    child: SeasonMatchList(key: ValueKey('r${s.id}'), season: s, view: 'results'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Today extends ConsumerWidget {
  final int season;
  const _Today({required this.season});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveMatchesProvider(season)).valueOrNull ?? const <Match>[];
    final today = ref.watch(matchWindowProvider(('today', season, 30)));
    final next = ref.watch(matchWindowProvider(('upcoming', season, 5)));
    return LoadedView<List<Match>>(
      value: today,
      onRetry: () => ref.invalidate(matchWindowProvider(('today', season, 30))),
      builder: (rows) {
        final liveIds = live.map((m) => m.id).toSet();
        final others = rows.where((m) => !liveIds.contains(m.id)).toList();
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(liveMatchesProvider(season));
            ref.invalidate(matchWindowProvider(('today', season, 30)));
          },
          child: ListView(
            children: [
              if (live.isNotEmpty) ...[
                const DayHeader('En direct'),
                for (final m in live) MatchRow(match: m, onTap: () => openMatch(context, m.id)),
              ],
              if (others.isNotEmpty) ...[
                const DayHeader("Aujourd'hui"),
                for (final m in others) MatchRow(match: m, onTap: () => openMatch(context, m.id)),
              ],
              if (live.isEmpty && others.isEmpty) ...[
                const SizedBox(
                  height: 180,
                  child: MessageState(icon: Icons.sports_soccer, title: "Pas de match aujourd'hui"),
                ),
                if ((next.valueOrNull?.value ?? const []).isNotEmpty) ...[
                  const SectionHeader('Prochains matchs'),
                  for (final m in next.requireValue.value)
                    MatchRow(match: m, showDate: true, onTap: () => openMatch(context, m.id)),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}
