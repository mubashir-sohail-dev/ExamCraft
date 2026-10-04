import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_app/core/constants/subjects.dart';
import 'package:flutter_app/core/network/api_client.dart';
import 'package:flutter_app/core/routes/app_routes.dart';
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
import 'package:flutter_app/screens/about/about_screen.dart';
import 'package:flutter_app/screens/home/home_dashboard_screen.dart';
import 'package:flutter_app/screens/home/home_screen.dart';
import 'package:flutter_app/screens/settings/settings_screen.dart';

Widget createTestableWidget({
  required Widget child,
  ThemeController? themeController,
  String initialRoute = AppRoutes.home,
}) {
  final controller = themeController ?? ThemeController();
  final apiClient = ApiClient();
  final assessmentRepo = AssessmentRepository(apiClient: apiClient);
  final pdfRepo = PdfRepository(apiClient: apiClient);
  final questionBankRepo = QuestionBankRepository();
  final recentPapersRepo = RecentPapersRepository();
  final settingsRepo = SettingsRepository();
  final uploadRepo = UploadRepository(apiClient: apiClient);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeController>.value(value: controller),
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
    child: Consumer<ThemeController>(
      builder: (context, tc, _) {
        return MaterialApp(
          title: 'ExamCraft AI Test',
          theme: tc.lightThemeData,
          darkTheme: tc.darkThemeData,
          themeMode: tc.themeMode,
          initialRoute: initialRoute,
          routes: {
            AppRoutes.home: (context) => child,
            ...AppRoutes.routesMap,
          },
        );
      },
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  group('Milestone 3 Core Hub Screens Tests', () {
    // -------------------------------------------------------------------------
    // 1. Home Screen Tests
    // -------------------------------------------------------------------------
    group('HomeScreen Tests', () {
      testWidgets('renders header, hero banner, and connectivity pill',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestableWidget(child: const HomeScreen()),
        );

        expect(find.text('ExamCraft AI'), findsOneWidget);
        expect(find.text('Welcome back, Professor'), findsOneWidget);
        expect(find.text('Connected'), findsOneWidget);
        expect(find.text('Generate Assessment'), findsWidgets);
        expect(find.text('Upload Textbook'), findsOneWidget);
      });

      testWidgets('presents all 5 mandatory subjects in grid',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestableWidget(child: const HomeScreen()),
        );

        for (final subject in SubjectUtils.allSubjects) {
          expect(find.text(subject.displayName), findsOneWidget);
        }
      });

      testWidgets('quick actions tile for Question Bank exists',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestableWidget(child: const HomeScreen()),
        );

        expect(find.byKey(const Key('quick_action_question_bank')), findsOneWidget);
        expect(find.byKey(const Key('quick_action_recent_papers')), findsOneWidget);
      });

      testWidgets('switches light and dark theme mode',
          (WidgetTester tester) async {
        final themeController = ThemeController();
        await tester.pumpWidget(
          createTestableWidget(
            child: const HomeScreen(),
            themeController: themeController,
          ),
        );

        expect(themeController.themeMode, ThemeMode.system);

        final themeToggleBtn = find.byKey(const Key('theme_toggle_button'));
        expect(themeToggleBtn, findsOneWidget);

        await tester.tap(themeToggleBtn);
        await tester.pumpAndSettle();

        expect(themeController.themeMode, isNot(ThemeMode.system));
      });
    });

    // -------------------------------------------------------------------------
    // 2. Home Dashboard Overview Tests
    // -------------------------------------------------------------------------
    group('HomeDashboardScreen Tests', () {
      testWidgets('renders performance metrics cards',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            child: const HomeDashboardScreen(),
            initialRoute: AppRoutes.homeOverview,
          ),
        );

        expect(find.text('Dashboard Overview'), findsOneWidget);
        expect(find.text('Total Assessments'), findsOneWidget);
        expect(find.text('Question Bank Count'), findsOneWidget);
        expect(find.text('Active Subjects'), findsOneWidget);
        expect(find.text('System Health'), findsOneWidget);
      });

      testWidgets('renders subject usage distribution for all 5 subjects',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            child: const HomeDashboardScreen(),
            initialRoute: AppRoutes.homeOverview,
          ),
        );

        expect(find.byKey(const Key('subject_usage_distribution_card')), findsOneWidget);

        for (final subject in SubjectUtils.allSubjects) {
          expect(find.text(subject.displayName), findsOneWidget);
        }
      });

      testWidgets('displays system health & telemetry details',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            child: const HomeDashboardScreen(),
            initialRoute: AppRoutes.homeOverview,
          ),
        );

        expect(find.text('Core Engine Endpoint'), findsOneWidget);
        expect(find.text('Knowledge Base Index'), findsOneWidget);
        expect(find.text('AI Question Engine'), findsOneWidget);
      });
    });

    // -------------------------------------------------------------------------
    // 3. About Screen Tests
    // -------------------------------------------------------------------------
    group('AboutScreen Tests', () {
      testWidgets('renders app branding and version 1.0.0 info',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            child: const AboutScreen(),
            initialRoute: AppRoutes.about,
          ),
        );

        expect(find.text('About ExamCraft AI'), findsOneWidget);
        expect(find.text('Version 1.0.0 (Production Release)'), findsOneWidget);
        expect(find.text('AI Assessment Builder for Educators'), findsOneWidget);
      });

      testWidgets('presents core technologies grid', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            child: const AboutScreen(),
            initialRoute: AppRoutes.about,
          ),
        );

        expect(find.text('Core Technologies'), findsOneWidget);
        expect(find.text('Core Service'), findsOneWidget);
        expect(find.text('Knowledge Base'), findsOneWidget);
        expect(find.text('AI Question Engine'), findsOneWidget);
        expect(find.text('ExamCraft AI UI Framework'), findsOneWidget);
      });

      testWidgets('triggers live backend health check', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            child: const AboutScreen(),
            initialRoute: AppRoutes.about,
          ),
        );

        final checkHealthBtn = find.byKey(const Key('btn_health_check'));
        expect(checkHealthBtn, findsOneWidget);

        await tester.tap(checkHealthBtn);
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Pinging...'), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 800));
        await tester.pumpAndSettle();

        expect(find.text('Pinging...'), findsNothing);
      });
    });

    // -------------------------------------------------------------------------
    // 4. Settings Screen Tests
    // -------------------------------------------------------------------------
    group('SettingsScreen Tests', () {
      testWidgets('renders dark mode toggle switch', (WidgetTester tester) async {
        final themeController = ThemeController();
        await tester.pumpWidget(
          createTestableWidget(
            child: const SettingsScreen(),
            themeController: themeController,
            initialRoute: AppRoutes.settings,
          ),
        );

        expect(find.text('Appearance Options'), findsOneWidget);

        final switchFinder = find.byKey(const Key('switch_theme_mode'));
        expect(switchFinder, findsOneWidget);

        await tester.tap(switchFinder);
        await tester.pumpAndSettle();

        expect(themeController.themeMode, ThemeMode.dark);
      });

      testWidgets('renders default subject dropdown with 5 mandatory subjects',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            child: const SettingsScreen(),
            initialRoute: AppRoutes.settings,
          ),
        );

        final dropdownFinder = find.byKey(const Key('dropdown_default_subject'));
        expect(dropdownFinder, findsOneWidget);

        await tester.tap(dropdownFinder);
        await tester.pumpAndSettle();

        for (final subject in SubjectUtils.allSubjects) {
          expect(find.text(subject.displayName), findsWidgets);
        }
      });

      testWidgets('tests API base URL connection ping button',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            child: const SettingsScreen(),
            initialRoute: AppRoutes.settings,
          ),
        );

        final inputUrl = find.byKey(const Key('input_api_base_url'));
        expect(inputUrl, findsOneWidget);

        final testConnBtn = find.byKey(const Key('btn_test_connection'));
        expect(testConnBtn, findsOneWidget);

        await tester.ensureVisible(testConnBtn);
        await tester.tap(testConnBtn);
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Connection successful'),
          findsOneWidget,
        );
      });

      testWidgets('opens clear local cache dialog', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            child: const SettingsScreen(),
            initialRoute: AppRoutes.settings,
          ),
        );

        final clearCacheBtn = find.byKey(const Key('btn_clear_cache'));
        expect(clearCacheBtn, findsOneWidget);

        await tester.ensureVisible(clearCacheBtn);
        await tester.tap(clearCacheBtn);
        await tester.pumpAndSettle();

        expect(find.text('Clear Local Cache'), findsWidgets);
        expect(
          find.text('Are you sure you want to clear temporary offline cache? Saved papers will remain intact.'),
          findsOneWidget,
        );

        final confirmBtn = find.byKey(const Key('btn_confirm_clear_cache'));
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        expect(find.text('Local cache cleared successfully!'), findsOneWidget);
      });
    });
  });
}
