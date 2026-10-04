import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/subjects.dart';
import 'package:flutter_app/data/models/assessment_model.dart';
import 'package:flutter_app/data/models/pdf_model.dart';
import 'package:flutter_app/data/models/recent_papers_model.dart';
import 'package:flutter_app/data/repositories/assessment_repository.dart';
import 'package:flutter_app/data/repositories/pdf_repository.dart';
import 'package:flutter_app/data/repositories/recent_papers_repository.dart';

enum AssessmentStateStatus {
  initial,
  loadingSubjects,
  loadingChapters,
  generating,
  renderingPdf,
  success,
  error,
}

class AssessmentProvider extends ChangeNotifier {
  final IAssessmentRepository assessmentRepository;
  final IPdfRepository pdfRepository;
  final IRecentPapersRepository? recentPapersRepository;
  VoidCallback? onAssessmentGenerated;

  AssessmentStateStatus _status = AssessmentStateStatus.initial;
  ExamSubject _selectedSubject = ExamSubject.chemistry;
  int _selectedGrade = 9;
  List<ExamSubject> _supportedSubjects = SubjectUtils.allSubjects;
  List<String> _chapters = [];
  String? _selectedChapter;
  String _testType = 'full_chapter';
  String? _topicQuery;

  int _mcqCount = 5;
  int _shortCount = 3;
  int _longCount = 1;
  bool _includeAnswerKey = true;

  AssessmentModel? _generatedAssessment;
  PdfRenderResponseModel? _pdfResponse;
  String? _errorMessage;

  List<String> _availableExercises = [];
  String? _selectedExercise;
  String? _generationInstruction;

  // Getters
  AssessmentStateStatus get status => _status;
  ExamSubject get selectedSubject => _selectedSubject;
  int get selectedGrade => _selectedGrade;
  List<ExamSubject> get supportedSubjects => _supportedSubjects;
  List<String> get chapters => _chapters;
  String? get selectedChapter => _selectedChapter;
  String get testType => _testType;
  String? get topicQuery => _topicQuery;
  int get mcqCount => _mcqCount;
  int get shortCount => _shortCount;
  int get longCount => _longCount;
  bool get includeAnswerKey => _includeAnswerKey;
  AssessmentModel? get generatedAssessment => _generatedAssessment;
  PdfRenderResponseModel? get pdfResponse => _pdfResponse;
  String? get errorMessage => _errorMessage;
  List<String> get availableExercises => _availableExercises;
  String? get selectedExercise => _selectedExercise;
  String? get generationInstruction => _generationInstruction;

  bool get isLoading =>
      _status == AssessmentStateStatus.loadingSubjects ||
      _status == AssessmentStateStatus.loadingChapters ||
      _status == AssessmentStateStatus.generating ||
      _status == AssessmentStateStatus.renderingPdf;

  AssessmentProvider({
    required this.assessmentRepository,
    required this.pdfRepository,
    this.recentPapersRepository,
  });

  /// Initialize provider by loading supported subjects and default chapters
  Future<void> initialize() async {
    await fetchSupportedSubjects();
    await fetchChaptersForSubject(_selectedSubject);
  }

  /// Fetch list of supported subjects from backend
  Future<void> fetchSupportedSubjects() async {
    _status = AssessmentStateStatus.loadingSubjects;
    _errorMessage = null;
    notifyListeners();

    try {
      final subjects = await assessmentRepository.getSupportedSubjects();
      if (subjects.isNotEmpty) {
        _supportedSubjects = subjects;
      }
      _status = AssessmentStateStatus.initial;
    } catch (e) {
      _errorMessage = 'Failed to fetch supported subjects: ${e.toString()}';
      _status = AssessmentStateStatus.error;
    } finally {
      notifyListeners();
    }
  }

  /// Select grade and dynamically reload chapters for selected subject
  Future<void> selectGrade(int grade) async {
    if (_selectedGrade == grade && _chapters.isNotEmpty) return;
    _selectedGrade = grade;
    _selectedChapter = null;
    _availableExercises = [];
    _selectedExercise = null;
    notifyListeners();
    await fetchChaptersForSubject(_selectedSubject, grade: grade);
  }

  /// Select subject and dynamically load its chapters
  Future<void> selectSubject(ExamSubject subject) async {
    _selectedSubject = subject;
    _selectedChapter = null;
    notifyListeners();
    await fetchChaptersForSubject(subject);
  }

  /// Fetch available chapters for selected subject and grade
  Future<void> fetchChaptersForSubject(ExamSubject subject, {int? grade}) async {
    final targetGrade = grade ?? _selectedGrade;
    _status = AssessmentStateStatus.loadingChapters;
    _errorMessage = null;
    notifyListeners();

    try {
      final loadedChapters =
          await assessmentRepository.getSubjectChapters(subject, grade: targetGrade);
      _chapters = loadedChapters;
      if (_chapters.isNotEmpty) {
        _selectedChapter = _chapters.first;
        await _fetchMetadataIfMath(_selectedSubject, _selectedChapter!);
      } else {
        _availableExercises = [];
        _selectedExercise = null;
      }
      _status = AssessmentStateStatus.initial;
    } catch (e) {
      _errorMessage =
          'Failed to fetch chapters for ${subject.displayName}: ${e.toString()}';
      _status = AssessmentStateStatus.error;
    } finally {
      notifyListeners();
    }
  }

  void selectChapter(String chapter) {
    _selectedChapter = chapter;
    notifyListeners();
    _fetchMetadataIfMath(_selectedSubject, chapter);
  }

  Future<void> _fetchMetadataIfMath(ExamSubject subject, String chapter) async {
    if (subject.apiString == 'Mathematics') {
      try {
        final metadata = await assessmentRepository.getChapterMetadata(
            subject.apiString, chapter, grade: _selectedGrade);
        _availableExercises = metadata.exercises;
        if (!_availableExercises.contains(_selectedExercise)) {
          _selectedExercise =
              _availableExercises.isNotEmpty ? _availableExercises.first : null;
        }
      } catch (e) {
        _availableExercises = [];
        _selectedExercise = null;
      }
    } else {
      _availableExercises = [];
      _selectedExercise = null;
    }
    notifyListeners();
  }

  void setTestType(String type) {
    _testType = type;
    notifyListeners();
  }

  void setTopicQuery(String? query) {
    _topicQuery = query;
    notifyListeners();
  }

  void setGenerationInstruction(String? instruction) {
    _generationInstruction = instruction;
    notifyListeners();
  }

  void setSelectedExercise(String? exercise) {
    _selectedExercise = exercise;
    notifyListeners();
  }

  void updateQuestionCounts({int? mcq, int? short, int? long}) {
    if (mcq != null && mcq >= 1) _mcqCount = mcq;
    if (short != null && short >= 0) _shortCount = short;
    if (long != null && long >= 0) _longCount = long;
    notifyListeners();
  }

  void toggleAnswerKey(bool value) {
    _includeAnswerKey = value;
    notifyListeners();
  }

  /// Generate draft assessment test using live backend RAG endpoint
  Future<AssessmentModel?> generateDraftTest() async {
    debugPrint(
        '[AssessmentProvider] generateDraftTest() START - status=$_status subject=${_selectedSubject.displayName}');
    if (_testType == 'topic' &&
        (_topicQuery == null || _topicQuery!.trim().isEmpty)) {
      _errorMessage =
          'Topic query is required for topic-based test generation.';
      _status = AssessmentStateStatus.error;
      notifyListeners();
      return null;
    }

    _status = AssessmentStateStatus.generating;
    _errorMessage = null;
    _pdfResponse = null;
    debugPrint(
        '[AssessmentProvider] generateDraftTest() status set to generating, calling notifyListeners');
    notifyListeners();

    final chapterFallback = _selectedChapter ??
        (_chapters.isNotEmpty ? _chapters.first : 'General');
    final request = GenerationOptions(
      subject: _selectedSubject,
      chapterName: chapterFallback,
      grade: _selectedGrade,
      testType: _testType,
      topicQuery: _topicQuery,
      mcqCount: _mcqCount,
      shortCount: _shortCount,
      longCount: _longCount,
      includeAnswerKey: _includeAnswerKey,
      exercise: _selectedSubject.apiString == 'Mathematics'
          ? _selectedExercise
          : null,
      generationInstruction: _generationInstruction,
    );

    try {
      debugPrint(
          '[AssessmentProvider] calling assessmentRepository.generateDraftTest()...');
      final result = await assessmentRepository.generateDraftTest(request);
      debugPrint(
          '[AssessmentProvider] generateDraftTest returned: ${result.testTitle}, mcqs=${result.mcqs.length}');
      _generatedAssessment = result;
      _status = AssessmentStateStatus.success;

      if (recentPapersRepository != null) {
        debugPrint(
            '[AssessmentProvider] saving recent paper to local storage...');
        final recentPaper = RecentPaperModel(
          paperId: DateTime.now().millisecondsSinceEpoch.toString(),
          title: result.testTitle,
          subject: _selectedSubject,
          chapterOrTopic: result.chapterOrTopic,
          totalMarks: result.totalMarks,
          dateCreated: DateTime.now(),
          timeAllowed: result.timeAllowed,
          testData: result,
        );
        await recentPapersRepository!.saveRecentPaper(recentPaper);
        debugPrint(
            '[AssessmentProvider] recent paper saved, scheduling onAssessmentGenerated callback for next frame...');
        if (onAssessmentGenerated != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onAssessmentGenerated?.call();
            debugPrint(
                '[AssessmentProvider] onAssessmentGenerated callback completed (deferred)');
          });
        }
      }

      return result;
    } catch (e, stack) {
      debugPrint('[AssessmentProvider] ERROR in generateDraftTest: $e');
      debugPrint('[AssessmentProvider] STACK: $stack');
      _errorMessage = e.toString();
      _status = AssessmentStateStatus.error;
      return null;
    } finally {
      debugPrint(
          '[AssessmentProvider] generateDraftTest FINALLY - calling notifyListeners, status=$_status');
      notifyListeners();
    }
  }

  /// Render approved draft into a PDF binary paper
  Future<PdfRenderResponseModel?> renderPdf() async {
    if (_generatedAssessment == null) {
      _errorMessage = 'No generated assessment available to render PDF.';
      _status = AssessmentStateStatus.error;
      notifyListeners();
      return null;
    }

    _status = AssessmentStateStatus.renderingPdf;
    _errorMessage = null;
    notifyListeners();

    final request = PdfRenderRequestModel(
      testData: _generatedAssessment!,
      includeAnswerKey: _includeAnswerKey,
    );

    try {
      final response = await pdfRepository.renderPdf(request);
      _pdfResponse = response;
      _status = AssessmentStateStatus.success;
      return response;
    } catch (e) {
      _errorMessage = 'Failed to render PDF: ${e.toString()}';
      _status = AssessmentStateStatus.error;
      return null;
    } finally {
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AssessmentStateStatus.error) {
      _status = AssessmentStateStatus.initial;
    }
    notifyListeners();
  }

  void resetDraft() {
    _generatedAssessment = null;
    _pdfResponse = null;
    _status = AssessmentStateStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }

  /// Helper method for populating draft assessment in tests
  void setTestAssessment(AssessmentModel assessment) {
    _generatedAssessment = assessment;
    notifyListeners();
  }
}
