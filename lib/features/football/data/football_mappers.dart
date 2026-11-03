import '../domain/models.dart';

/// JSON to domain. Tolerant by design: optional fields may be missing or malformed; a row without its identity is
/// skipped by [mapRows] instead of failing a whole screen.
int? _int(dynamic value) => value is int ? value : (value is num ? value.toInt() : int.tryParse('${value ?? ''}'));
String _text(dynamic value) => value is String ? value.trim() : (value is num ? '$value' : '');
String? _optional(dynamic value) {
  final text = _text(value);
  return text.isEmpty ? null : text;
}

DateTime? _date(dynamic value) => value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;
Map<String, dynamic> _map(dynamic value) => value is Map ? Map<String, dynamic>.from(value) : const {};
int _required(dynamic value) {
  final id = _int(value);
  if (id == null || id <= 0) throw const FormatException('Missing identity');
  return id;
}

/// Maps a list, dropping rows that cannot be identified.
List<T> mapRows<T>(dynamic rows, T Function(Map<String, dynamic>) map) {
  if (rows is! List) throw const FormatException('Expected a list');
  final out = <T>[];
  for (final row in rows) {
    try {
      if (row is Map) out.add(map(Map<String, dynamic>.from(row)));
    } on FormatException {
      continue;
    } on TypeError {
      continue;
    }
  }
  return out;
}

Competition competitionFrom(Map<String, dynamic> j) => Competition(
  id: _required(j['id']),
  name: _text(j['name']),
  slug: _text(j['slug']),
  currentSeasonId: _int(j['current_season_id']),
);

Season seasonFrom(Map<String, dynamic> j) => Season(
  id: _required(j['id']),
  name: _text(j['name']),
  slug: _text(j['slug']),
  start: _date(j['start_date']),
  end: _date(j['end_date']),
  isCurrent: j['is_current'] == true,
);

Stage stageFrom(Map<String, dynamic> j) => Stage(
  id: _required(j['id']),
  seasonId: _int(j['season_id']) ?? 0,
  name: _text(j['name']),
  type: _text(j['type']),
  order: _int(j['sort_order']) ?? 0,
);

Group groupFrom(Map<String, dynamic> j) =>
    Group(id: _required(j['id']), stageId: _int(j['stage_id']) ?? 0, name: _text(j['name']));

Club clubFrom(Map<String, dynamic> j) => Club(
  id: _required(j['id']),
  name: _text(j['name']),
  shortName: _text(j['short_name']),
  slug: _text(j['slug']),
  logoUrl: _optional(j['logo_url']),
  city: _text(j['city']),
);

ClubProfile? clubProfileFrom(Map<String, dynamic> j) {
  final p = _map(j['profile']);
  if (p.isEmpty) return null;
  return ClubProfile(
    founded: _int(p['founded']),
    city: _optional(p['city']),
    stadium: _optional(p['stadium']),
    website: _optional(p['website']),
    historyHtml: _optional(p['history_html']),
    socials: p['socials'] is List ? (p['socials'] as List).whereType<String>().toList() : const [],
  );
}

DataQuality qualityFrom(dynamic value) {
  final q = _map(value);
  final state = _text(q['state']);
  return DataQuality(
    state: state.isEmpty ? 'unverified' : state,
    label: _text(q['label']),
    verified: state == 'verified' || state == 'manual',
  );
}

Match matchFrom(Map<String, dynamic> j) {
  final kickoff =
      _date(j['kickoff_at']) ??
      _date(_text(j['kickoff_datetime']).isEmpty ? null : '${_text(j['kickoff_datetime']).replaceFirst(' ', 'T')}Z');
  return Match(
    id: _required(j['id']),
    seasonId: _int(j['season_id']) ?? 0,
    stageId: _int(j['stage_id']) ?? 0,
    groupId: _int(j['group_id']),
    home: MatchSide(
      teamId: _required(j['home_team_id']),
      name: _text(j['home_name']),
      logoUrl: _optional(j['home_logo']),
      score: _int(j['home_score']),
    ),
    away: MatchSide(
      teamId: _required(j['away_team_id']),
      name: _text(j['away_name']),
      logoUrl: _optional(j['away_logo']),
      score: _int(j['away_score']),
    ),
    kickoff: kickoff?.toUtc(),
    venue: _text(j['venue']),
    round: _text(j['round']),
    status: MatchStatus.parse(_optional(j['status'])),
    minute: _int(j['current_minute']),
    period: _optional(j['current_period']),
    groupName: _text(j['group_name']),
    stageName: _text(j['stage_name']),
    quality: qualityFrom(j['quality']),
  );
}

MatchEvent eventFrom(Map<String, dynamic> j) => MatchEvent(
  id: _required(j['id']),
  type: EventType.parse(_optional(j['event_type'])),
  minute: _int(j['minute']),
  extraMinute: _int(j['extra_minute']),
  teamId: _int(j['team_id']),
  teamName: _text(j['team_name']),
  playerId: _int(j['player_id']),
  playerName: _optional(j['player_name']),
  relatedPlayerName: _optional(j['related_player_name']),
  detail: _optional(j['detail']),
);

StandingRow standingFrom(Map<String, dynamic> j, Map<int, Club> clubs) {
  final team = _required(j['team_id']);
  final club = clubs[team];
  return StandingRow(
    teamId: team,
    teamName: _optional(j['team_name']) ?? club?.name ?? '',
    logoUrl: _optional(j['logo_url']) ?? club?.logoUrl,
    stageId: _required(j['stage_id']),
    groupId: _int(j['group_id']),
    position: _int(j['position']) ?? 0,
    played: _int(j['played']) ?? 0,
    won: _int(j['won']) ?? 0,
    drawn: _int(j['drawn']) ?? 0,
    lost: _int(j['lost']) ?? 0,
    goalsFor: _int(j['goals_for']) ?? 0,
    goalsAgainst: _int(j['goals_against']) ?? 0,
    goalDifference: _int(j['goal_difference']) ?? 0,
    points: _int(j['points']) ?? 0,
    quality: qualityFrom(j['quality']),
  );
}

SquadMember squadMemberFrom(Map<String, dynamic> j) => SquadMember(
  playerId: _required(j['player_id']),
  name: _optional(j['display_name']) ?? _text(j['name']),
  number: _int(j['shirt_number']),
  position: _optional(j['squad_position']) ?? _text(j['position']),
  nationality: _text(j['nationality']),
  birthDate: _date(j['date_of_birth']),
  photoUrl: _optional(j['photo_url']),
);

Player playerFrom(Map<String, dynamic> j) => Player(
  id: _required(j['id']),
  name: _optional(j['display_name']) ?? _text(j['name']),
  birthDate: _date(j['date_of_birth']),
  nationality: _text(j['nationality']),
  position: _text(j['position']),
  photoUrl: _optional(j['photo_url']),
  memberships: j['memberships'] is List ? mapRows(j['memberships'], membershipFrom) : const [],
);

PlayerMembership membershipFrom(Map<String, dynamic> j) => PlayerMembership(
  teamId: _required(j['team_id']),
  teamName: _text(j['team_name']),
  teamLogo: _optional(j['team_logo']),
  seasonId: _int(j['season_id']) ?? 0,
  seasonName: _text(j['season_name']),
  number: _int(j['shirt_number']),
  position: _text(j['position']),
);

ClubNewsItem clubNewsFrom(Map<String, dynamic> j) => ClubNewsItem(
  id: _required(j['id']),
  title: _text(j['title']),
  date: _date(j['published_at']),
  imageUrl: _optional(j['image']),
  link: _text(j['url']),
  category: _optional(j['category']),
  excerpt: _optional(j['excerpt']),
);
