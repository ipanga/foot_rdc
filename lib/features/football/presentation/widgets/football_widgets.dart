import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/football_client.dart';
import '../../domain/models.dart';
import '../football_labels.dart';

/// Crest from the server's canonical URL; neutral initials when a club has none.
class ClubCrest extends StatelessWidget {
  final String? url;
  final String name;
  final double size;
  const ClubCrest({super.key, this.url, required this.name, this.size = 24});

  /// Tests run without the image plugin.
  @visibleForTesting
  static bool loadImages = true;

  @override
  Widget build(BuildContext context) {
    final fallback = _Initials(name: name, size: size);
    if (url == null || url!.isEmpty || !loadImages) return fallback;
    return ExcludeSemantics(
      child: CachedNetworkImage(
        imageUrl: url!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        memCacheWidth: (size * 3).round(),
        fadeInDuration: Duration.zero,
        placeholder: (_, _) => SizedBox(width: size, height: size),
        errorWidget: (_, _, _) => fallback,
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String name;
  final double size;
  const _Initials({required this.name, required this.size});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final text = words.isEmpty
        ? '?'
        : (words.length == 1 ? words.first.substring(0, 1) : '${words.first[0]}${words.last[0]}').toUpperCase();
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: scheme.surfaceContainerHighest, shape: BoxShape.circle),
        child: Text(
          text,
          maxLines: 1,
          style: TextStyle(fontSize: size * 0.36, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

/// Match state in words; colour only reinforces it.
class StatusBadge extends StatelessWidget {
  final MatchStatus status;
  final int? minute;
  const StatusBadge({super.key, required this.status, this.minute});
  @override
  Widget build(BuildContext context) {
    if (status == MatchStatus.scheduled || status == MatchStatus.finished || status == MatchStatus.unknown)
      return const SizedBox.shrink();
    final live = status.isLive;
    final text = status == MatchStatus.live && minute != null ? "$minute'" : statusLabel(status);
    final color = live
        ? AppColors.matchLive
        : (status == MatchStatus.postponed ? AppColors.warningDark : Theme.of(context).colorScheme.onSurfaceVariant);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (live)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        Flexible(
          child: Text(
            text,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ),
      ],
    );
  }
}

/// One match in a list: left column time or state, then one line per club with its score.
class MatchRow extends StatelessWidget {
  final Match match;
  final VoidCallback? onTap;
  const MatchRow({super.key, required this.match, this.onTap});

  String get _semantics {
    final score = match.status.hasScore && match.home.score != null
        ? '${match.home.score} à ${match.away.score}'
        : kickoffTime(match.kickoff);
    return '${match.home.name} contre ${match.away.name}, $score, ${statusLabel(match.status)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showTime =
        !match.status.isLive && match.status != MatchStatus.postponed && match.status != MatchStatus.cancelled;
    return Semantics(
      button: true,
      label: _semantics,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 58,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showTime && !match.status.hasScore)
                        Text(
                          kickoffTime(match.kickoff),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
                        )
                      else if (match.status == MatchStatus.finished)
                        Text('Terminé', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                      StatusBadge(status: match.status, minute: match.minute),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      _Side(side: match.home, other: match.away, status: match.status),
                      const SizedBox(height: 6),
                      _Side(side: match.away, other: match.home, status: match.status),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Side extends StatelessWidget {
  final MatchSide side;
  final MatchSide other;
  final MatchStatus status;
  const _Side({required this.side, required this.other, required this.status});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final won = status.isOver && side.score != null && other.score != null && side.score! > other.score!;
    return Row(
      children: [
        ClubCrest(url: side.logoUrl, name: side.name, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            side.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: won ? FontWeight.w700 : FontWeight.w500,
              color: scheme.onSurface,
            ),
          ),
        ),
        if (status.hasScore && side.score != null)
          Text(
            '${side.score}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: won || status.isLive ? FontWeight.w800 : FontWeight.w600,
              color: status.isLive ? AppColors.matchLive : scheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
      ],
    );
  }
}

/// Small horizontal card of the Home match strip.
class MatchChip extends StatelessWidget {
  final Match match;
  final VoidCallback? onTap;
  const MatchChip({super.key, required this.match, this.onTap});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scored = match.status.hasScore && match.home.score != null;
    Widget line(MatchSide side) => Row(
      children: [
        ClubCrest(url: side.logoUrl, name: side.name, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            side.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        if (scored) Text('${side.score}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
    return Semantics(
      button: true,
      label:
          '${match.home.name} contre ${match.away.name}, ${scored ? '${match.home.score} à ${match.away.score}' : '${dayLabel(match.kickoff)} ${kickoffTime(match.kickoff)}'}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 176,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              match.status.isLive
                  ? StatusBadge(status: match.status, minute: match.minute)
                  : Text(
                      '${shortDate(match.kickoff)} · ${match.status == MatchStatus.finished ? 'Terminé' : (match.status == MatchStatus.scheduled ? kickoffTime(match.kickoff) : statusLabel(match.status))}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                    ),
              line(match.home),
              line(match.away),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader(this.title, {super.key, this.action, this.onAction});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
      ],
    ),
  );
}

class DayHeader extends StatelessWidget {
  final String text;
  const DayHeader(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}

/// Friendly wording for a failure. Raw HTTP never reaches the screen.
String failureMessage(Object? error) {
  final kind = error is FootballFailure ? error.kind : FootballError.server;
  return switch (kind) {
    FootballError.offline || FootballError.cacheMiss => 'Pas de connexion. Vérifiez votre réseau.',
    FootballError.timeout => 'Le serveur met trop de temps à répondre.',
    FootballError.notFound => 'Cette page n’est plus disponible.',
    FootballError.malformed || FootballError.server => 'Les données sont indisponibles pour le moment.',
  };
}

class MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? detail;
  final VoidCallback? onRetry;
  const MessageState({super.key, required this.icon, required this.title, this.detail, this.onRetry});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            if (detail != null) ...[
              const SizedBox(height: 4),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
            ],
          ],
        ),
      ),
    );
  }
}

class StaleNotice extends StatelessWidget {
  const StaleNotice({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: AppColors.warningContainer,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: const Text(
      'Données enregistrées. Actualisation impossible pour le moment.',
      style: TextStyle(fontSize: 12, color: AppColors.onWarningContainer),
    ),
  );
}

class ListSkeleton extends StatelessWidget {
  final int rows;
  const ListSkeleton({super.key, this.rows = 6});
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar(double width) => Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
    );
    return Semantics(
      label: 'Chargement',
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rows,
        itemBuilder: (_, _) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              bar(44),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [bar(160), const SizedBox(height: 10), bar(130)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading, error and stale handling for a [Loaded] value. A refreshing screen keeps its data.
class LoadedView<T> extends StatelessWidget {
  final AsyncValue<Loaded<T>> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final Widget? loading;
  const LoadedView({super.key, required this.value, required this.builder, this.onRetry, this.loading});
  @override
  Widget build(BuildContext context) {
    if (value.hasValue) {
      final loaded = value.requireValue;
      return Column(
        children: [
          if (loaded.stale) const StaleNotice(),
          Expanded(child: builder(loaded.value)),
        ],
      );
    }
    if (value.hasError) {
      return MessageState(icon: Icons.cloud_off_outlined, title: failureMessage(value.error), onRetry: onRetry);
    }
    return loading ?? const ListSkeleton();
  }
}

/// Matches grouped under day headers.
List<Object> groupByDay(List<Match> matches) {
  final out = <Object>[];
  String? day;
  for (final match in matches) {
    final label = dayLabel(match.kickoff);
    if (label != day) {
      out.add(label);
      day = label;
    }
    out.add(match);
  }
  return out;
}

/// Compact table with the columns that matter, full columns on request. Nothing is computed here.
class StandingsTableView extends StatelessWidget {
  final List<StandingRow> rows;
  final bool full;
  final int? highlightTeam;
  final ValueChanged<int>? onClub;
  const StandingsTableView({super.key, required this.rows, this.full = false, this.highlightTeam, this.onClub});

  static const _compact = ['MJ', 'Diff.', 'Pts'];
  static const _all = ['MJ', 'G', 'N', 'P', 'BP', 'BC', 'Diff.', 'Pts'];

  List<String> _values(StandingRow r) {
    final diff = r.goalDifference > 0 ? '+${r.goalDifference}' : '${r.goalDifference}';
    return full
        ? [
            '${r.played}',
            '${r.won}',
            '${r.drawn}',
            '${r.lost}',
            '${r.goalsFor}',
            '${r.goalsAgainst}',
            diff,
            '${r.points}',
          ]
        : ['${r.played}', diff, '${r.points}'];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = full ? 27.0 : 40.0;
    final titles = full ? _all : _compact;
    return LayoutBuilder(
      builder: (context, box) {
        final showCrest = box.maxWidth > 340 || !full;
        Widget cell(String text, {bool strong = false, Color? color}) => SizedBox(
          width: width,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.clip,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: full ? 12 : 13,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        );
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '#',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                    ),
                  ),
                  Expanded(
                    child: Text('Club', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                  ),
                  for (final t in titles) cell(t, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
            Divider(height: 1, color: scheme.outlineVariant),
            for (final r in rows)
              Semantics(
                button: onClub != null,
                label: '${r.position}, ${r.teamName}, ${r.points} points, ${r.played} matchs joués',
                excludeSemantics: true,
                child: InkWell(
                  onTap: onClub == null ? null : () => onClub!(r.teamId),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    color: r.teamId == highlightTeam ? scheme.primaryContainer.withValues(alpha: 0.4) : null,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            '${r.position}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (showCrest) ...[
                          ClubCrest(url: r.logoUrl, name: r.teamName, size: 20),
                          const SizedBox(width: 8),
                        ] else
                          const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            r.teamName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                        for (final (i, v) in _values(r).indexed) cell(v, strong: i == titles.length - 1),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class ProvisionalNote extends StatelessWidget {
  final bool verified;
  const ProvisionalNote({super.key, required this.verified});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: Text(
      verified
          ? 'Classement vérifié.'
          : 'Classement provisoire, calculé à partir des résultats enregistrés. Pas encore homologué par la ligue.',
      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}
