class Match {
  final int id;
  final DateTime dateGmt;
  final String status;
  final String homeTeam;
  final String awayTeam;
  final int? homeScore;
  final int? awayScore;

  const Match({
    required this.id,
    required this.dateGmt,
    required this.status,
    required this.homeTeam,
    required this.awayTeam,
    this.homeScore,
    this.awayScore,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    final title = json['title']?['rendered'] as String? ?? '';
    final teams = _parseTeams(title);
    final scores = _parseScores(json);

    return Match(
      id: json['id'] as int? ?? 0,
      dateGmt: DateTime.tryParse(json['date_gmt'] as String? ?? '') ??
          DateTime.now(),
      status: json['status'] as String? ?? '',
      homeTeam: teams['home'] ?? 'Unknown',
      awayTeam: teams['away'] ?? 'Unknown',
      homeScore: scores['home'],
      awayScore: scores['away'],
    );
  }

  static Map<String, String> _parseTeams(String title) {
    // Title format: "Team A vs Team B" or "Team A - Team B"
    final separators = [' vs ', ' VS ', ' - ', ' vs. ', ' VS. '];

    for (final sep in separators) {
      if (title.contains(sep)) {
        final parts = title.split(sep);
        if (parts.length >= 2) {
          return {
            'home': parts[0].trim(),
            'away': parts[1].trim(),
          };
        }
      }
    }

    return {'home': title, 'away': ''};
  }

  static Map<String, int?> _parseScores(Map<String, dynamic> json) {
    try {
      final mainResults = json['main_results'] as List<dynamic>?;
      if (mainResults != null && mainResults.length >= 2) {
        return {
          'home': int.tryParse(mainResults[0].toString()),
          'away': int.tryParse(mainResults[1].toString()),
        };
      }
    } catch (_) {}

    return {'home': null, 'away': null};
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date_gmt': dateGmt.toIso8601String(),
      'status': status,
      'title': {'rendered': '$homeTeam vs $awayTeam'},
      'main_results': [homeScore, awayScore],
    };
  }

  Match copyWith({
    int? id,
    DateTime? dateGmt,
    String? status,
    String? homeTeam,
    String? awayTeam,
    int? homeScore,
    int? awayScore,
  }) {
    return Match(
      id: id ?? this.id,
      dateGmt: dateGmt ?? this.dateGmt,
      status: status ?? this.status,
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
    );
  }

  @override
  String toString() {
    return 'Match(id: $id, $homeTeam vs $awayTeam, score: $homeScore-$awayScore)';
  }
}
