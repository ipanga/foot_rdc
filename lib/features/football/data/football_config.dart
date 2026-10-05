import '../domain/football_models.dart';

class FootballConfig {
  final Uri origin;
  final int competitionId;
  final int seasonId;
  final String environment;
  final FootballLiveGate live;
  FootballConfig({
    required this.origin,
    required this.competitionId,
    required this.seasonId,
    this.environment = 'staging',
    this.live = const FootballLiveGate(),
  }) {
    if (origin.userInfo.isNotEmpty ||
        origin.query.isNotEmpty ||
        origin.fragment.isNotEmpty ||
        (origin.path != '' && origin.path != '/') ||
        competitionId <= 0 ||
        seasonId <= 0 ||
        !['staging', 'development', 'production'].contains(environment)) {
      throw ArgumentError('Invalid Core configuration');
    }
    final local = [
      'localhost',
      '127.0.0.1',
      'sportrdc-dev.local',
    ].contains(origin.host);
    final approved =
        origin.host == 'staging.sportrdc.com' ||
        origin.host == 'sportrdc.com' ||
        origin.host == 'footrdc.com';
    if ((!approved && !local) ||
        (origin.scheme != 'https' &&
            !(environment == 'development' &&
                local &&
                origin.scheme == 'http'))) {
      throw ArgumentError('Only approved Core origins are allowed');
    }
    if (environment == 'production' &&
        (local || origin.host == 'staging.sportrdc.com')) {
      throw ArgumentError('Staging cannot be production');
    }
  }
  String get baseUrl =>
      '${origin.toString().replaceFirst(RegExp(r'/$'), '')}/wp-json/rdcfootball/v1';
  static FootballConfig? fromEnvironment() {
    const env = String.fromEnvironment('RDCF_ENV', defaultValue: 'off');
    if (env == 'off') return null;
    const origin = String.fromEnvironment('RDCF_API_ORIGIN');
    const competition = int.fromEnvironment(
      'RDCF_COMPETITION_ID',
      defaultValue: 1,
    );
    const season = int.fromEnvironment('RDCF_SEASON_ID', defaultValue: 1);
    if (origin.isEmpty && env != 'staging') {
      throw ArgumentError('Explicit Core origin required outside staging');
    }
    return FootballConfig(
      origin: Uri.parse(
        origin.isEmpty ? 'https://staging.sportrdc.com' : origin,
      ),
      competitionId: competition,
      seasonId: season,
      environment: env,
    );
    // Phase6 never accepts readiness from a build flag: genuine live evidence is pending.
  }
}
