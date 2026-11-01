import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/countries.dart';
import '../../domain/models.dart';
import '../football_labels.dart';
import '../football_routes.dart';
import '../providers.dart';
import '../widgets/football_widgets.dart';

/// Only what is known about a player is shown; missing fields simply do not appear.
class PlayerDetailScreen extends ConsumerWidget {
  final int playerId;
  const PlayerDetailScreen({super.key, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(playerProvider(playerId));
    return Scaffold(
      appBar: AppBar(title: Text(value.valueOrNull?.value.name ?? 'Joueur')),
      body: LoadedView<Player>(
        value: value,
        onRetry: () => ref.invalidate(playerProvider(playerId)),
        builder: (player) {
          final age = ageAt(player.birthDate, DateTime.now());
          final facts = <(String, String)>[
            if (player.position.isNotEmpty) ('Poste', positionLabel(player.position)),
            if (player.nationality.isNotEmpty) ('Nationalité', countryName(player.nationality)),
            if (age != null) ('Âge', '$age ans'),
          ];
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(player.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              ),
              for (final (k, v) in facts)
                ListTile(
                  dense: true,
                  title: Text(k),
                  trailing: Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              if (player.memberships.isNotEmpty) ...[
                const SectionHeader('Effectifs'),
                for (final m in player.memberships)
                  ListTile(
                    leading: ClubCrest(url: m.teamLogo, name: m.teamName, size: 32),
                    title: Text(m.teamName),
                    subtitle: Text(
                      [
                        m.seasonName.replaceAll('-', '–'),
                        if (m.number != null) 'N° ${m.number}',
                        if (m.position.isNotEmpty) positionLabel(m.position),
                      ].join(' · '),
                    ),
                    onTap: () => openClub(context, m.teamId),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
