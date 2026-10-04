import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes/app_routes.dart';
import '../core/theme/app_theme.dart';

/// Base app screen wrapper providing standardized AppBar, Navigation Drawer, and Theme Mode Toggle.
class BaseAppScreen extends StatelessWidget {
  final String title;
  final String routeName;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const BaseAppScreen({
    super.key,
    required this.title,
    required this.routeName,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    ThemeController? themeController;
    try {
      themeController = Provider.of<ThemeController>(context);
    } catch (_) {
      // Provider not present in test scope, fallback handled gracefully
    }

    final theme = Theme.of(context);
    final isDark = themeController?.isDarkMode(context) ??
        theme.brightness == Brightness.dark;

    return Scaffold(
      drawerEnableOpenDragGesture: true,
      drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.25,
      appBar: AppBar(
        title: Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (actions != null) ...actions!,
          IconButton(
            key: const Key('theme_toggle_button'),
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
            ),
            tooltip: 'Toggle Light/Dark Theme',
            onPressed: () {
              if (themeController != null) {
                themeController.toggleTheme(context);
              }
            },
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
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'ExamCraft AI',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Assessment Builder v1.0.0',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            _buildNavItem(
                context, Icons.dashboard, 'Dashboard', AppRoutes.home),
            _buildNavItem(context, Icons.auto_awesome, 'Generate Assessment',
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
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildNavItem(
      BuildContext context, IconData icon, String label, String targetRoute) {
    final isSelected = ModalRoute.of(context)?.settings.name == targetRoute ||
        routeName == targetRoute;
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? theme.colorScheme.primary : null,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : null,
        ),
      ),
      selected: isSelected,
      selectedTileColor:
          theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (!isSelected) {
          if (targetRoute == AppRoutes.home) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
              (route) => false,
            );
          } else {
            Navigator.pushNamed(context, targetRoute);
          }
        }
      },
    );
  }
}
