import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/subjects.dart';
import 'package:flutter_app/data/models/recent_papers_model.dart';
import 'package:flutter_app/data/repositories/recent_papers_repository.dart';

class RecentPapersProvider extends ChangeNotifier {
  final IRecentPapersRepository recentPapersRepository;

  List<RecentPaperModel> _papers = [];
  ExamSubject? _selectedSubjectFilter;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<RecentPaperModel> get papers => _papers;
  ExamSubject? get selectedSubjectFilter => _selectedSubjectFilter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<RecentPaperModel> get favoritePapers =>
      _papers.where((p) => p.isFavorite).toList();

  RecentPapersProvider({required this.recentPapersRepository}) {
    loadRecentPapers();
  }

  Future<void> loadRecentPapers() async {
    debugPrint(
        '[RecentPapersProvider] loadRecentPapers() START - current papers count: ${_papers.length}');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await recentPapersRepository.getRecentPapers(
        subjectFilter: _selectedSubjectFilter,
      );
      _papers = results;
      debugPrint(
          '[RecentPapersProvider] loadRecentPapers() SUCCESS - loaded ${_papers.length} papers');
    } catch (e, stack) {
      _errorMessage = 'Failed to load recent papers: ${e.toString()}';
      debugPrint('[RecentPapersProvider] loadRecentPapers() ERROR: $e');
      debugPrint('[RecentPapersProvider] STACK: $stack');
    } finally {
      _isLoading = false;
      debugPrint(
          '[RecentPapersProvider] loadRecentPapers() FINALLY - calling notifyListeners, papers=${_papers.length}');
      notifyListeners();
    }
  }

  void filterBySubject(ExamSubject? subject) {
    if (_selectedSubjectFilter == subject) return;
    _selectedSubjectFilter = subject;
    loadRecentPapers();
  }

  Future<void> savePaper(RecentPaperModel paper) async {
    try {
      await recentPapersRepository.saveRecentPaper(paper);
      await loadRecentPapers();
    } catch (e) {
      _errorMessage = 'Failed to save paper: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> deletePaper(String paperId) async {
    try {
      await recentPapersRepository.deleteRecentPaper(paperId);
      await loadRecentPapers();
    } catch (e) {
      _errorMessage = 'Failed to delete paper: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String paperId) async {
    try {
      await recentPapersRepository.toggleFavorite(paperId);
      await loadRecentPapers();
    } catch (e) {
      _errorMessage = 'Failed to update favorite status: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    try {
      await recentPapersRepository.clearAllRecentPapers();
      await loadRecentPapers();
    } catch (e) {
      _errorMessage = 'Failed to clear recent papers: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Helper method for populating papers in unit tests
  void setTestPapers(List<RecentPaperModel> testPapers) {
    _papers = testPapers;
    notifyListeners();
  }
}
