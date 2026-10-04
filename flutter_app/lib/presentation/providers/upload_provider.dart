import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/core/constants/subjects.dart';
import 'package:flutter_app/data/models/textbook_model.dart';
import 'package:flutter_app/data/repositories/upload_repository.dart';

enum UploadStateStatus {
  idle,
  selecting,
  uploading,
  extracting,
  indexing,
  success,
  error,
}

class UploadProvider extends ChangeNotifier {
  static const String _storageKey = 'textbooks_storage';

  final IUploadRepository uploadRepository;

  UploadStateStatus _status = UploadStateStatus.idle;
  File? _selectedFile;
  String _selectedFileName = '';
  int _fileSizeBytes = 0;
  ExamSubject _selectedSubject = ExamSubject.chemistry;
  int _selectedGrade = 9;
  String _chapterName = '';
  double _progress = 0.0;
  String? _errorMessage;
  TextbookProcessingStatusModel? _processingStatus;
  List<Map<String, dynamic>> _uploadedTextbooks = [];

  UploadProvider({required this.uploadRepository}) {
    loadUploadedTextbooks();
  }

  // Getters
  UploadStateStatus get status => _status;
  File? get selectedFile => _selectedFile;
  String get selectedFileName => _selectedFileName;
  int get fileSizeBytes => _fileSizeBytes;
  ExamSubject get selectedSubject => _selectedSubject;
  int get selectedGrade => _selectedGrade;
  String get chapterName => _chapterName;
  double get progress => _progress;
  String? get errorMessage => _errorMessage;
  TextbookProcessingStatusModel? get processingStatus => _processingStatus;
  List<Map<String, dynamic>> get uploadedTextbooks =>
      List.unmodifiable(_uploadedTextbooks);

  bool get isUploading =>
      _status == UploadStateStatus.uploading ||
      _status == UploadStateStatus.extracting ||
      _status == UploadStateStatus.indexing;

  Future<void> loadUploadedTextbooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        _uploadedTextbooks = decoded.cast<Map<String, dynamic>>();
      } else {
        _uploadedTextbooks = [];
      }
    } catch (_) {
      _uploadedTextbooks = [];
    }
    notifyListeners();
  }

  Future<void> _saveTextbookToStorage({
    required String filename,
    required ExamSubject subject,
    required int grade,
    required int chunksIndexed,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final item = {
        'filename': filename,
        'subject': subject.displayName,
        'subject_api': subject.apiString,
        'grade': grade,
        'chunks_indexed': chunksIndexed,
        'upload_date': DateTime.now().toIso8601String(),
      };
      _uploadedTextbooks.insert(0, item);
      await prefs.setString(_storageKey, jsonEncode(_uploadedTextbooks));
    } catch (_) {}
  }

  void setSubject(ExamSubject subject) {
    _selectedSubject = subject;
    notifyListeners();
  }

  void setGrade(int grade) {
    _selectedGrade = grade;
    notifyListeners();
  }

  void setChapterName(String name) {
    _chapterName = name;
    notifyListeners();
  }

  void setSelectedFile(File file, {String? customName, int? customSize}) {
    _selectedFile = file;
    _selectedFileName =
        customName ?? file.path.split(Platform.pathSeparator).last;
    _fileSizeBytes =
        customSize ?? (file.existsSync() ? file.lengthSync() : 2500000);
    _status = UploadStateStatus.selecting;
    _errorMessage = null;
    notifyListeners();
  }

  void clearSelectedFile() {
    _selectedFile = null;
    _selectedFileName = '';
    _fileSizeBytes = 0;
    _progress = 0.0;
    _status = UploadStateStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> startUpload() async {
    if (_selectedFile == null) {
      _errorMessage = 'Please select a textbook PDF file to upload.';
      _status = UploadStateStatus.error;
      notifyListeners();
      return false;
    }

    _status = UploadStateStatus.uploading;
    _progress = 0.25;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await uploadRepository.uploadTextbook(
        file: _selectedFile!,
        subject: _selectedSubject,
        grade: _selectedGrade,
      );

      if (response.isSuccess) {
        await _saveTextbookToStorage(
          filename: _selectedFileName,
          subject: _selectedSubject,
          grade: _selectedGrade,
          chunksIndexed: response.chunksIndexed,
        );
        _progress = 1.0;
        _status = UploadStateStatus.success;
        _errorMessage = null;
      } else {
        _status = UploadStateStatus.error;
        _errorMessage = response.message;
      }
      notifyListeners();
      return response.isSuccess;
    } catch (e) {
      _errorMessage = e.toString();
      _status = UploadStateStatus.error;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _status = UploadStateStatus.idle;
    _selectedFile = null;
    _selectedFileName = '';
    _fileSizeBytes = 0;
    _progress = 0.0;
    _errorMessage = null;
    _processingStatus = null;
    notifyListeners();
  }
}
