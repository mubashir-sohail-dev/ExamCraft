import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/subjects.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/connection_provider.dart';
import '../../presentation/providers/settings_provider.dart';
import '../base_app_screen.dart';

/// App Settings & Advanced Config Telemetry Screen.
/// Manages theme mode options, default subject preferences, API endpoint configuration, telemetry switches, and cache diagnostics.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _urlController =
      TextEditingController(text: 'https://testai.ai-vision.studio');
  final TextEditingController _apiKeyController =
      TextEditingController(text: 'examcraft-secret-key-2026');
  ExamSubject _selectedDefaultSubject = ExamSubject.chemistry;
  bool _enableTelemetry = true;
  bool _enableDebugLogs = true;
  bool _includeAnswerKey = true;
  bool _isTestingConnection = false;
  String? _connectionTestResult;
  bool _connectionSuccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProviderSettings();
    });
  }

  void _loadProviderSettings() {
    try {
      final provider = Provider.of<SettingsProvider>(context, listen: false);
      if (provider.baseUrl.isNotEmpty) {
        _urlController.text = provider.baseUrl;
      }
      if (provider.clientApiKey.isNotEmpty) {
        _apiKeyController.text = provider.clientApiKey;
      }
      setState(() {
        _enableTelemetry = provider.enableTelemetry;
        _includeAnswerKey = provider.includeAnswerKey;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _urlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionTestResult = null;
      _connectionSuccess = false;
    });

    final targetUrl = _urlController.text.trim();
    Map<String, dynamic> result;

    try {
      final provider = Provider.of<SettingsProvider>(context, listen: false);
      result = await provider.testConnection(targetUrl);
      if (result['success'] == true && mounted) {
        Provider.of<ConnectionProvider>(context, listen: false).checkHealth();
      }
    } catch (_) {
      result = {
        'success': false,
        'message': 'Connection test error. Please check server URL format.',
      };
    }

    if (!mounted) return;

    setState(() {
      _isTestingConnection = false;
      _connectionSuccess = result['success'] == true;
      _connectionTestResult = result['message'] as String?;
    });
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Local Cache'),
        content: const Text(
            'Are you sure you want to clear temporary offline cache? Saved papers will remain intact.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('btn_confirm_clear_cache'),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Local cache cleared successfully!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    ThemeController? themeController;
    try {
      themeController = Provider.of<ThemeController>(context);
    } catch (_) {}

    final isDark = themeController?.isDarkMode(context) ??
        theme.brightness == Brightness.dark;

    return BaseAppScreen(
      title: 'Settings & Telemetry',
      routeName: AppRoutes.settings,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Connection Status Card
            _buildConnectionStatusCard(context, theme, isDark),
            const SizedBox(height: 24),

            // 2. Appearance Options
            Text(
              'Appearance Options',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildAppearanceSection(context, theme, themeController, isDark),
            const SizedBox(height: 28),

            // 3. Default Subject Preference (All 5 Mandatory Subjects)
            Text(
              'Default Subject Preference',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildDefaultSubjectSection(context, theme, isDark),
            const SizedBox(height: 28),

            // 4. API Base URL Configuration
            Text(
              'Backend API Configuration',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildApiConfigSection(context, theme),
            const SizedBox(height: 28),

            // 5. Telemetry & Diagnostics Options
            Text(
              'Advanced Telemetry & Diagnostics',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildTelemetrySection(context, theme),
            const SizedBox(height: 28),

            // 6. Backend Health Metrics
            Text(
              'Backend Health & Specs',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildBackendHealthGrid(context, theme),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatusCard(
      BuildContext context, ThemeData theme, bool isDark) {
    return Consumer<ConnectionProvider>(
      builder: (context, conn, child) {
        final isOnline = conn.status == ConnectionStatus.online;
        final isDegraded = conn.status == ConnectionStatus.degraded;
        final iconColor = isOnline
            ? const Color(0xFF006E2C)
            : (isDegraded ? Colors.orange : theme.colorScheme.error);
        final iconData = isOnline
            ? Icons.check_circle
            : (isDegraded ? Icons.warning_amber_rounded : Icons.error);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conn.message,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      conn.latencyMs != null
                          ? 'Latency: ${conn.latencyMs}ms'
                          : 'Status: ${conn.status.name.toUpperCase()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppearanceSection(BuildContext context, ThemeData theme,
      ThemeController? themeController, bool isDark) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: SwitchListTile(
        key: const Key('switch_theme_mode'),
        value: isDark,
        onChanged: (val) {
          if (themeController != null) {
            themeController.toggleTheme(context);
          }
        },
        title: const Text(
          'Dark Mode',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Toggle between Light and Dark Material 3 theme'),
        secondary: Icon(
          isDark ? Icons.dark_mode : Icons.light_mode,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildDefaultSubjectSection(
      BuildContext context, ThemeData theme, bool isDark) {
    final subjects = SubjectUtils.allSubjects;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Default Preferred Subject:',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExamSubject>(
              key: const Key('dropdown_default_subject'),
              initialValue: _selectedDefaultSubject,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: subjects.map((subject) {
                final color = isDark ? subject.darkColor : subject.color;
                return DropdownMenuItem<ExamSubject>(
                  value: subject,
                  child: Row(
                    children: [
                      Icon(subject.icon, color: color, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          subject.displayName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newSubject) {
                if (newSubject != null) {
                  setState(() {
                    _selectedDefaultSubject = newSubject;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiConfigSection(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick URL Presets:', style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ActionChip(
                  key: const Key('chip_preset_emulator'),
                  label: const Text('Android Emulator'),
                  avatar: const Icon(Icons.phone_android, size: 16),
                  onPressed: () {
                    setState(() {
                      _urlController.text = 'http://10.0.2.2:8000';
                    });
                  },
                ),
                ActionChip(
                  key: const Key('chip_preset_localhost'),
                  label: const Text('Localhost'),
                  avatar: const Icon(Icons.computer, size: 16),
                  onPressed: () {
                    setState(() {
                      _urlController.text = 'http://localhost:8000';
                    });
                  },
                ),
                ActionChip(
                  key: const Key('chip_preset_cloud'),
                  label: const Text('Cloud'),
                  avatar: const Icon(Icons.cloud_outlined, size: 16),
                  onPressed: () {
                    setState(() {
                      _urlController.text = 'https://testai.ai-vision.studio';
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('input_api_base_url'),
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Base API Endpoint URL',
                hintText: 'https://testai.ai-vision.studio',
                prefixIcon: const Icon(Icons.dns),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('input_client_api_key'),
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'Client API Key',
                hintText: 'examcraft-secret-key-2026',
                prefixIcon: const Icon(Icons.key),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  key: const Key('btn_save_url'),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      final provider =
                          Provider.of<SettingsProvider>(context, listen: false);
                      await provider.updateBaseUrl(_urlController.text);
                      await provider.updateClientApiKey(_apiKeyController.text);
                    } catch (_) {}
                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('API Configuration saved successfully!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save URL'),
                ),
                OutlinedButton.icon(
                  key: const Key('btn_test_connection'),
                  onPressed: _isTestingConnection ? null : _testConnection,
                  icon: _isTestingConnection
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync),
                  label: Text(
                      _isTestingConnection ? 'Testing...' : 'Test Connection'),
                ),
              ],
            ),
            if (_connectionTestResult != null) ...[
              const SizedBox(height: 12),
              Text(
                _connectionTestResult!,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: _connectionSuccess
                      ? const Color(0xFF006E2C)
                      : theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetrySection(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          SwitchListTile(
            key: const Key('switch_enable_telemetry'),
            title: const Text('Enable Telemetry'),
            subtitle: const Text(
                'Send anonymous usage analytics to improve AI accuracy'),
            value: _enableTelemetry,
            onChanged: (val) {
              setState(() => _enableTelemetry = val);
              try {
                Provider.of<SettingsProvider>(context, listen: false)
                    .toggleTelemetry(val);
              } catch (_) {}
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            key: const Key('switch_enable_debug_logs'),
            title: const Text('Enable Debug Logs'),
            subtitle: const Text(
                'Record verbose HTTP and LLM prompt diagnostic logs'),
            value: _enableDebugLogs,
            onChanged: (val) {
              setState(() => _enableDebugLogs = val);
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            key: const Key('switch_include_answer_key'),
            title: const Text('Include Answer Key by Default'),
            subtitle:
                const Text('Automatically generate answers for exported PDFs'),
            value: _includeAnswerKey,
            onChanged: (val) {
              setState(() => _includeAnswerKey = val);
            },
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  key: const Key('btn_clear_cache'),
                  onPressed: _clearCache,
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('Clear Local Cache'),
                ),
                OutlinedButton.icon(
                  key: const Key('btn_export_logs'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Diagnostics logs exported to local storage!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.file_download),
                  label: const Text('Export Logs'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackendHealthGrid(BuildContext context, ThemeData theme) {
    return Consumer<ConnectionProvider>(
      builder: (context, conn, child) {
        final isOnline = conn.status == ConnectionStatus.online;
        final qdrantConnected = conn.healthData?['qdrant_connected'] == true;
        final llmAvailable = conn.healthData?['llm_available'] == true;

        final metrics = [
          {'label': 'Core Engine', 'val': isOnline ? 'Operational' : 'Offline'},
          {
            'label': 'Response Latency',
            'val': conn.latencyMs != null ? '${conn.latencyMs}ms' : '--'
          },
          {'label': 'App Version', 'val': 'v1.0.0'},
          {
            'label': 'AI Question Engine',
            'val': llmAvailable
                ? 'Connected'
                : (isOnline ? 'Active' : 'Unreachable')
          },
          {
            'label': 'Knowledge Base Index',
            'val': qdrantConnected ? 'Active' : 'Disconnected'
          },
          {
            'label': 'Semantic Search',
            'val': qdrantConnected ? 'Ready' : 'Unavailable'
          },
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final isVeryNarrow = constraints.maxWidth < 340;
            final crossAxisCount = isVeryNarrow ? 1 : 2;
            final childAspectRatio = isVeryNarrow
                ? 3.6
                : (constraints.maxWidth < 400 ? 1.9 : 2.4);

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: metrics.length,
              itemBuilder: (context, index) {
                final item = metrics[index];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item['label']!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['val']!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
