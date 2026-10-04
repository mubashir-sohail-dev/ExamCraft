import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/data/models/settings_model.dart';

abstract class ISettingsRepository {
  Future<SettingsModel> getSettings();
  Future<void> saveSettings(SettingsModel settings);
  Future<void> resetSettings();
  Future<void> sendTelemetryEvent(
      String eventName, Map<String, dynamic> payload);
}

/// Repository for application settings configuration persisted via SharedPreferences.
class SettingsRepository implements ISettingsRepository {
  static const String _settingsKey = 'app_settings_storage';
  SettingsModel? _cachedSettings;

  @override
  Future<SettingsModel> getSettings() async {
    if (_cachedSettings != null) return _cachedSettings!;
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_settingsKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      _cachedSettings = const SettingsModel();
      return _cachedSettings!;
    }
    try {
      _cachedSettings =
          SettingsModel.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
      return _cachedSettings!;
    } catch (_) {
      _cachedSettings = const SettingsModel();
      return _cachedSettings!;
    }
  }

  @override
  Future<void> saveSettings(SettingsModel settings) async {
    _cachedSettings = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  @override
  Future<void> resetSettings() async {
    _cachedSettings = const SettingsModel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_settingsKey);
  }

  @override
  Future<void> sendTelemetryEvent(
      String eventName, Map<String, dynamic> payload) async {
    // No-op for telemetry in production release
  }
}
