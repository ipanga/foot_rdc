import 'dart:ui';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'locale_provider.g.dart';

@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Locale build() {
    _loadSavedLocale();

    // Get system locale as fallback
    final systemLocale = PlatformDispatcher.instance.locale;

    // Default to French, but use English if system is English
    if (systemLocale.languageCode == 'en') {
      return const Locale('en');
    }
    return const Locale('fr');
  }

  /// Load the saved locale from SharedPreferences
  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code');

    if (languageCode != null) {
      state = Locale(languageCode);
    }
  }

  /// Change the application locale and persist it
  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    state = locale;
  }

  /// Change locale by language code
  Future<void> changeLocale(String languageCode) async {
    await setLocale(Locale(languageCode));
  }
}
