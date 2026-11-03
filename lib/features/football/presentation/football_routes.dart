import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/presentation/app_tabs.dart';

import 'screens/club_detail_screen.dart';
import 'screens/match_detail_screen.dart';
import 'screens/player_detail_screen.dart';

void openMatch(BuildContext context, int id) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MatchDetailScreen(matchId: id)));
void openClub(BuildContext context, int id) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ClubDetailScreen(clubId: id)));
void openPlayer(BuildContext context, int id) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PlayerDetailScreen(playerId: id)));

/// Standings live in the Classement tab: switch to it rather than stacking a copy of the tab.
void openStandings(BuildContext context) {
  Navigator.of(context).popUntil((route) => route.isFirst);
  ProviderScope.containerOf(context, listen: false).read(currentTabProvider.notifier).state = AppTab.classement;
}
