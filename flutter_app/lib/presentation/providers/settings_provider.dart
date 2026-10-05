import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/api_client.dart';
import 'package:flutter_app/data/models/settings_model.dart';
import 'package:flutter_app/data/repositories/settings_repository.dart';

class SettingsProvider extends ChangeNotifier {
  final ISettingsRepository settingsRepository;
  final ApiClient? apiClient;

  SettingsModel _settings = const SettingsModel();
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  SettingsModel get settings => _settings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get baseUrl => _settings.baseUrl;
  String get clientApiKey => _settings.clientApiKey;
  String get adminApiKey => _settings.adminApiKey;
  bool get isDarkMode => _settings.isDarkMode;
  bool get enableTelemetry => _settings.enableTelemetry;
  bool get includeAnswerKey => _settings.includeAnswerKey;

  SettingsProvider({
    required this.settingsRepository,
    this.apiClient,
  }) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _settings = await settingsRepository.getSettings();
      if (apiClient != null) {
        apiClient!.updateBaseUrl(_settings.baseUrl);
        apiClient!.updateClientApiKey(_settings.clientApiKey);
        apiClient!.updateAdminApiKey(_settings.adminApiKey);
      }
    } catch (e) {
      _errorMessage = 'Failed to load settings: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateBaseUrl(String newUrl) async {
    final cleanUrl = newUrl.trim();
    if (cleanUrl.isEmpty || cleanUrl == _settings.baseUrl) return;

    final updated = _settings.copyWith(baseUrl: cleanUrl);
    await _saveAndNotify(updated);
    if (apiClient != null) {
      apiClient!.updateBaseUrl(cleanUrl);
    }
  }

  Future<void> updateClientApiKey(String newKey) async {
    final cleanKey = newKey.trim();
    if (cleanKey == _settings.clientApiKey) return;

    final updated = _settings.copyWith(clientApiKey: cleanKey);
    await _saveAndNotify(updated);
    if (apiClient != null) {
      apiClient!.updateClientApiKey(cleanKey);
    }
  }

  Future<void> updateAdminApiKey(String newKey) async {
    final cleanKey = newKey.trim();
    if (cleanKey == _settings.adminApiKey) return;

    final updated = _settings.copyWith(adminApiKey: cleanKey);
    await _saveAndNotify(updated);
    if (apiClient != null) {
      apiClient!.updateAdminApiKey(cleanKey);
    }
  }

  Future<void> updateDefaultQuestionCounts({
    int? mcq,
    int? short,
    int? long,
  }) async {
    final updated = _settings.copyWith(
      defaultMcqCount: mcq ?? _settings.defaultMcqCount,
      defaultShortCount: short ?? _settings.defaultShortCount,
      defaultLongCount: long ?? _settings.defaultLongCount,
    );
    await _saveAndNotify(updated);
  }

  Future<void> toggleIncludeAnswerKey(bool value) async {
    final updated = _settings.copyWith(includeAnswerKey: value);
    await _saveAndNotify(updated);
  }

  Future<void> toggleTelemetry(bool value) async {
    final updated = _settings.copyWith(enableTelemetry: value);
    await _saveAndNotify(updated);
  }

  Future<void> toggleDarkMode(bool value) async {
    final updated = _settings.copyWith(isDarkMode: value);
    await _saveAndNotify(updated);
  }

  Future<void> toggleDebugLogs(bool value) async {
    final updated = _settings.copyWith(enableDebugLogs: value);
    await _saveAndNotify(updated);
  }

  Future<Map<String, dynamic>> testConnection([String? targetUrl]) async {
    final url = (targetUrl ?? _settings.baseUrl).trim();
    if (apiClient != null) {
      return await apiClient!.checkHealth(overrideBaseUrl: url);
    }
    final client = ApiClient(baseUrl: url);
    return await client.checkHealth();
  }

  Future<void> resetToDefaults() async {
    try {
      await settingsRepository.resetSettings();
      _settings = const SettingsModel();
      if (apiClient != null) {
        apiClient!.updateBaseUrl(_settings.baseUrl);
        apiClient!.updateClientApiKey(_settings.clientApiKey);
        apiClient!.updateAdminApiKey(_settings.adminApiKey);
      }
    } catch (e) {
      _errorMessage = 'Failed to reset settings: ${e.toString()}';
    } finally {
      notifyListeners();
    }
  }

  Future<void> _saveAndNotify(SettingsModel newSettings) async {
    _settings = newSettings;
    try {
      await settingsRepository.saveSettings(newSettings);
    } catch (e) {
      _errorMessage = 'Failed to save settings: ${e.toString()}';
    } finally {
      notifyListeners();
    }
  }
}
