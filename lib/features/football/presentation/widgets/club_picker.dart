import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models.dart';
import '../providers.dart';
import 'football_widgets.dart';

/// Lower-case, without French accents, for searching club names.
String foldClubName(String text) => text
    .toLowerCase()
    .replaceAll(RegExp('[éèêë]'), 'e')
    .replaceAll(RegExp('[àâä]'), 'a')
    .replaceAll(RegExp('[ôö]'), 'o')
    .replaceAll(RegExp('[îï]'), 'i')
    .replaceAll(RegExp('[ûüù]'), 'u')
    .replaceAll('ç', 'c');

/// The clubs of the current Linafoot season, searchable, with a check mark on the [selected] ones. Followed clubs
/// that are not in this season (relegated, or a list that changed) stay listed below, so they can still be removed.
/// Used by the first-launch club selection and by Plus › Notifications › Clubs suivis.
class ClubPicker extends ConsumerStatefulWidget {
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  /// Shown above the search field, scrolling with the list.
  final List<Widget> header;
  final EdgeInsets padding;
  const ClubPicker({
    super.key,
    required this.selected,
    required this.onToggle,
    this.header = const [],
    this.padding = EdgeInsets.zero,
  });

  @override
  ConsumerState<ClubPicker> createState() => _ClubPickerState();
}

class _ClubPickerState extends ConsumerState<ClubPicker> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final season = ref.watch(currentSeasonProvider);
    void retry() {
      ref.invalidate(seasonsProvider);
      ref.read(footballRefreshProvider.notifier).state++;
    }

    Widget list(List<Widget> rows) => ListView(padding: widget.padding, children: [...widget.header, ...rows]);
    Widget failed(Object? error) =>
        list([MessageState(icon: Icons.cloud_off_outlined, title: failureMessage(error), onRetry: retry)]);

    return season.when(
      loading: () => list([const SizedBox(height: 8), const LinearProgressIndicator(minHeight: 2)]),
      error: (error, _) => failed(error),
      data: (s) {
        final clubs = ref.watch(clubsProvider(s.id));
        if (clubs.hasError && !clubs.hasValue) return failed(clubs.error);
        if (!clubs.hasValue) return list([const SizedBox(height: 8), const LinearProgressIndicator(minHeight: 2)]);
        final loaded = clubs.requireValue;
        final all = [...loaded.value]..sort((a, b) => a.name.compareTo(b.name));
        final key = foldClubName(_query.trim());
        final rows = key.isEmpty ? all : all.where((c) => foldClubName(c.name).contains(key)).toList();
        final inSeason = {for (final c in all) c.id};
        final elsewhere = widget.selected.where((id) => !inSeason.contains(id)).toList()..sort();
        return list([
          if (loaded.stale) const StaleNotice(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              key: const ValueKey('club-search'),
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                isDense: true,
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher un club',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Aucun club ne correspond à « ${_query.trim()} ».', textAlign: TextAlign.center),
            ),
          for (final club in rows)
            ClubChoiceTile(
              key: ValueKey('pick-${club.id}'),
              club: club,
              selected: widget.selected.contains(club.id),
              onTap: () => widget.onToggle(club.id),
            ),
          if (elsewhere.isNotEmpty && key.isEmpty) ...[
            const SectionHeader('Autres clubs suivis'),
            for (final id in elsewhere)
              _ElsewhereTile(key: ValueKey('pick-$id'), id: id, onTap: () => widget.onToggle(id)),
          ],
        ]);
      },
    );
  }
}

/// One club with its crest and a round check mark, announced as a checkbox.
class ClubChoiceTile extends StatelessWidget {
  final Club club;
  final bool selected;
  final VoidCallback onTap;
  final String? subtitle;
  const ClubChoiceTile({super.key, required this.club, required this.selected, required this.onTap, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.brandPrimaryLight : AppColors.brandPrimaryDark;
    return Semantics(
      checked: selected,
      button: true,
      label: club.name,
      excludeSemantics: true,
      onTap: onTap,
      child: ListTile(
        onTap: onTap,
        minVerticalPadding: 10,
        leading: ClubCrest(url: club.logoUrl, name: club.name, size: 36),
        title: Text(
          club.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
        ),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: Icon(
            selected ? Icons.check_circle : Icons.radio_button_unchecked,
            key: ValueKey(selected),
            color: selected ? accent : theme.colorScheme.outline,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class _ElsewhereTile extends ConsumerWidget {
  final int id;
  final VoidCallback onTap;
  const _ElsewhereTile({super.key, required this.id, required this.onTap});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final club = ref.watch(clubProvider(id)).valueOrNull?.value ?? Club(id: id, name: 'Club n° $id');
    return ClubChoiceTile(club: club, selected: true, onTap: onTap, subtitle: 'Hors de la saison en cours');
  }
}
