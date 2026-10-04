import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_app/core/constants/subjects.dart';
import 'package:flutter_app/core/network/api_client.dart';
import 'package:flutter_app/core/routes/app_routes.dart';
import 'package:flutter_app/data/models/assessment_model.dart';
import 'package:flutter_app/data/models/settings_model.dart';
import 'package:flutter_app/data/models/textbook_model.dart';
import 'package:flutter_app/data/repositories/assessment_repository.dart';
import 'package:flutter_app/data/repositories/pdf_repository.dart';
import 'package:flutter_app/data/repositories/settings_repository.dart';
import 'package:flutter_app/data/repositories/upload_repository.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/presentation/providers/assessment_provider.dart';
import 'package:flutter_app/presentation/providers/connection_provider.dart';
import 'package:flutter_app/presentation/providers/settings_provider.dart';
import 'package:flutter_app/presentation/providers/upload_provider.dart';
import 'package:flutter_app/screens/generate/generate_assessment_screen.dart';
import 'package:flutter_app/screens/settings/settings_screen.dart';
import 'package:flutter_app/screens/upload/upload_textbook_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Spy ApiClient to verify HTTP calls, paths, headers, and query parameters.
class SpyApiClient extends ApiClient {
  String? lastGetPath;
  Map<String, dynamic>? lastGetQueryParams;
  String? lastPostPath;
  dynamic lastPostData;

  SpyApiClient({super.baseUrl});

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    dynamic options,
  }) async {
    lastGetPath = path;
    lastGetQueryParams = queryParameters;
    if (path.contains('/chapters') && !path.contains('/metadata')) {
      final grade = queryParameters?['grade'] as int? ?? 9;
      if (grade == 10) {
        return {'chapters': <String>[]};
      }
      return {
        'chapters': ['Chapter 1: Vectors', 'Chapter 2: Motion']
      };
    }
    if (path.contains('/metadata')) {
      return {
        'subject': 'Mathematics',
        'chapter': 'Matrices',
        'exercises': ['Ex 1.1', 'Ex 1.2'],
        'formula_count': 5,
        'has_theorems': false,
      };
    }
    return {'status': 'ok'};
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    dynamic options,
  }) async {
    lastPostPath = path;
    lastPostData = data;
    return {
      'test_title': 'Mock Parity Test',
      'subject': 'Physics',
      'chapter_or_topic': 'Vectors',
      'grade': (data is Map && data.containsKey('grade')) ? data['grade'] : 9,
      'total_marks': 25,
      'time_allowed': '45 Minutes',
      'instructions': ['Attempt all'],
      'mcqs': [],
      'short_questions': [],
      'long_questions': [],
    };
  }
}

/// Mock repository for widget tests providing controlled chapter lists per grade.
class ParityMockAssessmentRepository implements IAssessmentRepository {
  int lastGradeQueried = 9;

  @override
  Future<List<ExamSubject>> getSupportedSubjects() async {
    return SubjectUtils.allSubjects;
  }

  @override
  Future<List<String>> getSubjectChapters(ExamSubject subject,
      {int grade = 9}) async {
    lastGradeQueried = grade;
    if (grade == 10) {
      // Empty chapters to simulate unindexed textbook in Qdrant (e.g. Class 10 Chemistry)
      return [];
    } else if (grade == 11) {
      return ['First Year Mechanics', 'First Year Thermodynamics'];
    } else if (grade == 12) {
      return ['Second Year Electromagnetism', 'Second Year Nuclear Physics'];
    }
    return ['Class 9 Matter', 'Class 9 Structure', 'Class 9 Reactions'];
  }

  @override
  Future<ChapterMetadata> getChapterMetadata(String subject, String chapter,
      {int grade = 9}) async {
    lastGradeQueried = grade;
    return ChapterMetadata(
      subject: subject,
      chapter: chapter,
      exercises: ['Exercise 1.1', 'Exercise 1.2'],
    );
  }

  @override
  Future<AssessmentModel> generateDraftTest(GenerationOptions request) async {
    return AssessmentModel(
      testTitle: '${request.subject.displayName} Class ${request.grade} Test',
      subject: request.subject,
      chapterOrTopic: request.chapterName,
      grade: request.grade,
      totalMarks: 25,
    );
  }
}

class ParityMockUploadRepository implements IUploadRepository {
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
      chunksIndexed: 348,
    );
  }

  @override
  Future<TextbookProcessingStatusModel> getUploadStatus(String uploadId) async {
    return TextbookProcessingStatusModel(
      uploadId: uploadId,
      filename: 'textbook.pdf',
      subject: ExamSubject.mathematics,
      grade: 11,
      status: TextbookUploadStatus.completed,
      progress: 1.0,
      message: 'Processing completed',
      chunksProcessed: 348,
      totalChunks: 348,
      updatedAt: DateTime.now(),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Milestone 2 Parity Tests: R1 - API Client Security & Platform-Aware Base URL', () {
    test('1. resolveDefaultBaseUrl returns 10.0.2.2 for Android and localhost for others', () {
      expect(
        ApiClient.resolveDefaultBaseUrl(isAndroid: true),
        equals('http://10.0.2.2:8000'),
      );
      expect(
        ApiClient.resolveDefaultBaseUrl(isAndroid: false),
        equals('http://localhost:8000'),
      );

      final client = ApiClient();
      final expectedBaseUrl =
          Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
      expect(client.baseUrl, equals(expectedBaseUrl));
    });

    test('2. ApiClient attaches X-API-Key: examcraft-secret-key-2026 to client routes', () {
      final client = ApiClient();

      expect(
        client.getApiKeyForPath('/api/subjects'),
        equals(ApiClient.defaultClientApiKey),
      );
      expect(
        client.getApiKeyForPath('/api/tests/draft'),
        equals(ApiClient.defaultClientApiKey),
      );
      expect(
        client.getApiKeyForPath('/api/subjects/Chemistry/chapters'),
        equals(ApiClient.defaultClientApiKey),
      );

      final headers = client.getHeadersForPath('/api/subjects');
      expect(headers['X-API-Key'], equals('examcraft-secret-key-2026'));
    });

    test('3. ApiClient attaches X-API-Key: examcraft-admin-key-2026 to admin and upload routes', () {
      final client = ApiClient();

      expect(
        client.getApiKeyForPath('/api/admin/system-stats'),
        equals(ApiClient.defaultAdminApiKey),
      );
      expect(
        client.getApiKeyForPath('/api/upload-textbook'),
        equals(ApiClient.defaultAdminApiKey),
      );
      expect(
        client.getApiKeyForPath('/api/admin/collections'),
        equals('examcraft-admin-key-2026'),
      );

      final adminHeaders = client.getHeadersForPath('/api/admin/indexing');
      expect(adminHeaders['X-API-Key'], equals('examcraft-admin-key-2026'));
    });

    test('4. Dynamic API key mutation via updateClientApiKey updates outgoing headers', () {
      final client = ApiClient();
      expect(client.clientApiKey, equals('examcraft-secret-key-2026'));

      client.updateClientApiKey('custom-teacher-secret-key-2026');
      expect(client.clientApiKey, equals('custom-teacher-secret-key-2026'));
      expect(
        client.getApiKeyForPath('/api/subjects'),
        equals('custom-teacher-secret-key-2026'),
      );

      // Admin key must remain separate and untouched
      expect(
        client.getApiKeyForPath('/api/admin/status'),
        equals('examcraft-admin-key-2026'),
      );
    });
  });

  group('Milestone 2 Parity Tests: R2 - Academic Grade in Models & Repository', () {
    test('5. GenerationOptions.toJson() and fromJson() serialize grade (9..12)', () {
      const options9 = GenerationOptions(
        subject: ExamSubject.physics,
        chapterName: 'Kinematics',
        grade: 9,
      );
      expect(options9.toJson()['grade'], equals(9));

      const options11 = GenerationOptions(
        subject: ExamSubject.mathematics,
        chapterName: 'Calculus',
        grade: 11,
      );
      final json11 = options11.toJson();
      expect(json11['grade'], equals(11));

      final parsed = GenerationOptions.fromJson(json11);
      expect(parsed.grade, equals(11));
      expect(parsed.subject, equals(ExamSubject.mathematics));
      expect(parsed.chapterName, equals('Calculus'));

      final copied = parsed.copyWith(grade: 12);
      expect(copied.grade, equals(12));
    });

    test('6. AssessmentModel serializes and deserializes grade correctly', () {
      const model = AssessmentModel(
        testTitle: 'Class 10 Chemistry Test',
        subject: ExamSubject.chemistry,
        chapterOrTopic: 'Chemical Equilibrium',
        grade: 10,
        totalMarks: 30,
      );
      expect(model.grade, equals(10));

      final json = model.toJson();
      expect(json['grade'], equals(10));

      final parsed = AssessmentModel.fromJson(json);
      expect(parsed.grade, equals(10));
      expect(parsed.testTitle, equals('Class 10 Chemistry Test'));

      final copied = parsed.copyWith(grade: 12);
      expect(copied.grade, equals(12));
    });

    test('7. AssessmentRepository passes grade query parameter to endpoints', () async {
      final spyClient = SpyApiClient();
      final repository = AssessmentRepository(apiClient: spyClient);

      await repository.getSubjectChapters(ExamSubject.physics, grade: 11);
      expect(spyClient.lastGetPath, contains('/api/subjects/Physics/chapters'));
      expect(spyClient.lastGetQueryParams?['grade'], equals(11));

      await repository.getChapterMetadata('Mathematics', 'Matrices', grade: 12);
      expect(
        spyClient.lastGetPath,
        contains('/api/subjects/Mathematics/chapters/Matrices/metadata'),
      );
      expect(spyClient.lastGetQueryParams?['grade'], equals(12));
    });
  });

  group('Milestone 2 Parity Tests: R3 - AssessmentProvider Grade State & Reloading', () {
    test('8. AssessmentProvider.selectGrade() updates state and reloads chapters for target grade', () async {
      final mockRepo = ParityMockAssessmentRepository();
      final provider = AssessmentProvider(
        assessmentRepository: mockRepo,
        pdfRepository: PdfRepository(apiClient: ApiClient()),
      );

      // Initial state
      expect(provider.selectedGrade, equals(9));

      // Select Grade 11
      await provider.selectGrade(11);
      expect(provider.selectedGrade, equals(11));
      expect(mockRepo.lastGradeQueried, equals(11));
      expect(provider.chapters, contains('First Year Mechanics'));
      expect(provider.selectedChapter, equals('First Year Mechanics'));

      // Select Grade 10 (which has no chapters indexed in our mock)
      await provider.selectGrade(10);
      expect(provider.selectedGrade, equals(10));
      expect(mockRepo.lastGradeQueried, equals(10));
      expect(provider.chapters, isEmpty);
      expect(provider.selectedChapter, isNull);
    });
  });

  group('Milestone 2 Parity Tests: R4 - Generator UI Class Selector & Actionable Empty State', () {
    Widget createTestableWidget({
      required ParityMockAssessmentRepository repository,
      required AssessmentProvider provider,
    }) {
      final themeController = ThemeController();
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeController>.value(value: themeController),
          ChangeNotifierProvider<AssessmentProvider>.value(value: provider),
          ChangeNotifierProvider<ConnectionProvider>(
            create: (_) => ConnectionProvider(apiClient: ApiClient()),
          ),
          ChangeNotifierProvider<UploadProvider>(
            create: (_) => UploadProvider(
              uploadRepository: UploadRepository(apiClient: ApiClient()),
            ),
          ),
        ],
        child: MaterialApp(
          routes: AppRoutes.routesMap,
          home: Scaffold(
            body: GenerateAssessmentScreen(repository: repository),
          ),
        ),
      );
    }

    testWidgets('9. Displays Class 9..12 chips; switching to empty Class 10 renders amber card and disables generate button',
        (WidgetTester tester) async {
      final mockRepo = ParityMockAssessmentRepository();
      final provider = AssessmentProvider(
        assessmentRepository: mockRepo,
        pdfRepository: PdfRepository(apiClient: ApiClient()),
      );

      await tester.pumpWidget(
        createTestableWidget(repository: mockRepo, provider: provider),
      );
      await tester.pumpAndSettle();

      // Verify Class ChoiceChips exist for classes 9, 10, 11, 12
      expect(find.byKey(const Key('chip_class_9')), findsOneWidget);
      expect(find.byKey(const Key('chip_class_10')), findsOneWidget);
      expect(find.byKey(const Key('chip_class_11')), findsOneWidget);
      expect(find.byKey(const Key('chip_class_12')), findsOneWidget);

      // In Class 9, chapters are available, dropdown is present, button is enabled
      expect(find.byKey(const Key('dropdown_chapter')), findsOneWidget);
      expect(find.byKey(const Key('card_empty_chapters_warning')), findsNothing);

      final generateBtnFinder = find.byKey(const Key('btn_generate_assessment'));
      expect(generateBtnFinder, findsOneWidget);
      ElevatedButton btnWidget = tester.widget<ElevatedButton>(generateBtnFinder);
      expect(btnWidget.onPressed, isNotNull);

      // Switch to Class 10 (which has 0 chapters indexed in Qdrant)
      await tester.tap(find.byKey(const Key('chip_class_10')));
      await tester.pumpAndSettle();

      // Verify Class 10 is active in provider
      expect(provider.selectedGrade, equals(10));
      expect(provider.chapters, isEmpty);

      // Verify amber card with warning and "Upload Textbook" button is rendered
      expect(find.byKey(const Key('card_empty_chapters_warning')), findsOneWidget);
      expect(find.text('No Indexed Chapters Available'), findsOneWidget);
      expect(find.byKey(const Key('btn_upload_textbook_empty')), findsOneWidget);

      // Chapter dropdown must NOT be rendered
      expect(find.byKey(const Key('dropdown_chapter')), findsNothing);

      // Generate Assessment button MUST BE DISABLED (onPressed == null)
      btnWidget = tester.widget<ElevatedButton>(generateBtnFinder);
      expect(
        btnWidget.onPressed,
        isNull,
        reason: 'Generate button must be disabled when chapters are empty to prevent mock fallback',
      );

      // Switch back to Class 11 (chapters available)
      await tester.tap(find.byKey(const Key('chip_class_11')));
      await tester.pumpAndSettle();

      expect(provider.selectedGrade, equals(11));
      expect(provider.chapters, isNotEmpty);
      expect(find.byKey(const Key('card_empty_chapters_warning')), findsNothing);
      expect(find.byKey(const Key('dropdown_chapter')), findsOneWidget);

      btnWidget = tester.widget<ElevatedButton>(generateBtnFinder);
      expect(btnWidget.onPressed, isNotNull);
    });
  });

  group('Milestone 2 Parity Tests: R5 - Settings URL Presets & Client API Key', () {
    test('10. SettingsModel includes clientApiKey and updates properly', () {
      const defaultSettings = SettingsModel();
      expect(
        defaultSettings.clientApiKey,
        equals('examcraft-secret-key-2026'),
      );

      final json = defaultSettings.toJson();
      expect(json['client_api_key'], equals('examcraft-secret-key-2026'));

      final fromJson = SettingsModel.fromJson({
        'client_api_key': 'new-test-key-1234',
        'base_url': 'http://localhost:8000',
      });
      expect(fromJson.clientApiKey, equals('new-test-key-1234'));
      expect(fromJson.baseUrl, equals('http://localhost:8000'));

      final updated = defaultSettings.copyWith(clientApiKey: 'updated-key');
      expect(updated.clientApiKey, equals('updated-key'));
    });

    test('11. SettingsProvider updates clientApiKey, persists, and syncs ApiClient', () async {
      SharedPreferences.setMockInitialValues({});
      final client = ApiClient();
      final settingsRepo = SettingsRepository();
      final provider = SettingsProvider(
        settingsRepository: settingsRepo,
        apiClient: client,
      );

      await Future.delayed(Duration.zero);
      expect(provider.clientApiKey, equals('examcraft-secret-key-2026'));
      expect(client.clientApiKey, equals('examcraft-secret-key-2026'));

      await provider.updateClientApiKey('new-persisted-key-777');
      expect(provider.clientApiKey, equals('new-persisted-key-777'));
      expect(client.clientApiKey, equals('new-persisted-key-777'));

      // Verify persistence in SettingsRepository
      final savedSettings = await settingsRepo.getSettings();
      expect(savedSettings.clientApiKey, equals('new-persisted-key-777'));
    });

    testWidgets('12. SettingsScreen renders presets chips and client API key field, and saves both',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final settingsRepo = SettingsRepository();
      final client = ApiClient();
      final settingsProvider = SettingsProvider(
        settingsRepository: settingsRepo,
        apiClient: client,
      );
      final themeController = ThemeController();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeController>.value(value: themeController),
            ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
            ChangeNotifierProvider<ConnectionProvider>(
              create: (_) => ConnectionProvider(apiClient: client),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SettingsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify preset chips exist
      final emulatorChip = find.byKey(const Key('chip_preset_emulator'));
      expect(emulatorChip, findsOneWidget);
      expect(find.byKey(const Key('chip_preset_localhost')), findsOneWidget);
      expect(find.byKey(const Key('chip_preset_cloud')), findsOneWidget);

      // Verify client api key input field exists
      final apiKeyInput = find.byKey(const Key('input_client_api_key'));
      expect(apiKeyInput, findsOneWidget);

      // Tap Android Emulator preset chip
      await tester.ensureVisible(emulatorChip);
      await tester.tap(emulatorChip);
      await tester.pumpAndSettle();

      final urlField = tester.widget<TextField>(find.byKey(const Key('input_api_base_url')));
      expect(urlField.controller?.text, equals('http://10.0.2.2:8000'));

      // Enter new API key and save
      await tester.ensureVisible(apiKeyInput);
      await tester.enterText(apiKeyInput, 'my-custom-teacher-key-999');
      await tester.pumpAndSettle();

      final saveBtn = find.byKey(const Key('btn_save_url'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(settingsProvider.baseUrl, equals('http://10.0.2.2:8000'));
      expect(settingsProvider.clientApiKey, equals('my-custom-teacher-key-999'));
      expect(client.clientApiKey, equals('my-custom-teacher-key-999'));
    });

    testWidgets('13. UploadTextbookScreen pre-fills subject and grade from route arguments',
        (WidgetTester tester) async {
      final uploadRepo = ParityMockUploadRepository();
      final themeController = ThemeController();

      await tester.pumpWidget(
        MultiProvider(
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
                      key: const Key('btn_trigger_nav'),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.upload,
                          arguments: {
                            'subject': 'Mathematics',
                            'grade': 11,
                          },
                        );
                      },
                      child: const Text('Go to Upload'),
                    ),
                  ),
              AppRoutes.upload: (context) => UploadTextbookScreen(uploadRepository: uploadRepo),
            },
            initialRoute: '/',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger navigation to /upload with subject=Mathematics, grade=11
      await tester.tap(find.byKey(const Key('btn_trigger_nav')));
      await tester.pumpAndSettle();

      expect(find.byType(UploadTextbookScreen), findsOneWidget);

      // Verify pre-filled subject and grade are rendered on screen
      expect(find.text('Mathematics'), findsWidgets);
      expect(find.text('Class 11'), findsWidgets);

      // Tap upload button to confirm state passed to repository
      final uploadBtn = find.byKey(const Key('btn_upload_textbook'));
      expect(uploadBtn, findsOneWidget);
      await tester.ensureVisible(uploadBtn);
      await tester.tap(uploadBtn);
      await tester.pumpAndSettle();

      expect(uploadRepo.uploadCalled, isTrue);
      expect(uploadRepo.lastSubject, equals(ExamSubject.mathematics));
      expect(uploadRepo.lastGrade, equals(11));
    });
  });
}
