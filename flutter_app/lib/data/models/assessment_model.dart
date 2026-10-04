import 'package:flutter_app/core/constants/subjects.dart';

/// Request model for test draft generation.
class GenerationOptions {
  final ExamSubject subject;
  final String chapterName;
  final int grade;
  final String testType; // 'topic' or 'full_chapter'
  final String? topicQuery;
  final int mcqCount;
  final int shortCount;
  final int longCount;
  final bool includeAnswerKey;
  final String? exercise;
  final String? generationInstruction;

  const GenerationOptions({
    required this.subject,
    required this.chapterName,
    this.grade = 9,
    this.testType = 'full_chapter',
    this.topicQuery,
    this.mcqCount = 5,
    this.shortCount = 3,
    this.longCount = 1,
    this.includeAnswerKey = true,
    this.exercise,
    this.generationInstruction,
  }) : assert(grade >= 9 && grade <= 12, 'grade must be between 9 and 12');

  Map<String, dynamic> toJson() {
    return {
      'subject': subject.apiString,
      'chapter_name': chapterName,
      'grade': grade,
      'test_type': testType,
      if (topicQuery != null && topicQuery!.isNotEmpty)
        'topic_query': topicQuery,
      'mcq_count': mcqCount,
      'short_count': shortCount,
      'long_count': longCount,
      'include_answer_key': includeAnswerKey,
      if (exercise != null && exercise!.isNotEmpty) 'exercise': exercise,
      if (generationInstruction != null && generationInstruction!.isNotEmpty)
        'generation_instruction': generationInstruction,
    };
  }

  factory GenerationOptions.fromJson(Map<String, dynamic> json) {
    return GenerationOptions(
      subject: SubjectUtils.fromApiString(json['subject'] as String),
      chapterName: json['chapter_name'] as String? ?? '',
      grade: json['grade'] as int? ?? 9,
      testType: json['test_type'] as String? ?? 'full_chapter',
      topicQuery: json['topic_query'] as String?,
      mcqCount: json['mcq_count'] as int? ?? 5,
      shortCount: json['short_count'] as int? ?? 3,
      longCount: json['long_count'] as int? ?? 1,
      includeAnswerKey: json['include_answer_key'] as bool? ?? true,
      exercise: json['exercise'] as String?,
      generationInstruction: json['generation_instruction'] as String?,
    );
  }

  GenerationOptions copyWith({
    ExamSubject? subject,
    String? chapterName,
    int? grade,
    String? testType,
    String? topicQuery,
    int? mcqCount,
    int? shortCount,
    int? longCount,
    bool? includeAnswerKey,
    String? exercise,
    String? generationInstruction,
  }) {
    return GenerationOptions(
      subject: subject ?? this.subject,
      chapterName: chapterName ?? this.chapterName,
      grade: grade ?? this.grade,
      testType: testType ?? this.testType,
      topicQuery: topicQuery ?? this.topicQuery,
      mcqCount: mcqCount ?? this.mcqCount,
      shortCount: shortCount ?? this.shortCount,
      longCount: longCount ?? this.longCount,
      includeAnswerKey: includeAnswerKey ?? this.includeAnswerKey,
      exercise: exercise ?? this.exercise,
      generationInstruction:
          generationInstruction ?? this.generationInstruction,
    );
  }
}

/// Model representing chapter metadata such as available exercises.
class ChapterMetadata {
  final String subject;
  final String chapter;
  final List<String> exercises;

  const ChapterMetadata({
    required this.subject,
    required this.chapter,
    required this.exercises,
  });

  factory ChapterMetadata.fromJson(Map<String, dynamic> json) {
    return ChapterMetadata(
      subject: json['subject'] as String? ?? '',
      chapter: json['chapter'] as String? ?? '',
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

/// Model representing a Multiple Choice Question (1 mark each).
class MCQItemModel {
  final int questionNumber;
  final String question;
  final List<String> options;
  final String correctOption;
  final String textbookReference;

  const MCQItemModel({
    required this.questionNumber,
    required this.question,
    required this.options,
    required this.correctOption,
    required this.textbookReference,
  });

  factory MCQItemModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? [];
    return MCQItemModel(
      questionNumber: json['question_number'] as int? ?? 1,
      question: json['question'] as String? ?? '',
      options: rawOptions.map((e) => e.toString()).toList(),
      correctOption: json['correct_option'] as String? ?? 'A',
      textbookReference: json['textbook_reference'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_number': questionNumber,
      'question': question,
      'options': options,
      'correct_option': correctOption,
      'textbook_reference': textbookReference,
    };
  }

  MCQItemModel copyWith({
    int? questionNumber,
    String? question,
    List<String>? options,
    String? correctOption,
    String? textbookReference,
  }) {
    return MCQItemModel(
      questionNumber: questionNumber ?? this.questionNumber,
      question: question ?? this.question,
      options: options ?? this.options,
      correctOption: correctOption ?? this.correctOption,
      textbookReference: textbookReference ?? this.textbookReference,
    );
  }
}

/// Model representing a Short Answer Question (2 marks default).
class ShortQuestionItemModel {
  final int questionNumber;
  final String question;
  final int marks;

  const ShortQuestionItemModel({
    required this.questionNumber,
    required this.question,
    this.marks = 2,
  });

  factory ShortQuestionItemModel.fromJson(Map<String, dynamic> json) {
    return ShortQuestionItemModel(
      questionNumber: json['question_number'] as int? ?? 1,
      question: json['question'] as String? ?? '',
      marks: json['marks'] as int? ?? 2,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_number': questionNumber,
      'question': question,
      'marks': marks,
    };
  }

  ShortQuestionItemModel copyWith({
    int? questionNumber,
    String? question,
    int? marks,
  }) {
    return ShortQuestionItemModel(
      questionNumber: questionNumber ?? this.questionNumber,
      question: question ?? this.question,
      marks: marks ?? this.marks,
    );
  }
}

/// Model representing a Long / Essay Question (5 marks default).
class LongQuestionItemModel {
  final int questionNumber;
  final String question;
  final int marks;

  const LongQuestionItemModel({
    required this.questionNumber,
    required this.question,
    this.marks = 5,
  });

  factory LongQuestionItemModel.fromJson(Map<String, dynamic> json) {
    return LongQuestionItemModel(
      questionNumber: json['question_number'] as int? ?? 1,
      question: json['question'] as String? ?? '',
      marks: json['marks'] as int? ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_number': questionNumber,
      'question': question,
      'marks': marks,
    };
  }

  LongQuestionItemModel copyWith({
    int? questionNumber,
    String? question,
    int? marks,
  }) {
    return LongQuestionItemModel(
      questionNumber: questionNumber ?? this.questionNumber,
      question: question ?? this.question,
      marks: marks ?? this.marks,
    );
  }
}

/// Assessment section container model for grouping questions by section.
class AssessmentSectionModel {
  final String sectionTitle;
  final String description;
  final int marksPerQuestion;
  final int totalSectionMarks;

  const AssessmentSectionModel({
    required this.sectionTitle,
    required this.description,
    required this.marksPerQuestion,
    required this.totalSectionMarks,
  });
}

/// Full Assessment Model matching Class9TestSchema backend output.
class AssessmentModel {
  final String testTitle;
  final ExamSubject subject;
  final String chapterOrTopic;
  final int grade;
  final int totalMarks;
  final String timeAllowed;
  final List<String> instructions;
  final List<MCQItemModel> mcqs;
  final List<ShortQuestionItemModel> shortQuestions;
  final List<LongQuestionItemModel> longQuestions;

  const AssessmentModel({
    required this.testTitle,
    required this.subject,
    required this.chapterOrTopic,
    this.grade = 9,
    required this.totalMarks,
    this.timeAllowed = '45 Minutes',
    this.instructions = const [
      'Attempt all questions.',
      'Write neatly and draw diagrams where necessary.'
    ],
    this.mcqs = const [],
    this.shortQuestions = const [],
    this.longQuestions = const [],
  });

  factory AssessmentModel.fromJson(Map<String, dynamic> json) {
    final rawSubject = json['subject'] as String? ?? 'Chemistry';
    final parsedSubject =
        SubjectUtils.tryParse(rawSubject) ?? ExamSubject.chemistry;

    final rawInstructions = json['instructions'] as List<dynamic>? ?? [];
    final instructionsList = rawInstructions.map((e) => e.toString()).toList();

    final rawMcqs = json['mcqs'] as List<dynamic>? ?? [];
    final mcqList = rawMcqs
        .map((e) => MCQItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final rawShorts = json['short_questions'] as List<dynamic>? ?? [];
    final shortList = rawShorts
        .map((e) => ShortQuestionItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final rawLongs = json['long_questions'] as List<dynamic>? ?? [];
    final longList = rawLongs
        .map((e) => LongQuestionItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return AssessmentModel(
      testTitle: json['test_title'] as String? ?? 'Assessment Test',
      subject: parsedSubject,
      chapterOrTopic: json['chapter_or_topic'] as String? ?? '',
      grade: json['grade'] as int? ?? 9,
      totalMarks: json['total_marks'] as int? ?? 0,
      timeAllowed: json['time_allowed'] as String? ?? '45 Minutes',
      instructions: instructionsList.isNotEmpty
          ? instructionsList
          : const [
              'Attempt all questions.',
              'Write neatly and draw diagrams where necessary.'
            ],
      mcqs: mcqList,
      shortQuestions: shortList,
      longQuestions: longList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'test_title': testTitle,
      'subject': subject.apiString,
      'chapter_or_topic': chapterOrTopic,
      'grade': grade,
      'total_marks': totalMarks,
      'time_allowed': timeAllowed,
      'instructions': instructions,
      'mcqs': mcqs.map((e) => e.toJson()).toList(),
      'short_questions': shortQuestions.map((e) => e.toJson()).toList(),
      'long_questions': longQuestions.map((e) => e.toJson()).toList(),
    };
  }

  int get calculatedTotalMarks {
    final mcqMarks = mcqs.length * 1;
    final shortMarks =
        shortQuestions.fold<int>(0, (sum, item) => sum + item.marks);
    final longMarks =
        longQuestions.fold<int>(0, (sum, item) => sum + item.marks);
    return mcqMarks + shortMarks + longMarks;
  }

  int get totalQuestionCount =>
      mcqs.length + shortQuestions.length + longQuestions.length;

  AssessmentModel copyWith({
    String? testTitle,
    ExamSubject? subject,
    String? chapterOrTopic,
    int? grade,
    int? totalMarks,
    String? timeAllowed,
    List<String>? instructions,
    List<MCQItemModel>? mcqs,
    List<ShortQuestionItemModel>? shortQuestions,
    List<LongQuestionItemModel>? longQuestions,
  }) {
    return AssessmentModel(
      testTitle: testTitle ?? this.testTitle,
      subject: subject ?? this.subject,
      chapterOrTopic: chapterOrTopic ?? this.chapterOrTopic,
      grade: grade ?? this.grade,
      totalMarks: totalMarks ?? this.totalMarks,
      timeAllowed: timeAllowed ?? this.timeAllowed,
      instructions: instructions ?? this.instructions,
      mcqs: mcqs ?? this.mcqs,
      shortQuestions: shortQuestions ?? this.shortQuestions,
      longQuestions: longQuestions ?? this.longQuestions,
    );
  }
}
