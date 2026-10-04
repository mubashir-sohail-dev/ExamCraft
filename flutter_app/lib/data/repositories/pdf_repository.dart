import 'dart:typed_data';
import 'package:flutter_app/core/constants/subjects.dart';
import 'package:flutter_app/core/network/api_client.dart';
import 'package:flutter_app/data/models/assessment_model.dart';
import 'package:flutter_app/data/models/pdf_model.dart';

abstract class IPdfRepository {
  Future<PdfRenderResponseModel> renderPdf(PdfRenderRequestModel request);
  Future<PdfRenderResponseModel> renderPdfFromAssessment(
    AssessmentModel assessment, {
    bool includeAnswerKey = true,
  });
}

class PdfRepository implements IPdfRepository {
  final ApiClient apiClient;

  PdfRepository({required this.apiClient});

  @override
  Future<PdfRenderResponseModel> renderPdf(
      PdfRenderRequestModel request) async {
    final Uint8List pdfBytes = await apiClient.postForBytes(
      '/api/tests/render-pdf',
      data: request.toJson(),
    );

    final subjectName = request.testData.subject.apiString.replaceAll(' ', '_');
    final filename = 'ExamCraft_AI_${subjectName}_Grade9_Test.pdf';

    return PdfRenderResponseModel(
      pdfBytes: pdfBytes,
      filename: filename,
      contentType: 'application/pdf',
      isSuccess: true,
    );
  }

  @override
  Future<PdfRenderResponseModel> renderPdfFromAssessment(
    AssessmentModel assessment, {
    bool includeAnswerKey = true,
  }) async {
    final request = PdfRenderRequestModel(
      testData: assessment,
      includeAnswerKey: includeAnswerKey,
    );
    return renderPdf(request);
  }
}
