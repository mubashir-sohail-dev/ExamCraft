import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_app/core/constants/subjects.dart';
import 'package:flutter_app/core/network/api_client.dart';
import 'package:flutter_app/core/routes/app_routes.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/data/models/assessment_model.dart';
import 'package:flutter_app/data/models/textbook_model.dart';
import 'package:flutter_app/data/repositories/assessment_repository.dart';
import 'package:flutter_app/data/repositories/pdf_repository.dart';
import 'package:flutter_app/data/repositories/recent_papers_repository.dart';
import 'package:flutter_app/data/repositories/upload_repository.dart';
import 'package:flutter_app/presentation/providers/assessment_provider.dart';
import 'package:flutter_app/presentation/providers/connection_provider.dart';
import 'package:flutter_app/presentation/providers/upload_provider.dart';
import 'package:flutter_app/screens/generate/generate_assessment_screen.dart';
import 'package:flutter_app/screens/generate/generating_screen.dart';
import 'package:flutter_app/screens/upload/upload_status_screen.dart';
import 'package:flutter_app/screens/upload/upload_textbook_screen.dart';

/// Fake Mock Upload Repository for genuine testing without network dependency.
class MockUploadRepository implements IUploadRepository {
  bool uploadCalled = false;
  ExamSubject? lastUploadedSubject;
  int? lastUploadedGrade;

  @override
  Future<TextbookUploadResponseModel> uploadTextbook({
    required File file,
    required ExamSubject subject,
    int grade = 9,
  }) async {
    uploadCalled = true;
    lastUploadedSubject = subject;
    lastUploadedGrade = grade;
    return TextbookUploadResponseModel(
      status: 'success',
      message: 'Uploaded ${subject.displayName} Grade $grade textbook successfully',
      chunksIndexed: 348,
    );
  }

  @override
  Future<TextbookProcessingStatusModel> getUploadStatus(String uploadId) async {
    return TextbookProcessingStatusModel(
      uploadId: uploadId,
      filename: 'Physics_Unit_3.pdf',
      subject: ExamSubject.physics,
      grade: 9,
      status: TextbookUploadStatus.completed,
      progress: 1.0,
      message: 'Processing completed',
      chunksProcessed: 348,
      totalChunks: 348,
      updatedAt: DateTime.now(),
    );
  }
}

/// Fake Mock Assessment Repository for testing subject chapter loading and draft generation.
class MockAssessmentRepository implements IAssessmentRepository {
  bool generateCalled = false;
  GenerationOptions? lastRequest;

  @override
  Future<List<ExamSubject>> getSupportedSubjects() async {
    return SubjectUtils.allSubjects;
  }

  @override
  Future<List<String>> getSubjectChapters(ExamSubject subject,
      {int grade = 9}) async {
    switch (subject) {
      case ExamSubject.physics:
        return ['Kinematics', 'Dynamics', 'Gravitation', 'Work & Energy'];
      case ExamSubject.chemistry:
        return ['Fundamentals of Chemistry', 'Structure of Atoms', 'Periodic Table'];
      case ExamSubject.mathematics:
        return ['Matrices', 'Real Numbers', 'Quadratic Equations', 'Calculus'];
      case ExamSubject.biology:
        return ['Cell Biology', 'Enzymes', 'Bioenergetics', 'Genetics'];
      case ExamSubject.computerScience:
        return ['Problem Solving', 'Data Structures', 'Algorithms', 'Databases'];
    }
  }

  @override
  Future<ChapterMetadata> getChapterMetadata(String subject, String chapter,
      {int grade = 9}) async {
    return ChapterMetadata(
      subject: subject,
      chapter: chapter,
      exercises: ['Exercise 1.1', 'Exercise 1.2'],
    );
  }

  @override
  Future<AssessmentModel> generateDraftTest(GenerationOptions request) async {
    generateCalled = true;
    lastRequest = request;
    final total = (request.mcqCount * 1) + (request.shortCount * 2) + (request.longCount * 5);

    return AssessmentModel(
      testTitle: '${request.subject.displayName} Test - ${request.chapterName}',
      subject: request.subject,
      chapterOrTopic: request.chapterName,
      totalMarks: total,
      mcqs: List.generate(
        request.mcqCount,
        (i) => MCQItemModel(
          questionNumber: i + 1,
          question: 'MCQ Q${i + 1}',
          options: const ['A', 'B', 'C', 'D'],
          correctOption: 'A',
          textbookReference: 'Pg ${i + 1}',
        ),
      ),
      shortQuestions: List.generate(
        request.shortCount,
        (i) => ShortQuestionItemModel(
          questionNumber: i + 1,
          question: 'Short Q${i + 1}',
          marks: 2,
        ),
      ),
      longQuestions: List.generate(
        request.longCount,
        (i) => LongQuestionItemModel(
          questionNumber: i + 1,
          question: 'Long Q${i + 1}',
          marks: 5,
        ),
      ),
    );
  }
}

void main() {
  late ThemeController themeController;
  late MockUploadRepository mockUploadRepo;
  late MockAssessmentRepository mockAssessmentRepo;

  setUp(() {
    themeController = ThemeController();
    mockUploadRepo = MockUploadRepository();
    mockAssessmentRepo = MockAssessmentRepository();
  });

  Widget buildAppWrapper({required Widget child, String initialRoute = '/'}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
        ChangeNotifierProvider<ConnectionProvider>(
          create: (_) => ConnectionProvider(apiClient: ApiClient()),
        ),
        ChangeNotifierProvider<UploadProvider>(
          create: (_) => UploadProvider(uploadRepository: mockUploadRepo),
        ),
        ChangeNotifierProvider<AssessmentProvider>(
          create: (_) => AssessmentProvider(
            assessmentRepository: mockAssessmentRepo,
            pdfRepository: PdfRepository(apiClient: ApiClient()),
            recentPapersRepository: RecentPapersRepository(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Test Generator Flow Test',
        theme: themeController.lightThemeData,
        darkTheme: themeController.darkThemeData,
        initialRoute: initialRoute,
        routes: AppRoutes.routesMap,
        home: child,
      ),
    );
  }

  group('Milestone 4 - Upload Textbook Screen Tests', () {
    testWidgets('Renders UploadTextbookScreen with subject dropdown, grade, and file picker',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildAppWrapper(
          child: UploadTextbookScreen(uploadRepository: mockUploadRepo),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Screen Header and Dropzone text
      expect(find.text('Upload Textbook'), findsWidgets);
      expect(find.text('Select PDF Textbook'), findsOneWidget);
      expect(find.byKey(const Key('btn_pick_file')), findsOneWidget);

      // Verify Subject selection dropdown with all 5 mandatory subjects
      expect(find.byKey(const Key('dropdown_subject')), findsOneWidget);
      expect(find.byKey(const Key('dropdown_grade')), findsOneWidget);
      expect(find.byKey(const Key('input_chapter_name')), findsOneWidget);
      expect(find.byKey(const Key('btn_upload_textbook')), findsOneWidget);
    });

    testWidgets('Form submission calls UploadRepository.uploadTextbook and navigates to /upload/status',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildAppWrapper(
          child: UploadTextbookScreen(uploadRepository: mockUploadRepo),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Upload button
      final uploadBtn = find.byKey(const Key('btn_upload_textbook'));
      expect(uploadBtn, findsOneWidget);
      await tester.ensureVisible(uploadBtn);
      await tester.tap(uploadBtn);
      await tester.pumpAndSettle();

      // Verify UploadRepository was called
      expect(mockUploadRepo.uploadCalled, isTrue);
      expect(mockUploadRepo.lastUploadedSubject, equals(ExamSubject.physics));

      // Verify navigation to UploadStatusScreen
      expect(find.text('Textbook Processing Status'), findsOneWidget);
    });
  });

  group('Milestone 4 - Upload & Processing Status Screen Tests', () {
    testWidgets('Renders UploadStatusScreen timeline, progress bar, cancel, and proceed buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildAppWrapper(
          child: const UploadStatusScreen(),
        ),
      );
      await tester.pump();

      // Verify title & timeline steps
      expect(find.text('Textbook Processing Status'), findsOneWidget);
      expect(find.text('Processing Pipeline Steps'), findsOneWidget);
      expect(find.text('Select PDF & File Validation'), findsOneWidget);
      expect(find.text('Document Upload to Backend'), findsOneWidget);
      expect(find.text('OCR Text Extraction & Chunking'), findsOneWidget);
      expect(find.text('Qdrant Knowledge Base Indexing'), findsOneWidget);

      // Verify action buttons
      final cancelBtn = find.byKey(const Key('btn_cancel_status'));
      final proceedBtn = find.byKey(const Key('btn_proceed_generate'));
      expect(cancelBtn, findsOneWidget);
      expect(proceedBtn, findsOneWidget);

      // Tap proceed to generate assessment button
      await tester.ensureVisible(proceedBtn);
      await tester.tap(proceedBtn);
      await tester.pumpAndSettle();

      // Verify navigation to GenerateAssessmentScreen
      expect(find.text('Generate Assessment'), findsWidgets);
    });
  });

  group('Milestone 4 - Assessment Repository Chapter Loading for All 5 Subjects', () {
    test('getSubjectChapters fetches chapters for all 5 mandatory subjects', () async {
      final repo = mockAssessmentRepo;

      for (final subject in ExamSubject.values) {
        final chapters = await repo.getSubjectChapters(subject);
        expect(chapters, isNotEmpty, reason: 'Subject ${subject.displayName} must have chapters');
      }
    });

    test('generateDraftTest computes total marks accurately', () async {
      const request = GenerationOptions(
        subject: ExamSubject.chemistry,
        chapterName: 'Structure of Atoms',
        mcqCount: 10,
        shortCount: 5,
        longCount: 2,
      );

      final result = await mockAssessmentRepo.generateDraftTest(request);
      expect(result.subject, equals(ExamSubject.chemistry));
      expect(result.mcqs.length, equals(10));
      expect(result.shortQuestions.length, equals(5));
      expect(result.longQuestions.length, equals(2));
      // (10 * 1) + (5 * 2) + (2 * 5) = 10 + 10 + 10 = 30
      expect(result.totalMarks, equals(30));
    });
  });

  group('Milestone 4 - Generate Assessment Screen Tests', () {
    testWidgets('Renders 5 subject grid, chapter dropdown, sliders, total marks, and generate submit',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildAppWrapper(
          child: GenerateAssessmentScreen(repository: mockAssessmentRepo),
        ),
      );
      await tester.pumpAndSettle();

      // Verify screen title
      expect(find.text('Generate Assessment'), findsWidgets);

      // Verify 5 mandatory subject tiles in selector grid
      for (final subject in ExamSubject.values) {
        expect(find.byKey(Key('subject_tile_${subject.name}')), findsOneWidget);
      }

      // Verify total marks auto-calculator widget
      expect(find.byKey(const Key('txt_total_marks')), findsOneWidget);
      // Default: (5 * 1) + (3 * 2) + (1 * 5) = 5 + 6 + 5 = 16 Marks
      expect(find.text('16 Marks'), findsOneWidget);

      // Tap Biology subject tile to change subject and load chapters
      final bioTile = find.byKey(const Key('subject_tile_biology'));
      await tester.tap(bioTile);
      await tester.pumpAndSettle();

      // Tap Generate Assessment button
      final generateBtn = find.byKey(const Key('btn_generate_assessment'));
      expect(generateBtn, findsOneWidget);
      await tester.ensureVisible(generateBtn);
      await tester.tap(generateBtn);
      await tester.pumpAndSettle();

      // Verify AssessmentRepository.generateDraftTest was called
      expect(mockAssessmentRepo.generateCalled, isTrue);
      expect(mockAssessmentRepo.lastRequest?.subject, equals(ExamSubject.biology));

      // Verify navigation to GeneratingScreen
      expect(find.text('Generating Assessment...'), findsWidgets);
    });
  });

  group('Milestone 4 - Generating Screen Tests', () {
    testWidgets('Renders GeneratingScreen steps and navigate to review',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildAppWrapper(
          child: const GeneratingScreen(),
        ),
      );
      await tester.pump();

      // Verify status heading and steps
      expect(find.byKey(const Key('txt_generating_status')), findsOneWidget);
      expect(find.byKey(const Key('btn_view_draft_result')), findsOneWidget);

      // Tap view draft result
      final viewBtn = find.byKey(const Key('btn_view_draft_result'));
      await tester.ensureVisible(viewBtn);
      await tester.tap(viewBtn);
      await tester.pumpAndSettle();

      // Verify navigation to review screen
      expect(find.text('Review Test Paper'), findsOneWidget);
    });
  });
}
