import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/subjects.dart';
import '../../core/routes/app_routes.dart';
import '../../data/models/recent_papers_model.dart';
import '../../presentation/providers/assessment_provider.dart';
import '../../presentation/providers/connection_provider.dart';
import '../../presentation/providers/question_bank_provider.dart';
import '../../presentation/providers/recent_papers_provider.dart';
import '../base_app_screen.dart';

/// Main Home Screen of ExamCraft AI.
/// Provides subject selection grid, quick actions, performance overview, and recent activity.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('[HomeScreen] build() called - context=$context');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Debug: check provider states
    try {
      final rp = Provider.of<RecentPapersProvider>(context, listen: false);
      final ap = Provider.of<AssessmentProvider>(context, listen: false);
      final cp = Provider.of<ConnectionProvider>(context, listen: false);
      final qb = Provider.of<QuestionBankProvider>(context, listen: false);
      debugPrint(
          '[HomeScreen] Providers OK: papers=${rp.papers.length}, assessStatus=${ap.status}, connStatus=${cp.status}, qbCount=${qb.totalCount}');
    } catch (e) {
      debugPrint('[HomeScreen] ERROR accessing providers: $e');
    }

    return BaseAppScreen(
      title: 'ExamCraft AI',
      routeName: AppRoutes.home,
      actions: [
        // Live Backend Connectivity Pill in Header
        Consumer<ConnectionProvider>(
          builder: (context, conn, child) {
            Color statusColor;
            Color bgColor;
            Color borderColor;
            Color textColor;
            String statusText;

            switch (conn.status) {
              case ConnectionStatus.online:
                statusColor = const Color(0xFF006E2C);
                bgColor =
                    isDark ? const Color(0xFF003915) : const Color(0xFFE8F5E9);
                borderColor =
                    isDark ? const Color(0xFF006E2C) : const Color(0xFF86F898);
                textColor =
                    isDark ? const Color(0xFF86F898) : const Color(0xFF005320);
                statusText = conn.latencyMs != null
                    ? 'Connected (${conn.latencyMs}ms)'
                    : 'Connected';
                break;
              case ConnectionStatus.degraded:
                statusColor = Colors.orange;
                bgColor =
                    isDark ? const Color(0xFF3E2723) : const Color(0xFFFFF3E0);
                borderColor = Colors.orange;
                textColor =
                    isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100);
                statusText = 'Degraded';
                break;
              case ConnectionStatus.checking:
                statusColor = Colors.blue;
                bgColor =
                    isDark ? const Color(0xFF0D47A1) : const Color(0xFFE3F2FD);
                borderColor = Colors.blue;
                textColor =
                    isDark ? const Color(0xFF90CAF9) : const Color(0xFF1565C0);
                statusText = 'Checking...';
                break;
              case ConnectionStatus.offline:
                statusColor = theme.colorScheme.error;
                bgColor = theme.colorScheme.errorContainer;
                borderColor = theme.colorScheme.error;
                textColor = theme.colorScheme.onErrorContainer;
                statusText = 'Offline';
                break;
            }

            return Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
      floatingActionButton: SafeArea(
        minimum: const EdgeInsets.all(16.0),
        child: FloatingActionButton.extended(
          key: const Key('home_fab_generate'),
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
          final assess =
              Provider.of<AssessmentProvider>(context, listen: false);
          await Future.wait([
            conn.checkHealth(),
            recent.loadRecentPapers(),
            assess.fetchSupportedSubjects(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Banner Section
              _buildHeroBanner(context, theme),
              const SizedBox(height: 24),

              // 2. Stats Summary Cards
              _buildStatsGrid(context, theme),
              const SizedBox(height: 28),

              // 3. Subject Selection Grid (All 5 Mandatory Subjects)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Subject',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '5 Mandatory Subjects',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSubjectGrid(context, theme),
              const SizedBox(height: 28),

              // 4. Quick Actions Row
              Text(
                'Quick Actions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildQuickActions(context, theme),
              const SizedBox(height: 28),

              // 5. Recent Activity & Drafts
              _buildRecentActivitySection(context, theme),
              const SizedBox(height: 28),

              // 6. Multimodal Vision Model Feature Banner
              _buildMultimodalFeatureCard(context, theme),
              const SizedBox(height: 80), // Padding for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Welcome back, Professor',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Efficiency meets AI. Start creating sophisticated assessments from your textbooks in seconds.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                key: const Key('hero_btn_generate'),
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.generate),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate Assessment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                  foregroundColor: theme.colorScheme.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              OutlinedButton.icon(
                key: const Key('hero_btn_upload'),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.upload),
                icon: const Icon(Icons.cloud_upload_outlined,
                    color: Colors.white),
                label: const Text(
                  'Upload Textbook',
                  style: TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, ThemeData theme) {
    RecentPapersProvider? papersProvider;
    AssessmentProvider? assessmentProvider;
    QuestionBankProvider? questionBankProvider;
    try {
      papersProvider = Provider.of<RecentPapersProvider>(context);
      assessmentProvider = Provider.of<AssessmentProvider>(context);
      questionBankProvider = Provider.of<QuestionBankProvider>(context);
    } catch (_) {}

    final validPapers = papersProvider?.papers ?? [];
    final papersCount = validPapers.length;
    final textbooksCount = validPapers.isNotEmpty
        ? validPapers.map((p) => p.subject).toSet().length
        : 0;
    final subjectsCount = assessmentProvider?.supportedSubjects.length ?? 5;
    final questionsCount = questionBankProvider?.totalCount ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final crossAxisCount =
            isWide ? 4 : (constraints.maxWidth > 450 ? 2 : 1);
        final aspectRatio = isWide ? 2.5 : (crossAxisCount == 2 ? 2.3 : 3.0);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: aspectRatio,
          children: [
            _buildStatCard(
              context: context,
              title: 'Total Classes',
              value: textbooksCount.toString(),
              icon: Icons.auto_stories,
              color: theme.colorScheme.primary,
            ),
            _buildStatCard(
              context: context,
              title: 'Active Subjects',
              value: subjectsCount.toString(),
              icon: Icons.collections_bookmark,
              color: const Color(0xFF006E2C),
            ),
            _buildStatCard(
              context: context,
              title: 'Generated Papers',
              value: papersCount.toString(),
              icon: Icons.history_edu,
              color: const Color(0xFF805600),
            ),
            _buildStatCard(
              context: context,
              title: 'Question Bank',
              value: questionsCount.toString(),
              icon: Icons.psychology_alt,
              color: const Color(0xFF9C27B0),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectGrid(BuildContext context, ThemeData theme) {
    final subjects = SubjectUtils.allSubjects;
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        double childAspectRatio = 1.35;

        if (constraints.maxWidth >= 900) {
          crossAxisCount = 3;
          childAspectRatio = 1.6;
        } else if (constraints.maxWidth >= 600) {
          crossAxisCount = 3;
          childAspectRatio = 1.45;
        } else if (constraints.maxWidth < 380) {
          childAspectRatio = 1.20;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            final subject = subjects[index];
            final color = isDark ? subject.darkColor : subject.color;

            return InkWell(
              key: Key('subject_grid_item_${subject.apiString.toLowerCase()}'),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '${AppRoutes.generate}?subject=${subject.apiString}',
                  arguments: {'subject': subject.apiString},
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: color.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(subject.icon, color: color, size: 24),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: color.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            subject.displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subject.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
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

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildActionTile(
            context: context,
            key: const Key('quick_action_question_bank'),
            title: 'Question Bank',
            icon: Icons.storage_outlined,
            route: AppRoutes.questionBank,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionTile(
            context: context,
            key: const Key('quick_action_recent_papers'),
            title: 'Recent Papers',
            icon: Icons.history,
            route: AppRoutes.recentPapers,
            color: const Color(0xFF006E2C),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required Key key,
    required String title,
    required IconData icon,
    required String route,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      key: key,
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(BuildContext context, ThemeData theme) {
    RecentPapersProvider? papersProvider;
    try {
      papersProvider = Provider.of<RecentPapersProvider>(context);
    } catch (_) {}

    final papers = papersProvider?.papers ?? [];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Papers & Activity',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.recentPapers),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (papers.isNotEmpty)
            ...papers
                .take(3)
                .map((paper) => _buildPaperRow(context, theme, paper))
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 48,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No assessments yet.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upload your first textbook to get started.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.upload),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload your first textbook'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaperRow(
      BuildContext context, ThemeData theme, RecentPaperModel paper) {
    final titleText = paper.title.isNotEmpty ? paper.title : 'Assessment Paper';
    final subjectText = paper.subject.displayName;
    final topicText =
        paper.chapterOrTopic.isNotEmpty ? paper.chapterOrTopic : 'General';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.description, color: theme.colorScheme.primary),
      ),
      title: Text(
        titleText,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '$subjectText • $topicText',
        style: theme.textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        try {
          final assessProvider =
              Provider.of<AssessmentProvider>(context, listen: false);
          assessProvider.setTestAssessment(paper.testData);
        } catch (_) {}
        Navigator.pushNamed(context, AppRoutes.review);
      },
    );
  }

  Widget _buildMultimodalFeatureCard(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surfaceContainerHighest,
            theme.colorScheme.surfaceContainerLow,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              color: theme.colorScheme.onPrimaryContainer,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'New Feature',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Multimodal Vision Analysis',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Generate questions directly from diagrams and charts in your textbooks with AI Vision Engine.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
