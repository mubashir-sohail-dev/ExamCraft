import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_app/core/constants/subjects.dart';
import 'package:flutter_app/core/network/api_client.dart';
import 'package:flutter_app/core/routes/app_routes.dart';
import 'package:flutter_app/data/models/assessment_model.dart';
import 'package:flutter_app/data/models/textbook_model.dart';
import 'package:flutter_app/data/repositories/assessment_repository.dart';
import 'package:flutter_app/data/repositories/pdf_repository.dart';
import 'package:flutter_app/data/repositories/upload_repository.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/presentation/providers/assessment_provider.dart';
import 'package:flutter_app/presentation/providers/connection_provider.dart';
import 'package:flutter_app/presentation/providers/upload_provider.dart';
import 'package:flutter_app/screens/generate/generate_assessment_screen.dart';
import 'package:flutter_app/screens/upload/upload_textbook_screen.dart';

/// Navigator Observer to capture pushed routes and arguments.
class AdversarialNavigatorObserver extends NavigatorObserver {
  final void Function(Route<dynamic> route) onPushed;
  AdversarialNavigatorObserver(this.onPushed);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    onPushed(route);
  }
}

/// Mock ApiClient for empirical repository testing.
class MockAdversarialApiClient extends ApiClient {
  String? lastPath;
  Map<String, dynamic>? lastQueryParams;
  bool shouldFail = false;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    dynamic options,
  }) async {
    lastPath = path;
    lastQueryParams = queryParameters;
    if (shouldFail) {
      throw ApiException(message: 'Simulated API network error');
    }
    if (path.contains('/chapters') && !path.contains('/metadata')) {
      final grade = queryParameters?['grade'] as int? ?? 9;
      if (grade == 10) return {'chapters': <String>[]};
      return {
        'chapters': ['Ch 1 (Grade $grade)', 'Ch 2 (Grade $grade)']
      };
    }
    if (path.contains('/metadata')) {
      final grade = queryParameters?['grade'] as int? ?? 9;
      return {
        'subject': 'Mathematics',
        'chapter': 'Ch 1',
        'exercises': ['Ex 1.1 (Grade $grade)', 'Ex 1.2 (Grade $grade)'],
      };
    }
    return {};
  }
}

/// Mock repository with controllable async responses for concurrency testing.
class MockAdversarialRepo implements IAssessmentRepository {
  int callCount = 0;
  List<int> gradesCalled = [];
  Map<int, Completer<List<String>>> completers = {};

  @override
  Future<List<ExamSubject>> getSupportedSubjects() async => SubjectUtils.allSubjects;

  @override
  Future<List<String>> getSubjectChapters(ExamSubject subject, {int grade = 9}) async {
    callCount++;
    gradesCalled.add(grade);
    if (completers.containsKey(grade)) {
      return completers[grade]!.future;
    }
    if (grade == 10) return [];
    return ['Ch 1 Grade $grade', 'Ch 2 Grade $grade'];
  }

  @override
  Future<ChapterMetadata> getChapterMetadata(String subject, String chapter, {int grade = 9}) async {
    return ChapterMetadata(
      subject: subject,
      chapter: chapter,
      exercises: ['Ex 1.1 (Grade $grade)', 'Ex 1.2 (Grade $grade)'],
    );
  }

  @override
  Future<AssessmentModel> generateDraftTest(GenerationOptions request) async {
    return AssessmentModel(
      testTitle: 'Test Class ${request.grade}',
      subject: request.subject,
      chapterOrTopic: request.chapterName,
      grade: request.grade,
      totalMarks: 25,
    );
  }
}

/// Mock upload repository for testing UploadTextbookScreen.
class MockAdversarialUploadRepo implements IUploadRepository {
  bool uploadCalled = false;
  ExamSubject? lastSubject;
  int? lastGrade;

  @override
  Future<TextbookUploadResponseModel> uploadTextbook({
    required File file,
    required ExamSubject subject,
    int grade = 9,
  }) async {
    uploadCalled = true;
    lastSubject = subject;
    lastGrade = grade;
    return TextbookUploadResponseModel(
      status: 'success',
      message: 'Uploaded ${subject.displayName} Grade $grade textbook successfully',
      chunksIndexed: 100,
    );
  }

  @override
  Future<TextbookProcessingStatusModel> getUploadStatus(String uploadId) async {
    return TextbookProcessingStatusModel(
      uploadId: uploadId,
      filename: 'sample.pdf',
      subject: ExamSubject.physics,
      grade: 10,
      status: TextbookUploadStatus.completed,
      progress: 1.0,
      message: 'Processed',
      chunksProcessed: 100,
      totalChunks: 100,
      updatedAt: DateTime.now(),
    );
  }
}

/// Helper to instantiate AssessmentProvider with mock dependencies.
AssessmentProvider createTestProvider(IAssessmentRepository repo) {
  return AssessmentProvider(
    assessmentRepository: repo,
    pdfRepository: PdfRepository(apiClient: ApiClient()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adversarial Challenge 1: Requirement R2 - Academic Grade in Models', () {
    test('1.1 GenerationOptions roundtrips grades 9..12 and serializes integer field', () {
      for (final g in [9, 10, 11, 12]) {
        final opts = GenerationOptions(
          subject: ExamSubject.physics,
          chapterName: 'Vectors',
          grade: g,
        );
        expect(opts.grade, equals(g));
        final json = opts.toJson();
        expect(json['grade'], equals(g));
        expect(json['grade'], isA<int>());

        final restored = GenerationOptions.fromJson(json);
        expect(restored.grade, equals(g));
        expect(restored.subject, equals(ExamSubject.physics));
        expect(restored.chapterName, equals('Vectors'));
      }
    });

    test('1.2 GenerationOptions boundary assertions reject out-of-range grades in debug mode', () {
      expect(
        () => GenerationOptions(subject: ExamSubject.physics, chapterName: 'C', grade: 8),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => GenerationOptions(subject: ExamSubject.physics, chapterName: 'C', grade: 13),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => GenerationOptions(subject: ExamSubject.physics, chapterName: 'C', grade: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => GenerationOptions(subject: ExamSubject.physics, chapterName: 'C', grade: -5),
        throwsA(isA<AssertionError>()),
      );
    });

    test('1.3 GenerationOptions.fromJson defaults to 9 when grade is null or missing', () {
      final jsonMissing = {
        'subject': 'Physics',
        'chapter_name': 'Kinematics',
      };
      expect(GenerationOptions.fromJson(jsonMissing).grade, equals(9));

      final jsonNull = {
        'subject': 'Physics',
        'chapter_name': 'Kinematics',
        'grade': null,
      };
      expect(GenerationOptions.fromJson(jsonNull).grade, equals(9));
    });

    test('1.4 GenerationOptions.fromJson typing edge case: double raises TypeError in cast', () {
      final jsonDouble = {
        'subject': 'Physics',
        'chapter_name': 'Kinematics',
        'grade': 10.0,
      };
      expect(
        () => GenerationOptions.fromJson(jsonDouble),
        throwsA(isA<TypeError>()),
        reason: 'Dart json[grade] as int? throws TypeError when given double 10.0',
      );
    });

    test('1.5 GenerationOptions copyWith updates grade and preserves all other fields', () {
      const original = GenerationOptions(
        subject: ExamSubject.chemistry,
        chapterName: 'Atomic Structure',
        grade: 9,
        mcqCount: 7,
        shortCount: 4,
        longCount: 2,
        includeAnswerKey: true,
      );
      final updated = original.copyWith(grade: 11);
      expect(updated.grade, equals(11));
      expect(updated.subject, equals(ExamSubject.chemistry));
      expect(updated.chapterName, equals('Atomic Structure'));
      expect(updated.mcqCount, equals(7));

      final unchanged = original.copyWith();
      expect(unchanged.grade, equals(9));
    });

    test('1.6 AssessmentModel roundtrips grades 9..12 and serializes integer field', () {
      for (final g in [9, 10, 11, 12]) {
        final model = AssessmentModel(
          testTitle: 'Class $g Test',
          subject: ExamSubject.biology,
          chapterOrTopic: 'Cells',
          grade: g,
          totalMarks: 30,
        );
        expect(model.grade, equals(g));
        final json = model.toJson();
        expect(json['grade'], equals(g));
        expect(json['grade'], isA<int>());

        final restored = AssessmentModel.fromJson(json);
        expect(restored.grade, equals(g));
        expect(restored.testTitle, equals('Class $g Test'));
        expect(restored.subject, equals(ExamSubject.biology));
      }
    });

    test('1.7 AssessmentModel.fromJson defaults to 9 when grade is null or missing', () {
      final jsonMissing = {
        'test_title': 'Biology Test',
        'subject': 'Biology',
        'chapter_or_topic': 'Cells',
        'total_marks': 25,
      };
      expect(AssessmentModel.fromJson(jsonMissing).grade, equals(9));

      final jsonNull = {
        'test_title': 'Biology Test',
        'subject': 'Biology',
        'chapter_or_topic': 'Cells',
        'grade': null,
        'total_marks': 25,
      };
      expect(AssessmentModel.fromJson(jsonNull).grade, equals(9));
    });

    test('1.8 AssessmentModel.fromJson typing edge case: double raises TypeError in cast', () {
      final jsonDouble = {
        'test_title': 'Biology Test',
        'subject': 'Biology',
        'chapter_or_topic': 'Cells',
        'grade': 10.0,
        'total_marks': 25,
      };
      expect(
        () => AssessmentModel.fromJson(jsonDouble),
        throwsA(isA<TypeError>()),
        reason: 'Dart json[grade] as int? throws TypeError when given double 10.0',
      );
    });

    test('1.9 AssessmentModel copyWith updates grade and preserves questions', () {
      const original = AssessmentModel(
        testTitle: 'Test 1',
        subject: ExamSubject.computerScience,
        chapterOrTopic: 'Algorithms',
        grade: 9,
        totalMarks: 50,
      );
      final updated = original.copyWith(grade: 12);
      expect(updated.grade, equals(12));
      expect(updated.chapterOrTopic, equals('Algorithms'));

      final unchanged = original.copyWith();
      expect(unchanged.grade, equals(9));
    });
  });

  group('Adversarial Challenge 2: Requirement R2 & R3 - Repository & Provider Grade Query Params', () {
    test('2.1 AssessmentRepository forwards grade query parameter for all classes 9..12', () async {
      final mockClient = MockAdversarialApiClient();
      final repo = AssessmentRepository(apiClient: mockClient);

      for (final g in [9, 10, 11, 12]) {
        await repo.getSubjectChapters(ExamSubject.computerScience, grade: g);
        expect(mockClient.lastQueryParams?['grade'], equals(g));
        expect(mockClient.lastPath, contains('/api/subjects/Computer%20Science/chapters'));

        await repo.getChapterMetadata('Mathematics', 'Ch 1: Limits', grade: g);
        expect(mockClient.lastQueryParams?['grade'], equals(g));
        expect(mockClient.lastPath, contains('/api/subjects/Mathematics/chapters/Ch%201%3A%20Limits/metadata'));
      }
    });

    test('2.2 AssessmentRepository returns empty list when getSubjectChapters encounters API failure', () async {
      final mockClient = MockAdversarialApiClient();
      mockClient.shouldFail = true;
      final repo = AssessmentRepository(apiClient: mockClient);

      final result = await repo.getSubjectChapters(ExamSubject.chemistry, grade: 10);
      expect(result, isEmpty);
    });

    test('2.3 AssessmentRepository rethrows ApiException on getChapterMetadata failure', () async {
      final mockClient = MockAdversarialApiClient();
      mockClient.shouldFail = true;
      final repo = AssessmentRepository(apiClient: mockClient);

      expect(
        () => repo.getChapterMetadata('Mathematics', 'Ch 1', grade: 9),
        throwsA(isA<ApiException>()),
      );
    });

    test('2.4 AssessmentProvider.selectGrade clears chapter and exercises immediately before async fetch', () async {
      final repo = MockAdversarialRepo();
      final provider = createTestProvider(repo);
      await provider.fetchChaptersForSubject(ExamSubject.physics, grade: 9);

      expect(provider.selectedGrade, equals(9));
      expect(provider.selectedChapter, equals('Ch 1 Grade 9'));

      // When selectGrade(10) is called, selection must be cleared immediately
      final future = provider.selectGrade(10);
      expect(provider.selectedGrade, equals(10));
      expect(provider.selectedChapter, isNull);
      expect(provider.availableExercises, isEmpty);
      expect(provider.selectedExercise, isNull);

      await future;
      expect(provider.chapters, isEmpty);
      expect(provider.selectedChapter, isNull);
    });

    test('2.5 AssessmentProvider.selectGrade early-returns if same grade and chapters non-empty', () async {
      final repo = MockAdversarialRepo();
      final provider = createTestProvider(repo);
      await provider.fetchChaptersForSubject(ExamSubject.physics, grade: 9);
      expect(repo.callCount, equals(1));

      await provider.selectGrade(9);
      expect(repo.callCount, equals(1), reason: 'Duplicate call should early return');
    });

    test('2.6 AssessmentProvider.selectGrade retries fetch if same grade but chapters empty', () async {
      final repo = MockAdversarialRepo();
      final provider = createTestProvider(repo);
      await provider.selectGrade(10); // Grade 10 returns empty list []
      expect(repo.callCount, equals(1));
      expect(provider.chapters, isEmpty);

      // Calling selectGrade(10) again should retry fetch because chapters is empty
      await provider.selectGrade(10);
      expect(repo.callCount, equals(2));
    });

    test('2.7 AssessmentProvider.generateDraftTest sets grade: provider.selectedGrade in GenerationOptions', () async {
      final repo = MockAdversarialRepo();
      final provider = createTestProvider(repo);
      await provider.selectGrade(11);
      provider.selectSubject(ExamSubject.physics);
      await provider.fetchChaptersForSubject(ExamSubject.physics, grade: 11);

      final testResult = await provider.generateDraftTest();
      expect(testResult?.grade, equals(11));
    });
  });

  group('Adversarial Challenge 3: Requirement R3 - Concurrency, Rapid Transitions & Race Conditions', () {
    test('3.1 Rapid successive grade switching (9 -> 10 -> 11 -> 12) converges on final selection', () async {
      final repo = MockAdversarialRepo();
      final provider = createTestProvider(repo);

      await Future.wait([
        provider.selectGrade(10),
        provider.selectGrade(11),
        provider.selectGrade(12),
      ]);

      expect(provider.selectedGrade, equals(12));
      expect(provider.selectedChapter, equals('Ch 1 Grade 12'));
      expect(provider.chapters, contains('Ch 1 Grade 12'));
    });

    test('3.2 Empirical proof of out-of-order async response completion hazard', () async {
      final repo = MockAdversarialRepo();
      repo.completers[10] = Completer<List<String>>();
      repo.completers[11] = Completer<List<String>>();

      final provider = createTestProvider(repo);

      // Trigger grade 10 (pending)
      final future10 = provider.selectGrade(10);
      // Trigger grade 11 (pending)
      final future11 = provider.selectGrade(11);

      expect(provider.selectedGrade, equals(11));

      // Fast network response: Grade 11 completes first
      repo.completers[11]!.complete(['Ch 1 Grade 11']);
      await future11;
      expect(provider.chapters, equals(['Ch 1 Grade 11']));

      // Slow network response: Grade 10 completes second (out of order!)
      repo.completers[10]!.complete(<String>[]);
      await future10;

      // Demonstrates the out-of-order completion hazard when lacking request tokens:
      // provider.chapters was overwritten by the stale Grade 10 response
      expect(provider.chapters, isEmpty);
      expect(provider.selectedGrade, equals(11));
    });

    test('3.3 Transitioning from empty chapters to non-empty restores chapter selection', () async {
      final repo = MockAdversarialRepo();
      final provider = createTestProvider(repo);

      // Select Grade 10 (empty)
      await provider.selectGrade(10);
      expect(provider.chapters, isEmpty);
      expect(provider.selectedChapter, isNull);

      // Select Grade 9 (available)
      await provider.selectGrade(9);
      expect(provider.chapters, isNotEmpty);
      expect(provider.selectedChapter, equals('Ch 1 Grade 9'));
    });
  });

  group('Adversarial Challenge 4: Requirement R4 - Generator UI ChoiceChips, Empty State & Zero-Mock', () {
    testWidgets('4.1 ChoiceChips render for Classes 9..12, amber card on empty, and button disabled',
        (WidgetTester tester) async {
      final repo = MockAdversarialRepo();
      final provider = createTestProvider(repo);
      final themeController = ThemeController();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeController>.value(value: themeController),
            ChangeNotifierProvider<AssessmentProvider>.value(value: provider),
            ChangeNotifierProvider<ConnectionProvider>(
              create: (_) => ConnectionProvider(apiClient: ApiClient()),
            ),
            ChangeNotifierProvider<UploadProvider>(
              create: (_) => UploadProvider(uploadRepository: MockAdversarialUploadRepo()),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: GenerateAssessmentScreen(repository: repo)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Chips 9, 10, 11, 12 must be rendered
      expect(find.byKey(const Key('chip_class_9')), findsOneWidget);
      expect(find.byKey(const Key('chip_class_10')), findsOneWidget);
      expect(find.byKey(const Key('chip_class_11')), findsOneWidget);
      expect(find.byKey(const Key('chip_class_12')), findsOneWidget);

      // Switch to Class 10 (empty chapters)
      await tester.tap(find.byKey(const Key('chip_class_10')));
      await tester.pumpAndSettle();

      expect(provider.selectedGrade, equals(10));
      expect(provider.chapters, isEmpty);

      // Amber warning card MUST be displayed
      final amberCard = find.byKey(const Key('card_empty_chapters_warning'));
      expect(amberCard, findsOneWidget);
      expect(find.text('No Indexed Chapters Available'), findsOneWidget);
      expect(find.byKey(const Key('btn_upload_textbook_empty')), findsOneWidget);
      expect(find.byKey(const Key('dropdown_chapter')), findsNothing);

      // Generate Assessment button MUST be disabled (onPressed == null)
      final generateBtn = tester.widget<ElevatedButton>(find.byKey(const Key('btn_generate_assessment')));
      expect(
        generateBtn.onPressed,
        isNull,
        reason: 'Zero-mock policy: generate button must be disabled when chapters are empty',
      );

      // Switch to Class 11 (chapters available)
      await tester.tap(find.byKey(const Key('chip_class_11')));
      await tester.pumpAndSettle();

      expect(provider.selectedGrade, equals(11));
      expect(provider.chapters, isNotEmpty);
      expect(find.byKey(const Key('card_empty_chapters_warning')), findsNothing);
      expect(find.byKey(const Key('dropdown_chapter')), findsOneWidget);

      final generateBtnActive = tester.widget<ElevatedButton>(find.byKey(const Key('btn_generate_assessment')));
      expect(generateBtnActive.onPressed, isNotNull);
    });

    testWidgets('4.2 Empty state "Upload Textbook" button pushes AppRoutes.upload with subject and grade arguments',
        (WidgetTester tester) async {
      final repo = MockAdversarialRepo();
      final provider = createTestProvider(repo);
      final themeController = ThemeController();

      String? pushedRouteName;
      Object? pushedRouteArgs;

      final observer = AdversarialNavigatorObserver((route) {
        pushedRouteName = route.settings.name;
        pushedRouteArgs = route.settings.arguments;
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeController>.value(value: themeController),
            ChangeNotifierProvider<AssessmentProvider>.value(value: provider),
            ChangeNotifierProvider<ConnectionProvider>(
              create: (_) => ConnectionProvider(apiClient: ApiClient()),
            ),
            ChangeNotifierProvider<UploadProvider>(
              create: (_) => UploadProvider(uploadRepository: MockAdversarialUploadRepo()),
            ),
          ],
          child: MaterialApp(
            navigatorObservers: [observer],
            routes: {
              '/': (context) => Scaffold(body: GenerateAssessmentScreen(repository: repo)),
              AppRoutes.upload: (context) => const Scaffold(body: Text('Upload Destination')),
            },
            initialRoute: '/',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Class 10 to trigger empty state
      await tester.tap(find.byKey(const Key('chip_class_10')));
      await tester.pumpAndSettle();

      // Tap Upload Textbook button in amber card
      final uploadBtn = find.byKey(const Key('btn_upload_textbook_empty'));
      expect(uploadBtn, findsOneWidget);
      await tester.ensureVisible(uploadBtn);
      await tester.tap(uploadBtn);
      await tester.pumpAndSettle();

      expect(pushedRouteName, equals(AppRoutes.upload));
      expect(pushedRouteArgs, isA<Map>());
      final mapArgs = pushedRouteArgs as Map;
      expect(mapArgs['grade'], equals(10));
      expect(mapArgs['subject'], equals(provider.selectedSubject.apiString));
    });
  });

  group('Adversarial Challenge 5: Requirement R4 - UploadTextbookScreen Route Argument Parsing Resilience', () {
    Widget createUploadNavApp({required Object? args, required MockAdversarialUploadRepo uploadRepo}) {
      final themeController = ThemeController();
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeController>.value(value: themeController),
          ChangeNotifierProvider<UploadProvider>(
            create: (_) => UploadProvider(uploadRepository: uploadRepo),
          ),
        ],
        child: MaterialApp(
          routes: {
            '/': (context) => Scaffold(
                  body: ElevatedButton(
                    key: const Key('btn_nav'),
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.upload, arguments: args);
                    },
                    child: const Text('Nav'),
                  ),
                ),
            AppRoutes.upload: (context) => UploadTextbookScreen(uploadRepository: uploadRepo),
          },
          initialRoute: '/',
        ),
      );
    }

    testWidgets('5.1 UploadTextbookScreen handles null route arguments gracefully',
        (WidgetTester tester) async {
      final uploadRepo = MockAdversarialUploadRepo();
      await tester.pumpWidget(createUploadNavApp(args: null, uploadRepo: uploadRepo));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_nav')));
      await tester.pumpAndSettle();

      expect(find.byType(UploadTextbookScreen), findsOneWidget);
      expect(find.text('Physics'), findsWidgets);
      expect(find.text('Class 9'), findsWidgets);
    });

    testWidgets('5.2 UploadTextbookScreen handles empty map arguments gracefully',
        (WidgetTester tester) async {
      final uploadRepo = MockAdversarialUploadRepo();
      await tester.pumpWidget(createUploadNavApp(args: const {}, uploadRepo: uploadRepo));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_nav')));
      await tester.pumpAndSettle();

      expect(find.byType(UploadTextbookScreen), findsOneWidget);
      expect(find.text('Physics'), findsWidgets);
      expect(find.text('Class 9'), findsWidgets);
    });

    testWidgets('5.3 UploadTextbookScreen handles malformed arguments (invalid subject and string grade) gracefully',
        (WidgetTester tester) async {
      final uploadRepo = MockAdversarialUploadRepo();
      await tester.pumpWidget(
        createUploadNavApp(
          args: const {'subject': 'Astrology', 'grade': 'Grade Ten'},
          uploadRepo: uploadRepo,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_nav')));
      await tester.pumpAndSettle();

      expect(find.byType(UploadTextbookScreen), findsOneWidget);
      expect(find.text('Physics'), findsWidgets);
      expect(find.text('Class 9'), findsWidgets);
    });

    testWidgets('5.4 UploadTextbookScreen pre-fills subject and grade from valid route arguments',
        (WidgetTester tester) async {
      final uploadRepo = MockAdversarialUploadRepo();
      await tester.pumpWidget(
        createUploadNavApp(
          args: const {'subject': 'Chemistry', 'grade': 10},
          uploadRepo: uploadRepo,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_nav')));
      await tester.pumpAndSettle();

      expect(find.byType(UploadTextbookScreen), findsOneWidget);
      expect(find.text('Chemistry'), findsWidgets);
      expect(find.text('Class 10'), findsWidgets);
    });
  });
}
