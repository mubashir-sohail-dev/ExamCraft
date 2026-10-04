import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../presentation/providers/connection_provider.dart';
import '../base_app_screen.dart';

/// About Screen & Application Version 1.0.0 Information.
/// Displays branding, version specs, system health check trigger, core technologies, and legal links.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool _isCheckingHealth = false;

  Future<void> _runHealthCheck() async {
    setState(() {
      _isCheckingHealth = true;
    });

    try {
      final provider = Provider.of<ConnectionProvider>(context, listen: false);
      await provider.checkHealth();
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _isCheckingHealth = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BaseAppScreen(
      title: 'About ExamCraft AI',
      routeName: AppRoutes.about,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),

            // 1. App Branding Hero Header
            _buildHeroHeader(context, theme),
            const SizedBox(height: 24),

            // 2. Application Description Card
            _buildDescriptionCard(context, theme),
            const SizedBox(height: 24),

            // 3. Live Backend Health Check Trigger Button
            _buildHealthCheckCard(context, theme),
            const SizedBox(height: 28),

            // 4. Core Technologies Grid
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Core Technologies',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildTechnologiesGrid(context, theme),
            const SizedBox(height: 28),

            // 5. System Specifications Card
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'System Specifications',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildSpecsCard(context, theme),
            const SizedBox(height: 28),

            // 6. Links & Legal Section
            _buildLinksSection(context, theme),
            const SizedBox(height: 32),

            // 7. Footer Credits
            Text(
              '© 2024 ExamCraft AI Labs. All rights reserved.\nBuilt with ❤ for Educators worldwide.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.auto_awesome,
            color: theme.colorScheme.onPrimaryContainer,
            size: 44,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'ExamCraft AI',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'AI Assessment Builder for Educators',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Version 1.0.0 (Production Release)',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          'ExamCraft AI empowers teachers and educational institutions to rapidly build customized, high-quality exam papers, quizzes, and assessments using advanced artificial intelligence and RAG textbook indexing.',
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildHealthCheckCard(BuildContext context, ThemeData theme) {
    return Consumer<ConnectionProvider>(
      builder: (context, conn, child) {
        final isOnline = conn.status == ConnectionStatus.online;
        final statusColor = isOnline
            ? const Color(0xFF006E2C)
            : (conn.status == ConnectionStatus.degraded
                ? Colors.orange
                : theme.colorScheme.error);
        final borderColor = isOnline
            ? const Color(0xFF86F898)
            : (conn.status == ConnectionStatus.degraded
                ? Colors.orangeAccent
                : theme.colorScheme.errorContainer);

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.speed,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Backend Connectivity Status',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    key: const Key('btn_health_check'),
                    onPressed: _isCheckingHealth ? null : _runHealthCheck,
                    icon: _isCheckingHealth
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync, size: 18),
                    label:
                        Text(_isCheckingHealth ? 'Pinging...' : 'Check Health'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Icon(isOnline ? Icons.check_circle : Icons.info,
                        color: statusColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        conn.latencyMs != null
                            ? '${conn.message} (${conn.latencyMs}ms)'
                            : conn.message,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildTechnologiesGrid(BuildContext context, ThemeData theme) {
    final techList = [
      {
        'title': 'Core Service',
        'desc': 'High-performance assessment generation engine',
        'icon': Icons.api,
      },
      {
        'title': 'Knowledge Base',
        'desc': 'Semantic textbook indexing & context retrieval engine',
        'icon': Icons.storage,
      },
      {
        'title': 'AI Question Engine',
        'desc': 'Multimodal AI model for reasoning and test generation',
        'icon': Icons.auto_awesome,
      },
      {
        'title': 'ExamCraft AI UI Framework',
        'desc': 'Cross-platform native toolkit for responsive user interfaces',
        'icon': Icons.layers,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isVeryNarrow = constraints.maxWidth < 360;
        final isWide = constraints.maxWidth > 500;
        final crossAxisCount = isWide ? 4 : (isVeryNarrow ? 1 : 2);
        final childAspectRatio = isVeryNarrow ? 3.0 : (isWide ? 1.4 : 1.05);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
      itemCount: techList.length,
      itemBuilder: (context, index) {
        final tech = techList[index];
        return Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  tech['icon'] as IconData,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tech['title'] as String,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tech['desc'] as String,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
      },
    );
  }

  Widget _buildSpecsCard(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          _buildSpecRow(theme, 'Application Version', '1.0.0+1'),
          const Divider(height: 16),
          _buildSpecRow(theme, 'Build Variant', 'Production Release'),
          const Divider(height: 16),
          _buildSpecRow(theme, 'Flutter SDK', '>=3.10.0'),
          const Divider(height: 16),
          _buildSpecRow(
              theme, 'Document Processing', 'Active Context Indexing'),
        ],
      ),
    );
  }

  Widget _buildSpecRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLinksSection(BuildContext context, ThemeData theme) {
    final links = [
      {'title': 'Documentation & User Guide', 'icon': Icons.menu_book},
      {'title': 'Report an Issue', 'icon': Icons.bug_report},
      {'title': 'Privacy Policy', 'icon': Icons.privacy_tip},
      {'title': 'Terms of Service', 'icon': Icons.gavel},
      {'title': 'Contact Support', 'icon': Icons.mail_outline},
    ];

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: links.map((link) {
          return ListTile(
            leading: Icon(
              link['icon'] as IconData,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            title: Text(
              link['title'] as String,
              style: theme.textTheme.bodyMedium,
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Opening ${link['title']}...'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
