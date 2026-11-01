import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../football_labels.dart';
import '../football_routes.dart';
import '../providers.dart';
import 'football_widgets.dart';

/// Clubs come from the saved season list, players from a server search run once per submitted query.
final _playerSearchProvider = FutureProvider.autoDispose.family<List<Player>, String>((ref, query) async {
  final repo = await ref.watch(footballRepositoryProvider.future);
  return repo.searchPlayers(query);
});

class FootballSearchResults extends ConsumerWidget {
  final String query;
  const FootballSearchResults({super.key, required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = query.trim().toLowerCase();
    if (key.length < 2) return const SizedBox.shrink();
    final season = ref.watch(currentSeasonProvider).valueOrNull;
    final clubs = season == null ? const <Club>[] : (ref.watch(clubsProvider(season.id)).valueOrNull?.value ?? const <Club>[]);
    final matches = clubs.where((c) => c.name.toLowerCase().contains(key)).take(3).toList();
    final players = (ref.watch(_playerSearchProvider(query.trim())).valueOrNull ?? const <Player>[]).take(3).toList();
    if (matches.isEmpty && players.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (matches.isNotEmpty) ...[
          const SectionHeader('Clubs'),
          for (final club in matches)
            ListTile(
              dense: true,
              leading: ClubCrest(url: club.logoUrl, name: club.name, size: 28),
              title: Text(club.name),
              onTap: () => openClub(context, club.id),
            ),
        ],
        if (players.isNotEmpty) ...[
          const SectionHeader('Joueurs'),
          for (final player in players)
            ListTile(
              dense: true,
              title: Text(player.name),
              subtitle: player.position.isEmpty ? null : Text(positionLabel(player.position)),
              onTap: () => openPlayer(context, player.id),
            ),
        ],
        if (matches.isNotEmpty || players.isNotEmpty) const SectionHeader('Articles'),
      ],
    );
  }
}
