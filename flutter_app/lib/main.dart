import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/assessment_repository.dart';
import 'data/repositories/pdf_repository.dart';
import 'data/repositories/question_bank_repository.dart';
import 'data/repositories/recent_papers_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/upload_repository.dart';
import 'presentation/providers/assessment_provider.dart';
import 'presentation/providers/connection_provider.dart';
import 'presentation/providers/question_bank_provider.dart';
import 'presentation/providers/recent_papers_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/upload_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Suppress verbose internal development logs in production release mode
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // Catch all Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    if (!kReleaseMode) {
      debugPrint('=== FLUTTER ERROR ===');
      debugPrint('Exception: ${details.exception}');
      debugPrint('Stack: ${details.stack}');
      debugPrint('Library: ${details.library}');
      debugPrint('Context: ${details.context}');
      debugPrint('=== END FLUTTER ERROR ===');
      FlutterError.presentError(details);
    }
  };

  // Catch unhandled asynchronous errors outside the widget tree (Futures, Streams, network callbacks)
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (!kReleaseMode) {
      debugPrint('=== UNHANDLED ASYNC ERROR (PlatformDispatcher) ===');
      debugPrint('Error: $error');
      debugPrint('Stack: $stack');
      debugPrint('=== END UNHANDLED ASYNC ERROR ===');
    }
    // Return true to intercept unhandled asynchronous exceptions and prevent isolate crash
    return true;
  };

  // Show friendly error widget instead of blank screen
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!kReleaseMode) {
      debugPrint('[ErrorWidget] Widget error: ${details.exception}');
    }
    return Material(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'An Unexpected Error Occurred',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                kReleaseMode
                    ? 'Please return to the previous screen or restart the app.'
                    : '${details.exception}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: kReleaseMode ? Colors.grey[700] : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  };

  final themeController = ThemeController();
  await themeController.loadThemeMode();

  final apiClient = ApiClient();
  final assessmentRepo = AssessmentRepository(apiClient: apiClient);
  final pdfRepo = PdfRepository(apiClient: apiClient);
  final questionBankRepo = QuestionBankRepository();
  final recentPapersRepo = RecentPapersRepository();
  final settingsRepo = SettingsRepository();
  final uploadRepo = UploadRepository(apiClient: apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
        ChangeNotifierProvider<ConnectionProvider>(
          create: (_) => ConnectionProvider(apiClient: apiClient),
        ),
        ChangeNotifierProvider<RecentPapersProvider>(
          create: (_) => RecentPapersProvider(
            recentPapersRepository: recentPapersRepo,
          ),
        ),
        ChangeNotifierProvider<QuestionBankProvider>(
          create: (_) => QuestionBankProvider(
            questionBankRepository: questionBankRepo,
          ),
        ),
        ChangeNotifierProxyProvider2<RecentPapersProvider, QuestionBankProvider,
            AssessmentProvider>(
          create: (_) => AssessmentProvider(
            assessmentRepository: assessmentRepo,
            pdfRepository: pdfRepo,
            recentPapersRepository: recentPapersRepo,
          ),
          update: (_, recentPapersProvider, questionBankProvider,
              assessmentProvider) {
            debugPrint(
                '[main] ProxyProvider2 UPDATE called - recentPapers.isLoading=${recentPapersProvider.isLoading}, papers=${recentPapersProvider.papers.length}, qb.isLoading=${questionBankProvider.isLoading}');
            assessmentProvider?.onAssessmentGenerated = () {
              debugPrint('[main] onAssessmentGenerated callback FIRED');
              recentPapersProvider.loadRecentPapers();
              questionBankProvider.fetchQuestions();
            };
            return assessmentProvider!;
          },
        ),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(
            settingsRepository: settingsRepo,
            apiClient: apiClient,
          ),
        ),
        ChangeNotifierProvider<UploadProvider>(
          create: (_) => UploadProvider(
            uploadRepository: uploadRepo,
          ),
        ),
      ],
      child: const ExamCraftApp(),
    ),
  );
}

class ExamCraftApp extends StatelessWidget {
  const ExamCraftApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);

    return MaterialApp(
      title: 'ExamCraft AI',
      debugShowCheckedModeBanner: false,
      theme: themeController.lightThemeData,
      darkTheme: themeController.darkThemeData,
      themeMode: themeController.themeMode,
      initialRoute: AppRoutes.initialRoute,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
