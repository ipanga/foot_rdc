import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/presentation/app_tabs.dart';
import '../../domain/models.dart';
import '../football_labels.dart';
import '../football_routes.dart';
import '../providers.dart';
import 'football_widgets.dart';

/// Home strip: live first, then today's and next matches, then the latest results. Silent when there is nothing.
class HomeMatchStrip extends ConsumerWidget {
  const HomeMatchStrip({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final season = ref.watch(currentSeasonProvider).valueOrNull;
    if (season == null) return const SizedBox.shrink();
    final live = ref.watch(liveMatchesProvider(season.id)).valueOrNull ?? const <Match>[];
    final upcoming = ref.watch(matchWindowProvider(('upcoming', season.id, 6))).valueOrNull?.value ?? const <Match>[];
    final finished = ref.watch(matchWindowProvider(('finished', season.id, 4))).valueOrNull?.value ?? const <Match>[];
    final seen = <int>{};
    final rows = [...live, ...upcoming, ...finished].where((m) => seen.add(m.id)).toList();
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Matchs',
          action: 'Tout voir',
          onAction: () => ref.read(currentTabProvider.notifier).state = AppTab.matches,
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) =>
                MatchChip(match: rows[index], onTap: () => openMatch(context, rows[index].id)),
          ),
        ),
      ],
    );
  }
}

/// Group leaders at a glance, leading to the full tables.
class HomeLinafootSnapshot extends ConsumerWidget {
  const HomeLinafootSnapshot({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final season = ref.watch(currentSeasonProvider).valueOrNull;
    if (season == null) return const SizedBox.shrink();
    final tables = ref.watch(standingsProvider(season.id)).valueOrNull?.value ?? const <StandingTable>[];
    if (tables.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader('Linafoot', action: 'Classements', onAction: () => openStandings(context)),
        for (final table in tables.take(2)) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
            child: Text(
              phaseLabel(table.group?.name ?? table.stage?.name ?? ''),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          StandingsTableView(rows: table.rows.take(3).toList(), onClub: (id) => openClub(context, id)),
        ],
      ],
    );
  }
}
