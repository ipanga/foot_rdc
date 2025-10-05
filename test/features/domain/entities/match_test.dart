import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/features/domain/entities/match.dart';

void main() {
  group('Match Entity Tests', () {
    test('should create Match from JSON correctly', () {
      // Arrange
      final json = {
        "id": 65424,
        "date_gmt": "2025-06-27T11:00:22",
        "status": "publish",
        "title": {"rendered": "Anges Verts vs AC Rangers"},
        "main_results": ["3", "3"],
      };

      // Act
      final match = Match.fromJson(json);

      // Assert
      expect(match.id, 65424);
      expect(match.dateGmt, DateTime.parse("2025-06-27T11:00:22"));
      expect(match.status, "publish");
      expect(match.homeTeam, "Anges Verts");
      expect(match.awayTeam, "AC Rangers");
      expect(match.homeScore, "3");
      expect(match.awayScore, "3");
    });

    test('should create Match from JSON without scores', () {
      // Arrange
      final json = {
        "id": 65345,
        "date_gmt": "2025-06-24T13:00:38",
        "status": "future",
        "title": {"rendered": "FC Lupopo vs TP Mazembe"},
        "main_results": null,
      };

      // Act
      final match = Match.fromJson(json);

      // Assert
      expect(match.id, 65345);
      expect(match.homeTeam, "FC Lupopo");
      expect(match.awayTeam, "TP Mazembe");
      expect(match.homeScore, null);
      expect(match.awayScore, null);
    });

    test('should convert Match to JSON correctly', () {
      // Arrange
      final match = Match(
        id: 65424,
        dateGmt: DateTime.parse("2025-06-27T11:00:22"),
        status: "publish",
        homeTeam: "Anges Verts",
        awayTeam: "AC Rangers",
        homeScore: "3",
        awayScore: "3",
      );

      // Act
      final json = match.toJson();

      // Assert
      expect(json['id'], 65424);
      expect(json['date_gmt'], "2025-06-27T11:00:22.000");
      expect(json['status'], "publish");
      expect(json['title']['rendered'], "Anges Verts vs AC Rangers");
      expect(json['main_results'], ["3", "3"]);
    });

    test('should handle copyWith correctly', () {
      // Arrange
      final originalMatch = Match(
        id: 1,
        dateGmt: DateTime.now(),
        status: "publish",
        homeTeam: "Team A",
        awayTeam: "Team B",
        homeScore: "1",
        awayScore: "0",
      );

      // Act
      final updatedMatch = originalMatch.copyWith(
        homeScore: "2",
        awayScore: "1",
      );

      // Assert
      expect(updatedMatch.homeScore, "2");
      expect(updatedMatch.awayScore, "1");
      expect(updatedMatch.homeTeam, originalMatch.homeTeam);
      expect(updatedMatch.awayTeam, originalMatch.awayTeam);
    });
  });
}
