import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:foot_rdc/features/presentation/pages/article_web_list.dart';
import 'package:foot_rdc/features/presentation/pages/article_saved_list.dart';
import 'package:foot_rdc/features/presentation/pages/article_search_list.dart';
import 'package:foot_rdc/features/presentation/pages/matchs_list.dart';
import 'package:foot_rdc/features/presentation/pages/table_league.dart';
import 'package:foot_rdc/l10n/app_localizations.dart';

final currentPageProvider = StateProvider<int>((ref) => 0);

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentPage = ref.watch(currentPageProvider);

    List<Widget> pages = const [
      ArticleWebList(),
      MatchsList(),
      TableLeague(),
      ArticleSavedList(),
      ArticleSearchList(),
    ];

    return Scaffold(
      body: pages[currentPage],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey, width: 0.2)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 9,
          unselectedFontSize: 9,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w300),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w300),
          elevation: 0,
          currentIndex: currentPage,
          onTap: (value) {
            ref.read(currentPageProvider.notifier).state = value;
          },
          items: [
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/images/home-icon-v2-outlined.svg',
                height: 24,
                fit: BoxFit.contain,
              ),
              activeIcon: SvgPicture.asset(
                'assets/images/home-icon-v2-filled.svg',
                height: 24,
                fit: BoxFit.contain,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFec3535),
                  BlendMode.srcIn,
                ),
              ),
              label: l10n.home,
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/images/soccer-field-icon-outlined.svg',
                height: 24,
                fit: BoxFit.contain,
              ),
              activeIcon: SvgPicture.asset(
                'assets/images/soccer-field-icon-filled.svg',
                height: 24,
                fit: BoxFit.contain,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFec3535),
                  BlendMode.srcIn,
                ),
              ),
              label: l10n.matches,
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/images/ranking-icon-outlined.svg',
                height: 24,
                fit: BoxFit.contain,
              ),
              activeIcon: SvgPicture.asset(
                'assets/images/ranking-icon-filled.svg',
                height: 24,
                fit: BoxFit.contain,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFec3535),
                  BlendMode.srcIn,
                ),
              ),
              label: l10n.ranking,
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/images/save-icon-outlined.svg',
                height: 24,
                fit: BoxFit.contain,
              ),
              activeIcon: SvgPicture.asset(
                'assets/images/save-icon-filled.svg',
                height: 24,
                fit: BoxFit.contain,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFec3535),
                  BlendMode.srcIn,
                ),
              ),
              label: l10n.saved,
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/images/search-icon-outlined.svg',
                height: 24,
                fit: BoxFit.contain,
              ),
              activeIcon: SvgPicture.asset(
                'assets/images/search-icon-outlined.svg',
                height: 24,
                fit: BoxFit.contain,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFec3535),
                  BlendMode.srcIn,
                ),
              ),
              label: l10n.search,
            ),
          ],
        ),
      ),
    );
  }
}
