/// Advanced telemetry and application configuration options model.
class SettingsModel {
  final String baseUrl;
  final String clientApiKey;
  final int defaultMcqCount;
  final int defaultShortCount;
  final int defaultLongCount;
  final bool includeAnswerKey;
  final bool enableTelemetry;
  final bool enableDebugLogs;
  final bool isDarkMode;
  final int maxContextChars;

  const SettingsModel({
    this.baseUrl = 'https://testai.ai-vision.studio',
    this.clientApiKey = 'examcraft-secret-key-2026',
    this.defaultMcqCount = 5,
    this.defaultShortCount = 3,
    this.defaultLongCount = 1,
    this.includeAnswerKey = true,
    this.enableTelemetry = true,
    this.enableDebugLogs = true,
    this.isDarkMode = false,
    this.maxContextChars = 30000,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      baseUrl: json['base_url'] as String? ?? 'https://testai.ai-vision.studio',
      clientApiKey:
          json['client_api_key'] as String? ?? 'examcraft-secret-key-2026',
      defaultMcqCount: json['default_mcq_count'] as int? ?? 5,
      defaultShortCount: json['default_short_count'] as int? ?? 3,
      defaultLongCount: json['default_long_count'] as int? ?? 1,
      includeAnswerKey: json['include_answer_key'] as bool? ?? true,
      enableTelemetry: json['enable_telemetry'] as bool? ?? true,
      enableDebugLogs: json['enable_debug_logs'] as bool? ?? true,
      isDarkMode: json['is_dark_mode'] as bool? ?? false,
      maxContextChars: json['max_context_chars'] as int? ?? 30000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'base_url': baseUrl,
      'client_api_key': clientApiKey,
      'default_mcq_count': defaultMcqCount,
      'default_short_count': defaultShortCount,
      'default_long_count': defaultLongCount,
      'include_answer_key': includeAnswerKey,
      'enable_telemetry': enableTelemetry,
      'enable_debug_logs': enableDebugLogs,
      'is_dark_mode': isDarkMode,
      'max_context_chars': maxContextChars,
    };
  }

  SettingsModel copyWith({
    String? baseUrl,
    String? clientApiKey,
    int? defaultMcqCount,
    int? defaultShortCount,
    int? defaultLongCount,
    bool? includeAnswerKey,
    bool? enableTelemetry,
    bool? enableDebugLogs,
    bool? isDarkMode,
    int? maxContextChars,
  }) {
    return SettingsModel(
      baseUrl: baseUrl ?? this.baseUrl,
      clientApiKey: clientApiKey ?? this.clientApiKey,
      defaultMcqCount: defaultMcqCount ?? this.defaultMcqCount,
      defaultShortCount: defaultShortCount ?? this.defaultShortCount,
      defaultLongCount: defaultLongCount ?? this.defaultLongCount,
      includeAnswerKey: includeAnswerKey ?? this.includeAnswerKey,
      enableTelemetry: enableTelemetry ?? this.enableTelemetry,
      enableDebugLogs: enableDebugLogs ?? this.enableDebugLogs,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      maxContextChars: maxContextChars ?? this.maxContextChars,
    );
  }
}
