import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:foot_rdc/features/presentation/pages/article_web_list.dart';
import 'package:foot_rdc/features/presentation/pages/article_saved_list.dart';
import 'package:foot_rdc/features/presentation/pages/article_search_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentPage = 0;

  List<Widget> pages = const [
    ArticleWebList(),
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

      bottomNavigationBar: BottomNavigationBar(
        //iconSize: 35,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        onTap: (value) {
          setState(() {
            currentPage = value;
          });
        },
        currentIndex: currentPage,

        items: [
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/images/home-icon-v2-outlined.svg',
              height: 24,
              fit: BoxFit.contain,
            ),
            activeIcon: SvgPicture.asset(
              'assets/images/home-icon-v2-full.svg',
              height: 24,
              fit: BoxFit.contain,
              colorFilter: const ColorFilter.mode(
                Color(0xFFec3535),
                BlendMode.srcIn,
              ),
            ),
            label: 'HOME',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/images/save-icon-outlined.svg',
              height: 24,
              fit: BoxFit.contain,
            ),
            activeIcon: SvgPicture.asset(
              'assets/images/save-icon-full.svg',
              height: 24,
              fit: BoxFit.contain,
              colorFilter: const ColorFilter.mode(
                Color(0xFFec3535),
                BlendMode.srcIn,
              ),
            ),
            label: 'SAVED',
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
            label: 'SEARCH',
          ),
        ],
      ),
    );
  }
}
