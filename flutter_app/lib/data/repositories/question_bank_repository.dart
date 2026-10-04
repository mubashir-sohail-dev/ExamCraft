import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/data/models/question_bank_model.dart';
import 'package:flutter_app/data/models/recent_papers_model.dart';

abstract class IQuestionBankRepository {
  Future<List<QuestionItemModel>> getQuestions(QuestionBankFilterModel filter);
  Future<QuestionItemModel?> getQuestionById(String id);
  Future<int> getTotalQuestionCount(QuestionBankFilterModel filter);
}

/// Repository for Question Bank queries extracting questions from authentic backend-generated assessments.
class QuestionBankRepository implements IQuestionBankRepository {
  static const String _storageKey = 'recent_papers_storage';

  Future<List<QuestionItemModel>> _getAllQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      final papers = decoded
          .map((e) => RecentPaperModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final List<QuestionItemModel> questions = [];
      for (final paper in papers) {
        final assessment = paper.testData;
        int mcqIdx = 1;
        for (final mcq in assessment.mcqs) {
          questions.add(
            QuestionItemModel(
              id: '${paper.paperId}-mcq-${mcqIdx++}',
              question: mcq.question,
              type: QuestionType.mcq,
              options: mcq.options,
              answer: mcq.correctOption,
              subject: assessment.subject,
              chapterName: assessment.chapterOrTopic,
              difficulty: QuestionDifficulty.medium,
              marks: 1,
              textbookReference: mcq.textbookReference,
            ),
          );
        }
        int shortIdx = 1;
        for (final sq in assessment.shortQuestions) {
          questions.add(
            QuestionItemModel(
              id: '${paper.paperId}-sq-${shortIdx++}',
              question: sq.question,
              type: QuestionType.short,
              options: const [],
              answer: '',
              subject: assessment.subject,
              chapterName: assessment.chapterOrTopic,
              difficulty: QuestionDifficulty.medium,
              marks: sq.marks,
            ),
          );
        }
        int longIdx = 1;
        for (final lq in assessment.longQuestions) {
          questions.add(
            QuestionItemModel(
              id: '${paper.paperId}-lq-${longIdx++}',
              question: lq.question,
              type: QuestionType.long,
              options: const [],
              answer: '',
              subject: assessment.subject,
              chapterName: assessment.chapterOrTopic,
              difficulty: QuestionDifficulty.hard,
              marks: lq.marks,
            ),
          );
        }
      }
      return questions;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<QuestionItemModel>> getQuestions(
      QuestionBankFilterModel filter) async {
    final allQuestions = await _getAllQuestions();
    final filtered = _applyFilter(allQuestions, filter);

    final startIndex = (filter.page - 1) * filter.limit;
    if (startIndex >= filtered.length) {
      return [];
    }
    final endIndex = (startIndex + filter.limit < filtered.length)
        ? startIndex + filter.limit
        : filtered.length;

    return filtered.sublist(startIndex, endIndex);
  }

  @override
  Future<int> getTotalQuestionCount(QuestionBankFilterModel filter) async {
    final allQuestions = await _getAllQuestions();
    return _applyFilter(allQuestions, filter).length;
  }

  @override
  Future<QuestionItemModel?> getQuestionById(String id) async {
    final allQuestions = await _getAllQuestions();
    try {
      return allQuestions.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  List<QuestionItemModel> _applyFilter(
      List<QuestionItemModel> source, QuestionBankFilterModel filter) {
    return source.where((q) {
      if (filter.subject != null && q.subject != filter.subject) {
        return false;
      }
      if (filter.difficulty != null && q.difficulty != filter.difficulty) {
        return false;
      }
      if (filter.type != null && q.type != filter.type) {
        return false;
      }
      if (filter.chapterName != null && filter.chapterName!.isNotEmpty) {
        if (!q.chapterName
            .toLowerCase()
            .contains(filter.chapterName!.toLowerCase())) {
          return false;
        }
      }
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        final query = filter.searchQuery!.toLowerCase();
        final matchesQuestion = q.question.toLowerCase().contains(query);
        final matchesChapter = q.chapterName.toLowerCase().contains(query);
        final matchesTopic =
            q.topicName != null && q.topicName!.toLowerCase().contains(query);
        if (!matchesQuestion && !matchesChapter && !matchesTopic) {
          return false;
        }
      }
      return true;
    }).toList();
  }
}
