import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dark_theme.dart';
import 'light_theme.dart';

/// Controller managing global application theme state and persistent storage preferences.
class ThemeController extends ChangeNotifier {
  static const String _prefKeyThemeMode = 'examcraft_theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  SharedPreferences? _prefs;

  ThemeController({SharedPreferences? preferences}) : _prefs = preferences {
    if (_prefs != null) {
      _loadThemeFromPrefs();
    }
  }

  /// Active theme mode (light, dark, system).
  ThemeMode get themeMode => _themeMode;

  /// Check whether dark mode is currently active based on explicit setting or system preference.
  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  /// Light theme data.
  ThemeData get lightThemeData => ExamCraftLightTheme.themeData;

  /// Dark theme data.
  ThemeData get darkThemeData => ExamCraftDarkTheme.themeData;

  /// Asynchronously loads persistent theme preference from [SharedPreferences].
  Future<void> loadThemeMode() async {
    _prefs ??= await SharedPreferences.getInstance();
    _loadThemeFromPrefs();
  }

  void _loadThemeFromPrefs() {
    final savedMode = _prefs?.getString(_prefKeyThemeMode);
    if (savedMode == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (savedMode == 'light') {
      _themeMode = ThemeMode.light;
    } else if (savedMode == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  /// Updates active theme mode and persists choice to storage.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    _prefs ??= await SharedPreferences.getInstance();
    switch (mode) {
      case ThemeMode.dark:
        await _prefs?.setString(_prefKeyThemeMode, 'dark');
        break;
      case ThemeMode.light:
        await _prefs?.setString(_prefKeyThemeMode, 'light');
        break;
      case ThemeMode.system:
        await _prefs?.setString(_prefKeyThemeMode, 'system');
        break;
    }
  }

  /// Toggles between Light and Dark modes.
  Future<void> toggleTheme(BuildContext context) async {
    final currentIsDark = isDarkMode(context);
    await setThemeMode(currentIsDark ? ThemeMode.light : ThemeMode.dark);
  }
}
