import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/features/news/presentation/screens/article_detail_screen.dart';
import 'package:foot_rdc/features/news/presentation/widgets/article_list_item.dart';
import 'package:integration_test/integration_test.dart';

import 'qa_support.dart';

/// Article reading on a device: back stays reachable, the feed keeps its place, system back works.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('article back navigation', (tester) async {
    final qa = Qa(tester, binding, 'article');
    await qa.launch();
    await qa.wait(find.byType(ArticleListItem));

    // Feed position before opening an article.
    await qa.scroll(900);
    await qa.scroll(900);
    ScrollPosition feed() => tester
        .stateList<ScrollableState>(find.byType(Scrollable))
        .firstWhere((s) => s.position.axis == Axis.vertical && s.position.pixels > 0)
        .position;
    final before = feed().pixels;
    await tester.tap(find.byType(ArticleListItem).hitTestable().first);
    await qa.wait(find.byType(ArticleDetailScreen));
    await qa.pumpFor(const Duration(seconds: 3));
    await qa.shot('article-haut');

    // Long read: the bar with back, save and share stays at the top.
    final article = find.descendant(of: find.byType(ArticleDetailScreen), matching: find.byType(Scrollable)).first;
    await tester.drag(article, const Offset(0, -1600));
    await qa.pumpFor(const Duration(seconds: 1));
    final back = find.descendant(of: find.byType(ArticleDetailScreen), matching: find.byIcon(Icons.arrow_back));
    expect(back, findsOneWidget);
    final rect = tester.getRect(back);
    // ignore: avoid_print
    print('QA-INFO back button at ${rect.top.toStringAsFixed(0)} after scrolling; feed offset before $before');
    expect(rect.top, lessThan(140));
    await qa.shot('article-lecture-barre');
    await tester.drag(article, const Offset(0, -20000));
    await qa.pumpFor(const Duration(seconds: 1));
    expect(back, findsOneWidget);
    await qa.shot('article-fin-barre');

    // The visible back button returns to the same place in the feed.
    await tester.tap(back);
    await qa.pumpFor(const Duration(seconds: 1));
    expect(find.byType(ArticleDetailScreen), findsNothing);
    final after = feed().pixels;
    // ignore: avoid_print
    print('QA-INFO feed offset after back $after');
    expect((after - before).abs(), lessThan(2));
    await qa.shot('fil-meme-position');

    // System back (Android button, iOS edge swipe use the same pop route).
    await tester.tap(find.byType(ArticleListItem).hitTestable().first);
    await qa.wait(find.byType(ArticleDetailScreen));
    await qa.pumpFor(const Duration(seconds: 2));
    await qa.back();
    expect(find.byType(ArticleDetailScreen), findsNothing);
    expect((feed().pixels - before).abs(), lessThan(2));
  });
}
