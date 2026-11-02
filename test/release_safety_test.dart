import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Internal beta is the only release path, and credentials stay out of Git.
void main() {
  final fastfile = File('fastlane/Fastfile').readAsStringSync();
  final code = fastfile.split('\n').where((line) => !line.trimLeft().startsWith('#')).join('\n');

  test('no path to App Review or a public store track', () {
    for (final forbidden in [
      'upload_to_app_store',
      'appstore(',
      'deliver(',
      'submit_for_review',
      'promote',
      'distribute_external: true',
      'submit_beta_review: true',
      'rollout',
    ]) {
      expect(code.contains(forbidden), isFalse, reason: forbidden);
    }
    expect(RegExp(r'track: "(?!internal")').hasMatch(code.replaceAll('track: track', '')), isFalse);
    expect('upload_to_play_store'.allMatches(code), hasLength(1));
    expect('upload_to_testflight'.allMatches(code), hasLength(1));
    expect(code, contains('distribute_external: false'));
    expect(code, contains('submit_beta_review: false'));
  });

  test('credential files are ignored by Git', () {
    final ignore = File('.gitignore').readAsStringSync();
    for (final rule in ['*.p8', '*.mobileprovision', '*.ipa', '*.aab', 'fastlane/.env*']) {
      expect(ignore, contains(rule));
    }
    expect(File('android/.gitignore').readAsStringSync(), contains('key.properties'));
    final tracked = Process.runSync('git', ['ls-files']).stdout as String;
    expect(
      RegExp(r'\.(p8|jks|keystore|p12|mobileprovision)$|key\.properties$', multiLine: true).hasMatch(tracked),
      isFalse,
    );
  });

  test('the push extension carries the app version', () {
    final version = RegExp(
      r'^version: ([0-9.]+)\+([0-9]+)$',
      multiLine: true,
    ).firstMatch(File('pubspec.yaml').readAsStringSync())!;
    final project = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    for (final match in RegExp(r'MARKETING_VERSION = ([^;]+);').allMatches(project)) {
      expect(match.group(1), version.group(1));
    }
    for (final match in RegExp(r'CURRENT_PROJECT_VERSION = (\d+);').allMatches(project)) {
      expect(match.group(1), version.group(2));
    }
  });

  test('every iOS target stays on 15.0', () {
    final project = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final targets = RegExp(r'IPHONEOS_DEPLOYMENT_TARGET = ([^;]+);').allMatches(project).map((m) => m.group(1)).toSet();
    expect(targets, {'15.0'});
  });
}
