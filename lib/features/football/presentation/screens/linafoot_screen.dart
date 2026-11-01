import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../football_labels.dart';
import '../football_routes.dart';
import '../providers.dart';
import '../widgets/football_widgets.dart';
import '../widgets/paged_matches.dart';
import 'clubs_screen.dart';

/// Linafoot hub. The selected season drives every tab, so seasons can never mix.
class LinafootScreen extends ConsumerStatefulWidget {
  static const standingsTab = 3;

  final int initialTab;
  const LinafootScreen({super.key, this.initialTab = 0});
  @override
  ConsumerState<LinafootScreen> createState() => _LinafootScreenState();
}

class _LinafootScreenState extends ConsumerState<LinafootScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 5, vsync: this, initialIndex: widget.initialTab);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final season = ref.watch(activeSeasonProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Linafoot'),
        actions: const [_SeasonButton()],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Aperçu'),
            Tab(text: 'Calendrier'),
            Tab(text: 'Résultats'),
            Tab(text: 'Classements'),
            Tab(text: 'Clubs'),
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
        data: (s) => Column(
          children: [
            if (!s.isCurrent)
              Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text(
                  'Saison passée · ${s.label}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _Overview(key: ValueKey('o${s.id}'), season: s, onTab: _tabs.animateTo),
                  _Matches(key: ValueKey('f${s.id}'), season: s, view: 'fixtures'),
                  _Matches(key: ValueKey('r${s.id}'), season: s, view: 'results'),
                  _Standings(key: ValueKey('s${s.id}'), season: s),
                  ClubsDirectory(key: ValueKey('c${s.id}'), season: s),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeasonButton extends ConsumerWidget {
  const _SeasonButton();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasons = ref.watch(seasonsProvider).valueOrNull?.value ?? const <Season>[];
    final active = ref.watch(activeSeasonProvider).valueOrNull;
    if (seasons.length < 2 || active == null) return const SizedBox.shrink();
    return PopupMenuButton<Season>(
      tooltip: 'Changer de saison',
      initialValue: active,
      onSelected: (s) => ref.read(selectedSeasonIdProvider.notifier).state = s.isCurrent ? null : s.id,
      itemBuilder: (_) => [for (final s in seasons) PopupMenuItem(value: s, child: Text(s.label))],
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

class _Overview extends ConsumerWidget {
  final Season season;
  final ValueChanged<int> onTab;
  const _Overview({super.key, required this.season, required this.onTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stages = ref.watch(stagesProvider(season.id)).valueOrNull?.value ?? const <Stage>[];
    final tables = ref.watch(standingsProvider(season.id));
    final results = ref.watch(matchWindowProvider(('finished', season.id, 3)));
    final next = ref.watch(matchWindowProvider(('upcoming', season.id, 3)));
    final phase = stages.isEmpty ? '' : phaseLabel(stages.last.name);
    final upcoming = (next.valueOrNull?.value ?? const <Match>[]).where((m) => m.seasonId == season.id).toList();
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(standingsProvider(season.id));
        ref.invalidate(matchWindowProvider(('finished', season.id, 3)));
        ref.invalidate(matchWindowProvider(('upcoming', season.id, 3)));
      },
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              [season.label, if (phase.isNotEmpty) phase].join(' · '),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          if (tables.hasError && !tables.hasValue)
            MessageState(
              icon: Icons.cloud_off_outlined,
              title: failureMessage(tables.error),
              onRetry: () => ref.invalidate(standingsProvider(season.id)),
            ),
          if ((results.valueOrNull?.value ?? const []).isNotEmpty) ...[
            SectionHeader('Derniers résultats', action: 'Tout voir', onAction: () => onTab(2)),
            for (final m in results.requireValue.value)
              MatchRow(match: m, showDate: true, onTap: () => openMatch(context, m.id)),
          ],
          if (upcoming.isNotEmpty) ...[
            SectionHeader('Prochains matchs', action: 'Tout voir', onAction: () => onTab(1)),
            for (final m in upcoming) MatchRow(match: m, showDate: true, onTap: () => openMatch(context, m.id)),
          ],
          for (final table in (tables.valueOrNull?.value ?? const <StandingTable>[]).take(2)) ...[
            SectionHeader(
              phaseLabel(table.group?.name ?? table.stage?.name ?? ''),
              action: 'Classement',
              onAction: () => onTab(3),
            ),
            StandingsTableView(rows: table.rows.take(3).toList(), onClub: (id) => openClub(context, id)),
          ],
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Tous les clubs'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onTab(4),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Filter by phase or group; "Tous" by default.
class _Scope {
  final String label;
  final int? stage;
  final int? group;
  const _Scope(this.label, {this.stage, this.group});
}

class _Matches extends ConsumerStatefulWidget {
  final Season season;
  final String view;
  const _Matches({super.key, required this.season, required this.view});
  @override
  ConsumerState<_Matches> createState() => _MatchesState();
}

class _MatchesState extends ConsumerState<_Matches> {
  _Scope _scope = const _Scope('Tous');

  List<_Scope> _scopes(List<Stage> stages, List<Group> groups) {
    final out = <_Scope>[const _Scope('Tous')];
    for (final stage in stages) {
      final mine = groups.where((g) => g.stageId == stage.id).toList()..sort((a, b) => a.name.compareTo(b.name));
      if (mine.isEmpty) {
        out.add(_Scope(phaseLabel(stage.name), stage: stage.id));
      } else {
        for (final g in mine) {
          out.add(_Scope(phaseLabel(g.name), stage: stage.id, group: g.id));
        }
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
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

class _Standings extends ConsumerStatefulWidget {
  final Season season;
  const _Standings({super.key, required this.season});
  @override
  ConsumerState<_Standings> createState() => _StandingsState();
}

class _StandingsState extends ConsumerState<_Standings> {
  var _index = 0;
  var _full = false;

  @override
  Widget build(BuildContext context) {
    final provider = standingsProvider(widget.season.id);
    return LoadedView<List<StandingTable>>(
      value: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
      builder: (tables) {
        if (tables.isEmpty) {
          return const MessageState(icon: Icons.leaderboard_outlined, title: 'Aucun classement pour cette saison');
        }
        final table = tables[_index.clamp(0, tables.length - 1)];
        String name(StandingTable t) {
          final stage = t.stage;
          final own = phaseLabel(t.group?.name ?? stage?.name ?? '');
          return stage != null && stage.isPlayoff && t.group != null ? 'Play-offs · $own' : own;
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(provider),
          child: ListView(
            children: [
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    for (final (i, t) in tables.indexed)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(name(t)),
                          selected: i == _index,
                          onSelected: (_) => setState(() => _index = i),
                        ),
                      ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _full = !_full),
                  child: Text(_full ? 'Vue compacte' : 'Tableau complet'),
                ),
              ),
              StandingsTableView(rows: table.rows, full: _full, onClub: (id) => openClub(context, id)),
              ProvisionalNote(verified: table.verified),
            ],
          ),
        );
      },
    );
  }
}
