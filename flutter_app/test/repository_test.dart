import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/core/constants/subjects.dart';
import 'package:flutter_app/data/models/assessment_model.dart';
import 'package:flutter_app/data/models/pdf_model.dart';
import 'package:flutter_app/data/models/question_bank_model.dart';
import 'package:flutter_app/data/models/recent_papers_model.dart';
import 'package:flutter_app/data/models/settings_model.dart';
import 'package:flutter_app/data/models/textbook_model.dart';
import 'package:flutter_app/core/network/api_client.dart';
import 'package:flutter_app/data/repositories/question_bank_repository.dart';
import 'package:flutter_app/data/repositories/recent_papers_repository.dart';
import 'package:flutter_app/data/repositories/settings_repository.dart';
import 'package:flutter_app/data/repositories/upload_repository.dart';

void main() {
  group('Data Models Unit Tests', () {
    test('AssessmentModel JSON roundtrip and calculated marks', () {
      const jsonMap = {
        'test_title': 'Class 9 Chemistry Test',
        'subject': 'Chemistry',
        'chapter_or_topic': 'Periodic Table',
        'total_marks': 16,
        'time_allowed': '45 Minutes',
        'instructions': ['Attempt all questions.'],
        'mcqs': [
          {
            'question_number': 1,
            'question': 'What is atomic number?',
            'options': ['A) 1', 'B) 2', 'C) 3', 'D) 4'],
            'correct_option': 'A',
            'textbook_reference': 'Pg 10',
          }
        ],
        'short_questions': [
          {'question_number': 1, 'question': 'Short Q1', 'marks': 2}
        ],
        'long_questions': [
          {'question_number': 1, 'question': 'Long Q1', 'marks': 5}
        ],
      };

      final model = AssessmentModel.fromJson(jsonMap);
      expect(model.testTitle, equals('Class 9 Chemistry Test'));
      expect(model.subject, equals(ExamSubject.chemistry));
      expect(model.calculatedTotalMarks, equals(1 + 2 + 5));
      expect(model.totalQuestionCount, equals(3));

      final serialized = model.toJson();
      expect(serialized['subject'], equals('Chemistry'));
      expect(serialized['total_marks'], equals(16));
    });

    test('PdfRenderRequestModel serialization', () {
      const assessment = AssessmentModel(
        testTitle: 'Test Paper',
        subject: ExamSubject.physics,
        chapterOrTopic: 'Kinematics',
        totalMarks: 10,
      );

      const req = PdfRenderRequestModel(
        testData: assessment,
        includeAnswerKey: true,
      );

      final json = req.toJson();
      expect(json['include_answer_key'], isTrue);
      expect(json['test_data']['subject'], equals('Physics'));
    });

    test('TextbookUploadResponseModel JSON parsing', () {
      final json = {
        'status': 'success',
        'message': 'Uploaded textbook successfully',
        'chunks_indexed': 120,
      };

      final response = TextbookUploadResponseModel.fromJson(json);
      expect(response.isSuccess, isTrue);
      expect(response.chunksIndexed, equals(120));
    });

    test('SettingsModel copyWith and defaults', () {
      const defaultSettings = SettingsModel();
      expect(defaultSettings.baseUrl, equals('https://testai.ai-vision.studio'));
      expect(defaultSettings.defaultMcqCount, equals(5));

      final updated = defaultSettings.copyWith(
        baseUrl: 'http://10.0.2.2:8000',
        defaultMcqCount: 10,
      );

      expect(updated.baseUrl, equals('http://10.0.2.2:8000'));
      expect(updated.defaultMcqCount, equals(10));
      expect(updated.defaultShortCount, equals(3)); // unchanged
    });
  });

  group('QuestionBankRepository Unit Tests across 5 Subjects', () {
    late QuestionBankRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final recentRepo = RecentPapersRepository();
      int i = 1;
      for (final subject in SubjectUtils.allSubjects) {
        await recentRepo.saveRecentPaper(
          RecentPaperModel(
            paperId: 'paper_00$i',
            title: '${subject.displayName} Quiz',
            subject: subject,
            chapterOrTopic: 'Chapter 1',
            totalMarks: 10,
            dateCreated: DateTime.now(),
            testData: AssessmentModel(
              testTitle: '${subject.displayName} Quiz',
              subject: subject,
              chapterOrTopic: 'Chapter 1',
              totalMarks: 10,
              mcqs: [
                MCQItemModel(
                  questionNumber: 1,
                  question: subject == ExamSubject.biology
                      ? 'What is powerhouse of the cell?'
                      : 'Sample MCQ for ${subject.displayName}',
                  options: const ['A) 1', 'B) 2', 'C) 3', 'D) 4'],
                  correctOption: 'A',
                  textbookReference: 'Pg 1',
                )
              ],
              shortQuestions: const [
                ShortQuestionItemModel(questionNumber: 1, question: 'Sample Short', marks: 2)
              ],
              longQuestions: const [
                LongQuestionItemModel(questionNumber: 1, question: 'Sample Long', marks: 5)
              ],
            ),
          ),
        );
        i++;
      }
      repo = QuestionBankRepository();
    });

    test('Should return questions for all 5 subjects', () async {
      for (final subject in SubjectUtils.allSubjects) {
        final filter = QuestionBankFilterModel(subject: subject);
        final questions = await repo.getQuestions(filter);
        final count = await repo.getTotalQuestionCount(filter);

        expect(count, greaterThan(0),
            reason: 'Subject ${subject.displayName} should have questions');
        expect(questions, isNotEmpty);
        expect(questions.every((q) => q.subject == subject), isTrue);
      }
    });

    test('Should filter by difficulty level', () async {
      const filter = QuestionBankFilterModel(
        difficulty: QuestionDifficulty.medium,
      );
      final questions = await repo.getQuestions(filter);
      expect(questions, isNotEmpty);
      expect(
          questions.every((q) => q.difficulty == QuestionDifficulty.medium), isTrue);
    });

    test('Should filter by question type (MCQ, Short, Long)', () async {
      const mcqFilter = QuestionBankFilterModel(type: QuestionType.mcq);
      final mcqs = await repo.getQuestions(mcqFilter);
      expect(mcqs.every((q) => q.type == QuestionType.mcq), isTrue);

      const longFilter = QuestionBankFilterModel(type: QuestionType.long);
      final longs = await repo.getQuestions(longFilter);
      expect(longs.every((q) => q.type == QuestionType.long), isTrue);
    });

    test('Should filter by search query', () async {
      const filter = QuestionBankFilterModel(searchQuery: 'powerhouse');
      final questions = await repo.getQuestions(filter);
      expect(questions.length, equals(1));
      expect(questions.first.subject, equals(ExamSubject.biology));
    });

    test('Should handle pagination properly', () async {
      const filterPage1 = QuestionBankFilterModel(limit: 2, page: 1);
      final page1 = await repo.getQuestions(filterPage1);
      expect(page1.length, equals(2));

      const filterPage2 = QuestionBankFilterModel(limit: 2, page: 2);
      final page2 = await repo.getQuestions(filterPage2);
      expect(page2.length, equals(2));
      expect(page1.first.id, isNot(equals(page2.first.id)));
    });
  });

  group('RecentPapersRepository Unit Tests', () {
    late RecentPapersRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repo = RecentPapersRepository();
      await repo.saveRecentPaper(
        RecentPaperModel(
          paperId: 'paper_001',
          title: 'Physics Quiz',
          subject: ExamSubject.physics,
          chapterOrTopic: 'Kinematics',
          totalMarks: 10,
          dateCreated: DateTime.now(),
          testData: const AssessmentModel(
            testTitle: 'Physics Quiz',
            subject: ExamSubject.physics,
            chapterOrTopic: 'Kinematics',
            totalMarks: 10,
          ),
        ),
      );
      await repo.saveRecentPaper(
        RecentPaperModel(
          paperId: 'paper_002',
          title: 'Chemistry Quiz',
          subject: ExamSubject.chemistry,
          chapterOrTopic: 'Atoms',
          totalMarks: 10,
          dateCreated: DateTime.now(),
          testData: const AssessmentModel(
            testTitle: 'Chemistry Quiz',
            subject: ExamSubject.chemistry,
            chapterOrTopic: 'Atoms',
            totalMarks: 10,
          ),
        ),
      );
    });

    test('Should seed initial recent papers', () async {
      final papers = await repo.getRecentPapers();
      expect(papers.length, equals(2));
    });

    test('Should save new paper and retrieve it', () async {
      final newPaper = RecentPaperModel(
        paperId: 'paper_test_123',
        title: 'Biology Test',
        subject: ExamSubject.biology,
        chapterOrTopic: 'Cell Biology',
        totalMarks: 20,
        dateCreated: DateTime.now(),
        testData: const AssessmentModel(
          testTitle: 'Biology Test',
          subject: ExamSubject.biology,
          chapterOrTopic: 'Cell Biology',
          totalMarks: 20,
        ),
      );

      await repo.saveRecentPaper(newPaper);
      final fetched = await repo.getPaperById('paper_test_123');
      expect(fetched, isNotNull);
      expect(fetched!.title, equals('Biology Test'));
    });

    test('Should toggle favorite status', () async {
      final initial = await repo.getPaperById('paper_002');
      expect(initial!.isFavorite, isFalse);

      await repo.toggleFavorite('paper_002');
      final updated = await repo.getPaperById('paper_002');
      expect(updated!.isFavorite, isTrue);
    });

    test('Should delete paper by ID', () async {
      await repo.deleteRecentPaper('paper_001');
      final fetched = await repo.getPaperById('paper_001');
      expect(fetched, isNull);
    });

    test('Should filter recent papers by subject', () async {
      final chemPapers =
          await repo.getRecentPapers(subjectFilter: ExamSubject.chemistry);
      expect(chemPapers.every((p) => p.subject == ExamSubject.chemistry), isTrue);
    });
  });

  group('SettingsRepository Unit Tests', () {
    late SettingsRepository repo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repo = SettingsRepository();
    });

    test('Should get default settings', () async {
      final settings = await repo.getSettings();
      expect(settings.baseUrl, equals('https://testai.ai-vision.studio'));
      expect(settings.enableTelemetry, isTrue);
    });

    test('Should update and persist settings', () async {
      const newSettings = SettingsModel(
        baseUrl: 'http://10.0.2.2:8000',
        enableTelemetry: false,
      );

      await repo.saveSettings(newSettings);
      final current = await repo.getSettings();

      expect(current.baseUrl, equals('http://10.0.2.2:8000'));
      expect(current.enableTelemetry, isFalse);
    });

    test('Should reset settings to defaults', () async {
      const custom = SettingsModel(baseUrl: 'http://custom:9000');
      await repo.saveSettings(custom);
      await repo.resetSettings();

      final reset = await repo.getSettings();
      expect(reset.baseUrl, equals('https://testai.ai-vision.studio'));
    });
  });

  group('UploadRepository Unit Tests', () {
    late UploadRepository repo;

    setUp(() {
      repo = UploadRepository(
        apiClient: ApiClient(baseUrl: 'http://localhost:8000'),
      );
    });

    test('Should throw ApiException without fallback when offline', () async {
      expect(
        () async => await repo.getUploadStatus('upload_123'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
