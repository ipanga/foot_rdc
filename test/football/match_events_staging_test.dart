import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/features/football/domain/models.dart';
import 'package:foot_rdc/features/football/presentation/screens/match_detail_screen.dart';

import 'support.dart';

/// Real responses of the RDC Football match editor (Core 0.13.0) captured on FootRDC Staging, 10 Nov 2026:
/// a Sportmonks goal corrected on FootRDC, goals added by hand (own goal 45+2, unknown penalty taker 90+4),
/// served under the contract fixture's match id. Checks the app reads them with no app change.
Map<String, dynamic> stagingData() {
  final staging = jsonDecode(File('test/fixtures/staging_match_events.json').readAsStringSync()) as Map<String, dynamic>;
  final data = productionContract();
  // Crest images are not loaded in widget tests (no platform plugins); names are what is checked.
  final match = Map<String, dynamic>.from(staging['match'] as Map)
    ..['id'] = 6476
    ..['home_logo'] = null
    ..['away_logo'] = null;
  final events = [
    for (final e in staging['events'] as List) Map<String, dynamic>.from(e as Map)..['match_id'] = 6476,
  ];
  match['events'] = events;
  return {...data, 'match': match, 'events': events};
}

void main() {
  test('edited events parse: types, added time, scorer, unknown scorer, club', () async {
    final (repo, _, _) = contractRepository(data: stagingData());
    final events = await repo.events(6476);
    expect(events.map((e) => e.clock), ["30'", "45+2'", "45+4'", "48'", "90+4'"]);
    expect(events.map((e) => e.type), [
      EventType.redCard,
      EventType.ownGoal,
      EventType.goal,
      EventType.goal,
      EventType.penaltyGoal,
    ]);
    expect(events[3].playerName, 'Timité Yacouba');
    expect(events[4].playerName, isNull);
    expect(events[4].detail, isNull);
    expect(events.where((e) => e.type.isGoal).every((e) => e.teamName == 'FC Saint Eloi Lupopo'), isTrue);
  });

  testWidgets('match screen shows the edited timeline without inventing a scorer', (tester) async {
    final (repo, _, _) = contractRepository(data: stagingData());
    await tester.pumpWidget(app(const MatchDetailScreen(matchId: 6476), repo, size: const Size(390, 2400)));
    await settle(tester);
    expect(find.text('Fil du match'), findsOneWidget);
    // The row title is the scorer; the line below joins the event kind and the club.
    expect(find.text('But contre son camp · FC Saint Eloi Lupopo'), findsOneWidget);
    // Unknown penalty taker: the kind becomes the title, no name is invented.
    expect(find.text('But sur penalty'), findsOneWidget);
    expect(find.text('FC Saint Eloi Lupopo'), findsWidgets);
    expect(find.text('Timité Yacouba'), findsOneWidget);
    expect(find.text("90+4'"), findsOneWidget);
    expect(find.text('null'), findsNothing);
  });
}
