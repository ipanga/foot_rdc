import 'package:flutter/material.dart';
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
        /* iconSize: 35,
        selectedFontSize: 0,
        unselectedFontSize: 0, */
        onTap: (value) {
          setState(() {
            currentPage = value;
          });
        },
        currentIndex: currentPage,

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.save), label: 'Saved'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        ],
      ),
    );
  }
}
