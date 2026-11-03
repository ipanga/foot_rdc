import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/dio_client.dart';
import '../../home/presentation/app_tabs.dart';
import '../data/football_client.dart';
import '../data/football_repository.dart';
import '../domain/models.dart';

final footballRepositoryProvider = FutureProvider<FootballRepository>((ref) async {
  final http = DioClient(baseUrl: FootballClient.baseUrl, logResponses: false);
  ref.onDispose(() => http.dio.close(force: true));
  return FootballRepository(FootballClient(http, PreferencesFootballCache(await SharedPreferences.getInstance())));
});

/// Tabs stay alive, so this is what refreshes them: raised when the reader returns to a football tab or the app.
/// Data still within its cache lifetime makes no request.
final footballRefreshProvider = StateProvider<int>((ref) => 0);

Stream<Loaded<T>> _swr<T>(Ref ref, Future<T> Function(FootballRepository repo, CachePolicy policy) load) async* {
  ref.watch(footballRefreshProvider);
  final repo = await ref.watch(footballRepositoryProvider.future);
  yield* staleWhileRevalidate((policy) => load(repo, policy));
}

final seasonsProvider = StreamProvider<Loaded<List<Season>>>((ref) => _swr(ref, (r, p) => r.seasons(policy: p)));

/// The season chosen in Matchs or Classement; null means the API's current season.
final selectedSeasonIdProvider = StateProvider<int?>((ref) => null);

final currentSeasonProvider = Provider<AsyncValue<Season>>(
  (ref) => ref.watch(seasonsProvider).whenData((loaded) {
    final rows = loaded.value;
    if (rows.isEmpty) throw const FootballFailure(FootballError.notFound);
    return rows.firstWhere((s) => s.isCurrent, orElse: () => rows.first);
  }),
);

/// Everything in the hub derives from this one value, so a screen cannot mix two seasons.
final activeSeasonProvider = Provider<AsyncValue<Season>>((ref) {
  final selected = ref.watch(selectedSeasonIdProvider);
  final current = ref.watch(currentSeasonProvider);
  if (selected == null) return current;
  return ref
      .watch(seasonsProvider)
      .whenData((loaded) => loaded.value.firstWhere((s) => s.id == selected, orElse: () => current.requireValue));
});

final standingsProvider = StreamProvider.autoDispose.family<Loaded<List<StandingTable>>, int>(
  (ref, season) => _swr(ref, (r, p) => r.standings(season, policy: p)),
);
final clubsProvider = StreamProvider.autoDispose.family<Loaded<List<Club>>, int>(
  (ref, season) => _swr(ref, (r, p) => r.clubs(season, policy: p)),
);
final stagesProvider = StreamProvider.autoDispose.family<Loaded<List<Stage>>, int>(
  (ref, season) => _swr(ref, (r, p) => r.stages(season, policy: p)),
);
final groupsProvider = StreamProvider.autoDispose.family<Loaded<List<Group>>, int>(
  (ref, season) => _swr(ref, (r, p) => r.groups(season, policy: p)),
);

/// (window name, season, limit): a short list such as today or the latest results.
final matchWindowProvider = StreamProvider.autoDispose.family<Loaded<List<Match>>, (String, int, int)>(
  (ref, key) => _swr(ref, (r, p) async => (await r.window(key.$1, key.$2, limit: key.$3, policy: p)).rows),
);
final clubProvider = StreamProvider.autoDispose.family<Loaded<Club>, int>(
  (ref, id) => _swr(ref, (r, p) => r.club(id, policy: p)),
);
final clubProfileProvider = StreamProvider.autoDispose.family<Loaded<ClubProfile?>, int>(
  (ref, id) => _swr(ref, (r, p) => r.clubProfile(id, policy: p)),
);

/// One page of a club's linked articles: (club id, page).
final clubNewsProvider = StreamProvider.autoDispose.family<Loaded<List<ClubNewsItem>>, (int, int)>(
  (ref, key) => _swr(ref, (r, p) => r.clubNews(key.$1, page: key.$2, policy: p)),
);
final clubMatchesProvider = StreamProvider.autoDispose.family<Loaded<List<Match>>, (int, int, String)>(
  (ref, key) => _swr(ref, (r, p) async => (await r.clubMatches(key.$1, key.$2, key.$3, policy: p)).rows),
);
final squadProvider = StreamProvider.autoDispose.family<Loaded<List<SquadMember>>, (int, int)>(
  (ref, key) => _swr(ref, (r, p) => r.squad(key.$1, key.$2, policy: p)),
);
final playerProvider = StreamProvider.autoDispose.family<Loaded<Player>, int>(
  (ref, id) => _swr(ref, (r, p) => r.player(id, policy: p)),
);

/// App lifecycle, kept current by [FootballLifecycle]; polling only runs in the foreground.
final appForegroundProvider = StateProvider<bool>((ref) => true);

class FootballLifecycle extends ConsumerStatefulWidget {
  final Widget child;
  const FootballLifecycle({super.key, required this.child});
  @override
  ConsumerState<FootballLifecycle> createState() => _FootballLifecycleState();
}

class _FootballLifecycleState extends ConsumerState<FootballLifecycle> with WidgetsBindingObserver {
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(appForegroundProvider.notifier).state = state == AppLifecycleState.resumed;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class MatchDetail {
  final Match match;
  final List<MatchEvent> events;
  const MatchDetail(this.match, this.events);
}

/// Override in tests to run the polling loop quickly.
final livePollIntervalProvider = Provider<Duration>((ref) => const Duration(seconds: 30));

/// The match on screen. While the server says it is live it refreshes; it stops when the match ends or the screen
/// closes, and waits while the app is in the background.
final matchDetailProvider = StreamProvider.autoDispose.family<Loaded<MatchDetail>, int>((ref, id) async* {
  var closed = false;
  ref.onDispose(() => closed = true);
  final repo = await ref.watch(footballRepositoryProvider.future);
  final interval = ref.watch(livePollIntervalProvider);
  late Loaded<MatchDetail> current;
  await for (final state in _loadDetail(repo, id)) {
    current = state;
    yield state;
  }
  while (current.value.match.status.isLive) {
    await Future<void>.delayed(interval);
    if (closed) return;
    if (!ref.read(appForegroundProvider)) continue;
    try {
      current = Loaded(MatchDetail(await repo.match(id, live: true), await repo.events(id, live: true)));
    } on FootballFailure {
      current = Loaded(current.value, stale: true);
    }
    yield current;
  }
});

Stream<Loaded<MatchDetail>> _loadDetail(FootballRepository repo, int id) => staleWhileRevalidate(
  (policy) async => MatchDetail(await repo.match(id, policy: policy), await repo.events(id, policy: policy)),
);

/// Live matches of a season: polls only while a match is live and the screen is open.
final liveMatchesProvider = StreamProvider.autoDispose.family<List<Match>, int>((ref, season) async* {
  var closed = false;
  ref.onDispose(() => closed = true);
  ref.watch(footballRefreshProvider);
  final repo = await ref.watch(footballRepositoryProvider.future);
  final interval = ref.watch(livePollIntervalProvider);
  while (!closed) {
    if (ref.read(appForegroundProvider) && ref.read(currentTabProvider).showsLiveScores) {
      List<Match> rows;
      try {
        rows = (await repo.window('live', season)).rows;
      } on FootballFailure {
        rows = const [];
      }
      if (closed) return;
      yield rows;
      if (rows.isEmpty) return;
    }
    await Future<void>.delayed(interval);
  }
});

/// Followed clubs, kept on the device.
class FavoriteClubs extends StateNotifier<Set<int>> {
  static const _key = 'rdcf_favorite_clubs';
  FavoriteClubs() : super(const {}) {
    SharedPreferences.getInstance().then((p) {
      if (mounted) state = (p.getStringList(_key) ?? const []).map(int.tryParse).whereType<int>().toSet();
    });
  }
  Future<void> toggle(int id) async {
    state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state.map((e) => '$e').toList());
  }
}

final favoriteClubsProvider = StateNotifierProvider<FavoriteClubs, Set<int>>((ref) => FavoriteClubs());
