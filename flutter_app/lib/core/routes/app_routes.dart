import 'package:flutter/material.dart';

import '../../screens/placeholder_screens.dart';

/// Central Route Architecture for ExamCraft AI Application.
/// Maps 26 design screens across 11 core routes and sub-route variations.
abstract class AppRoutes {
  // 11 Core Routes Constants
  static const String home = '/home';
  static const String generate = '/generate';
  static const String generating = '/generating';
  static const String review = '/review';
  static const String pdfPreview = '/pdf_preview';
  static const String questionBank = '/question_bank';
  static const String recentPapers = '/recent_papers';
  static const String upload = '/upload';
  static const String uploadStatus = '/upload/status';
  static const String settings = '/settings';
  static const String about = '/about';

  // Sub-routes & Aliases for specific UI screens
  static const String homeOverview = '/home/overview';
  static const String pdfPreviewActions = '/pdf_preview/actions';
  static const String questionBankFilters = '/question_bank/filters';
  static const String settingsAdvanced = '/settings/advanced';
  static const String aboutVersion = '/about/version';

  /// Initial route loaded upon application launch.
  static const String initialRoute = home;

  /// Map of all registered routes and their corresponding widget builders.
  static Map<String, WidgetBuilder> get routesMap => {
        home: (context) => const HomeScreen(),
        homeOverview: (context) => const HomeDashboardScreen(),
        '/home/dashboard': (context) => const HomeDashboardScreen(),
        generate: (context) => const GenerateAssessmentScreen(),
        generating: (context) => const GeneratingScreen(),
        '/generate/processing': (context) => const GeneratingScreen(),
        review: (context) => const ReviewPaperScreen(),
        pdfPreview: (context) => const PdfPreviewScreen(),
        '/pdf-preview': (context) => const PdfPreviewScreen(),
        pdfPreviewActions: (context) => const PdfPreviewScreen(),
        '/pdf-preview/actions': (context) => const PdfPreviewScreen(),
        questionBank: (context) => const QuestionBankScreen(),
        '/question-bank': (context) => const QuestionBankScreen(),
        questionBankFilters: (context) => const QuestionBankScreen(),
        '/question-bank/filters': (context) => const QuestionBankScreen(),
        recentPapers: (context) => const RecentPapersScreen(),
        '/recent-papers': (context) => const RecentPapersScreen(),
        upload: (context) => const UploadTextbookScreen(),
        '/upload/textbook': (context) => const UploadTextbookScreen(),
        uploadStatus: (context) => const UploadStatusScreen(),
        settings: (context) => const SettingsScreen(),
        settingsAdvanced: (context) => const SettingsScreen(),
        about: (context) => const AboutScreen(),
        aboutVersion: (context) => const AboutScreen(),
      };

  /// Route generator for dynamic navigation, parameter resolution, and fallback handling.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    String? path = settings.name;
    Map<String, dynamic> queryParams = {};

    if (path != null) {
      if (path == '/') path = home;
      try {
        final uri = Uri.parse(path);
        path = uri.path;
        if (path == '/') path = home;
        queryParams = Map<String, dynamic>.from(uri.queryParameters);
      } catch (_) {}
    }

    final builder = routesMap[path];
    if (builder != null) {
      Object? mergedArgs = settings.arguments;
      if (queryParams.isNotEmpty) {
        if (mergedArgs is Map) {
          mergedArgs = {...queryParams, ...mergedArgs};
        } else {
          mergedArgs ??= queryParams;
        }
      }

      final normalizedSettings = RouteSettings(
        name: path,
        arguments: mergedArgs,
      );

      return MaterialPageRoute(
        builder: builder,
        settings: normalizedSettings,
      );
    }

    // Fallback 404 handler
    return MaterialPageRoute(
      builder: (context) => NotFoundScreen(routeName: settings.name),
      settings: settings,
    );
  }
}
