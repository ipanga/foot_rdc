class Ranking {
  final int id;
  final String title;
  final Map<String, TeamData> data;

  const Ranking({required this.id, required this.title, required this.data});

  /// Get table headers from the data map (key "0")
  TeamData? get headers => data['0'];

  /// Get all team data excluding headers
  List<TeamData> get teams {
    return data.entries
        .where((entry) => entry.key != '0')
        .map((entry) => entry.value)
        .toList()
      ..sort((a, b) => a.pos.compareTo(b.pos));
  }
}

class TeamData {
  final String? p; // Matches played (J)
  final String? w; // Wins (G)
  final String? d; // Draws (N)
  final String? ptwo; // Losses (D)
  final String? f; // Goals for (BP)
  final String? a; // Goals against (BC)
  final String? gd; // Goal difference (DIF)
  final String? pts; // Points (Pts)
  final String name; // Club name
  final int pos; // Position

  const TeamData({
    this.p,
    this.w,
    this.d,
    this.ptwo,
    this.f,
    this.a,
    this.gd,
    this.pts,
    required this.name,
    required this.pos,
  });

  /// Check if this is a header row
  bool get isHeader =>
      pos == 0 ||
      name.toLowerCase().contains('pos') ||
      name.toLowerCase().contains('club');
}
