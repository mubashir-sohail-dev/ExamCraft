import 'package:flutter_app/core/constants/subjects.dart';

/// Question types available in the Question Bank.
enum QuestionType {
  mcq,
  short,
  long,
}

extension QuestionTypeExtension on QuestionType {
  String get displayName {
    switch (this) {
      case QuestionType.mcq:
        return 'Multiple Choice (MCQ)';
      case QuestionType.short:
        return 'Short Answer';
      case QuestionType.long:
        return 'Long / Essay';
    }
  }

  String get code {
    switch (this) {
      case QuestionType.mcq:
        return 'mcq';
      case QuestionType.short:
        return 'short';
      case QuestionType.long:
        return 'long';
    }
  }
}

/// Question difficulty levels.
enum QuestionDifficulty {
  easy,
  medium,
  hard,
}

extension QuestionDifficultyExtension on QuestionDifficulty {
  String get displayName {
    switch (this) {
      case QuestionDifficulty.easy:
        return 'Easy';
      case QuestionDifficulty.medium:
        return 'Medium';
      case QuestionDifficulty.hard:
        return 'Hard';
    }
  }
}

/// Model representing an individual question in the Question Bank repository.
class QuestionItemModel {
  final String id;
  final String question;
  final QuestionType type;
  final List<String> options;
  final String answer; // correct option or answer key snippet
  final ExamSubject subject;
  final String chapterName;
  final String? topicName;
  final QuestionDifficulty difficulty;
  final int marks;
  final String textbookReference;

  const QuestionItemModel({
    required this.id,
    required this.question,
    required this.type,
    this.options = const [],
    required this.answer,
    required this.subject,
    required this.chapterName,
    this.topicName,
    this.difficulty = QuestionDifficulty.medium,
    required this.marks,
    this.textbookReference = '',
  });

  factory QuestionItemModel.fromJson(Map<String, dynamic> json) {
    final rawSubject = json['subject'] as String? ?? 'Chemistry';
    final parsedSubject =
        SubjectUtils.tryParse(rawSubject) ?? ExamSubject.chemistry;

    final typeStr = (json['type'] as String? ?? 'mcq').toLowerCase();
    QuestionType parsedType = QuestionType.mcq;
    if (typeStr.contains('short')) {
      parsedType = QuestionType.short;
    } else if (typeStr.contains('long')) {
      parsedType = QuestionType.long;
    }

    final diffStr = (json['difficulty'] as String? ?? 'medium').toLowerCase();
    QuestionDifficulty parsedDiff = QuestionDifficulty.medium;
    if (diffStr == 'easy') {
      parsedDiff = QuestionDifficulty.easy;
    } else if (diffStr == 'hard') {
      parsedDiff = QuestionDifficulty.hard;
    }

    final rawOptions = json['options'] as List<dynamic>? ?? [];

    return QuestionItemModel(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      type: parsedType,
      options: rawOptions.map((e) => e.toString()).toList(),
      answer: json['answer'] as String? ?? '',
      subject: parsedSubject,
      chapterName: json['chapter_name'] as String? ?? '',
      topicName: json['topic_name'] as String?,
      difficulty: parsedDiff,
      marks: json['marks'] as int? ?? 1,
      textbookReference: json['textbook_reference'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'type': type.code,
      'options': options,
      'answer': answer,
      'subject': subject.apiString,
      'chapter_name': chapterName,
      if (topicName != null) 'topic_name': topicName,
      'difficulty': difficulty.name,
      'marks': marks,
      'textbook_reference': textbookReference,
    };
  }

  QuestionItemModel copyWith({
    String? id,
    String? question,
    QuestionType? type,
    List<String>? options,
    String? answer,
    ExamSubject? subject,
    String? chapterName,
    String? topicName,
    QuestionDifficulty? difficulty,
    int? marks,
    String? textbookReference,
  }) {
    return QuestionItemModel(
      id: id ?? this.id,
      question: question ?? this.question,
      type: type ?? this.type,
      options: options ?? this.options,
      answer: answer ?? this.answer,
      subject: subject ?? this.subject,
      chapterName: chapterName ?? this.chapterName,
      topicName: topicName ?? this.topicName,
      difficulty: difficulty ?? this.difficulty,
      marks: marks ?? this.marks,
      textbookReference: textbookReference ?? this.textbookReference,
    );
  }
}

/// Filter options for querying the Question Bank across all 5 subjects.
class QuestionBankFilterModel {
  final ExamSubject? subject;
  final QuestionDifficulty? difficulty;
  final QuestionType? type;
  final String? searchQuery;
  final String? chapterName;
  final int page;
  final int limit;

  const QuestionBankFilterModel({
    this.subject,
    this.difficulty,
    this.type,
    this.searchQuery,
    this.chapterName,
    this.page = 1,
    this.limit = 20,
  });

  Map<String, dynamic> toJson() {
    return {
      if (subject != null) 'subject': subject!.apiString,
      if (difficulty != null) 'difficulty': difficulty!.name,
      if (type != null) 'type': type!.code,
      if (searchQuery != null && searchQuery!.isNotEmpty)
        'search_query': searchQuery,
      if (chapterName != null && chapterName!.isNotEmpty)
        'chapter_name': chapterName,
      'page': page,
      'limit': limit,
    };
  }

  QuestionBankFilterModel copyWith({
    ExamSubject? subject,
    QuestionDifficulty? difficulty,
    QuestionType? type,
    String? searchQuery,
    String? chapterName,
    int? page,
    int? limit,
    bool clearSubject = false,
    bool clearDifficulty = false,
    bool clearType = false,
    bool clearSearchQuery = false,
    bool clearChapterName = false,
  }) {
    return QuestionBankFilterModel(
      subject: clearSubject ? null : (subject ?? this.subject),
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
      type: clearType ? null : (type ?? this.type),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      chapterName: clearChapterName ? null : (chapterName ?? this.chapterName),
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}
