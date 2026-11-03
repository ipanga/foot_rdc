import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/features/news/data/models/article_model.dart';
import 'package:foot_rdc/main.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

/// Shared device-QA driver: launches the real app and takes named screenshots. Read-only against Production.
class Qa {
  final WidgetTester tester;
  final IntegrationTestWidgetsFlutterBinding binding;
  final String prefix;
  int step = 0;
  Qa(this.tester, this.binding, this.prefix);

  String get os => Platform.operatingSystem;

  Future<void> launch() async {
    await initializeDateFormatting('fr');
    await Hive.initFlutter((await getApplicationDocumentsDirectory()).path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ArticleModelAdapter());
    if (!Hive.isBoxOpen('articles')) await Hive.openBox<ArticleModel>('articles');
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
  }

  Future<void> pumpFor(Duration total) async {
    final end = DateTime.now().add(total);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  Future<void> wait(Finder finder, {int seconds = 30}) async {
    for (var i = 0; i < seconds * 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return;
    }
    // ignore: avoid_print
    print('QA-FAIL $prefix step $step: not on screen: ${finder.describeMatch(Plurality.zero)}');
    await binding.takeScreenshot('$os-$prefix-FAIL-$step');
    throw TestFailure('Not found on screen: $finder');
  }

  Future<void> shot(String name) async {
    await pumpFor(const Duration(milliseconds: 1500));
    step++;
    // ignore: avoid_print
    print('QA-STEP $step $name');
    for (var attempt = 1; ; attempt++) {
      try {
        await binding.takeScreenshot('$os-$prefix-${step.toString().padLeft(2, '0')}-$name');
        return;
      } on PlatformException catch (error) {
        if (attempt == 4) rethrow;
        // ignore: avoid_print
        print('QA-SHOT-RETRY step $step attempt $attempt: ${error.message}');
        await tester.pump(const Duration(seconds: 1));
      }
    }
  }

  Future<void> nav(String label) async {
    await tester.tap(find.text(label).last);
    await pumpFor(const Duration(milliseconds: 400));
  }

  Future<void> back() async {
    await tester.binding.handlePopRoute();
    await pumpFor(const Duration(milliseconds: 1200));
  }

  Future<void> scroll(double dy) async {
    await tester.drag(find.byType(Scrollable).first, Offset(0, -dy));
    await pumpFor(const Duration(milliseconds: 800));
  }
}
