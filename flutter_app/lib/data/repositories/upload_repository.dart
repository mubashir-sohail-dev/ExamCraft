import 'dart:io';
import 'package:flutter_app/core/constants/subjects.dart';
import 'package:flutter_app/core/network/api_client.dart';
import 'package:flutter_app/data/models/textbook_model.dart';

abstract class IUploadRepository {
  Future<TextbookUploadResponseModel> uploadTextbook({
    required File file,
    required ExamSubject subject,
    int grade = 9,
  });

  Future<TextbookProcessingStatusModel> getUploadStatus(String uploadId);
}

class UploadRepository implements IUploadRepository {
  final ApiClient apiClient;

  UploadRepository({required this.apiClient});

  @override
  Future<TextbookUploadResponseModel> uploadTextbook({
    required File file,
    required ExamSubject subject,
    int grade = 9,
  }) async {
    try {
      final responseData = await apiClient.postMultipart(
        '/api/admin/upload-textbook',
        file: file,
        fileKey: 'file',
        fields: {
          'subject': subject.apiString,
          'grade': grade.toString(),
        },
      );

      if (responseData is Map<String, dynamic>) {
        return TextbookUploadResponseModel.fromJson(responseData);
      }
      throw ApiException(
          message: 'Invalid response from textbook upload endpoint.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to upload textbook: $e');
    }
  }

  @override
  Future<TextbookProcessingStatusModel> getUploadStatus(String uploadId) async {
    try {
      final responseData = await apiClient.get(
        '/api/admin/upload-status/${Uri.encodeComponent(uploadId)}',
      );

      if (responseData is Map<String, dynamic>) {
        return TextbookProcessingStatusModel.fromJson(responseData);
      }
      throw ApiException(
          message: 'Invalid response from upload status endpoint.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to fetch upload status: $e');
    }
  }
}
