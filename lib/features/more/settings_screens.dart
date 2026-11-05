import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/football/presentation/widgets/club_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/notifications/push.dart';
import '../../shared/providers/notification_provider.dart';
import '../../shared/providers/theme_provider.dart';
import '../football/presentation/providers.dart';
import '../football/presentation/widgets/football_widgets.dart';

/// Plus › Thème: automatic (follows the device), light or dark. Saved on the device.
class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  static const _options = [
    (
      ThemeModeCustom.system,
      Icons.brightness_auto_outlined,
      'Automatique',
      'Suit le mode clair ou sombre de l’appareil',
    ),
    (ThemeModeCustom.light, Icons.light_mode_outlined, 'Clair', null),
    (ThemeModeCustom.dark, Icons.dark_mode_outlined, 'Sombre', null),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeCustomNotifierProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Thème')),
      body: ListView(
        children: [
          const SectionHeader('Apparence'),
          for (final (mode, icon, label, detail) in _options)
            ListTile(
              key: ValueKey('theme-${mode.name}'),
              leading: Icon(icon),
              title: Text(label),
              subtitle: detail == null ? null : Text(detail),
              selected: current == mode,
              selectedColor: scheme.primary,
              trailing: current == mode ? Icon(Icons.check, color: scheme.primary) : null,
              onTap: () => ref.read(themeCustomNotifierProvider.notifier).setTheme(mode),
            ),
        ],
      ),
    );
  }
}

/// Plus › Notifications: Actualités, Matchs Linafoot and Général. The device permission and the app's choices are
/// shown apart; choices are saved on the device at once and sent to the FootRDC server.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});
  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Back from the system settings: show the permission as it is now.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.read(notificationNotifierProvider.notifier).refresh();
  }

  static String _hm(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

  Future<int?> _pickTime(int initial) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
      helpText: 'Choisir l’heure',
      builder: (context, child) =>
          MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    return t == null ? null : t.hour * 60 + t.minute;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationNotifierProvider);
    final notifier = ref.read(notificationNotifierProvider.notifier);
    final followed = ref.watch(favoriteClubsProvider);
    final p = state.prefs;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    void set(NotificationPrefs next) => notifier.setPrefs(next);

    final (IconData icon, Color color, String status) = switch (state) {
      _ when !state.enabled => (
        Icons.notifications_off_outlined,
        scheme.onSurfaceVariant,
        'Toutes les notifications FootRDC sont désactivées.',
      ),
      _ when state.blockedByDevice => (
        Icons.block,
        scheme.error,
        'Non autorisées par l’appareil. Autorisez FootRDC pour les recevoir.',
      ),
      _ when state.permission == PushPermission.notDetermined => (
        Icons.notifications_none,
        scheme.onSurfaceVariant,
        'Autorisez les notifications pour recevoir vos alertes.',
      ),
      _ => (Icons.notifications_active_outlined, scheme.primary, 'Activées sur cet appareil.'),
    };
    final permissionLabel = switch (state.permission) {
      PushPermission.granted => 'Accordée',
      PushPermission.denied => 'Refusée',
      PushPermission.notDetermined => 'Pas encore demandée',
    };
    final matchOn = p.enabled && p.matchAlerts;
    Widget type(String key, String title, String subtitle, bool value, NotificationPrefs Function(bool) change) =>
        SwitchListTile(
          key: ValueKey('notif-$key'),
          title: Text(title),
          subtitle: Text(subtitle),
          value: value,
          onChanged: matchOn ? (v) => set(change(v)) : null,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Semantics(
              liveRegion: true,
              child: Container(
                key: const ValueKey('notif-status'),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, color: color, size: 22),
                        const SizedBox(width: 12),
                        Expanded(child: Text(status, style: theme.textTheme.bodyMedium)),
                      ],
                    ),
                    if (state.enabled && state.permission == PushPermission.notDetermined)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: FilledButton(
                          onPressed: notifier.requestPermission,
                          child: const Text('Autoriser les notifications'),
                        ),
                      ),
                    if (state.blockedByDevice)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.notifications_active_outlined),
                          label: const Text('Autoriser les notifications'),
                          onPressed: notifier.allowOrOpenSettings,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SectionHeader('Actualités'),
          SwitchListTile(
            key: const ValueKey('notif-news'),
            secondary: const Icon(Icons.article_outlined),
            title: const Text('Articles à la Une'),
            subtitle: const Text('Une notification quand un article « À la Une » est publié'),
            value: p.news,
            onChanged: p.enabled ? (v) => set(p.copyWith(news: v)) : null,
          ),
          const SectionHeader('Matchs Linafoot'),
          SwitchListTile(
            key: const ValueKey('notif-match'),
            secondary: const Icon(Icons.sports_soccer),
            title: const Text('Alertes de mes clubs'),
            subtitle: const Text('Uniquement pour les clubs que vous suivez'),
            value: p.matchAlerts,
            onChanged: p.enabled ? (v) => set(p.copyWith(matchAlerts: v)) : null,
          ),
          ListTile(
            key: const ValueKey('notif-clubs'),
            leading: const Icon(Icons.star_border),
            title: const Text('Clubs suivis'),
            subtitle: Text(
              followed.isEmpty
                  ? 'Aucun club suivi : choisissez au moins un club'
                  : '${followed.length} club${followed.length > 1 ? 's' : ''}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const FollowClubsScreen())),
          ),
          type('result', 'Résultats finaux', 'Le score final confirmé', p.result, (v) => p.copyWith(result: v)),
          type(
            'changes',
            'Changements de match',
            'Report, annulation ou nouvel horaire',
            p.changes,
            (v) => p.copyWith(changes: v),
          ),
          type(
            'prematch',
            'Rappel avant le match',
            'Une heure avant le coup d’envoi',
            p.prematch,
            (v) => p.copyWith(prematch: v),
          ),
          type('kickoff', 'Coup d’envoi', 'Quand le match commence', p.kickoff, (v) => p.copyWith(kickoff: v)),
          type('goals', 'Buts', 'Selon la disponibilité des données en direct', p.goals, (v) => p.copyWith(goals: v)),
          const SectionHeader('Général'),
          SwitchListTile(
            key: const ValueKey('notif-all'),
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications FootRDC'),
            subtitle: const Text('Activer ou désactiver toutes les notifications'),
            value: p.enabled,
            onChanged: notifier.setEnabled,
          ),
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('Autorisation de l’appareil'),
            subtitle: Text(permissionLabel),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: notifier.openDeviceSettings,
          ),
          SwitchListTile(
            key: const ValueKey('notif-quiet'),
            secondary: const Icon(Icons.bedtime_outlined),
            title: const Text('Heures calmes'),
            subtitle: Text(
              p.quietHours
                  ? 'De ${_hm(p.quietStart!)} à ${_hm(p.quietEnd!)} : aucune notification'
                  : 'Aucune notification pendant la nuit',
            ),
            value: p.quietHours,
            onChanged: p.enabled
                ? (v) => set(p.copyWith(quietStart: () => v ? 22 * 60 : null, quietEnd: () => v ? 7 * 60 : null))
                : null,
          ),
          if (p.quietHours) ...[
            ListTile(
              key: const ValueKey('notif-quiet-start'),
              contentPadding: const EdgeInsets.only(left: 72, right: 16),
              title: const Text('Début'),
              trailing: Text(_hm(p.quietStart!), style: theme.textTheme.titleMedium),
              onTap: () async {
                final m = await _pickTime(p.quietStart!);
                if (m != null) set(p.copyWith(quietStart: () => m));
              },
            ),
            ListTile(
              key: const ValueKey('notif-quiet-end'),
              contentPadding: const EdgeInsets.only(left: 72, right: 16),
              title: const Text('Fin'),
              trailing: Text(_hm(p.quietEnd!), style: theme.textTheme.titleMedium),
              onTap: () async {
                final m = await _pickTime(p.quietEnd!);
                if (m != null) set(p.copyWith(quietEnd: () => m));
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.volume_up_outlined),
            title: const Text('Son et vibration'),
            subtitle: const Text('Réglés par le système, pour chaque type de notification'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: notifier.openDeviceSettings,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              [
                if (state.syncFailed)
                  'Hors ligne : vos choix sont enregistrés sur l’appareil et seront envoyés à la reconnexion.',
                if (state.code != null) 'Code de l’appareil : ${state.code}',
              ].join('\n'),
              key: const ValueKey('notif-diagnostic'),
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// Choose the followed clubs (the same list as the star on a club page and Plus › Clubs suivis). Changes apply at once.
class FollowClubsScreen extends ConsumerWidget {
  const FollowClubsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followed = ref.watch(favoriteClubsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Clubs suivis')),
      body: ClubPicker(
        selected: followed,
        onToggle: (id) => ref.read(favoriteClubsProvider.notifier).toggle(id),
        padding: const EdgeInsets.only(bottom: 24),
      ),
    );
  }
}

/// Plus › À propos.
void showFootRdcAbout(BuildContext context) => showAboutDialog(
  context: context,
  applicationName: 'FootRDC',
  applicationIcon: Image.asset('assets/images/logo_splash_footrdc.png', width: 48, height: 48),
  applicationLegalese: '© ${DateTime.now().year} FOOTRDC.COM',
  children: [
    const SizedBox(height: 16),
    const Text('L’actualité du football congolais : articles, matchs, classements et clubs.'),
    const SizedBox(height: 8),
    TextButton(
      style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
      onPressed: () => launchUrl(Uri.parse('https://footrdc.com/'), mode: LaunchMode.externalApplication),
      child: const Text('footrdc.com'),
    ),
  ],
);
