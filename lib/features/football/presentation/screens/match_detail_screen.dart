import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models.dart';
import '../football_labels.dart';
import '../football_routes.dart';
import '../providers.dart';
import '../widgets/football_widgets.dart';

class MatchDetailScreen extends ConsumerWidget {
  final int matchId;
  const MatchDetailScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(matchDetailProvider(matchId));
    return Scaffold(
      appBar: AppBar(title: const Text('Match')),
      body: LoadedView<MatchDetail>(
        value: value,
        onRetry: () => ref.invalidate(matchDetailProvider(matchId)),
        builder: (detail) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(matchDetailProvider(matchId)),
          child: ListView(
            children: [
              _Header(match: detail.match),
              _Facts(match: detail.match),
              const SectionHeader('Fil du match'),
              _Timeline(match: detail.match, events: detail.events),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Match match;
  const _Header({required this.match});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scored = match.status.hasScore && match.home.score != null;
    final center = scored ? '${match.home.score} – ${match.away.score}' : kickoffTime(match.kickoff);
    return Semantics(
      container: true,
      label:
          '${match.home.name} contre ${match.away.name}, ${scored ? '${match.home.score} à ${match.away.score}' : kickoffTime(match.kickoff)}, ${statusLabel(match.status)}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _Team(side: match.home)),
            SizedBox(
              width: 112,
              child: Column(
                children: [
                  Text(
                    center,
                    style: TextStyle(
                      fontSize: scored ? 30 : 24,
                      fontWeight: FontWeight.w800,
                      color: match.status.isLive ? AppColors.matchLive : scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (match.status == MatchStatus.finished || match.status == MatchStatus.scheduled)
                    Text(
                      match.status == MatchStatus.finished ? 'Terminé' : dayLabel(match.kickoff),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                    )
                  else
                    StatusBadge(status: match.status, minute: match.minute),
                ],
              ),
            ),
            Expanded(child: _Team(side: match.away)),
          ],
        ),
      ),
    );
  }
}

class _Team extends StatelessWidget {
  final MatchSide side;
  const _Team({required this.side});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => openClub(context, side.teamId),
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          ClubCrest(url: side.logoUrl, name: side.name, size: 56),
          const SizedBox(height: 8),
          Text(
            side.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

class _Facts extends StatelessWidget {
  final Match match;
  const _Facts({required this.match});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = <(IconData, String)>[
      if (match.kickoff != null) (Icons.schedule, '${dayLabel(match.kickoff)} · ${kickoffTime(match.kickoff)}'),
      if (match.venue.isNotEmpty) (Icons.place_outlined, match.venue),
      if (match.groupName.isNotEmpty || match.stageName.isNotEmpty)
        (
          Icons.emoji_events_outlined,
          [
            'Linafoot',
            phaseLabel(match.groupName.isNotEmpty ? match.groupName : match.stageName),
            if (match.round.isNotEmpty) 'Journée ${match.round}',
          ].join(' · '),
        ),
    ];
    return Column(
      children: [
        Divider(height: 1, color: scheme.outlineVariant),
        for (final (icon, text) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
              ],
            ),
          ),
        Divider(height: 1, color: scheme.outlineVariant),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  final Match match;
  final List<MatchEvent> events;
  const _Timeline({required this.match, required this.events});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (events.isEmpty) {
      final text = switch (match.status) {
        MatchStatus.scheduled || MatchStatus.postponed => 'Le fil du match sera disponible pendant la rencontre.',
        _ => 'Aucun événement enregistré pour ce match.',
      };
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Text(text, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
      );
    }
    return Column(
      children: [for (final event in events) _EventRow(event: event, match: match)],
    );
  }
}

class _EventRow extends StatelessWidget {
  final MatchEvent event;
  final Match match;
  const _EventRow({required this.event, required this.match});

  (IconData, Color, String) _kind(ColorScheme scheme) => switch (event.type) {
    EventType.goal => (Icons.sports_soccer, scheme.onSurface, 'But'),
    EventType.penaltyGoal => (Icons.sports_soccer, scheme.onSurface, 'But sur penalty'),
    EventType.ownGoal => (Icons.sports_soccer, AppColors.error, 'But contre son camp'),
    EventType.yellowCard => (Icons.square_rounded, AppColors.warning, 'Carton jaune'),
    EventType.redCard => (Icons.square_rounded, AppColors.error, 'Carton rouge'),
    EventType.substitution => (Icons.swap_horiz, scheme.onSurfaceVariant, 'Remplacement'),
    EventType.var_ => (Icons.tv, scheme.onSurfaceVariant, 'VAR'),
    EventType.other => (Icons.circle_outlined, scheme.onSurfaceVariant, 'Événement'),
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, color, label) = _kind(scheme);
    final club = event.teamName.isNotEmpty
        ? event.teamName
        : (event.teamId == match.home.teamId
              ? match.home.name
              : (event.teamId == match.away.teamId ? match.away.name : ''));
    final who = [
      if (event.playerName != null) event.playerName!,
      if (event.relatedPlayerName != null) event.relatedPlayerName!,
      if (event.playerName == null && event.detail != null) event.detail!,
    ].join(' · ');
    return Semantics(
      label: '${event.clock} $label ${who.isEmpty ? '' : who} $club',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(event.clock, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    who.isEmpty ? label : who,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    [if (who.isNotEmpty) label, if (club.isNotEmpty) club].join(' · '),
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
