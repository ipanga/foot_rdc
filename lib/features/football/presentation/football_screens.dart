import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/football_models.dart';
import 'football_providers.dart';
import 'football_strings.dart';
import 'football_widgets.dart';

class FootballCompetitionScreen extends ConsumerStatefulWidget {
  final int? competitionId;
  const FootballCompetitionScreen({this.competitionId, super.key});
  @override
  ConsumerState<FootballCompetitionScreen> createState() => _CompetitionState();
}

class _CompetitionState extends ConsumerState<FootballCompetitionScreen> {
  int _phase = 0;
  String _view = 'results';
  @override
  Widget build(BuildContext context) {
    final s = FootballStrings.of(context);
    final config = ref.watch(footballConfigProvider);
    final data = ref.watch(footballContextProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('competition')),
        actions: [
          IconButton(
            tooltip: s.t('teams'),
            icon: const Icon(Icons.groups_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/football/teams'),
          ),
        ],
      ),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => FootballEmpty(
          footballError(context, error),
          retry: () async {
            try {
              await (await ref.read(
                footballRepositoryProvider.future,
              )).context(refresh: true);
            } catch (_) {
              /* The provider renders the localized retry state. */
            }
            ref.invalidate(footballContextProvider);
          },
        ),
        data: (info) {
          if ((widget.competitionId != null &&
                  widget.competitionId != info.competition.id) ||
              config == null) {
            return FootballEmpty(s.t('unavailable'));
          }
          final phase = info.phases.isEmpty
              ? null
              : info.phases[_phase.clamp(0, info.phases.length - 1)];
          final filters = <String, dynamic>{
            'season_id': info.season.id,
            if (_view != 'standings') 'competition_id': info.competition.id,
            ...?phase?.filters,
            if (_view != 'standings') 'view': _view,
          };
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            info.competition.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            info.season.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      info.teams.isEmpty
                          ? s.t('partial')
                          : '${info.teams.length} ${s.t('teams').toLowerCase()}',
                    ),
                  ],
                ),
              ),
              if (info.phases.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      for (var index = 0; index < info.phases.length; index++)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            labelStyle: Theme.of(context).textTheme.labelLarge,
                            label: Text(
                              s.phase((
                                name: info.phases[index].name,
                                type: info.phases[index].type,
                              )),
                            ),
                            selected: index == _phase,
                            onSelected: (_) => setState(() => _phase = index),
                          ),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final view in ['fixtures', 'results', 'standings'])
                      ChoiceChip(
                        labelStyle: Theme.of(context).textTheme.labelLarge,
                        label: Text(s.t(view)),
                        selected: _view == view,
                        onSelected: (_) => setState(() => _view = view),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: FootballList(
                  query: FootballQuery(
                    _view == 'standings' ? 'standings' : 'matches',
                    filters,
                  ),
                  empty: _view == 'standings'
                      ? 'standingsEmpty'
                      : 'matchesEmpty',
                  row: (context, row) => _view == 'standings'
                      ? _Standing(row, info.teams)
                      : FootballMatchTile(row),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class FootballMatchCenterScreen extends ConsumerStatefulWidget {
  const FootballMatchCenterScreen({super.key});
  @override
  ConsumerState<FootballMatchCenterScreen> createState() => _CenterState();
}

class _CenterState extends ConsumerState<FootballMatchCenterScreen> {
  String _view = 'finished';
  @override
  Widget build(BuildContext context) {
    final s = FootballStrings.of(context),
        config = ref.watch(footballConfigProvider);
    final views = [
      'today',
      if (config?.live.enabled == true) 'live',
      'upcoming',
      'finished',
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('match')),
        actions: [
          IconButton(
            tooltip: s.t('competition'),
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: () => Navigator.of(
              context,
            ).pushNamed('/football/competition/${config?.competitionId ?? 1}'),
          ),
          IconButton(
            tooltip: s.t('teams'),
            icon: const Icon(Icons.groups_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/football/teams'),
          ),
        ],
      ),
      body: config == null
          ? FootballEmpty(s.t('unavailable'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final view in views)
                        ChoiceChip(
                          labelStyle: Theme.of(context).textTheme.labelLarge,
                          label: Text(s.t(view)),
                          selected: _view == view,
                          onSelected: (_) => setState(() => _view = view),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: FootballList(
                    query: FootballQuery('matches/$_view', {
                      'competition_id': config.competitionId,
                      'season_id': config.seasonId,
                    }),
                    empty: 'matchesEmpty',
                    row: (_, row) => FootballMatchTile(row),
                  ),
                ),
              ],
            ),
    );
  }
}

class FootballTeamsScreen extends ConsumerStatefulWidget {
  const FootballTeamsScreen({super.key});
  @override
  ConsumerState<FootballTeamsScreen> createState() => _TeamsState();
}

class _TeamsState extends ConsumerState<FootballTeamsScreen> {
  String _search = '';
  @override
  Widget build(BuildContext context) {
    final s = FootballStrings.of(context),
        data = ref.watch(footballDirectoryProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('teams'))),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => FootballEmpty(
          footballError(context, e),
          retry: () => ref.invalidate(footballDirectoryProvider),
        ),
        data: (info) {
          final rows =
              info.rows
                  .where(
                    (row) => '${row.name} ${row.text('city')}'
                        .toLowerCase()
                        .contains(_search.toLowerCase()),
                  )
                  .toList()
                ..sort((a, b) => a.name.compareTo(b.name));
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: (value) => setState(() => _search = value),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: s.t('search'),
                  ),
                ),
              ),
              if (info.cached) Text(s.t('cached')),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    try {
                      await (await ref.read(
                        footballRepositoryProvider.future,
                      )).directory(refresh: true);
                    } catch (_) {
                      /* Preserve the localized provider error state. */
                    }
                    ref.invalidate(footballDirectoryProvider);
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: rows.isEmpty ? 1 : rows.length,
                    itemBuilder: (_, index) => rows.isEmpty
                        ? FootballEmpty(s.t('empty'))
                        : ListTile(
                            leading: FootballLogo(rows[index].text('logo_url')),
                            title: Text(rows[index].name),
                            subtitle: rows[index].text('city').isEmpty
                                ? null
                                : Text(rows[index].text('city')),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(
                              context,
                            ).pushNamed('/football/team/${rows[index].id}'),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class FootballTeamScreen extends ConsumerStatefulWidget {
  final int teamId;
  const FootballTeamScreen(this.teamId, {super.key});
  @override
  ConsumerState<FootballTeamScreen> createState() => _TeamState();
}

class _TeamState extends ConsumerState<FootballTeamScreen> {
  String _section = 'overview';
  String _schedule = 'upcoming';
  @override
  Widget build(BuildContext context) {
    final s = FootballStrings.of(context),
        config = ref.watch(footballConfigProvider);
    final team = ref.watch(
      footballSingleProvider(FootballQuery('teams/${widget.teamId}')),
    );
    final info = team.valueOrNull;
    final prefix = 'teams/${widget.teamId}';
    final filters = <String, dynamic>{'season_id': config?.seasonId ?? 1};
    Widget body;
    if (_section == 'overview') {
      body = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          team.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => FootballEmpty(
              footballError(context, e),
              retry: () =>
                  ref.invalidate(footballSingleProvider(FootballQuery(prefix))),
            ),
            data: (row) =>
                row == null ? FootballEmpty(s.t('empty')) : _TeamHeader(row),
          ),
          _Heading(s.t('next')),
          _SingleSection(
            FootballQuery('$prefix/next-match', filters),
            empty: 'nextEmpty',
          ),
          _Heading(s.t('recent')),
          FootballList(
            query: FootballQuery('$prefix/results', {...filters, 'limit': 5}),
            embedded: true,
            paginate: false,
            empty: 'matchesEmpty',
            row: (_, row) => FootballMatchTile(row),
          ),
        ],
      );
    } else {
      final view = _section == 'fixtures' ? 'matches' : _section;
      body = FootballList(
        query: FootballQuery('$prefix/$view', {
          ...filters,
          if (view == 'matches') 'view': _schedule,
        }),
        empty: view == 'standings'
            ? 'standingsEmpty'
            : view == 'matches' || view == 'results'
            ? 'matchesEmpty'
            : 'empty',
        header: [
          if (view == 'matches')
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final mode in ['upcoming', 'finished'])
                    ChoiceChip(
                      labelStyle: Theme.of(context).textTheme.labelLarge,
                      label: Text(s.t(mode)),
                      selected: _schedule == mode,
                      onSelected: (_) => setState(() => _schedule = mode),
                    ),
                ],
              ),
            ),
          if (view == 'squad') _Heading(s.t('squadPartial')),
          if (view == 'statistics') _Heading(s.t('partial')),
        ],
        group: view == 'squad'
            ? (row) => s.role(
                row.text('squad_position').isEmpty
                    ? row.text('position')
                    : row.text('squad_position'),
              )
            : null,
        row: (_, row) => view == 'squad'
            ? _Player(row)
            : view == 'statistics'
            ? FootballMetrics(row.metrics)
            : view == 'standings'
            ? _Standing(row, {
                for (final team
                    in ref.watch(footballDirectoryProvider).valueOrNull?.rows ??
                        <FootballRecord>[])
                  team.id: team,
              })
            : FootballMatchTile(row),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(info?.name ?? s.t('teams'))),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final section in [
                  'overview',
                  'results',
                  'fixtures',
                  'standings',
                  'statistics',
                  'squad',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      labelStyle: Theme.of(context).textTheme.labelLarge,
                      label: Text(s.t(section)),
                      selected: section == _section,
                      onSelected: (_) => setState(() => _section = section),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String title;
  const _Heading(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _TeamHeader extends StatelessWidget {
  final FootballRecord team;
  const _TeamHeader(this.team);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        FootballLogo(team.text('logo_url'), size: 64),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(team.name, style: Theme.of(context).textTheme.titleLarge),
              for (final key in ['city', 'country', 'venue', 'founded_year'])
                if (team.text(key).isNotEmpty) Text(team.text(key)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Standing extends StatelessWidget {
  final FootballRecord standing;
  final Map<int, FootballRecord> teams;
  const _Standing(this.standing, this.teams);
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Text('${standing.number('position') ?? '\u2014'}'),
    title: Text(
      teams[standing.number('team_id')]?.name ??
          FootballStrings.of(context).t('teams'),
    ),
    subtitle: Text(FootballStrings.of(context).t('partial')),
    trailing: Text(
      '${standing.number('points') ?? '\u2014'} ${FootballStrings.of(context).t('points')}',
    ),
  );
}

class _Player extends StatelessWidget {
  final FootballRecord player;
  const _Player(this.player);
  @override
  Widget build(BuildContext context) {
    final s = FootballStrings.of(context);
    final metrics = <String, num>{};
    for (final stat in player.nested('statistics')) {
      metrics.addAll(stat.metrics);
    }
    return ExpansionTile(
      leading: FootballLogo(player.text('photo_url')),
      title: Text(
        player.text('display_name').isEmpty
            ? player.name
            : player.text('display_name'),
      ),
      subtitle: Text(
        [
          s.role(
            player.text('squad_position').isEmpty
                ? player.text('position')
                : player.text('squad_position'),
          ),
          if (player.number('shirt_number') != null)
            '#${player.number('shirt_number')}',
          if (player.text('nationality').isNotEmpty) player.text('nationality'),
        ].join(' · '),
      ),
      children: [
        metrics.isEmpty
            ? FootballEmpty(s.t('empty'))
            : FootballMetrics(metrics),
      ],
    );
  }
}

class _SingleSection extends ConsumerWidget {
  final FootballQuery query;
  final String empty;
  const _SingleSection(this.query, {this.empty = 'empty'});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(footballSingleProvider(query))
      .when(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => FootballEmpty(
          footballError(context, e),
          retry: () => ref.invalidate(footballSingleProvider(query)),
        ),
        data: (row) => row == null
            ? FootballEmpty(FootballStrings.of(context).t(empty))
            : FootballMatchTile(row),
      );
}

class FootballMatchScreen extends ConsumerStatefulWidget {
  final int matchId;
  const FootballMatchScreen(this.matchId, {super.key});
  @override
  ConsumerState<FootballMatchScreen> createState() => _MatchState();
}

class _MatchState extends ConsumerState<FootballMatchScreen>
    with WidgetsBindingObserver {
  Timer? _refresh;
  bool _foreground = true, _refreshing = false, _pollFailed = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _refresh?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (state != AppLifecycleState.resumed) {
      _refresh?.cancel();
      _refresh = null;
    } else {
      _startRefresh();
    }
  }

  void _startRefresh() {
    if (ref
            .read(
              footballSingleProvider(
                FootballQuery('matches/${widget.matchId}'),
              ),
            )
            .valueOrNull
            ?.isLive !=
        true) {
      _refresh?.cancel();
      _refresh = null;
      return;
    }
    if (_refresh != null ||
        !mounted ||
        !_foreground ||
        ref.read(footballConfigProvider)?.live.enabled != true) {
      return;
    }
    _refresh = Timer.periodic(const Duration(seconds: 60), (_) async {
      if (_refreshing || !_foreground) return;
      _refreshing = true;
      final query = FootballQuery('matches/${widget.matchId}');
      try {
        await (await ref.read(
          footballRepositoryProvider.future,
        )).single(query, refresh: true);
        if (mounted) {
          setState(() => _pollFailed = false);
          ref.invalidate(footballSingleProvider(query));
        }
      } catch (_) {
        if (mounted) setState(() => _pollFailed = true);
      } finally {
        _refreshing = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = FootballStrings.of(context),
        query = FootballQuery('matches/${widget.matchId}');
    final live = ref.watch(footballConfigProvider)?.live.enabled ?? false;
    _startRefresh();
    return Scaffold(
      appBar: AppBar(title: Text(s.t('match'))),
      body: ref
          .watch(footballSingleProvider(query))
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => FootballEmpty(
              footballError(context, e),
              retry: () => ref.invalidate(footballSingleProvider(query)),
            ),
            data: (row) {
              if (row == null) return FootballEmpty(s.t('empty'));
              return RefreshIndicator(
                onRefresh: () async {
                  try {
                    await (await ref.read(
                      footballRepositoryProvider.future,
                    )).single(query, refresh: true);
                  } catch (_) {
                    /* Retain cached content or localized error. */
                  }
                  ref.invalidate(footballSingleProvider(query));
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            row.text('competition_name'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${row.text('season_name')} · ${s.phase((name: row.text('group_name').isEmpty ? row.text('stage_name') : row.text('group_name'), type: row.text('stage_name') == 'Championship Round' ? 'playoff' : ''))}',
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _MatchTeam(
                                  row.text('home_name'),
                                  row.text('home_logo'),
                                  row.number('home_team_id'),
                                ),
                              ),
                              SizedBox(
                                width: 110,
                                child: Text(
                                  row.score(liveAllowed: live),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              Expanded(
                                child: _MatchTeam(
                                  row.text('away_name'),
                                  row.text('away_logo'),
                                  row.number('away_team_id'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            row.isLive && !live
                                ? s.t('livePending')
                                : s.status(row.status),
                          ),
                          if (row.kickoff != null)
                            Text(
                              DateFormat.yMMMMEEEEd(
                                s.language,
                              ).add_Hm().format(row.kickoff!.toLocal()),
                            ),
                          if (row.text('venue').isNotEmpty)
                            Text(row.text('venue')),
                          if (row.data['quality'] is Map &&
                              (row.data['quality'] as Map)['publishable'] !=
                                  true)
                            Text(s.t('unverified')),
                          if (live &&
                              row.isLive &&
                              row.number('current_minute') != null)
                            Text("${row.number('current_minute')}'"),
                          if (live &&
                              row.isLive &&
                              s.period(row.text('current_period')).isNotEmpty)
                            Text(s.period(row.text('current_period'))),
                          if (row.stale || _pollFailed) Text(s.t('stale')),
                        ],
                      ),
                    ),
                    _Heading(s.t('eventsPartial')),
                    if (row.nested('events').isEmpty || (row.isLive && !live))
                      FootballEmpty(s.t('eventsEmpty')),
                    if (!row.isLive || live)
                      for (final event in row.nested('events'))
                        ListTile(
                          leading: Text(
                            event.number('minute') == null
                                ? '\u2014'
                                : "${event.number('minute')}'",
                          ),
                          title: Text(
                            s.t(
                              [
                                    'goal',
                                    'own_goal',
                                    'penalty',
                                    'yellow_card',
                                    'red_card',
                                    'substitution',
                                    'var',
                                  ].contains(event.text('event_type'))
                                  ? event.text('event_type')
                                  : 'event',
                            ),
                          ),
                          subtitle: event.text('player_name').isEmpty
                              ? null
                              : Text(event.text('player_name')),
                        ),
                  ],
                ),
              );
            },
          ),
    );
  }
}

class _MatchTeam extends StatelessWidget {
  final String name, logo;
  final int? id;
  const _MatchTeam(this.name, this.logo, this.id);
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: id == null
        ? null
        : () => Navigator.of(context).pushNamed('/football/team/$id'),
    child: Column(
      children: [
        FootballLogo(logo, size: 56),
        const SizedBox(height: 8),
        Text(name, textAlign: TextAlign.center),
      ],
    ),
  );
}

Route<dynamic>? footballRoute(RouteSettings settings) {
  final parts = Uri.tryParse(settings.name ?? '')?.pathSegments ?? [];
  if (parts.length < 2 || parts.first != 'football') return null;
  final id = parts.length == 3 ? int.tryParse(parts[2]) : null;
  Widget? screen;
  if (parts.length == 2 && parts[1] == 'teams') {
    screen = const FootballTeamsScreen();
  }
  if (id != null && id > 0) {
    screen = switch (parts[1]) {
      'competition' => FootballCompetitionScreen(competitionId: id),
      'team' => FootballTeamScreen(id),
      'match' => FootballMatchScreen(id),
      _ => null,
    };
  }
  return MaterialPageRoute(
    settings: settings,
    builder: (context) =>
        screen ??
        Scaffold(
          body: FootballEmpty(FootballStrings.of(context).t('unavailable')),
        ),
  );
}
