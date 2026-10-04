import 'dart:typed_data';
import 'package:flutter_app/data/models/assessment_model.dart';

/// Request payload model for rendering PDF examination paper via POST /api/tests/render-pdf.
class PdfRenderRequestModel {
  final AssessmentModel testData;
  final bool includeAnswerKey;

  const PdfRenderRequestModel({
    required this.testData,
    this.includeAnswerKey = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'test_data': testData.toJson(),
      'include_answer_key': includeAnswerKey,
    };
  }

  factory PdfRenderRequestModel.fromJson(Map<String, dynamic> json) {
    return PdfRenderRequestModel(
      testData: AssessmentModel.fromJson(
        json['test_data'] as Map<String, dynamic>? ?? {},
      ),
      includeAnswerKey: json['include_answer_key'] as bool? ?? true,
    );
  }

  PdfRenderRequestModel copyWith({
    AssessmentModel? testData,
    bool? includeAnswerKey,
  }) {
    return PdfRenderRequestModel(
      testData: testData ?? this.testData,
      includeAnswerKey: includeAnswerKey ?? this.includeAnswerKey,
    );
  }
}

/// Response payload model holding rendered PDF binary bytes & metadata.
class PdfRenderResponseModel {
  final Uint8List pdfBytes;
  final String filename;
  final String contentType;
  final bool isSuccess;
  final String? errorMessage;

  const PdfRenderResponseModel({
    required this.pdfBytes,
    this.filename = 'ExamCraft_AI_Test_Paper.pdf',
    this.contentType = 'application/pdf',
    this.isSuccess = true,
    this.errorMessage,
  });

  int get byteLength => pdfBytes.length;

  PdfRenderResponseModel copyWith({
    Uint8List? pdfBytes,
    String? filename,
    String? contentType,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return PdfRenderResponseModel(
      pdfBytes: pdfBytes ?? this.pdfBytes,
      filename: filename ?? this.filename,
      contentType: contentType ?? this.contentType,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
