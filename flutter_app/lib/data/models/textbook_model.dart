import 'package:flutter_app/core/constants/subjects.dart';

/// Response model for admin textbook upload endpoint (POST /api/admin/upload-textbook).
class TextbookUploadResponseModel {
  final String status;
  final String message;
  final int chunksIndexed;

  const TextbookUploadResponseModel({
    required this.status,
    required this.message,
    required this.chunksIndexed,
  });

  factory TextbookUploadResponseModel.fromJson(Map<String, dynamic> json) {
    return TextbookUploadResponseModel(
      status: json['status'] as String? ?? 'unknown',
      message: json['message'] as String? ?? '',
      chunksIndexed: json['chunks_indexed'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'chunks_indexed': chunksIndexed,
    };
  }

  bool get isSuccess => status.toLowerCase() == 'success';

  TextbookUploadResponseModel copyWith({
    String? status,
    String? message,
    int? chunksIndexed,
  }) {
    return TextbookUploadResponseModel(
      status: status ?? this.status,
      message: message ?? this.message,
      chunksIndexed: chunksIndexed ?? this.chunksIndexed,
    );
  }
}

/// Enum for textbook processing lifecycle status.
enum TextbookUploadStatus {
  idle,
  uploading,
  extracting,
  indexing,
  completed,
  failed,
}

/// Model representing detailed textbook processing status for background polling/progress.
class TextbookProcessingStatusModel {
  final String uploadId;
  final String filename;
  final ExamSubject subject;
  final int grade;
  final TextbookUploadStatus status;
  final double progress; // 0.0 to 1.0
  final String message;
  final int chunksProcessed;
  final int totalChunks;
  final DateTime updatedAt;

  const TextbookProcessingStatusModel({
    required this.uploadId,
    required this.filename,
    required this.subject,
    this.grade = 9,
    this.status = TextbookUploadStatus.idle,
    this.progress = 0.0,
    this.message = '',
    this.chunksProcessed = 0,
    this.totalChunks = 0,
    required this.updatedAt,
  });

  factory TextbookProcessingStatusModel.fromJson(Map<String, dynamic> json) {
    final rawSubject = json['subject'] as String? ?? 'Chemistry';
    final parsedSubject =
        SubjectUtils.tryParse(rawSubject) ?? ExamSubject.chemistry;

    final statusStr = json['status'] as String? ?? 'idle';
    TextbookUploadStatus parsedStatus = TextbookUploadStatus.idle;
    switch (statusStr.toLowerCase()) {
      case 'uploading':
        parsedStatus = TextbookUploadStatus.uploading;
        break;
      case 'extracting':
        parsedStatus = TextbookUploadStatus.extracting;
        break;
      case 'indexing':
      case 'processing':
        parsedStatus = TextbookUploadStatus.indexing;
        break;
      case 'completed':
      case 'success':
        parsedStatus = TextbookUploadStatus.completed;
        break;
      case 'failed':
      case 'error':
        parsedStatus = TextbookUploadStatus.failed;
        break;
      default:
        parsedStatus = TextbookUploadStatus.idle;
    }

    return TextbookProcessingStatusModel(
      uploadId: json['upload_id'] as String? ?? '',
      filename: json['filename'] as String? ?? '',
      subject: parsedSubject,
      grade: json['grade'] as int? ?? 9,
      status: parsedStatus,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      message: json['message'] as String? ?? '',
      chunksProcessed: json['chunks_processed'] as int? ?? 0,
      totalChunks: json['total_chunks'] as int? ?? 0,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'upload_id': uploadId,
      'filename': filename,
      'subject': subject.apiString,
      'grade': grade,
      'status': status.name,
      'progress': progress,
      'message': message,
      'chunks_processed': chunksProcessed,
      'total_chunks': totalChunks,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TextbookProcessingStatusModel copyWith({
    String? uploadId,
    String? filename,
    ExamSubject? subject,
    int? grade,
    TextbookUploadStatus? status,
    double? progress,
    String? message,
    int? chunksProcessed,
    int? totalChunks,
    DateTime? updatedAt,
  }) {
    return TextbookProcessingStatusModel(
      uploadId: uploadId ?? this.uploadId,
      filename: filename ?? this.filename,
      subject: subject ?? this.subject,
      grade: grade ?? this.grade,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      chunksProcessed: chunksProcessed ?? this.chunksProcessed,
      totalChunks: totalChunks ?? this.totalChunks,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
