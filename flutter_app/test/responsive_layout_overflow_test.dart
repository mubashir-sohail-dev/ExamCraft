import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_app/core/constants/subjects.dart';
import 'package:flutter_app/core/network/api_client.dart';
import 'package:flutter_app/core/routes/app_routes.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/data/models/assessment_model.dart';
import 'package:flutter_app/data/models/recent_papers_model.dart';
import 'package:flutter_app/data/repositories/assessment_repository.dart';
import 'package:flutter_app/data/repositories/pdf_repository.dart';
import 'package:flutter_app/data/repositories/question_bank_repository.dart';
import 'package:flutter_app/data/repositories/recent_papers_repository.dart';
import 'package:flutter_app/data/repositories/settings_repository.dart';
import 'package:flutter_app/presentation/providers/assessment_provider.dart';
import 'package:flutter_app/presentation/providers/connection_provider.dart';
import 'package:flutter_app/presentation/providers/question_bank_provider.dart';
import 'package:flutter_app/presentation/providers/recent_papers_provider.dart';
import 'package:flutter_app/presentation/providers/settings_provider.dart';
import 'package:flutter_app/screens/about/about_screen.dart';
import 'package:flutter_app/screens/question_bank/question_bank_screen.dart';
import 'package:flutter_app/screens/recent_papers/recent_papers_screen.dart';
import 'package:flutter_app/screens/review/review_screen.dart';
import 'package:flutter_app/screens/settings/settings_screen.dart';

/// Helper to wrap screens with all required providers and MaterialApp
Widget _buildTestApp(Widget child, {
  QuestionBankProvider? qbProvider,
  AssessmentProvider? assessmentProvider,
  RecentPapersProvider? recentProvider,
  ConnectionProvider? connectionProvider,
  SettingsProvider? settingsProvider,
  ThemeController? themeController,
}) {
  final apiClient = ApiClient();
  final qbRepo = QuestionBankRepository();
  final recentRepo = RecentPapersRepository();
  final pdfRepo = PdfRepository(apiClient: apiClient);
  final assessRepo = AssessmentRepository(apiClient: apiClient);
  final settingsRepo = SettingsRepository();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeController>.value(
        value: themeController ?? ThemeController(),
      ),
      ChangeNotifierProvider<QuestionBankProvider>.value(
        value: qbProvider ?? QuestionBankProvider(questionBankRepository: qbRepo),
      ),
      ChangeNotifierProvider<RecentPapersProvider>.value(
        value: recentProvider ?? RecentPapersProvider(recentPapersRepository: recentRepo),
      ),
      ChangeNotifierProvider<AssessmentProvider>.value(
        value: assessmentProvider ?? AssessmentProvider(
          assessmentRepository: assessRepo,
          pdfRepository: pdfRepo,
        ),
      ),
      ChangeNotifierProvider<ConnectionProvider>.value(
        value: connectionProvider ?? ConnectionProvider(apiClient: apiClient),
      ),
      ChangeNotifierProvider<SettingsProvider>.value(
        value: settingsProvider ?? SettingsProvider(
          settingsRepository: settingsRepo,
          apiClient: apiClient,
        ),
      ),
    ],
    child: MaterialApp(
      routes: AppRoutes.routesMap,
      home: child,
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final recentRepo = RecentPapersRepository();
    await recentRepo.saveRecentPaper(
      RecentPaperModel(
        paperId: 'paper_sample_001',
        title: 'Class 9 Physics Examination',
        subject: ExamSubject.physics,
        chapterOrTopic: 'Chapter 1: Physical Quantities & Measurement',
        totalMarks: 25,
        dateCreated: DateTime(2026, 9, 13),
        testData: const AssessmentModel(
          testTitle: 'Class 9 Physics Examination',
          subject: ExamSubject.physics,
          chapterOrTopic: 'Chapter 1: Physical Quantities & Measurement',
          totalMarks: 25,
          mcqs: [
            MCQItemModel(
              questionNumber: 1,
              question: 'Which of the following physical quantities is an authentic base SI quantity under international convention?',
              options: [
                'A: Thermodynamic Temperature measured in Kelvin',
                'B: Electric potential difference measured in Volts',
                'C: Frequency measured in Hertz cycles per second',
                'D: Force measured in standard Newtons',
              ],
              correctOption: 'A',
              textbookReference: 'Textbook Physics Grade 9, Unit 1: Physical Quantities, Section 1.3 Base and Derived Quantities, Page 8, Exercise 1.3 Question 2',
            ),
          ],
          shortQuestions: [
            ShortQuestionItemModel(
              questionNumber: 1,
              question: 'Define base units and derived units with two standard SI examples each.',
              marks: 2,
            ),
          ],
          longQuestions: [
            LongQuestionItemModel(
              questionNumber: 1,
              question: 'Explain screw gauge zero error with diagrammatic derivation.',
              marks: 5,
            ),
          ],
        ),
      ),
    );
  });

  group('Responsive Layout Overflow Tests (Narrow 320px & 360px Viewports)', () {
    testWidgets('QuestionBankScreen: renders tags, citations, and pagination with 0 overflows on 360x640', (tester) async {
      // 360x640 screen constraint
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final qbRepo = QuestionBankRepository();
      final qbProvider = QuestionBankProvider(questionBankRepository: qbRepo);

      await tester.pumpWidget(_buildTestApp(
        const QuestionBankScreen(),
        qbProvider: qbProvider,
      ));
      await tester.pumpAndSettle();

      // Verify zero layout or RenderFlex overflow exceptions
      expect(tester.takeException(), isNull, reason: 'Initial render must have zero RenderFlex overflow exceptions');

      // Tap to expand question to test citation rendering
      expect(qbProvider.questions.isNotEmpty, isTrue);
      final firstQ = qbProvider.questions.first;
      final expandBtn = find.byKey(Key('toggle_expand_btn_${firstQ.id}'));
      if (expandBtn.evaluate().isNotEmpty) {
        await tester.ensureVisible(expandBtn);
        await tester.tap(expandBtn);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Expanded question citation must wrap without RenderFlex overflow');
      }
    });

    testWidgets('QuestionBankScreen: renders on ultra-narrow 320x640 with zero RenderFlex overflow', (tester) async {
      // 320x640 screen constraint
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final qbRepo = QuestionBankRepository();
      final qbProvider = QuestionBankProvider(questionBankRepository: qbRepo);

      await tester.pumpWidget(_buildTestApp(
        const QuestionBankScreen(),
        qbProvider: qbProvider,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'Ultra-narrow 320px viewport must not overflow');
    });

    testWidgets('ReviewPaperScreen: renders long questions, options, and summary chips without overflow on 360x640', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final apiClient = ApiClient();
      final assessRepo = AssessmentRepository(apiClient: apiClient);
      final pdfRepo = PdfRepository(apiClient: apiClient);
      final assessProvider = AssessmentProvider(
        assessmentRepository: assessRepo,
        pdfRepository: pdfRepo,
      );

      const longAssessment = AssessmentModel(
        testTitle: 'Class 9 Chemistry Comprehensive Chapter 3 Assessment on Atomic Models and Periodic Trends',
        subject: ExamSubject.chemistry,
        chapterOrTopic: 'Chapter 3: Atomic Structure and Periodic Properties of Chemical Elements',
        totalMarks: 50,
        timeAllowed: '60 Minutes',
        mcqs: [
          MCQItemModel(
            questionNumber: 1,
            question: 'Which of the following statements accurately characterizes the fundamental Bohr atomic model postulates regarding electron transitions between quantized orbits?',
            options: [
              'A: Electrons absorb electromagnetic energy continuously and emit continuous radiation in all states',
              'B: Electrons revolve in stationary orbits without radiating energy and jump with quantized delta E = hv',
              'C: Electrons decay rapidly into the positively charged nucleus within picoseconds of formation',
              'D: The angular momentum of revolving electrons can take any real arbitrary continuous float value',
            ],
            correctOption: 'B',
            textbookReference: 'Textbook Chapter 3, Section 3.2, Page 54, Exercise 3.2 Question 5',
          ),
        ],
        shortQuestions: [
          ShortQuestionItemModel(
            questionNumber: 1,
            question: 'State two significant differences between Rutherford atomic model and Bohr atomic theory with respect to stability and emission spectra.',
            marks: 2,
          ),
        ],
        longQuestions: [
          LongQuestionItemModel(
            questionNumber: 1,
            question: 'Describe in extensive detail the experimental apparatus and observations of Rutherford gold foil scattering experiment, outlining both successes and critical shortcomings.',
            marks: 5,
          ),
        ],
      );

      assessProvider.setTestAssessment(longAssessment);

      await tester.pumpWidget(_buildTestApp(
        const ReviewPaperScreen(),
        assessmentProvider: assessProvider,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'ReviewPaperScreen with long options and title must have 0 overflows');
    });

    testWidgets('RecentPapersScreen: renders cards with favorite button and long titles on 360x640', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final recentRepo = RecentPapersRepository();
      final recentProvider = RecentPapersProvider(recentPapersRepository: recentRepo);

      await recentRepo.saveRecentPaper(
        RecentPaperModel(
          paperId: 'overflow_test_paper',
          title: 'Class 9 Physics Final Term Assessment on Dynamics and Gravitation',
          subject: ExamSubject.physics,
          chapterOrTopic: 'Chapter 3 Dynamics & Chapter 5 Gravitation',
          totalMarks: 75,
          timeAllowed: '90 Mins',
          dateCreated: DateTime(2026, 9, 13),
          isFavorite: true,
          testData: const AssessmentModel(
            testTitle: 'Class 9 Physics Final Term Assessment',
            subject: ExamSubject.physics,
            chapterOrTopic: 'Chapter 3 Dynamics',
            totalMarks: 75,
            mcqs: [],
            shortQuestions: [],
            longQuestions: [],
          ),
        ),
      );
      await recentProvider.loadRecentPapers();

      await tester.pumpWidget(_buildTestApp(
        const RecentPapersScreen(),
        recentProvider: recentProvider,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'RecentPapersScreen card header must not overflow');
    });

    testWidgets('AboutScreen: renders specification table without overflow on 320x640', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp(
        const AboutScreen(),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'AboutScreen specifications must not overflow on 320px');
    });

    testWidgets('SettingsScreen: renders API config, telemetry buttons, and health grid without overflow on 360x640', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp(
        const SettingsScreen(),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'SettingsScreen must not overflow on 360px viewport');
    });

    testWidgets('SettingsScreen: renders without overflow on ultra-narrow 320x640 viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp(
        const SettingsScreen(),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'SettingsScreen must not overflow on 320px viewport');
    });
  });
}
