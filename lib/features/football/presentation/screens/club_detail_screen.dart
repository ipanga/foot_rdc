import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/navigation/deep_link_handler.dart';
import '../../data/football_repository.dart';
import '../../domain/countries.dart';
import '../../domain/models.dart';
import '../football_labels.dart';
import '../football_routes.dart';
import '../providers.dart';
import '../widgets/football_widgets.dart';

/// Club page: follows the season chosen in Matchs or Classement.
class ClubDetailScreen extends ConsumerWidget {
  final int clubId;
  const ClubDetailScreen({super.key, required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final club = ref.watch(clubProvider(clubId));
    final season = ref.watch(activeSeasonProvider);
    final followed = ref.watch(favoriteClubsProvider).contains(clubId);
    final name = club.valueOrNull?.value.name ?? '';
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text(name),
          actions: [
            IconButton(
              tooltip: followed ? 'Ne plus suivre' : 'Suivre ce club',
              icon: Icon(followed ? Icons.star : Icons.star_border),
              onPressed: () => ref.read(favoriteClubsProvider.notifier).toggle(clubId),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Aperçu'),
              Tab(text: 'Actualités'),
              Tab(text: 'Résultats'),
              Tab(text: 'Calendrier'),
              Tab(text: 'Classement'),
              Tab(text: 'Effectif'),
            ],
          ),
        ),
        body: season.when(
          loading: () => const ListSkeleton(),
          error: (error, _) => MessageState(icon: Icons.cloud_off_outlined, title: failureMessage(error)),
          data: (s) => LoadedView<Club>(
            value: club,
            onRetry: () => ref.invalidate(clubProvider(clubId)),
            builder: (c) => TabBarView(
              children: [
                _Overview(club: c, season: s),
                _News(club: c.id),
                _ClubMatches(club: c.id, season: s.id, view: 'results'),
                _ClubMatches(club: c.id, season: s.id, view: 'upcoming'),
                _Standing(club: c.id, season: s.id),
                _Squad(club: c.id, season: s.id),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Overview extends ConsumerWidget {
  final Club club;
  final Season season;
  const _Overview({required this.club, required this.season});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(clubProfileProvider(club.id)).valueOrNull?.value;
    final next = ref.watch(clubMatchesProvider((club.id, season.id, 'upcoming'))).valueOrNull?.value ?? const <Match>[];
    final last = ref.watch(clubMatchesProvider((club.id, season.id, 'results'))).valueOrNull?.value ?? const <Match>[];
    final squad = ref.watch(squadProvider((club.id, season.id))).valueOrNull?.value ?? const <SquadMember>[];
    final tables = ref.watch(standingsProvider(season.id)).valueOrNull?.value ?? const <StandingTable>[];
    StandingTable? table;
    for (final t in tables) {
      if (t.rows.any((r) => r.teamId == club.id)) table = t;
    }
    final row = table?.rows.firstWhere((r) => r.teamId == club.id);
    final facts = <(String, String)>[
      if ((profile?.city ?? club.city).isNotEmpty) ('Ville', profile?.city ?? club.city),
      if (profile?.stadium != null) ('Stade', profile!.stadium!),
      if (profile?.founded != null) ('Fondation', '${profile!.founded}'),
      if (table != null) ('Groupe', phaseLabel(table.group?.name ?? table.stage?.name ?? '')),
    ];
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClubCrest(url: club.logoUrl, name: club.name, size: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Text(club.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        for (final (k, v) in facts)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  child: Text(k, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ),
                Expanded(
                  child: Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        if (profile?.website != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => launchUrl(Uri.parse(profile!.website!), mode: LaunchMode.externalApplication),
                child: const Text('Site officiel'),
              ),
            ),
          ),
        if (next.isNotEmpty) ...[
          const SectionHeader('Prochain match'),
          MatchRow(match: next.first, showDate: true, onTap: () => openMatch(context, next.first.id)),
        ],
        if (last.isNotEmpty) ...[
          const SectionHeader('Dernier résultat'),
          MatchRow(match: last.first, showDate: true, onTap: () => openMatch(context, last.first.id)),
        ],
        if (row != null) ...[
          const SectionHeader('Classement'),
          StandingsTableView(rows: [row], highlightTeam: club.id),
        ],
        if (squad.isNotEmpty) ...[
          const SectionHeader('Effectif'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Text(
              '${squad.length} joueurs enregistrés pour ${season.label}. La liste peut être incomplète.',
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }
}

class _News extends ConsumerStatefulWidget {
  final int club;
  const _News({required this.club});
  @override
  ConsumerState<_News> createState() => _NewsState();
}

class _NewsState extends ConsumerState<_News> {
  int _pages = 1;

  @override
  Widget build(BuildContext context) {
    final first = ref.watch(clubNewsProvider((widget.club, 1)));
    return LoadedView<List<ClubNewsItem>>(
      value: first,
      onRetry: () => ref.invalidate(clubNewsProvider((widget.club, 1))),
      builder: (_) {
        final rows = <ClubNewsItem>[];
        var more = false;
        var loading = false;
        for (var page = 1; page <= _pages; page++) {
          final value = ref.watch(clubNewsProvider((widget.club, page)));
          final list = value.valueOrNull?.value;
          if (list == null) {
            loading = value.isLoading;
            break;
          }
          rows.addAll(list);
          more = list.length == FootballRepository.clubNewsPageSize;
        }
        if (rows.isEmpty) {
          return const MessageState(
            icon: Icons.article_outlined,
            title: 'Aucune actualité liée à ce club',
            detail: 'Les articles apparaissent ici quand la rédaction les lie au club.',
          );
        }
        return ListView.separated(
          itemCount: rows.length + 1,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index == rows.length) {
              if (loading) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (!more) return const SizedBox(height: 24);
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: OutlinedButton(onPressed: () => setState(() => _pages++), child: const Text('Charger plus')),
                ),
              );
            }
            return ClubNewsTile(item: rows[index]);
          },
        );
      },
    );
  }
}

/// A linked article: opens inside the app by its id, whatever host the link carries.
class ClubNewsTile extends StatelessWidget {
  final ClubNewsItem item;
  const ClubNewsTile({super.key, required this.item});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => pushLinks.add('footrdc://article/${item.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 96,
                height: 64,
                child: item.imageUrl == null || !ClubCrest.showImages
                    ? ColoredBox(
                        color: scheme.surfaceContainerHighest,
                        child: Icon(Icons.article_outlined, color: scheme.onSurfaceVariant),
                      )
                    : CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 288,
                        errorWidget: (_, _, _) => ColoredBox(color: scheme.surfaceContainerHighest),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.category != null)
                    Text(
                      item.category!.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
                    ),
                  Text(
                    item.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(shortDate(item.date), style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClubMatches extends ConsumerWidget {
  final int club;
  final int season;
  final String view;
  const _ClubMatches({required this.club, required this.season, required this.view});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = clubMatchesProvider((club, season, view));
    return LoadedView<List<Match>>(
      value: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
      builder: (rows) {
        if (rows.isEmpty) {
          return MessageState(
            icon: Icons.event_busy_outlined,
            title: view == 'results' ? 'Aucun résultat cette saison' : 'Aucun match à venir',
          );
        }
        final items = groupByDay(rows);
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(provider),
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              if (item is String) return DayHeader(item);
              final match = item as Match;
              return MatchRow(match: match, onTap: () => openMatch(context, match.id));
            },
          ),
        );
      },
    );
  }
}

class _Standing extends ConsumerWidget {
  final int club;
  final int season;
  const _Standing({required this.club, required this.season});
  @override
  Widget build(BuildContext context, WidgetRef ref) => LoadedView<List<StandingTable>>(
    value: ref.watch(standingsProvider(season)),
    onRetry: () => ref.invalidate(standingsProvider(season)),
    builder: (tables) {
      final mine = tables.where((t) => t.rows.any((r) => r.teamId == club)).toList();
      if (mine.isEmpty) {
        return const MessageState(
          icon: Icons.leaderboard_outlined,
          title: 'Ce club n’a pas de classement cette saison',
        );
      }
      return ListView(
        children: [
          for (final table in mine) ...[
            SectionHeader(phaseLabel(table.group?.name ?? table.stage?.name ?? '')),
            StandingsTableView(
              rows: table.rows,
              highlightTeam: club,
              onClub: (id) => id == club ? null : openClub(context, id),
            ),
            ProvisionalNote(verified: table.verified),
          ],
        ],
      );
    },
  );
}

class _Squad extends ConsumerWidget {
  final int club;
  final int season;
  const _Squad({required this.club, required this.season});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = squadProvider((club, season));
    return LoadedView<List<SquadMember>>(
      value: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
      builder: (rows) {
        if (rows.isEmpty) {
          return const MessageState(
            icon: Icons.groups_outlined,
            title: 'Effectif non disponible',
            detail: 'Aucun joueur enregistré pour ce club cette saison.',
          );
        }
        final known = positionGroups.map((p) => p.$1).toSet();
        final sections = <(String, List<SquadMember>)>[
          for (final (key, label) in positionGroups) (label, rows.where((m) => m.position == key).toList()),
          ('Autres', rows.where((m) => !known.contains(m.position)).toList()),
        ];
        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                '${rows.length} joueurs enregistrés. La liste peut être incomplète.',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            for (final (label, members) in sections)
              if (members.isNotEmpty) ...[
                DayHeader('$label (${members.length})'),
                for (final m in members)
                  ListTile(
                    dense: true,
                    leading: SizedBox(
                      width: 28,
                      child: Text(
                        m.number == null ? '–' : '${m.number}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                    title: Text(
                      m.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: _detail(m).isEmpty ? null : Text(_detail(m)),
                    onTap: () => openPlayer(context, m.playerId),
                  ),
              ],
          ],
        );
      },
    );
  }

  String _detail(SquadMember m) {
    final age = ageAt(m.birthDate, DateTime.now());
    return [if (m.nationality.isNotEmpty) countryName(m.nationality), if (age != null) '$age ans'].join(' · ');
  }
}
