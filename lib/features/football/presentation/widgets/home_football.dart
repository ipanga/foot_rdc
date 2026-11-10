import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/presentation/app_tabs.dart';
import '../../domain/models.dart';
import '../football_labels.dart';
import '../football_routes.dart';
import '../providers.dart';
import 'football_widgets.dart';

/// Accueil: « Derniers résultats » and « Prochains matchs » of the current Linafoot season, each a short carousel.
/// Results are only finished or awarded matches (never postponed, cancelled or abandoned ones), newest first; fixtures
/// are live matches first, then the scheduled ones, nearest first. Each section is silent when it has nothing.
class HomeMatchStrip extends ConsumerWidget {
  const HomeMatchStrip({super.key});

  static const resultsCount = 5;
  static const fixturesCount = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final season = ref.watch(currentSeasonProvider).valueOrNull;
    if (season == null) return const SizedBox.shrink();
    final live = ref.watch(liveMatchesProvider(season.id)).valueOrNull ?? const <Match>[];
    final upcoming = ref.watch(matchWindowProvider(('upcoming', season.id, 6))).valueOrNull?.value ?? const <Match>[];
    // A few more than shown: the finished view also lists cancelled and abandoned matches, which are not results.
    final finished = ref.watch(matchWindowProvider(('finished', season.id, 10))).valueOrNull?.value ?? const <Match>[];
    final results = homeResults(finished);
    final fixtures = homeFixtures(live, upcoming);
    if (results.isEmpty && fixtures.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (results.isNotEmpty)
          _Carousel(
            title: 'Derniers résultats',
            action: 'Tout voir',
            actionKey: const ValueKey('home-results-all'),
            stripKey: const ValueKey('home-results-strip'),
            onAction: () => openMatchesSection(ref, MatchesSection.results),
            matches: results,
          ),
        if (fixtures.isNotEmpty)
          _Carousel(
            title: 'Prochains matchs',
            action: 'Calendrier',
            actionKey: const ValueKey('home-fixtures-all'),
            stripKey: const ValueKey('home-fixtures-strip'),
            onAction: () => openMatchesSection(ref, MatchesSection.fixtures),
            matches: fixtures,
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Opens the Matchs tab on [section] for the current season (the matches shown on Accueil are the current season's).
void openMatchesSection(WidgetRef ref, int section) {
  ref.read(selectedSeasonIdProvider.notifier).state = null;
  ref.read(matchesSectionProvider.notifier).state = section;
  ref.read(currentTabProvider.notifier).state = AppTab.matches;
}

/// Completed matches with an official result, newest first.
List<Match> homeResults(List<Match> finished) {
  final rows = finished.where((m) => m.status.isOver && m.home.score != null && m.away.score != null).toList()
    ..sort((a, b) => (b.kickoff ?? DateTime(0)).compareTo(a.kickoff ?? DateTime(0)));
  return rows.take(HomeMatchStrip.resultsCount).toList();
}

/// Live matches first, then scheduled ones from the nearest; postponed or cancelled ones are never fixtures here.
List<Match> homeFixtures(List<Match> live, List<Match> upcoming) {
  final seen = <int>{};
  final next = upcoming.where((m) => m.status == MatchStatus.scheduled).toList()
    ..sort((a, b) => (a.kickoff ?? DateTime(9999)).compareTo(b.kickoff ?? DateTime(9999)));
  return [
    ...live.where((m) => m.status.isLive),
    ...next,
  ].where((m) => seen.add(m.id)).take(HomeMatchStrip.fixturesCount).toList();
}

class _Carousel extends StatelessWidget {
  final String title;
  final String action;
  final Key actionKey;
  final Key stripKey;
  final VoidCallback onAction;
  final List<Match> matches;
  const _Carousel({
    required this.title,
    required this.action,
    required this.actionKey,
    required this.stripKey,
    required this.onAction,
    required this.matches,
  });

  @override
  Widget build(BuildContext context) {
    // Fixed card height on Accueil: text grows up to 1.3× here (full size on the Matchs tab).
    final scale = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3).scale(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 0),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  // One line: with very large text the title shrinks instead of breaking inside a word.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(title, maxLines: 1, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              TextButton(key: actionKey, onPressed: onAction, child: Text(action)),
            ],
          ),
        ),
        SizedBox(
          height: 96 * scale + 12,
          child: ListView.separated(
            key: stripKey,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: matches.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) =>
                HomeMatchCard(match: matches[index], onTap: () => openMatch(context, matches[index].id)),
          ),
        ),
      ],
    );
  }
}

/// Compact match card: date (and kickoff time for a fixture) with the group, then one line per club; a result shows
/// both scores with the winner's in bold, a fixture shows no score, a live match a « En direct » badge.
class HomeMatchCard extends StatelessWidget {
  final Match match;
  final VoidCallback? onTap;
  const HomeMatchCard({super.key, required this.match, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final result = match.status.isOver || match.status.isLive;
    final scored = result && match.home.score != null && match.away.score != null;
    final group = phaseLabel(match.groupName.isNotEmpty ? match.groupName : match.stageName);
    final when = match.status.isLive
        ? null
        : match.status.isOver
        ? '${shortDate(match.kickoff)}${match.status == MatchStatus.awarded ? ' · ${statusLabel(match.status)}' : ''}'
        : '${_day(match.kickoff)} · ${kickoffTime(match.kickoff)}';
    int? other(MatchSide side) => identical(side, match.home) ? match.away.score : match.home.score;
    Widget line(MatchSide side) {
      final wins = scored && match.status.isOver && (side.score ?? 0) > (other(side) ?? 0);
      return Row(
        children: [
          ClubCrest(url: side.logoUrl, name: side.name, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              side.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: wins ? FontWeight.w700 : FontWeight.w500),
            ),
          ),
          if (scored)
            SizedBox(
              width: 22,
              child: Text(
                '${side.score}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: wins || match.status.isLive ? FontWeight.w800 : FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
        ],
      );
    }

    final label = scored
        ? '${match.home.name} ${match.home.score}, ${match.away.name} ${match.away.score}, ${match.status.isLive ? 'en direct' : (when ?? '')}'
        : '${match.home.name} contre ${match.away.name}, ${_day(match.kickoff)} à ${kickoffTime(match.kickoff)}';
    // Fixed card height on Accueil: text grows up to 1.3× here (full size on the Matchs tab).
    final card = Semantics(
      button: true,
      label: '$label${group.isEmpty ? '' : ', $group'}',
      excludeSemantics: true,
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 204,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // The date and kickoff time are always shown in full; only the group gives way.
                Row(
                  children: [
                    if (match.status.isLive)
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: StatusBadge(status: match.status, minute: match.minute),
                        ),
                      )
                    else
                      Text(
                        when!,
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: match.status.isOver ? FontWeight.w500 : FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    if (group.isNotEmpty)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            group,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                  ],
                ),
                line(match.home),
                line(match.away),
              ],
            ),
          ),
        ),
      ),
    );
    return MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3, child: card);
  }

  /// « Aujourd'hui », « Demain », else a short date: the card has no room for a weekday and a month name.
  static String _day(DateTime? utc) {
    final day = dayLabel(utc);
    return day == "Aujourd'hui" || day == 'Demain' ? day : shortDate(utc);
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
