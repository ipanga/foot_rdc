import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/dio_client.dart';
import '../data/football_api.dart';
import '../data/football_config.dart';
import '../data/football_repository.dart';
import '../domain/football_models.dart';

final footballConfigProvider = Provider<FootballConfig?>(
  (ref) => FootballConfig.fromEnvironment(),
);
final footballRepositoryProvider = FutureProvider<FootballRepository>((
  ref,
) async {
  final config = ref.watch(footballConfigProvider);
  if (config == null) throw const FootballFailure('unavailable');
  final client = DioClient(baseUrl: config.baseUrl, logResponses: false);
  ref.onDispose(() => client.dio.close(force: true));
  return FootballRepository(
    RdcFootballApiClient(
      config,
      client,
      PreferencesFootballCache(await SharedPreferences.getInstance()),
    ),
  );
});
final footballContextProvider = FutureProvider<FootballContext>(
  (ref) async => (await ref.watch(footballRepositoryProvider.future)).context(),
);
final footballDirectoryProvider = FutureProvider<FootballPage>(
  (ref) async =>
      (await ref.watch(footballRepositoryProvider.future)).directory(),
);
final footballSingleProvider = FutureProvider.autoDispose
    .family<FootballRecord?, FootballQuery>(
      (ref, query) async =>
          (await ref.watch(footballRepositoryProvider.future)).single(query),
    );
