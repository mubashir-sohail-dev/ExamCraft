import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_app/core/constants/subjects.dart';
import 'package:flutter_app/core/routes/app_routes.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/data/models/question_bank_model.dart';
import 'package:flutter_app/data/models/recent_papers_model.dart';
import 'package:flutter_app/data/models/assessment_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/core/network/api_client.dart';
import 'package:flutter_app/data/repositories/assessment_repository.dart';
import 'package:flutter_app/data/repositories/pdf_repository.dart';
import 'package:flutter_app/data/repositories/question_bank_repository.dart';
import 'package:flutter_app/data/repositories/recent_papers_repository.dart';
import 'package:flutter_app/presentation/providers/assessment_provider.dart';
import 'package:flutter_app/presentation/providers/question_bank_provider.dart';
import 'package:flutter_app/presentation/providers/recent_papers_provider.dart';
import 'package:flutter_app/screens/pdf_preview/pdf_preview_screen.dart';
import 'package:flutter_app/screens/question_bank/question_bank_screen.dart';
import 'package:flutter_app/screens/recent_papers/recent_papers_screen.dart';
import 'package:flutter_app/screens/review/review_screen.dart';

AssessmentModel _createSampleTestAssessment() {
  return const AssessmentModel(
    testTitle: 'Test Assessment',
    subject: ExamSubject.physics,
    chapterOrTopic: 'Chapter 1',
    totalMarks: 25,
    mcqs: [
      MCQItemModel(
        questionNumber: 1,
        question: 'What is subatomic?',
        options: ['A', 'B', 'C', 'D'],
        correctOption: 'A',
        textbookReference: 'Chapter 1, Page 5',
      ),
    ],
    shortQuestions: [
      ShortQuestionItemModel(
        questionNumber: 1,
        question: 'Define physics.',
        marks: 2,
      ),
      ShortQuestionItemModel(
        questionNumber: 2,
        question: 'What is energy?',
        marks: 2,
      ),
    ],
    longQuestions: [
      LongQuestionItemModel(
        questionNumber: 1,
        question: 'Explain Newton laws.',
        marks: 5,
      ),
    ],
  );
}

List<RecentPaperModel> _createSampleTestPapers() {
  final sampleTest = _createSampleTestAssessment();
  return [
    RecentPaperModel(
      paperId: 'paper_001',
      title: 'Class 9 Physics - Chapter 1 Quiz',
      subject: ExamSubject.physics,
      chapterOrTopic: 'Chapter 1: Physical Quantities',
      totalMarks: 25,
      dateCreated: DateTime(2025, 2, 10),
      isFavorite: true,
      testData: sampleTest,
    ),
    RecentPaperModel(
      paperId: 'paper_002',
      title: 'Class 9 Chemistry - Chapter 3 Test',
      subject: ExamSubject.chemistry,
      chapterOrTopic: 'Chapter 3: Periodic Table',
      totalMarks: 50,
      dateCreated: DateTime(2025, 2, 8),
      isFavorite: false,
      testData: sampleTest,
    ),
  ];
}

Widget _createTestWidget(Widget child, {
  QuestionBankProvider? qbProvider,
  AssessmentProvider? assessmentProvider,
  RecentPapersProvider? recentProvider,
  ThemeController? themeController,
}) {
  final apiClient = ApiClient();
  final qbRepo = QuestionBankRepository();
  final recentRepo = RecentPapersRepository();
  final pdfRepo = PdfRepository(apiClient: apiClient);
  final assessRepo = AssessmentRepository(apiClient: apiClient);

  final defaultQb = QuestionBankProvider(questionBankRepository: qbRepo);
  final defaultRecent = RecentPapersProvider(recentPapersRepository: recentRepo);
  final defaultAssess = AssessmentProvider(
    assessmentRepository: assessRepo,
    pdfRepository: pdfRepo,
  );
  final defaultTheme = ThemeController();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeController>.value(value: themeController ?? defaultTheme),
      ChangeNotifierProvider<QuestionBankProvider>.value(value: qbProvider ?? defaultQb),
      ChangeNotifierProvider<RecentPapersProvider>.value(value: recentProvider ?? defaultRecent),
      ChangeNotifierProvider<AssessmentProvider>.value(value: assessmentProvider ?? defaultAssess),
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
        paperId: 'paper_005',
        title: 'Class 9 Computer Science Quiz',
        subject: ExamSubject.computerScience,
        chapterOrTopic: 'Chapter 1',
        totalMarks: 10,
        dateCreated: DateTime.now(),
        testData: const AssessmentModel(
          testTitle: 'Class 9 Computer Science Quiz',
          subject: ExamSubject.computerScience,
          chapterOrTopic: 'Chapter 1',
          totalMarks: 10,
          mcqs: [
            MCQItemModel(
              questionNumber: 1,
              question: 'CS MCQ 1',
              options: ['A) 1', 'B) 2', 'C) 3', 'D) 4'],
              correctOption: 'A',
              textbookReference: 'Pg 10',
            ),
          ],
          shortQuestions: [
            ShortQuestionItemModel(questionNumber: 1, question: 'CS Short Q1', marks: 2),
          ],
          longQuestions: [
            LongQuestionItemModel(questionNumber: 1, question: 'CS Long Q1', marks: 5),
          ],
        ),
      ),
    );
    await recentRepo.saveRecentPaper(
      RecentPaperModel(
        paperId: 'paper_004',
        title: 'Class 9 Mathematics Quiz',
        subject: ExamSubject.mathematics,
        chapterOrTopic: 'Chapter 1',
        totalMarks: 10,
        dateCreated: DateTime.now(),
        testData: const AssessmentModel(
          testTitle: 'Class 9 Mathematics Quiz',
          subject: ExamSubject.mathematics,
          chapterOrTopic: 'Chapter 1',
          totalMarks: 10,
          mcqs: [
            MCQItemModel(
              questionNumber: 1,
              question: 'Math MCQ 1',
              options: ['A) 1', 'B) 2', 'C) 3', 'D) 4'],
              correctOption: 'A',
              textbookReference: 'Pg 10',
            ),
          ],
          shortQuestions: [
            ShortQuestionItemModel(questionNumber: 1, question: 'Math Short Q1', marks: 2),
          ],
          longQuestions: [
            LongQuestionItemModel(questionNumber: 1, question: 'Math Long Q1', marks: 5),
          ],
        ),
      ),
    );
    await recentRepo.saveRecentPaper(
      RecentPaperModel(
        paperId: 'paper_003',
        title: 'Class 9 Biology Quiz',
        subject: ExamSubject.biology,
        chapterOrTopic: 'Chapter 1',
        totalMarks: 10,
        dateCreated: DateTime.now(),
        testData: const AssessmentModel(
          testTitle: 'Class 9 Biology Quiz',
          subject: ExamSubject.biology,
          chapterOrTopic: 'Chapter 1',
          totalMarks: 10,
          mcqs: [
            MCQItemModel(
              questionNumber: 1,
              question: 'Biology MCQ 1',
              options: ['A) 1', 'B) 2', 'C) 3', 'D) 4'],
              correctOption: 'A',
              textbookReference: 'Pg 10',
            ),
          ],
          shortQuestions: [
            ShortQuestionItemModel(questionNumber: 1, question: 'Biology Short Q1', marks: 2),
          ],
          longQuestions: [
            LongQuestionItemModel(questionNumber: 1, question: 'Biology Long Q1', marks: 5),
          ],
        ),
      ),
    );
    await recentRepo.saveRecentPaper(
      RecentPaperModel(
        paperId: 'paper_002',
        title: 'Class 9 Chemistry - Chapter 3 Test',
        subject: ExamSubject.chemistry,
        chapterOrTopic: 'Chapter 3',
        totalMarks: 15,
        dateCreated: DateTime.now(),
        testData: const AssessmentModel(
          testTitle: 'Class 9 Chemistry - Chapter 3 Test',
          subject: ExamSubject.chemistry,
          chapterOrTopic: 'Chapter 3',
          totalMarks: 15,
          mcqs: [
            MCQItemModel(
              questionNumber: 1,
              question: 'Chemistry MCQ 1',
              options: ['A) H2O', 'B) CO2', 'C) O2', 'D) N2'],
              correctOption: 'A',
              textbookReference: 'Pg 45',
            ),
          ],
          shortQuestions: [
            ShortQuestionItemModel(questionNumber: 1, question: 'Chemistry Short Q1', marks: 2),
          ],
          longQuestions: [
            LongQuestionItemModel(questionNumber: 1, question: 'Chemistry Long Q1', marks: 5),
          ],
        ),
      ),
    );
    await recentRepo.saveRecentPaper(
      RecentPaperModel(
        paperId: 'paper_001',
        title: 'Class 9 Physics - Chapter 1 Quiz',
        subject: ExamSubject.physics,
        chapterOrTopic: 'Chapter 1',
        totalMarks: 10,
        isFavorite: true,
        dateCreated: DateTime.now(),
        testData: const AssessmentModel(
          testTitle: 'Class 9 Physics - Chapter 1 Quiz',
          subject: ExamSubject.physics,
          chapterOrTopic: 'Chapter 1',
          totalMarks: 10,
          mcqs: [
            MCQItemModel(
              questionNumber: 1,
              question: 'Physics MCQ 1',
              options: ['A) 10', 'B) 20', 'C) 30', 'D) 40'],
              correctOption: 'A',
              textbookReference: 'Pg 10',
            ),
          ],
          shortQuestions: [
            ShortQuestionItemModel(questionNumber: 1, question: 'Physics Short Q1', marks: 2),
          ],
          longQuestions: [
            LongQuestionItemModel(questionNumber: 1, question: 'Physics Long Q1', marks: 5),
          ],
        ),
      ),
    );
  });

  group('Question Bank & Advanced Filters Screen Tests', () {
    testWidgets('Renders Question Bank Screen and filter chips for all 5 mandatory subjects', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget(const QuestionBankScreen()));
      await tester.pumpAndSettle();

      // Verify Header Title
      expect(find.text('Question Bank'), findsWidgets);

      // Verify Search Bar
      expect(find.byKey(const Key('qb_search_input')), findsOneWidget);

      // Verify Subject Filter Chips for all 5 Mandatory Subjects
      expect(find.byKey(const Key('qb_subject_chip_all')), findsOneWidget);
      expect(find.byKey(const Key('qb_subject_chip_physics')), findsOneWidget);
      expect(find.byKey(const Key('qb_subject_chip_chemistry')), findsOneWidget);
      expect(find.byKey(const Key('qb_subject_chip_mathematics')), findsOneWidget);
      expect(find.byKey(const Key('qb_subject_chip_biology')), findsOneWidget);
      expect(find.byKey(const Key('qb_subject_chip_computer science')), findsOneWidget);
    });

    testWidgets('Filters Question Bank by Subject chip selection', (WidgetTester tester) async {
      final qbRepo = QuestionBankRepository();
      final qbProvider = QuestionBankProvider(questionBankRepository: qbRepo);

      await tester.pumpWidget(_createTestWidget(const QuestionBankScreen(), qbProvider: qbProvider));
      await tester.pumpAndSettle();

      // Tap on Physics subject filter chip
      final physicsChip = find.byKey(const Key('qb_subject_chip_physics'));
      await tester.ensureVisible(physicsChip);
      await tester.tap(physicsChip);
      await tester.pumpAndSettle();

      expect(qbProvider.filter.subject, equals(ExamSubject.physics));
      expect(find.text('Physics'), findsWidgets);

      // Tap on Chemistry subject filter chip
      final chemistryChip = find.byKey(const Key('qb_subject_chip_chemistry'));
      await tester.ensureVisible(chemistryChip);
      await tester.tap(chemistryChip);
      await tester.pumpAndSettle();

      expect(qbProvider.filter.subject, equals(ExamSubject.chemistry));
    });

    testWidgets('Expand question card to reveal answer key and options', (WidgetTester tester) async {
      final qbRepo = QuestionBankRepository();
      final qbProvider = QuestionBankProvider(questionBankRepository: qbRepo);

      await tester.pumpWidget(_createTestWidget(const QuestionBankScreen(), qbProvider: qbProvider));
      await tester.pumpAndSettle();

      expect(qbProvider.questions.isNotEmpty, isTrue);

      final firstQ = qbProvider.questions.first;
      final toggleBtn = find.byKey(Key('toggle_expand_btn_${firstQ.id}'));
      expect(toggleBtn, findsOneWidget);

      // Expand card
      await tester.ensureVisible(toggleBtn);
      await tester.tap(toggleBtn);
      await tester.pumpAndSettle();

      expect(find.text('Answer Key / Solution:'), findsOneWidget);
    });

    testWidgets('Open and apply Advanced Filters modal', (WidgetTester tester) async {
      final qbRepo = QuestionBankRepository();
      final qbProvider = QuestionBankProvider(questionBankRepository: qbRepo);

      await tester.pumpWidget(_createTestWidget(const QuestionBankScreen(), qbProvider: qbProvider));
      await tester.pumpAndSettle();

      // Open Modal
      await tester.tap(find.byKey(const Key('qb_filter_icon_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Advanced Filters'), findsOneWidget);

      // Select MCQ type
      await tester.tap(find.byKey(const Key('qb_filter_type_mcq')));
      await tester.pumpAndSettle();

      // Select Hard difficulty
      await tester.tap(find.byKey(const Key('qb_filter_diff_hard')));
      await tester.pumpAndSettle();

      // Apply
      await tester.tap(find.byKey(const Key('qb_modal_apply_btn')));
      await tester.pumpAndSettle();

      expect(qbProvider.filter.type, equals(QuestionType.mcq));
      expect(qbProvider.filter.difficulty, equals(QuestionDifficulty.hard));
    });
  });

  group('Review Screen & Paper Editing Tests', () {
    testWidgets('Renders Review Screen header, summary stats, and section tabs', (WidgetTester tester) async {
      final assessRepo = AssessmentRepository(apiClient: ApiClient());
      final pdfRepo = PdfRepository(apiClient: ApiClient());
      final provider = AssessmentProvider(assessmentRepository: assessRepo, pdfRepository: pdfRepo);
      provider.setTestAssessment(_createSampleTestAssessment());

      await tester.pumpWidget(_createTestWidget(const ReviewPaperScreen(), assessmentProvider: provider));
      await tester.pumpAndSettle();

      expect(find.text('Review Test Paper'), findsWidgets);
      expect(find.byKey(const Key('review_test_title')), findsOneWidget);
      expect(find.byKey(const Key('tab_section_mcqs')), findsOneWidget);
      expect(find.byKey(const Key('tab_section_short')), findsOneWidget);
      expect(find.byKey(const Key('tab_section_long')), findsOneWidget);
      expect(find.byKey(const Key('review_export_pdf_btn')), findsOneWidget);
    });

    testWidgets('Edits MCQ question text in Review Screen', (WidgetTester tester) async {
      final assessRepo = AssessmentRepository(apiClient: ApiClient());
      final pdfRepo = PdfRepository(apiClient: ApiClient());
      final provider = AssessmentProvider(assessmentRepository: assessRepo, pdfRepository: pdfRepo);
      provider.setTestAssessment(_createSampleTestAssessment());

      await tester.pumpWidget(_createTestWidget(const ReviewPaperScreen(), assessmentProvider: provider));
      await tester.pumpAndSettle();

      // Tap edit on first MCQ
      final editBtn = find.byKey(const Key('edit_mcq_btn_0'));
      expect(editBtn, findsOneWidget);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      expect(find.text('Edit MCQ Question'), findsOneWidget);

      // Edit text
      await tester.enterText(find.byKey(const Key('edit_mcq_text_input')), 'Updated Subatomic Question?');
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.byKey(const Key('save_mcq_edit_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Updated Subatomic Question?'), findsOneWidget);
    });

    testWidgets('Deletes short question and updates total marks', (WidgetTester tester) async {
      final assessRepo = AssessmentRepository(apiClient: ApiClient());
      final pdfRepo = PdfRepository(apiClient: ApiClient());
      final provider = AssessmentProvider(assessmentRepository: assessRepo, pdfRepository: pdfRepo);
      provider.setTestAssessment(_createSampleTestAssessment());

      await tester.pumpWidget(_createTestWidget(const ReviewPaperScreen(), assessmentProvider: provider));
      await tester.pumpAndSettle();

      // Switch to Section B (Short questions)
      await tester.tap(find.byKey(const Key('tab_section_short')));
      await tester.pumpAndSettle();

      final deleteBtn = find.byKey(const Key('delete_short_btn_0'));
      expect(deleteBtn, findsOneWidget);

      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Question deleted
      expect(find.byKey(const Key('delete_short_btn_1')), findsNothing);
    });
  });

  group('Recent Papers Screen Tests', () {
    testWidgets('Renders Recent Papers Screen with subject filter chips for all 5 subjects', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestWidget(const RecentPapersScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Recent Papers Archive'), findsWidgets);
      expect(find.byKey(const Key('recent_papers_search_input')), findsOneWidget);

      // Verify all 5 subject chips exist
      expect(find.byKey(const Key('recent_subject_chip_all')), findsOneWidget);
      expect(find.byKey(const Key('recent_subject_chip_physics')), findsOneWidget);
      expect(find.byKey(const Key('recent_subject_chip_chemistry')), findsOneWidget);
      expect(find.byKey(const Key('recent_subject_chip_mathematics')), findsOneWidget);
      expect(find.byKey(const Key('recent_subject_chip_biology')), findsOneWidget);
      expect(find.byKey(const Key('recent_subject_chip_computer science')), findsOneWidget);
    });

    testWidgets('Filters Recent Papers list by subject chip', (WidgetTester tester) async {
      final recentRepo = RecentPapersRepository();
      for (final p in _createSampleTestPapers()) {
        await recentRepo.saveRecentPaper(p);
      }
      final provider = RecentPapersProvider(recentPapersRepository: recentRepo);
      await provider.loadRecentPapers();

      await tester.pumpWidget(_createTestWidget(const RecentPapersScreen(), recentProvider: provider));
      await tester.pumpAndSettle();

      // Filter Physics
      final physicsChip = find.byKey(const Key('recent_subject_chip_physics'));
      await tester.ensureVisible(physicsChip);
      await tester.tap(physicsChip);
      await tester.pumpAndSettle();

      expect(provider.selectedSubjectFilter, equals(ExamSubject.physics));
      expect(find.text('Class 9 Physics - Chapter 1 Quiz'), findsOneWidget);

      // Filter Chemistry
      final chemistryChip = find.byKey(const Key('recent_subject_chip_chemistry'));
      await tester.ensureVisible(chemistryChip);
      await tester.tap(chemistryChip);
      await tester.pumpAndSettle();

      expect(provider.selectedSubjectFilter, equals(ExamSubject.chemistry));
      expect(find.text('Class 9 Chemistry - Chapter 3 Test'), findsOneWidget);
    });

    testWidgets('Toggles favorite status on recent paper', (WidgetTester tester) async {
      final recentRepo = RecentPapersRepository();
      for (final p in _createSampleTestPapers()) {
        await recentRepo.saveRecentPaper(p);
      }
      final provider = RecentPapersProvider(recentPapersRepository: recentRepo);
      await provider.loadRecentPapers();

      await tester.pumpWidget(_createTestWidget(const RecentPapersScreen(), recentProvider: provider));
      await tester.pumpAndSettle();

      final favBtn = find.byKey(const Key('favorite_paper_btn_paper_001'));
      expect(favBtn, findsOneWidget);

      await tester.ensureVisible(favBtn);
      await tester.tap(favBtn);
      await tester.pumpAndSettle();

      expect(provider.papers.firstWhere((p) => p.paperId == 'paper_001').isFavorite, isFalse);
    });
  });

  group('PDF Preview & Actions Screen Tests', () {
    testWidgets('Renders PDF Preview canvas, zoom controls, and action toolbar buttons', (WidgetTester tester) async {
      final assessRepo = AssessmentRepository(apiClient: ApiClient());
      final pdfRepo = PdfRepository(apiClient: ApiClient());
      final provider = AssessmentProvider(assessmentRepository: assessRepo, pdfRepository: pdfRepo);
      provider.setTestAssessment(_createSampleTestAssessment());

      await tester.pumpWidget(_createTestWidget(const PdfPreviewScreen(), assessmentProvider: provider));
      await tester.pumpAndSettle();

      expect(find.text('PDF Document Preview'), findsWidgets);
      expect(find.text('Page 1 of 1'), findsOneWidget);
      expect(find.byKey(const Key('pdf_zoom_in_btn')), findsOneWidget);
      expect(find.byKey(const Key('pdf_zoom_out_btn')), findsOneWidget);
      expect(find.byKey(const Key('pdf_btn_download')), findsOneWidget);
      expect(find.byKey(const Key('pdf_btn_print')), findsOneWidget);
      expect(find.byKey(const Key('pdf_btn_share')), findsOneWidget);
      expect(find.byKey(const Key('pdf_btn_regenerate')), findsOneWidget);
    });

    testWidgets('Opens Export & Print Options modal in PDF Preview Screen', (WidgetTester tester) async {
      final assessRepo = AssessmentRepository(apiClient: ApiClient());
      final pdfRepo = PdfRepository(apiClient: ApiClient());
      final provider = AssessmentProvider(assessmentRepository: assessRepo, pdfRepository: pdfRepo);
      provider.setTestAssessment(_createSampleTestAssessment());

      await tester.pumpWidget(_createTestWidget(const PdfPreviewScreen(), assessmentProvider: provider));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('pdf_preview_options_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Export & Print Options'), findsOneWidget);
      expect(find.byKey(const Key('pdf_option_include_answer_key')), findsOneWidget);

      final applyBtn = find.byKey(const Key('pdf_apply_export_settings_btn'));
      await tester.ensureVisible(applyBtn);
      await tester.tap(applyBtn);
      await tester.pumpAndSettle();

      expect(find.text('Export & Print Options'), findsNothing);
    });
  });
}
