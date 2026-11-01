import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Saves the screenshots taken on the device under QA_SCREENS_DIR.
Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final dir = Platform.environment['QA_SCREENS_DIR'] ?? 'build/qa-screens';
    final file = File('$dir/$name.png');
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
    return true;
  },
);
