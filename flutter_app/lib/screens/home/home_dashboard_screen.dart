import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/subjects.dart';
import '../../core/routes/app_routes.dart';
import '../../presentation/providers/assessment_provider.dart';
import '../../presentation/providers/connection_provider.dart';
import '../../presentation/providers/question_bank_provider.dart';
import '../../presentation/providers/recent_papers_provider.dart';
import '../../presentation/providers/upload_provider.dart';
import '../base_app_screen.dart';

/// Home Dashboard - Advanced Overview Screen.
/// Displays system health, performance metrics, and subject usage distribution across all 5 mandatory subjects.
class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BaseAppScreen(
      title: 'Dashboard Overview',
      routeName: AppRoutes.homeOverview,
      floatingActionButton: SafeArea(
        minimum: const EdgeInsets.all(16.0),
        child: FloatingActionButton.extended(
          key: const Key('home_dashboard_fab_generate'),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.generate),
          icon: const Icon(Icons.add_circle_outline, size: 24),
          label: Text(
            'Generate Assessment',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          elevation: 3.0,
          highlightElevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          extendedPadding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final conn = Provider.of<ConnectionProvider>(context, listen: false);
          final recent =
              Provider.of<RecentPapersProvider>(context, listen: false);
          final questionBank =
              Provider.of<QuestionBankProvider>(context, listen: false);
          final upload = Provider.of<UploadProvider>(context, listen: false);
          await Future.wait([
            conn.checkHealth(),
            recent.loadRecentPapers(),
            questionBank.fetchQuestions(),
            upload.loadUploadedTextbooks(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Live Backend Telemetry Pill Banner
              _buildBackendHealthBanner(context, theme, isDark),
              const SizedBox(height: 20),

              // 2. Headline Title
              Text(
                'Performance Metrics',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // 3. Performance Metrics Cards (Total Assessments, Question Bank, 5 Subjects, System Health)
              _buildPerformanceMetricsCards(context, theme),
              const SizedBox(height: 28),

              // 4. Subject Usage Distribution Across All 5 Mandatory Subjects
              Text(
                'Subject Usage Distribution',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Breakdown across all 5 mandatory curriculum subjects',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              _buildSubjectUsageDistribution(context, theme, isDark),
              const SizedBox(height: 28),

              // 5. System Health & Infrastructure Diagnostics
              Text(
                'System Health & Telemetry',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildSystemHealthBreakdown(context, theme),
              const SizedBox(height: 28),

              // 6. Recent System Activity Log
              _buildRecentActivityLog(context, theme),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackendHealthBanner(
      BuildContext context, ThemeData theme, bool isDark) {
    return Consumer<ConnectionProvider>(
      builder: (context, conn, child) {
        String statusText;
        Color statusColor;
        switch (conn.status) {
          case ConnectionStatus.online:
            statusText = 'Server Status: Operational';
            statusColor = const Color(0xFF006E2C);
            break;
          case ConnectionStatus.degraded:
            statusText = 'Server Status: Degraded';
            statusColor = Colors.orange;
            break;
          case ConnectionStatus.checking:
            statusText = 'Server Status: Checking...';
            statusColor = Colors.blue;
            break;
          case ConnectionStatus.offline:
            statusText = 'Server Status: Unreachable';
            statusColor = theme.colorScheme.error;
            break;
        }

        final latencyText = conn.latencyMs != null
            ? 'Latency: ${conn.latencyMs}ms'
            : 'Latency: --';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                statusText,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                latencyText,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPerformanceMetricsCards(BuildContext context, ThemeData theme) {
    RecentPapersProvider? papersProvider;
    QuestionBankProvider? qbProvider;
    AssessmentProvider? assessProvider;
    ConnectionProvider? connProvider;

    try {
      papersProvider = Provider.of<RecentPapersProvider>(context);
      qbProvider = Provider.of<QuestionBankProvider>(context);
      assessProvider = Provider.of<AssessmentProvider>(context);
      connProvider = Provider.of<ConnectionProvider>(context);
    } catch (_) {}

    final totalPapers = papersProvider?.papers.length ?? 0;
    final totalQuestions = qbProvider?.totalCount ?? 0;
    final activeSubjectsCount = assessProvider?.supportedSubjects.length ?? 5;
    final healthVal = (connProvider?.status == ConnectionStatus.online)
        ? (connProvider?.latencyMs != null
            ? '100% (${connProvider?.latencyMs}ms)'
            : '100%')
        : (connProvider?.status == ConnectionStatus.degraded
            ? 'Degraded'
            : 'Offline');

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildMetricTile(
          context: context,
          key: const Key('metric_total_assessments'),
          title: 'Total Assessments',
          value: totalPapers.toString(),
          subtitle: 'Generated Papers',
          icon: Icons.article_outlined,
          color: theme.colorScheme.primary,
        ),
        _buildMetricTile(
          context: context,
          key: const Key('metric_question_bank'),
          title: 'Question Bank Count',
          value: totalQuestions.toString(),
          subtitle: 'Indexed Items',
          icon: Icons.storage_outlined,
          color: const Color(0xFF006E2C),
        ),
        _buildMetricTile(
          context: context,
          key: const Key('metric_active_subjects'),
          title: 'Active Subjects',
          value: activeSubjectsCount.toString(),
          subtitle: 'Mandatory Domains',
          icon: Icons.collections_bookmark_outlined,
          color: const Color(0xFF805600),
        ),
        _buildMetricTile(
          context: context,
          key: const Key('metric_system_health'),
          title: 'System Health',
          value: healthVal,
          subtitle: 'Uptime & Reliability',
          icon: Icons.monitor_heart_outlined,
          color: const Color(0xFF673AB7),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required BuildContext context,
    required Key key,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      key: key,
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectUsageDistribution(
      BuildContext context, ThemeData theme, bool isDark) {
    RecentPapersProvider? papersProvider;
    try {
      papersProvider = Provider.of<RecentPapersProvider>(context);
    } catch (_) {}

    final papers = papersProvider?.papers ?? [];
    final totalCount = papers.length;

    final subjects = [
      ExamSubject.physics,
      ExamSubject.chemistry,
      ExamSubject.mathematics,
      ExamSubject.biology,
      ExamSubject.computerScience,
    ];

    return Card(
      key: const Key('subject_usage_distribution_card'),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: subjects.map((subject) {
            final count = papers
                .where((p) => p.subject.apiString == subject.apiString)
                .length;
            final percentage = totalCount > 0 ? (count / totalCount) : 0.0;
            final color = isDark ? subject.darkColor : subject.color;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(subject.icon, color: color, size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                subject.displayName,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$count Papers (${(percentage * 100).toInt()}%)',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 8,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSystemHealthBreakdown(BuildContext context, ThemeData theme) {
    ConnectionProvider? conn;
    UploadProvider? upload;
    try {
      conn = Provider.of<ConnectionProvider>(context);
      upload = Provider.of<UploadProvider>(context);
    } catch (_) {}

    final isOnline = conn?.status == ConnectionStatus.online;
    final qdrantConnected = conn?.healthData?['qdrant_connected'] == true;
    final llmAvailable = conn?.healthData?['llm_available'] == true;
    final indexedTextbooksCount = upload?.uploadedTextbooks.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          _buildHealthRow(
            context,
            theme,
            label: 'Core Engine Endpoint',
            status: isOnline ? 'Operational' : 'Offline',
            detail: isOnline
                ? 'Server Active (${conn?.latencyMs ?? 0}ms)'
                : 'Backend Unreachable',
            isSuccess: isOnline,
          ),
          const Divider(height: 16),
          _buildHealthRow(
            context,
            theme,
            label: 'Knowledge Base Index',
            status: qdrantConnected ? 'Active' : 'Disconnected',
            detail: qdrantConnected
                ? '$indexedTextbooksCount Uploaded Textbooks'
                : 'Qdrant Collection Offline',
            isSuccess: qdrantConnected,
          ),
          const Divider(height: 16),
          _buildHealthRow(
            context,
            theme,
            label: 'AI Question Engine',
            status: isOnline ? 'Connected' : 'Disconnected',
            detail: isOnline
                ? (llmAvailable ? 'Multimodal LLM Ready' : 'Service Healthy')
                : 'AI Engine Unreachable',
            isSuccess: isOnline,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthRow(
    BuildContext context,
    ThemeData theme, {
    required String label,
    required String status,
    required String detail,
    required bool isSuccess,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              detail,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSuccess
                ? const Color(0xFF006E2C).withValues(alpha: 0.1)
                : theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isSuccess
                  ? const Color(0xFF006E2C)
                  : theme.colorScheme.onErrorContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivityLog(BuildContext context, ThemeData theme) {
    RecentPapersProvider? papersProvider;
    UploadProvider? uploadProvider;
    try {
      papersProvider = Provider.of<RecentPapersProvider>(context);
      uploadProvider = Provider.of<UploadProvider>(context);
    } catch (_) {}

    final papers = papersProvider?.papers ?? [];
    final uploads = uploadProvider?.uploadedTextbooks ?? [];

    final List<Map<String, dynamic>> activities = [];

    for (final p in papers.take(3)) {
      activities.add({
        'title': 'Generated ${p.title}',
        'subtitle': '${p.subject.displayName} • ${p.chapterOrTopic}',
        'icon': Icons.auto_awesome,
        'color': p.subject.color,
      });
    }

    for (final u in uploads.take(2)) {
      activities.add({
        'title': 'Indexed ${u['filename'] ?? 'Textbook.pdf'}',
        'subtitle': '${u['subject'] ?? 'General'} • Grade ${u['grade'] ?? 9}',
        'icon': Icons.upload_file,
        'color': const Color(0xFF006E2C),
      });
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent System Audit & Activity',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (activities.isNotEmpty)
            ...activities.map((act) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (act['color'] as Color).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        act['icon'] as IconData,
                        color: act['color'] as Color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            act['title'] as String,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            act['subtitle'] as String,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            })
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'No recent activity recorded.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
