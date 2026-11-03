import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/shared/widgets/premium_bottom_nav_bar.dart';

/// The bottom tabs, in display order. Refer to a tab by name, never by its position.
enum AppTab {
  home('Accueil'),
  edito('Édito'),
  matches('Matchs'),
  classement('Classement'),
  more('Plus');

  final String label;
  const AppTab(this.label);

  /// Tabs that show football data, which refreshes when the reader comes back to them.
  bool get showsFootball => this == home || this == matches || this == classement;

  /// Tabs that show live scores, so polling runs only while one of them is open.
  bool get showsLiveScores => this == home || this == matches;
}

final currentTabProvider = StateProvider<AppTab>((ref) => AppTab.home);

PremiumNavItem appTabNavItem(AppTab tab) => switch (tab) {
  AppTab.home => PremiumNavItem.svg(
    iconPath: 'assets/images/home-icon-v2-outlined.svg',
    activeIconPath: 'assets/images/home-icon-v2-filled.svg',
    label: tab.label,
  ),
  AppTab.edito => PremiumNavItem.icon(icon: Icons.edit_note_outlined, activeIcon: Icons.edit_note, label: tab.label),
  AppTab.matches => PremiumNavItem.svg(
    iconPath: 'assets/images/soccer-field-icon-outlined.svg',
    activeIconPath: 'assets/images/soccer-field-icon-filled.svg',
    label: tab.label,
  ),
  AppTab.classement => PremiumNavItem.svg(
    iconPath: 'assets/images/ranking-icon-outlined.svg',
    activeIconPath: 'assets/images/ranking-icon-filled.svg',
    label: tab.label,
  ),
  AppTab.more => PremiumNavItem.icon(
    icon: Icons.more_horiz_rounded,
    activeIcon: Icons.more_horiz_rounded,
    label: tab.label,
  ),
};

/// Keeps each tab's state. A tab is built on its first visit, so opening the app loads only Accueil.
class TabPages extends StatefulWidget {
  final AppTab current;
  final Widget Function(AppTab tab) builder;
  const TabPages({super.key, required this.current, required this.builder});

  @override
  State<TabPages> createState() => _TabPagesState();
}

class _TabPagesState extends State<TabPages> {
  final _opened = <AppTab>{};

  @override
  Widget build(BuildContext context) {
    _opened.add(widget.current);
    return IndexedStack(
      index: widget.current.index,
      children: [
        for (final tab in AppTab.values) _opened.contains(tab) ? widget.builder(tab) : const SizedBox.shrink(),
      ],
    );
  }
}
