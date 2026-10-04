import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/subjects.dart';
import '../../core/routes/app_routes.dart';
import '../../presentation/providers/upload_provider.dart';
import '../base_app_screen.dart';

/// Upload & Processing Status Screen (Light & Dark mode support).
/// Displays real-time PDF text extraction and Qdrant vector database indexing status without fake timers.
class UploadStatusScreen extends StatelessWidget {
  const UploadStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final uploadProvider = Provider.of<UploadProvider>(context);

    final filename = uploadProvider.selectedFileName.isNotEmpty
        ? uploadProvider.selectedFileName
        : 'Textbook.pdf';
    final subject = uploadProvider.selectedSubject;
    final isCompleted = uploadProvider.status == UploadStateStatus.success;
    final isError = uploadProvider.status == UploadStateStatus.error;
    final isUploading = uploadProvider.isUploading;
    final progress = uploadProvider.progress;

    return BaseAppScreen(
      title: 'Upload & Processing Status',
      routeName: AppRoutes.uploadStatus,
      body: RefreshIndicator(
        onRefresh: () async {
          await uploadProvider.loadUploadedTextbooks();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Textbook Processing Status',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Real-time PDF processing and textbook indexing pipeline.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // File Info & Progress Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.colorScheme.surfaceContainerLowest
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.picture_as_pdf,
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                filename,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${subject.displayName} • ${isCompleted ? "Indexing Completed" : (isUploading ? "Uploading & Indexing..." : "Ready")}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? const Color(0xFF006E2C)
                                    .withValues(alpha: 0.15)
                                : (isError
                                    ? theme.colorScheme.errorContainer
                                    : theme.colorScheme.primaryContainer),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isCompleted
                                ? 'Completed'
                                : (isError
                                    ? 'Failed'
                                    : '${(progress * 100).toInt()}%'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isCompleted
                                  ? const Color(0xFF006E2C)
                                  : (isError
                                      ? theme.colorScheme.onErrorContainer
                                      : theme.colorScheme.onPrimaryContainer),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: isCompleted ? 1.0 : progress,
                        minHeight: 10,
                        backgroundColor: theme.colorScheme.surfaceContainerHigh,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCompleted
                              ? const Color(0xFF006E2C)
                              : (isError
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats Grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cols = constraints.maxWidth > 600 ? 3 : 1;
                        return GridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            childAspectRatio: cols == 1 ? 4.5 : 2.5,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          children: [
                            _buildStatCard(
                              theme,
                              'STATUS',
                              isCompleted
                                  ? 'Complete'
                                  : (isUploading ? 'Uploading' : 'Idle'),
                              Icons.pages,
                            ),
                            _buildStatCard(
                              theme,
                              'TOTAL TEXTBOOKS',
                              '${uploadProvider.uploadedTextbooks.length}',
                              Icons.grid_view,
                            ),
                            _buildStatCard(
                              theme,
                              'KNOWLEDGE INDEX',
                              isCompleted ? 'Index Active' : 'Ready',
                              Icons.storage,
                              statusColor: isCompleted
                                  ? const Color(0xFF006E2C)
                                  : theme.colorScheme.primary,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Step Timeline Visualization
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Processing Pipeline Steps',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTimelineStep(
                      theme,
                      stepNum: 1,
                      title: 'Select PDF & File Validation',
                      subtitle: 'PDF textbook loaded and validated',
                      isDone:
                          uploadProvider.selectedFile != null || isCompleted,
                    ),
                    _buildTimelineStep(
                      theme,
                      stepNum: 2,
                      title: 'Document Upload to Backend',
                      subtitle: 'Sending PDF stream to FastAPI backend',
                      isDone: isCompleted,
                      isCurrent: isUploading && progress < 0.5,
                    ),
                    _buildTimelineStep(
                      theme,
                      stepNum: 3,
                      title: 'OCR Text Extraction & Chunking',
                      subtitle: 'Extracting content sections via PyMuPDF',
                      isDone: isCompleted,
                      isCurrent: isUploading && progress >= 0.5,
                    ),
                    _buildTimelineStep(
                      theme,
                      stepNum: 4,
                      title: 'Qdrant Knowledge Base Indexing',
                      subtitle:
                          'Embedding text chunks for RAG question generation',
                      isDone: isCompleted,
                      isCurrent: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Success Banner
              if (isCompleted) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006E2C).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF006E2C).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Color(0xFF006E2C), size: 36),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Textbook Successfully Indexed!',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF006E2C),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Content indexed into Qdrant knowledge base for assessment generation.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Action Buttons Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    key: const Key('btn_cancel_status'),
                    onPressed: () => Navigator.pushReplacementNamed(
                        context, AppRoutes.upload),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Upload'),
                  ),
                  ElevatedButton.icon(
                    key: const Key('btn_proceed_generate'),
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.generate),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Proceed to Generate Assessment'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      ThemeData theme, String label, String value, IconData icon,
      {Color? statusColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: statusColor ?? theme.colorScheme.primary, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor ?? theme.colorScheme.onSurface,
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
  }

  Widget _buildTimelineStep(
    ThemeData theme, {
    required int stepNum,
    required String title,
    required String subtitle,
    bool isDone = false,
    bool isCurrent = false,
  }) {
    Color iconColor;
    IconData iconData;

    if (isDone) {
      iconColor = const Color(0xFF006E2C);
      iconData = Icons.check_circle;
    } else if (isCurrent) {
      iconColor = theme.colorScheme.primary;
      iconData = Icons.sync;
    } else {
      iconColor = theme.colorScheme.outline;
      iconData = Icons.radio_button_unchecked;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(iconData, color: iconColor, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: isDone || isCurrent
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isDone || isCurrent
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.outline,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isDone)
            const Text(
              '100%',
              style: TextStyle(
                  color: Color(0xFF006E2C), fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}
