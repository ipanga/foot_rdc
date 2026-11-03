import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../football_labels.dart';
import '../providers.dart';
import 'paged_matches.dart';

/// Season picker shared by Matchs and Classement: one selected season drives both, so seasons never mix.
class SeasonButton extends ConsumerWidget {
  const SeasonButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasons = ref.watch(seasonsProvider).valueOrNull?.value ?? const <Season>[];
    final active = ref.watch(activeSeasonProvider).valueOrNull;
    if (seasons.length < 2 || active == null) return const SizedBox.shrink();
    return PopupMenuButton<Season>(
      tooltip: 'Changer de saison',
      initialValue: active,
      onSelected: (s) => ref.read(selectedSeasonIdProvider.notifier).state = s.isCurrent ? null : s.id,
      itemBuilder: (_) => [
        for (final s in seasons) PopupMenuItem(value: s, child: Text(s.isCurrent ? '${s.label} (en cours)' : s.label)),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(active.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Shown while a past season is selected, with a way back to the current one.
class PastSeasonBanner extends ConsumerWidget {
  final Season season;
  const PastSeasonBanner({super.key, required this.season});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (season.isCurrent) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Saison passée · ${season.label}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () => ref.read(selectedSeasonIdProvider.notifier).state = null,
              child: const Text('Saison en cours'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A phase or group filter; "Tous" by default.
class _Scope {
  final String label;
  final int? stage;
  final int? group;
  const _Scope(this.label, {this.stage, this.group});
}

/// Fixtures (next first) or results (latest first) of one season, filtered by phase or group.
class SeasonMatchList extends ConsumerStatefulWidget {
  final Season season;

  /// `fixtures` or `results`.
  final String view;
  const SeasonMatchList({super.key, required this.season, required this.view});
  @override
  ConsumerState<SeasonMatchList> createState() => _SeasonMatchListState();
}

class _SeasonMatchListState extends ConsumerState<SeasonMatchList> with AutomaticKeepAliveClientMixin {
  _Scope _scope = const _Scope('Tous');

  @override
  bool get wantKeepAlive => true;

  List<_Scope> _scopes(List<Stage> stages, List<Group> groups) {
    final out = <_Scope>[const _Scope('Tous')];
    for (final stage in stages) {
      final mine = groups.where((g) => g.stageId == stage.id).toList()..sort((a, b) => a.name.compareTo(b.name));
      if (mine.isEmpty) {
        out.add(_Scope(phaseLabel(stage.name), stage: stage.id));
      } else {
        for (final g in mine) {
          final own = phaseLabel(g.name);
          out.add(_Scope(stage.isPlayoff ? 'Play-offs · $own' : own, stage: stage.id, group: g.id));
        }
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final stages = ref.watch(stagesProvider(widget.season.id)).valueOrNull?.value ?? const <Stage>[];
    final groups = ref.watch(groupsProvider(widget.season.id)).valueOrNull?.value ?? const <Group>[];
    final scopes = _scopes(stages, groups);
    final results = widget.view == 'results';
    final season = widget.season.id;
    final scope = _scope;
    return Column(
      children: [
        if (scopes.length > 1)
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final s in scopes)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(s.label),
                      selected: s.label == scope.label,
                      onSelected: (_) => setState(() => _scope = s),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: PagedMatchList(
            identity: (widget.view, season, scope.label),
            load: (repo, page, policy) => repo.seasonMatches(
              season,
              widget.view,
              page: page,
              group: scope.group,
              stage: scope.stage,
              policy: policy,
            ),
            emptyTitle: results ? 'Aucun résultat pour le moment' : 'Aucun match à venir',
            emptyDetail: !results && !widget.season.isCurrent ? 'Cette saison est terminée.' : null,
          ),
        ),
      ],
    );
  }
}

/// The name of a standings table: "Groupe A", "Play-offs · Groupe 1"…
String standingTableName(StandingTable t) {
  final stage = t.stage;
  final own = phaseLabel(t.group?.name ?? stage?.name ?? '');
  return stage != null && stage.isPlayoff && t.group != null ? 'Play-offs · $own' : own;
}
