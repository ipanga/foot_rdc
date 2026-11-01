import 'package:flutter/material.dart';

import 'screens/club_detail_screen.dart';
import 'screens/linafoot_screen.dart';
import 'screens/match_detail_screen.dart';
import 'screens/player_detail_screen.dart';

void openMatch(BuildContext context, int id) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MatchDetailScreen(matchId: id)));
void openClub(BuildContext context, int id) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ClubDetailScreen(clubId: id)));
void openPlayer(BuildContext context, int id) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PlayerDetailScreen(playerId: id)));
void openStandings(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => const LinafootScreen(initialTab: LinafootScreen.standingsTab)));
