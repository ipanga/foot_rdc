import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:foot_rdc/features/presentation/pages/article_web_list.dart';
import 'package:foot_rdc/features/presentation/pages/article_saved_list.dart';
import 'package:foot_rdc/features/presentation/pages/article_search_list.dart';
import 'package:foot_rdc/features/presentation/pages/matchs_list.dart';
import 'package:foot_rdc/features/presentation/pages/table_league.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentPage = 0;

  List<Widget> pages = const [
    ArticleWebList(),
    MatchsList(),
    TableLeague(),
    ArticleSavedList(),
    ArticleSearchList(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        // Maintains the state of each page after navigation to another page
        index: currentPage,
        children: pages,
      ),

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
          onTap: (value) {
            setState(() {
              currentPage = value;
            });
          },
          currentIndex: currentPage,

          items: [
            // Home Icon
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
              label: 'Accueil',
              //label: 'ACCUEIL',
            ),

            // Matchs Icon
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
              label: 'Matchs',
              //label: 'MATCHS',
            ),

            // Ranking Icon
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
              label: 'Classement',
              //label: 'CLASSEMENT',
            ),

            // Saved Icon
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
              label: 'Enregistrés',
              //label: 'ENREGISTRÉS',
            ),

            // Search Icon
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
              label: 'Recherche',
              //label: 'RECHERCHE',
            ),
          ],
        ),
      ),
    );
  }
}
