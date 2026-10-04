import 'package:flutter_app/core/constants/subjects.dart';
import 'package:flutter_app/core/network/api_client.dart';
import 'package:flutter_app/data/models/assessment_model.dart';

abstract class IAssessmentRepository {
  Future<AssessmentModel> generateDraftTest(GenerationOptions request);
  Future<List<ExamSubject>> getSupportedSubjects();
  Future<List<String>> getSubjectChapters(ExamSubject subject, {int grade = 9});
  Future<ChapterMetadata> getChapterMetadata(String subject, String chapter,
      {int grade = 9});
}

class AssessmentRepository implements IAssessmentRepository {
  final ApiClient apiClient;

  AssessmentRepository({required this.apiClient});

  @override
  Future<AssessmentModel> generateDraftTest(GenerationOptions request) async {
    try {
      final responseData = await apiClient.post(
        '/api/tests/draft',
        data: request.toJson(),
      );

      if (responseData is Map<String, dynamic>) {
        return AssessmentModel.fromJson(responseData);
      }
      throw ApiException(
          message: 'Invalid response from backend assessment generation.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
          message: 'Failed to generate assessment from server: $e');
    }
  }

  @override
  Future<List<ExamSubject>> getSupportedSubjects() async {
    try {
      final responseData = await apiClient.get('/api/subjects');
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('subjects')) {
        final rawList = responseData['subjects'] as List<dynamic>;
        final subjects = rawList
            .map((e) => SubjectUtils.tryParse(e.toString()))
            .whereType<ExamSubject>()
            .toList();
        if (subjects.isNotEmpty) return subjects;
      }
    } catch (_) {}
    return SubjectUtils.allSubjects;
  }

  @override
  Future<List<String>> getSubjectChapters(ExamSubject subject,
      {int grade = 9}) async {
    try {
      final responseData = await apiClient.get(
        '/api/subjects/${Uri.encodeComponent(subject.apiString)}/chapters',
        queryParameters: {'grade': grade},
      );

      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('chapters')) {
        final rawList = responseData['chapters'] as List<dynamic>;
        final chapters = rawList.map((e) => e.toString()).toList();
        if (chapters.isNotEmpty) return chapters;
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<ChapterMetadata> getChapterMetadata(
      String subject, String chapter,
      {int grade = 9}) async {
    try {
      final responseData = await apiClient.get(
        '/api/subjects/${Uri.encodeComponent(subject)}/chapters/${Uri.encodeComponent(chapter)}/metadata',
        queryParameters: {'grade': grade},
      );

      if (responseData is Map<String, dynamic>) {
        return ChapterMetadata.fromJson(responseData);
      }
      throw ApiException(message: 'Invalid response for chapter metadata.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to fetch chapter metadata: $e');
    }
  }
}
