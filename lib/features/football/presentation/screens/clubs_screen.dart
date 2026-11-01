import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../football_labels.dart';
import '../football_routes.dart';
import '../providers.dart';
import '../widgets/football_widgets.dart';

/// Clubs of a season: search, group filter and followed clubs first.
class ClubsDirectory extends ConsumerStatefulWidget {
  final Season season;
  const ClubsDirectory({super.key, required this.season});
  @override
  ConsumerState<ClubsDirectory> createState() => _ClubsDirectoryState();
}

class _ClubsDirectoryState extends ConsumerState<ClubsDirectory> {
  var _query = '';
  String? _group;

  static String _fold(String text) => text
      .toLowerCase()
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[àâä]'), 'a')
      .replaceAll(RegExp('[ôö]'), 'o')
      .replaceAll(RegExp('[îï]'), 'i');

  @override
  Widget build(BuildContext context) {
    final season = widget.season.id;
    final tables = ref.watch(standingsProvider(season)).valueOrNull?.value ?? const <StandingTable>[];
    final favorites = ref.watch(favoriteClubsProvider);
    final groupOf = <int, String>{};
    for (final table in tables.where((t) => t.group != null && !(t.stage?.isPlayoff ?? false))) {
      for (final row in table.rows) {
        groupOf[row.teamId] = phaseLabel(table.group!.name);
      }
    }
    final labels = groupOf.values.toSet().toList()..sort();
    return LoadedView<List<Club>>(
      value: ref.watch(clubsProvider(season)),
      onRetry: () => ref.invalidate(clubsProvider(season)),
      builder: (clubs) {
        final key = _fold(_query.trim());
        final rows =
            clubs
                .where(
                  (c) => (key.isEmpty || _fold(c.name).contains(key)) && (_group == null || groupOf[c.id] == _group),
                )
                .toList()
              ..sort((a, b) => (favorites.contains(a.id) ? 0 : 1).compareTo(favorites.contains(b.id) ? 0 : 1));
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Rechercher un club',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            if (labels.length > 1)
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  children: [
                    for (final label in [null, ...labels])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(label ?? 'Tous'),
                          selected: _group == label,
                          onSelected: (_) => setState(() => _group = label),
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: rows.isEmpty
                  ? ListView(
                      children: const [MessageState(icon: Icons.search_off, title: 'Aucun club trouvé')],
                    )
                  : ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final club = rows[index];
                        return ClubTile(club: club, subtitle: groupOf[club.id] ?? '');
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class ClubTile extends ConsumerWidget {
  final Club club;
  final String subtitle;
  const ClubTile({super.key, required this.club, this.subtitle = ''});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followed = ref.watch(favoriteClubsProvider).contains(club.id);
    return ListTile(
      leading: ClubCrest(url: club.logoUrl, name: club.name, size: 32),
      title: Text(club.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      trailing: IconButton(
        tooltip: followed ? 'Ne plus suivre ${club.name}' : 'Suivre ${club.name}',
        icon: Icon(followed ? Icons.star : Icons.star_border),
        onPressed: () => ref.read(favoriteClubsProvider.notifier).toggle(club.id),
      ),
      onTap: () => openClub(context, club.id),
    );
  }
}
