import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/subjects.dart';
import 'package:flutter_app/data/models/question_bank_model.dart';
import 'package:flutter_app/data/repositories/question_bank_repository.dart';

class QuestionBankProvider extends ChangeNotifier {
  final IQuestionBankRepository questionBankRepository;

  QuestionBankFilterModel _filter = const QuestionBankFilterModel();
  List<QuestionItemModel> _questions = [];
  int _totalCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  QuestionBankFilterModel get filter => _filter;
  List<QuestionItemModel> get questions => _questions;
  int get totalCount => _totalCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalPages => (_totalCount / _filter.limit).ceil();

  QuestionBankProvider({required this.questionBankRepository}) {
    fetchQuestions();
  }

  /// Fetch questions from repository matching current filter
  Future<void> fetchQuestions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await questionBankRepository.getQuestions(_filter);
      final count = await questionBankRepository.getTotalQuestionCount(_filter);
      _questions = results;
      _totalCount = count;
    } catch (e) {
      _errorMessage = 'Failed to fetch questions: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSubject(ExamSubject? subject) {
    if (subject == _filter.subject) return;
    _filter = _filter.copyWith(
      subject: subject,
      clearSubject: subject == null,
      page: 1,
    );
    fetchQuestions();
  }

  void setDifficulty(QuestionDifficulty? difficulty) {
    if (difficulty == _filter.difficulty) return;
    _filter = _filter.copyWith(
      difficulty: difficulty,
      clearDifficulty: difficulty == null,
      page: 1,
    );
    fetchQuestions();
  }

  void setType(QuestionType? type) {
    if (type == _filter.type) return;
    _filter = _filter.copyWith(
      type: type,
      clearType: type == null,
      page: 1,
    );
    fetchQuestions();
  }

  void setSearchQuery(String? query) {
    _filter = _filter.copyWith(
      searchQuery: query,
      clearSearchQuery: query == null || query.isEmpty,
      page: 1,
    );
    fetchQuestions();
  }

  void setPage(int page) {
    if (page < 1 || (totalPages > 0 && page > totalPages)) return;
    _filter = _filter.copyWith(page: page);
    fetchQuestions();
  }

  void clearFilters() {
    _filter = const QuestionBankFilterModel();
    fetchQuestions();
  }
}
