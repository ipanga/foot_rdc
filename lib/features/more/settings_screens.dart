import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/providers/notification_provider.dart';
import '../../shared/providers/theme_provider.dart';
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

/// Plus › Notifications: the app preference and the device permission, shown separately.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});
  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> with WidgetsBindingObserver {
  bool _busy = false;

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

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationNotifierProvider);
    final notifier = ref.read(notificationNotifierProvider.notifier);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (IconData icon, Color color, String status) = switch (state) {
      _ when !state.enabled => (
        Icons.notifications_off_outlined,
        scheme.onSurfaceVariant,
        'Désactivées dans FootRDC. Vous ne recevrez pas de notifications.',
      ),
      _ when state.blockedByDevice => (
        Icons.block,
        scheme.error,
        'Non autorisées par l’appareil. Autorisez FootRDC dans les réglages de l’appareil pour les recevoir.',
      ),
      _ when state.receiving => (
        Icons.notifications_active_outlined,
        scheme.primary,
        'Activées. Vous recevrez les notifications FootRDC sur cet appareil.',
      ),
      _ => (
        Icons.hourglass_empty,
        scheme.onSurfaceVariant,
        'Autorisées par l’appareil. L’inscription aux notifications est en cours.',
      ),
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          SwitchListTile(
            key: const ValueKey('notifications-switch'),
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications FootRDC'),
            subtitle: const Text('Actualités et informations envoyées par la rédaction'),
            value: state.enabled,
            onChanged: _busy ? null : (value) => _run(() => notifier.setEnabled(value)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: color, size: 22),
                    const SizedBox(width: 12),
                    Expanded(child: Text(status, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
            ),
          ),
          if (state.blockedByDevice)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Ouvrir les réglages de l’appareil'),
                onPressed: _busy ? null : () => _run(notifier.openDeviceSettings),
              ),
            ),
          const SectionHeader('Détail'),
          ListTile(
            dense: true,
            title: const Text('Préférence FootRDC'),
            trailing: Text(state.enabled ? 'Activée' : 'Désactivée'),
          ),
          ListTile(
            dense: true,
            title: const Text('Autorisation de l’appareil'),
            trailing: Text(state.hasPermission ? 'Accordée' : 'Non accordée'),
          ),
        ],
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
