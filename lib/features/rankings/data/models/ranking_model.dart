import 'package:foot_rdc/features/rankings/domain/entities/ranking.dart';
import 'package:hive/hive.dart';

part 'ranking_model.g.dart';

@HiveType(typeId: 1)
class RankingModel extends Ranking {
  @HiveField(0)
  @override
  final int id;
  @HiveField(1)
  @override
  final String title;
  @HiveField(2)
  @override
  final Map<String, TeamData> data;

  const RankingModel({
    required this.id,
    required this.title,
    required this.data,
  }) : super(id: id, title: title, data: data);

  factory RankingModel.fromJson(Map<String, dynamic> json) {
    // Extract data field and parse team statistics
    final dataMap = json['data'] as Map<String, dynamic>;
    final Map<String, TeamData> parsedData = {};

    dataMap.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        parsedData[key] = TeamDataModel.fromJson(value);
      }
    });

    return RankingModel(
      id: json['id'] as int,
      title: json['title']['rendered'] as String,
      data: parsedData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': {'rendered': title},
      'data': data.map(
        (key, value) => MapEntry(key, (value as TeamDataModel).toJson()),
      ),
    };
  }
}

@HiveType(typeId: 2)
class TeamDataModel extends TeamData {
  @HiveField(0)
  @override
  final String? p;
  @HiveField(1)
  @override
  final String? w;
  @HiveField(2)
  @override
  final String? d;
  @HiveField(3)
  @override
  final String? ptwo;
  @HiveField(4)
  @override
  final String? f;
  @HiveField(5)
  @override
  final String? a;
  @HiveField(6)
  @override
  final String? gd;
  @HiveField(7)
  @override
  final String? pts;
  @HiveField(8)
  @override
  final String name;
  @HiveField(9)
  @override
  final int pos;

  const TeamDataModel({
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
  }) : super(
         p: p,
         w: w,
         d: d,
         ptwo: ptwo,
         f: f,
         a: a,
         gd: gd,
         pts: pts,
         name: name,
         pos: pos,
       );

  factory TeamDataModel.fromJson(Map<String, dynamic> json) {
    // Handle the special case where pos might be a string or int
    int position = 0;
    if (json['pos'] is int) {
      position = json['pos'];
    } else if (json['pos'] is String) {
      position = int.tryParse(json['pos']) ?? 0;
    }

    return TeamDataModel(
      p: json['p'] as String?,
      w: json['w'] as String?,
      d: json['d'] as String?,
      ptwo: json['ptwo'] as String?,
      f: json['f'] as String?,
      a: json['a'] as String?,
      gd: json['gd'] as String?,
      pts: json['pts'] as String?,
      name: json['name'] as String,
      pos: position,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'p': p,
      'w': w,
      'd': d,
      'ptwo': ptwo,
      'f': f,
      'a': a,
      'gd': gd,
      'pts': pts,
      'name': name,
      'pos': pos,
    };
  }
}
