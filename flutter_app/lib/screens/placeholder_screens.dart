import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes/app_routes.dart';
import '../core/theme/app_theme.dart';

export 'home/home_screen.dart';
export 'home/home_dashboard_screen.dart';
export 'about/about_screen.dart';
export 'settings/settings_screen.dart';
export 'upload/upload_textbook_screen.dart';
export 'upload/upload_status_screen.dart';
export 'generate/generate_assessment_screen.dart';
export 'generate/generating_screen.dart';
export 'question_bank/question_bank_screen.dart';
export 'review/review_screen.dart';
export 'recent_papers/recent_papers_screen.dart';
export 'pdf_preview/pdf_preview_screen.dart';

/// Base placeholder screen wrapper providing standard AppBar, Navigation Drawer, and Theme Toggle.
class BaseAppScreen extends StatelessWidget {
  final String title;
  final String routeName;
  final Widget body;

  const BaseAppScreen({
    super.key,
    required this.title,
    required this.routeName,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final theme = Theme.of(context);

    return Scaffold(
      drawerEnableOpenDragGesture: true,
      drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.25,
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: Icon(
              themeController.isDarkMode(context)
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: 'Toggle Light/Dark Theme',
            onPressed: () => themeController.toggleTheme(context),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ExamCraft AI',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Assessment Builder v1.0.0',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            _buildNavItem(
                context, Icons.dashboard, 'Dashboard', AppRoutes.home),
            _buildNavItem(context, Icons.note_add, 'Generate Assessment',
                AppRoutes.generate),
            _buildNavItem(context, Icons.grid_view, 'Question Bank',
                AppRoutes.questionBank),
            _buildNavItem(context, Icons.history, 'Recent Papers',
                AppRoutes.recentPapers),
            _buildNavItem(context, Icons.cloud_upload, 'Upload Textbook',
                AppRoutes.upload),
            const Divider(),
            _buildNavItem(
                context, Icons.settings, 'Settings', AppRoutes.settings),
            _buildNavItem(
                context, Icons.info_outline, 'About', AppRoutes.about),
          ],
        ),
      ),
      body: SafeArea(child: body),
    );
  }

  Widget _buildNavItem(
      BuildContext context, IconData icon, String label, String targetRoute) {
    final isSelected = ModalRoute.of(context)?.settings.name == targetRoute;
    return ListTile(
      leading: Icon(icon,
          color: isSelected ? Theme.of(context).colorScheme.primary : null),
      title: Text(label,
          style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (!isSelected) {
          Navigator.pushNamed(context, targetRoute);
        }
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Fallback Screens (NotFound & ServerError)
// -----------------------------------------------------------------------------
// 10. Fallback 404 Screen (Stitch-Compliant Material 3)
// -----------------------------------------------------------------------------
class NotFoundScreen extends StatelessWidget {
  final String? routeName;
  const NotFoundScreen({super.key, this.routeName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BaseAppScreen(
      title: 'Page Not Found',
      routeName: '/404',
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Styled Refined Icon Badge
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer
                      .withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.explore_off_rounded,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Page Not Found',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Text(
                  'The page you are looking for doesn\'t exist or has been moved.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.home),
                icon: const Icon(Icons.dashboard_rounded),
                label: const Text('Return to Dashboard'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                          'Thank you! Bug report submitted to ExamCraft AI diagnostics.'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                icon: const Icon(Icons.bug_report_outlined, size: 18),
                label: const Text('Report a Bug'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 11. 500 Server Error Screen Variant
// -----------------------------------------------------------------------------
class ServerErrorScreen extends StatelessWidget {
  final VoidCallback? onRetry;
  const ServerErrorScreen({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BaseAppScreen(
      title: 'Server Error',
      routeName: '/500',
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.errorContainer.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  size: 56,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                '500 - Server Error',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Text(
                  'Our servers encountered an unexpected condition. Please try again or check back soon.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry ??
                    () =>
                        Navigator.pushReplacementNamed(context, AppRoutes.home),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry Connection'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
