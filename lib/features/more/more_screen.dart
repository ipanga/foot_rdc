import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/notification_provider.dart';
import '../../shared/providers/theme_provider.dart';

import '../editorial/presentation/providers/editorial_providers.dart';
import '../editorial/presentation/screens/editorial_list_screen.dart';
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
          tile(Icons.lightbulb_outline, 'Bon à savoir', EditorialListScreen(channel: EditorialChannel.bonASavoir)),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Clubs suivis')),
      body: season == null
          ? const ListSkeleton()
          : LoadedView<List<Club>>(
              value: ref.watch(clubsProvider(season.id)),
              builder: (clubs) {
                final rows = clubs.where((c) => ids.contains(c.id)).toList();
                if (rows.isEmpty) {
                  return const MessageState(
                    icon: Icons.star_border,
                    title: 'Aucun club suivi',
                    detail: 'Touchez l’étoile sur la page d’un club pour le retrouver ici.',
                  );
                }
                return ListView(children: [for (final club in rows) ClubTile(club: club)]);
              },
            ),
    );
  }
}
