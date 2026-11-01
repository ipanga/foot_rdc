/// Football domain. Screens depend on these types, never on JSON. The server is authoritative: nothing here computes
/// standings or match state.
library;

enum MatchStatus {
  scheduled,
  live,
  halftime,
  finished,
  postponed,
  cancelled,
  abandoned,
  awarded,
  interrupted,
  unknown;

  bool get isLive => this == live || this == halftime;
  bool get isOver => this == finished || this == awarded;
  bool get hasScore => isLive || isOver || this == abandoned || this == interrupted;

  static MatchStatus parse(String? value) =>
      MatchStatus.values.firstWhere((status) => status.name == value, orElse: () => MatchStatus.unknown);
}

enum EventType {
  goal,
  ownGoal,
  penaltyGoal,
  yellowCard,
  redCard,
  substitution,
  var_,
  other;

  bool get isGoal => this == goal || this == ownGoal || this == penaltyGoal;

  static EventType parse(String? value) => switch (value) {
    'goal' => goal,
    'own_goal' => ownGoal,
    'penalty_goal' => penaltyGoal,
    'yellow_card' => yellowCard,
    'red_card' => redCard,
    'substitution' => substitution,
    'var' => var_,
    _ => other,
  };
}

class Competition {
  final int id;
  final String name;
  final String slug;
  final int? currentSeasonId;
  const Competition({required this.id, required this.name, required this.slug, this.currentSeasonId});
}

class Season {
  final int id;
  final String name;
  final String slug;
  final DateTime? start;
  final DateTime? end;
  final bool isCurrent;
  const Season({
    required this.id,
    required this.name,
    required this.slug,
    this.start,
    this.end,
    required this.isCurrent,
  });

  /// `2026-2027` as `2026–2027`.
  String get label => name.replaceAll('-', '–');
}

class Stage {
  final int id;
  final int seasonId;
  final String name;
  final String type;
  final int order;
  const Stage({required this.id, required this.seasonId, required this.name, required this.type, required this.order});
  bool get isPlayoff => type == 'playoff';
}

class Group {
  final int id;
  final int stageId;
  final String name;
  const Group({required this.id, required this.stageId, required this.name});
}

class Club {
  final int id;
  final String name;
  final String shortName;
  final String slug;
  final String? logoUrl;
  final String city;
  const Club({required this.id, required this.name, this.shortName = '', this.slug = '', this.logoUrl, this.city = ''});
}

class ClubProfile {
  final int? founded;
  final String? city;
  final String? stadium;
  final String? website;
  final String? historyHtml;
  final List<String> socials;
  const ClubProfile({this.founded, this.city, this.stadium, this.website, this.historyHtml, this.socials = const []});
}

class DataQuality {
  final String state;
  final String label;
  final bool verified;
  const DataQuality({this.state = 'unverified', this.label = '', this.verified = false});
}

class MatchSide {
  final int teamId;
  final String name;
  final String? logoUrl;
  final int? score;
  const MatchSide({required this.teamId, required this.name, this.logoUrl, this.score});
}

class Match {
  final int id;
  final int seasonId;
  final int stageId;
  final int? groupId;
  final MatchSide home;
  final MatchSide away;
  final DateTime? kickoff;
  final String venue;
  final String round;
  final MatchStatus status;
  final int? minute;
  final String? period;
  final String groupName;
  final String stageName;
  final DataQuality quality;

  const Match({
    required this.id,
    required this.seasonId,
    required this.stageId,
    this.groupId,
    required this.home,
    required this.away,
    this.kickoff,
    this.venue = '',
    this.round = '',
    required this.status,
    this.minute,
    this.period,
    this.groupName = '',
    this.stageName = '',
    this.quality = const DataQuality(),
  });

  bool involves(int teamId) => home.teamId == teamId || away.teamId == teamId;
}

class MatchEvent {
  final int id;
  final EventType type;
  final int? minute;
  final int? extraMinute;
  final int? teamId;
  final String teamName;
  final int? playerId;
  final String? playerName;
  final String? relatedPlayerName;
  final String? detail;
  const MatchEvent({
    required this.id,
    required this.type,
    this.minute,
    this.extraMinute,
    this.teamId,
    this.teamName = '',
    this.playerId,
    this.playerName,
    this.relatedPlayerName,
    this.detail,
  });

  String get clock => minute == null ? '' : "$minute${extraMinute != null && extraMinute! > 0 ? '+$extraMinute' : ''}'";
}

class StandingRow {
  final int teamId;
  final String teamName;
  final String? logoUrl;
  final int stageId;
  final int? groupId;
  final int position;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;
  final DataQuality quality;
  const StandingRow({
    required this.teamId,
    required this.teamName,
    this.logoUrl,
    required this.stageId,
    this.groupId,
    required this.position,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
    this.quality = const DataQuality(),
  });
}

/// One published table of a phase, with rows in the server's order.
class StandingTable {
  final Stage? stage;
  final Group? group;
  final List<StandingRow> rows;
  const StandingTable({this.stage, this.group, required this.rows});
  bool get verified => rows.isNotEmpty && rows.every((row) => row.quality.verified);
}

class SquadMember {
  final int playerId;
  final String name;
  final int? number;
  final String position;
  final String nationality;
  final DateTime? birthDate;
  final String? photoUrl;
  const SquadMember({
    required this.playerId,
    required this.name,
    this.number,
    this.position = '',
    this.nationality = '',
    this.birthDate,
    this.photoUrl,
  });
}

class PlayerMembership {
  final int teamId;
  final String teamName;
  final String? teamLogo;
  final int seasonId;
  final String seasonName;
  final int? number;
  final String position;
  const PlayerMembership({
    required this.teamId,
    required this.teamName,
    this.teamLogo,
    required this.seasonId,
    required this.seasonName,
    this.number,
    this.position = '',
  });
}

class Player {
  final int id;
  final String name;
  final DateTime? birthDate;
  final String nationality;
  final String position;
  final String? photoUrl;
  final List<PlayerMembership> memberships;
  const Player({
    required this.id,
    required this.name,
    this.birthDate,
    this.nationality = '',
    this.position = '',
    this.photoUrl,
    this.memberships = const [],
  });
}

class ClubNewsItem {
  final int id;
  final String title;
  final DateTime? date;
  final String? imageUrl;
  final String link;
  const ClubNewsItem({required this.id, required this.title, this.date, this.imageUrl, this.link = ''});
}

/// A page of a longer list.
class PageResult<T> {
  final List<T> rows;
  final bool hasMore;
  const PageResult(this.rows, {this.hasMore = false});
}

/// Data on screen. [stale] is true when a refresh failed and this is the last saved copy.
class Loaded<T> {
  final T value;
  final bool stale;
  const Loaded(this.value, {this.stale = false});
}
