import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/core/theme/dark_theme.dart';
import 'package:flutter_app/core/theme/light_theme.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = true;
    SharedPreferences.setMockInitialValues({});
  });

  group('ExamCraft Theme System Tests', () {
    test('Light Theme specification check', () {
      final theme = ExamCraftLightTheme.themeData;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, equals(Brightness.light));
      expect(theme.colorScheme.primary, equals(const Color(0xFF005BBF)));
      expect(theme.colorScheme.surface, equals(const Color(0xFFF7F9FF)));
    });

    test('Dark Theme specification check', () {
      final theme = ExamCraftDarkTheme.themeData;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.colorScheme.primary, equals(const Color(0xFFADC7FF)));
      expect(theme.colorScheme.surface, equals(const Color(0xFF121316)));
    });

    test('ThemeController initial state and mode updates', () async {
      final controller = ThemeController();
      expect(controller.themeMode, equals(ThemeMode.system));

      await controller.setThemeMode(ThemeMode.dark);
      expect(controller.themeMode, equals(ThemeMode.dark));

      await controller.setThemeMode(ThemeMode.light);
      expect(controller.themeMode, equals(ThemeMode.light));
    });
  });
}
