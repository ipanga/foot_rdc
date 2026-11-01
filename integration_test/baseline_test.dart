import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/features/news/data/models/article_model.dart';
import 'package:foot_rdc/main.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('baseline navigation', (tester) async {
    await Hive.initFlutter((await getApplicationDocumentsDirectory()).path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ArticleModelAdapter());
    await Hive.openBox<ArticleModel>('articles');
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
    Future<void> settle() async {
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    await settle();
    await binding.takeScreenshot('${Platform.operatingSystem}-01-accueil');
    for (final (i, label) in const ['À Savoir', 'Matchs', 'Classement', 'Enregistrés'].indexed) {
      await tester.tap(find.text(label).last);
      await settle();
      await binding.takeScreenshot('${Platform.operatingSystem}-0${i + 2}-${label.toLowerCase().replaceAll(' ', '-')}');
    }
  });
}
