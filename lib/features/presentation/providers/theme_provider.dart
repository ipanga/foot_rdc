import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeModeCustom { system, light, dark }

class ThemeNotifierCustom extends StateNotifier<ThemeModeCustom> {
  ThemeNotifierCustom() : super(ThemeModeCustom.system) {
    _loadTheme();
  }

  static const String _themeKey = 'theme_mode';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(_themeKey);

    if (themeModeString != null) {
      state = ThemeModeCustom.values.firstWhere(
        (mode) => mode.toString() == themeModeString,
        orElse: () => ThemeModeCustom.system,
      );
    }
  }

  Future<void> setTheme(ThemeModeCustom themeMode) async {
    state = themeMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeMode.toString());
  }

  bool isDarkMode(BuildContext context) {
    switch (state) {
      case ThemeModeCustom.light:
        return false;
      case ThemeModeCustom.dark:
        return true;
      case ThemeModeCustom.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
  }

  ThemeMode getFlutterThemeMode(BuildContext context) {
    switch (state) {
      case ThemeModeCustom.light:
        return ThemeMode.light;
      case ThemeModeCustom.dark:
        return ThemeMode.dark;
      case ThemeModeCustom.system:
        return ThemeMode.system;
    }
  }
}

final themeCustomNotifierProvider =
    StateNotifierProvider<ThemeNotifierCustom, ThemeModeCustom>(
      (ref) => ThemeNotifierCustom(),
    );
