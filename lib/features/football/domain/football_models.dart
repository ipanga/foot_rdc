import 'dart:collection';

int? coreInt(Object? value) => value == null ? null : int.tryParse('$value');
String coreText(Object? value) => value is String ? value.trim() : '';
dynamic _freeze(dynamic value) => switch (value) {
  Map() => Map.unmodifiable(
    value.map((key, child) => MapEntry(key, _freeze(child))),
  ),
  List() => List.unmodifiable(value.map(_freeze)),
  _ => value,
};

class FootballRecord {
  final Map<String, dynamic> data;
  FootballRecord(Map<String, dynamic> json)
    : data = UnmodifiableMapView({
        for (final entry in json.entries) entry.key: _freeze(entry.value),
      }) {
    if ((coreInt(json['id']) ?? 0) <= 0) {
      throw const FormatException('Invalid Core identity');
    }
  }
  int get id => coreInt(data['id'])!;
  int? number(String key) => coreInt(data[key]);
  String text(String key) => coreText(data[key]);
  String get name => text('name');
  String get status => text('status');
  bool get isLive => status == 'live' || status == 'halftime';
  bool get standingPublishable =>
      data['quality'] is Map && (data['quality'] as Map)['publishable'] == true;
  bool get stale =>
      data['freshness'] is Map && (data['freshness'] as Map)['stale'] == true;
  DateTime? get kickoff {
    final raw = text('kickoff_datetime');
    if (raw.isEmpty) return null;
    final iso = raw.replaceFirst(' ', 'T');
    return DateTime.tryParse(
      RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(iso) ? iso : '${iso}Z',
    );
  }

  String score({required bool liveAllowed}) {
    if (isLive && !liveAllowed) return '\u2014';
    final home = number('home_score'), away = number('away_score');
    return home == null || away == null ? '\u2014' : '$home - $away';
  }

  Map<String, num> get metrics {
    final value = data['metrics'];
    if (value is! Map) return {};
    return {
      for (final entry in value.entries)
        if (entry.value is num) '${entry.key}': entry.value as num,
    };
  }

  List<FootballRecord> nested(String key) => data[key] is List
      ? (data[key] as List)
            .whereType<Map>()
            .map((row) => FootballRecord(Map<String, dynamic>.from(row)))
            .toList()
      : [];
}

class FootballPhase {
  final int stageId;
  final int? groupId;
  final String name;
  final String type;
  const FootballPhase(this.stageId, this.groupId, this.name, this.type);
  Map<String, dynamic> get filters => {
    'stage_id': stageId,
    if (groupId != null) 'group_id': groupId,
  };
}

class FootballPage {
  final List<FootballRecord> rows;
  final bool hasMore;
  final bool cached;
  const FootballPage(this.rows, {this.hasMore = false, this.cached = false});
}

class FootballContext {
  final FootballRecord competition;
  final FootballRecord season;
  final List<FootballPhase> phases;
  final Map<int, FootballRecord> teams;
  const FootballContext(this.competition, this.season, this.phases, this.teams);
}

class FootballQuery {
  final String path;
  final Map<String, dynamic> filters;
  const FootballQuery(this.path, [this.filters = const {}]);
  String get key {
    final keys = filters.keys.toList()..sort();
    return '$path?${Uri(queryParameters: {for (final key in keys) key: '${filters[key]}'}).query}';
  }

  @override
  bool operator ==(Object other) => other is FootballQuery && key == other.key;
  @override
  int get hashCode => key.hashCode;
}

enum FootballReadiness { unvalidated, degraded, validated }

class FootballLiveGate {
  final bool requested;
  final FootballReadiness readiness;
  const FootballLiveGate({
    this.requested = false,
    this.readiness = FootballReadiness.unvalidated,
  });
  bool get enabled => requested && readiness == FootballReadiness.validated;
}
