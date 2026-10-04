import 'package:flutter_app/core/constants/subjects.dart';
import 'package:flutter_app/data/models/assessment_model.dart';

/// Metadata model representing a previously generated examination paper stored locally.
class RecentPaperModel {
  final String paperId;
  final String title;
  final ExamSubject subject;
  final String chapterOrTopic;
  final int totalMarks;
  final DateTime dateCreated;
  final String timeAllowed;
  final AssessmentModel testData;
  final String? pdfPath;
  final bool isFavorite;

  const RecentPaperModel({
    required this.paperId,
    required this.title,
    required this.subject,
    required this.chapterOrTopic,
    required this.totalMarks,
    required this.dateCreated,
    this.timeAllowed = '45 Minutes',
    required this.testData,
    this.pdfPath,
    this.isFavorite = false,
  });

  factory RecentPaperModel.fromJson(Map<String, dynamic> json) {
    final rawSubject = json['subject'] as String? ?? 'Chemistry';
    final parsedSubject =
        SubjectUtils.tryParse(rawSubject) ?? ExamSubject.chemistry;

    final rawTestData = json['test_data'] as Map<String, dynamic>? ?? {};
    final parsedTestData = AssessmentModel.fromJson(rawTestData);

    return RecentPaperModel(
      paperId: json['paper_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Generated Paper',
      subject: parsedSubject,
      chapterOrTopic: json['chapter_or_topic'] as String? ?? '',
      totalMarks: json['total_marks'] as int? ?? 0,
      dateCreated: json['date_created'] != null
          ? DateTime.tryParse(json['date_created'] as String) ?? DateTime.now()
          : DateTime.now(),
      timeAllowed: json['time_allowed'] as String? ?? '45 Minutes',
      testData: parsedTestData,
      pdfPath: json['pdf_path'] as String?,
      isFavorite: json['is_favorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paper_id': paperId,
      'title': title,
      'subject': subject.apiString,
      'chapter_or_topic': chapterOrTopic,
      'total_marks': totalMarks,
      'date_created': dateCreated.toIso8601String(),
      'time_allowed': timeAllowed,
      'test_data': testData.toJson(),
      'pdf_path': pdfPath,
      'is_favorite': isFavorite,
    };
  }

  RecentPaperModel copyWith({
    String? paperId,
    String? title,
    ExamSubject? subject,
    String? chapterOrTopic,
    int? totalMarks,
    DateTime? dateCreated,
    String? timeAllowed,
    AssessmentModel? testData,
    String? pdfPath,
    bool? isFavorite,
  }) {
    return RecentPaperModel(
      paperId: paperId ?? this.paperId,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      chapterOrTopic: chapterOrTopic ?? this.chapterOrTopic,
      totalMarks: totalMarks ?? this.totalMarks,
      dateCreated: dateCreated ?? this.dateCreated,
      timeAllowed: timeAllowed ?? this.timeAllowed,
      testData: testData ?? this.testData,
      pdfPath: pdfPath ?? this.pdfPath,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
