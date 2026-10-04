// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_app/core/network/api_client.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/data/repositories/assessment_repository.dart';
import 'package:flutter_app/data/repositories/pdf_repository.dart';
import 'package:flutter_app/data/repositories/question_bank_repository.dart';
import 'package:flutter_app/data/repositories/recent_papers_repository.dart';
import 'package:flutter_app/data/repositories/settings_repository.dart';
import 'package:flutter_app/data/repositories/upload_repository.dart';
import 'package:flutter_app/presentation/providers/assessment_provider.dart';
import 'package:flutter_app/presentation/providers/connection_provider.dart';
import 'package:flutter_app/presentation/providers/question_bank_provider.dart';
import 'package:flutter_app/presentation/providers/recent_papers_provider.dart';
import 'package:flutter_app/presentation/providers/settings_provider.dart';
import 'package:flutter_app/presentation/providers/upload_provider.dart';
import 'package:flutter_app/main.dart';

void main() {
  testWidgets('ExamCraftApp smoke test - verifies home screen and zero-mock empty state', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final themeController = ThemeController();
    final apiClient = ApiClient();
    final assessmentRepo = AssessmentRepository(apiClient: apiClient);
    final pdfRepo = PdfRepository(apiClient: apiClient);
    final questionBankRepo = QuestionBankRepository();
    final recentPapersRepo = RecentPapersRepository();
    final settingsRepo = SettingsRepository();
    final uploadRepo = UploadRepository(apiClient: apiClient);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeController>.value(value: themeController),
          ChangeNotifierProvider<ConnectionProvider>(
            create: (_) => ConnectionProvider(apiClient: apiClient),
          ),
          ChangeNotifierProvider<AssessmentProvider>(
            create: (_) => AssessmentProvider(
              assessmentRepository: assessmentRepo,
              pdfRepository: pdfRepo,
              recentPapersRepository: recentPapersRepo,
            ),
          ),
          ChangeNotifierProvider<QuestionBankProvider>(
            create: (_) => QuestionBankProvider(
              questionBankRepository: questionBankRepo,
            ),
          ),
          ChangeNotifierProvider<RecentPapersProvider>(
            create: (_) => RecentPapersProvider(
              recentPapersRepository: recentPapersRepo,
            ),
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
    await tester.pumpAndSettle();

    expect(find.text('ExamCraft AI'), findsWidgets);
    expect(find.byKey(const Key('home_fab_generate')), findsOneWidget);
    expect(find.text('No assessments yet.'), findsOneWidget);
  });
}
