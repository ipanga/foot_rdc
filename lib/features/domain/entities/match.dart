class Match {
  final int id;
  final DateTime dateGmt;
  final String status;
  final String homeTeam;
  final String awayTeam;
  final String? homeScore;
  final String? awayScore;

  Match({
    required this.id,
    required this.dateGmt,
    required this.status,
    required this.homeTeam,
    required this.awayTeam,
    this.homeScore,
    this.awayScore,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    // Extract teams from title: "Team A vs Team B"
    final titleRendered = json['title']?['rendered'] ?? '';
    final teams = titleRendered.split(' vs ');
    final homeTeam = teams.isNotEmpty ? teams[0].trim() : '';
    final awayTeam = teams.length > 1 ? teams[1].trim() : '';

    // Extract scores from main_results if available
    final mainResults = json['main_results'] as List<dynamic>?;
    String? homeScore;
    String? awayScore;

    if (mainResults != null && mainResults.length >= 2) {
      homeScore = mainResults[0]?.toString();
      awayScore = mainResults[1]?.toString();
    }

    return Match(
      id: json['id'] ?? 0,
      dateGmt: DateTime.parse(
        json['date_gmt'] ?? DateTime.now().toIso8601String(),
      ),
      status: json['status'] ?? '',
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeScore: homeScore,
      awayScore: awayScore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date_gmt': dateGmt.toIso8601String(),
      'status': status,
      'title': {'rendered': '$homeTeam vs $awayTeam'},
      'main_results': homeScore != null && awayScore != null
          ? [homeScore, awayScore]
          : null,
    };
  }

  Match copyWith({
    int? id,
    DateTime? dateGmt,
    String? status,
    String? homeTeam,
    String? awayTeam,
    String? homeScore,
    String? awayScore,
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
    return 'Match(id: $id, homeTeam: $homeTeam, awayTeam: $awayTeam, homeScore: $homeScore, awayScore: $awayScore)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Match &&
        other.id == id &&
        other.dateGmt == dateGmt &&
        other.status == status &&
        other.homeTeam == homeTeam &&
        other.awayTeam == awayTeam &&
        other.homeScore == homeScore &&
        other.awayScore == awayScore;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      dateGmt,
      status,
      homeTeam,
      awayTeam,
      homeScore,
      awayScore,
    );
  }
}
