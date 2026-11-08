import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/notification_provider.dart';
import '../../shared/providers/theme_provider.dart';

import '../football/domain/models.dart';
import '../football/presentation/providers.dart';
import '../football/presentation/screens/clubs_screen.dart';
import '../football/presentation/widgets/football_widgets.dart';
import '../saved_articles/presentation/screens/saved_articles_screen.dart';
import '../search/presentation/screens/search_screen.dart';
import 'settings_screens.dart';

/// Everything that does not need a tab of its own.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followed = ref.watch(favoriteClubsProvider).length;
    final theme = ref.watch(themeCustomNotifierProvider);
    final notifications = ref.watch(notificationNotifierProvider);
    Widget tile(IconData icon, String title, Widget page, {String? subtitle}) => ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _push(context, page),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Plus')),
      body: ListView(
        children: [
          const SectionHeader('Football'),
          tile(Icons.shield_outlined, 'Clubs', const _ClubsPage()),
          tile(
            Icons.star_border,
            'Clubs suivis',
            const _FollowedPage(),
            subtitle: followed == 0 ? null : '$followed club${followed > 1 ? 's' : ''}',
          ),
          const SectionHeader('Articles'),
          tile(Icons.search, 'Recherche', const SearchScreen()),
          tile(Icons.bookmark_border, 'Articles enregistrés', const _SavedPage()),
          const SectionHeader('Application'),
          tile(
            Icons.palette_outlined,
            'Thème',
            const ThemeSettingsScreen(),
            subtitle: switch (theme) {
              ThemeModeCustom.system => 'Automatique',
              ThemeModeCustom.light => 'Clair',
              ThemeModeCustom.dark => 'Sombre',
            },
          ),
          tile(
            Icons.notifications_outlined,
            'Notifications',
            const NotificationSettingsScreen(),
            subtitle: notifications.receiving
                ? 'Activées'
                : notifications.enabled
                ? (notifications.hasPermission ? 'En cours d’activation' : 'Non autorisées par l’appareil')
                : 'Désactivées',
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('À propos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showFootRdcAbout(context),
          ),
        ],
      ),
    );
  }
}

class _SavedPage extends StatelessWidget {
  const _SavedPage();
  @override
  Widget build(BuildContext context) => const SavedArticlesScreen();
}

class _ClubsPage extends ConsumerWidget {
  const _ClubsPage();
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Clubs')),
    body: ref
        .watch(currentSeasonProvider)
        .when(
          loading: () => const ListSkeleton(),
          error: (error, _) => MessageState(icon: Icons.cloud_off_outlined, title: failureMessage(error)),
          data: (season) => ClubsDirectory(season: season),
        ),
  );
}

class _FollowedPage extends ConsumerWidget {
  const _FollowedPage();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(favoriteClubsProvider);
    final season = ref.watch(currentSeasonProvider).valueOrNull;
    void choose() => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const FollowClubsScreen()));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clubs suivis'),
        actions: [
          TextButton(key: const ValueKey('followed-edit'), onPressed: choose, child: const Text('Modifier')),
          const SizedBox(width: 4),
        ],
      ),
      body: ids.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MessageState(
                    icon: Icons.star_border,
                    title: 'Aucun club suivi',
                    detail: 'Choisissez vos clubs pour les retrouver ici et recevoir leurs alertes.',
                  ),
                  FilledButton(onPressed: choose, child: const Text('Choisir mes clubs')),
                ],
              ),
            )
          : season == null
          ? const ListSkeleton()
          : LoadedView<List<Club>>(
              value: ref.watch(clubsProvider(season.id)),
              onRetry: () => ref.invalidate(clubsProvider(season.id)),
              builder: (clubs) {
                final rows = clubs.where((c) => ids.contains(c.id)).toList()..sort((a, b) => a.name.compareTo(b.name));
                final inSeason = {for (final c in clubs) c.id};
                // Followed clubs outside this season (relegated, or a changed list) stay followed and listed.
                final elsewhere = ids.where((id) => !inSeason.contains(id)).toList()..sort();
                return ListView(
                  children: [
                    for (final club in rows) ClubTile(club: club),
                    for (final id in elsewhere) _FollowedElsewhere(id: id),
                  ],
                );
              },
            ),
    );
  }
}

class _FollowedElsewhere extends ConsumerWidget {
  final int id;
  const _FollowedElsewhere({required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final club = ref.watch(clubProvider(id)).valueOrNull?.value ?? Club(id: id, name: 'Club n° $id');
    return ClubTile(club: club, subtitle: 'Hors de la saison en cours');
  }
}
