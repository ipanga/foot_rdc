import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/navigation/deep_link_handler.dart';
import '../../core/notifications/push.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/providers/notification_provider.dart';
import '../football/presentation/providers.dart';
import '../football/presentation/widgets/club_picker.dart';

/// Optional favourite-club selection, offered once to users who follow no club (fresh install or upgrade).
/// Never blocks the app: « Plus tard », back and closing all lead to Home, and the offer is not repeated.
class ClubOnboarding {
  /// `followed` (already followed clubs when checked), `done` (Continuer) or `later` (Plus tard, back, close).
  static const stateKey = 'rdcf_club_onboarding';

  /// Whether to offer the selection: only before any answer, and only to users without followed clubs.
  static bool shouldOffer({required String? state, required Set<int> followed}) => state == null && followed.isEmpty;

  /// The initial position of the « Alertes de match » switch: on, unless the user turned notifications or match
  /// alerts off earlier (never re-enabled silently).
  static bool alertsDefault(NotificationState notifications, {required bool explicitMatchAlertsOff}) =>
      notifications.prefs.enabled && !explicitMatchAlertsOff;
}

/// Checks once after launch whether to offer the club selection, then shows it over Home.
class ClubOnboardingGate extends ConsumerStatefulWidget {
  final Widget child;

  /// Time allowed to load the season's clubs; without them the offer waits for a later launch.
  final Duration loadLimit;
  const ClubOnboardingGate({super.key, required this.child, this.loadLimit = const Duration(seconds: 10)});

  @override
  ConsumerState<ClubOnboardingGate> createState() => _ClubOnboardingGateState();
}

class _ClubOnboardingGateState extends ConsumerState<ClubOnboardingGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_maybeOffer()));
  }

  void _log(String reason) => debugPrint('club-onboarding: $reason');

  Future<void> _maybeOffer() async {
    final store = await SharedPreferences.getInstance();
    final answered = store.getString(ClubOnboarding.stateKey);
    if (answered != null) return _log('already answered ($answered)');
    await ref.read(favoriteClubsProvider.notifier).ready;
    if (!mounted) return;
    if (ref.read(favoriteClubsProvider).isNotEmpty) {
      await store.setString(ClubOnboarding.stateKey, 'followed');
      return _log('clubs already followed');
    }
    // The current season's clubs, from the API or its cache. Offline or failing: ask at a later launch instead
    // of opening on an error.
    try {
      final repo = await ref.read(footballRepositoryProvider.future);
      final seasons = await repo.seasons().timeout(widget.loadLimit);
      if (seasons.isEmpty) return _log('no season');
      final current = seasons.firstWhere((s) => s.isCurrent, orElse: () => seasons.first);
      if ((await repo.clubs(current.id).timeout(widget.loadLimit)).isEmpty) return _log('no clubs');
    } catch (error) {
      return _log('clubs unavailable ($error), next launch');
    }
    final navigator = appNavigatorKey.currentState;
    // Another screen is open (a notification or a link opened the app): offer it at a later launch.
    if (!mounted || navigator == null || navigator.canPop()) return _log('another screen is open, next launch');
    _log('offered');
    final continued = await navigator.push<bool>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const ClubOnboardingScreen()),
    );
    await store.setString(ClubOnboarding.stateKey, continued == true ? 'done' : 'later');
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// « Suivez vos clubs »: the season's clubs with crests, search, several choices, « Continuer » and « Plus tard ».
class ClubOnboardingScreen extends ConsumerStatefulWidget {
  const ClubOnboardingScreen({super.key});
  @override
  ConsumerState<ClubOnboardingScreen> createState() => _ClubOnboardingScreenState();
}

class _ClubOnboardingScreenState extends ConsumerState<ClubOnboardingScreen> {
  late Set<int> _selected = {...ref.read(favoriteClubsProvider)};
  bool? _alerts;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initAlerts());
  }

  Future<void> _initAlerts() async {
    final store = await SharedPreferences.getInstance();
    await ref.read(notificationNotifierProvider.notifier).ready;
    if (!mounted) return;
    final state = ref.read(notificationNotifierProvider);
    final explicit = store.getStringList(PushStore.explicitKey);
    // Before explicit choices were tracked (5.12.11 (34)), a stored « off » counts as the user's choice.
    final chosen = explicit == null ? store.getString(PushStore.prefsKey) != null : explicit.contains('match_alerts');
    final value = ClubOnboarding.alertsDefault(state, explicitMatchAlertsOff: !state.prefs.matchAlerts && chosen);
    setState(() => _alerts ??= value);
  }

  Future<void> _continue() async {
    setState(() => _saving = true);
    await ref.read(favoriteClubsProvider.notifier).setAll(_selected);
    PushPermission? permission;
    if (_alerts == true) permission = await ref.read(notificationNotifierProvider.notifier).enableClubAlerts();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    Navigator.of(context).pop(true);
    if (permission == PushPermission.denied) {
      messenger?.showSnackBar(
        SnackBar(
          content: const Text('Les notifications de FootRDC sont refusées par l’appareil.'),
          action: SnackBarAction(
            label: 'Autoriser',
            onPressed: () => ref.read(notificationNotifierProvider.notifier).allowOrOpenSettings(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final count = _selected.length;
    return Scaffold(
      // Closing (×) or going back counts as « Plus tard ».
      appBar: AppBar(title: const Text('Vos clubs')),
      body: ClubPicker(
        selected: _selected,
        onToggle: (id) =>
            setState(() => _selected = _selected.contains(id) ? ({..._selected}..remove(id)) : {..._selected, id}),
        padding: const EdgeInsets.only(bottom: 16),
        header: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Suivez vos clubs',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choisissez les clubs de Linafoot que vous aimez. Vous pourrez recevoir les alertes de leurs '
                  'matchs et modifier ce choix à tout moment dans Plus › Clubs suivis.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Material(
        color: theme.scaffoldBackgroundColor,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: scheme.outlineVariant, width: 0.5)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    key: const ValueKey('onboarding-alerts'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Alertes de match'),
                    subtitle: const Text('Coup d’envoi, résultat final, report ou annulation'),
                    value: _alerts ?? false,
                    onChanged: _alerts == null || _saving ? null : (v) => setState(() => _alerts = v),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      TextButton(
                        key: const ValueKey('onboarding-later'),
                        onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(minimumSize: const Size(96, 48)),
                        child: const Text('Plus tard'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          key: const ValueKey('onboarding-continue'),
                          onPressed: count == 0 || _saving ? null : _continue,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            // The one strong action of the screen: solid FootRDC red (4.5:1 with white).
                            backgroundColor: AppColors.brandPrimaryDark,
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          child: Text(
                            count == 0 ? 'Continuer' : 'Continuer ($count)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
