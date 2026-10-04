import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/core/constants/subjects.dart';
import 'package:flutter_app/data/models/recent_papers_model.dart';

abstract class IRecentPapersRepository {
  Future<List<RecentPaperModel>> getRecentPapers({ExamSubject? subjectFilter});
  Future<RecentPaperModel?> getPaperById(String paperId);
  Future<void> saveRecentPaper(RecentPaperModel paper);
  Future<void> deleteRecentPaper(String paperId);
  Future<void> toggleFavorite(String paperId);
  Future<void> clearAllRecentPapers();
}

/// Repository for local persistent storage and retrieval of authentic backend-generated exam papers.
class RecentPapersRepository implements IRecentPapersRepository {
  static const String _storageKey = 'recent_papers_storage';
  List<RecentPaperModel>? _cache;

  Future<void> _ensureLoaded() async {
    if (_cache != null) return;
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      _cache = [];
      return;
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      _cache = decoded
          .map((e) => RecentPaperModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _cache = [];
    }
  }

  Future<void> _saveToStorage() async {
    if (_cache == null) return;
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> encoded =
        _cache!.map((e) => e.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(encoded));
  }

  @override
  Future<List<RecentPaperModel>> getRecentPapers(
      {ExamSubject? subjectFilter}) async {
    await _ensureLoaded();
    final list = _cache ?? [];
    if (subjectFilter == null) {
      return List.unmodifiable(list);
    }
    return List.unmodifiable(
      list.where((p) => p.subject == subjectFilter),
    );
  }

  @override
  Future<RecentPaperModel?> getPaperById(String paperId) async {
    await _ensureLoaded();
    try {
      return (_cache ?? []).firstWhere((p) => p.paperId == paperId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveRecentPaper(RecentPaperModel paper) async {
    await _ensureLoaded();
    final existingIndex = _cache!.indexWhere((p) => p.paperId == paper.paperId);
    if (existingIndex >= 0) {
      _cache![existingIndex] = paper;
    } else {
      _cache!.insert(0, paper);
    }
    await _saveToStorage();
  }

  @override
  Future<void> deleteRecentPaper(String paperId) async {
    await _ensureLoaded();
    _cache!.removeWhere((p) => p.paperId == paperId);
    await _saveToStorage();
  }

  @override
  Future<void> toggleFavorite(String paperId) async {
    await _ensureLoaded();
    final index = _cache!.indexWhere((p) => p.paperId == paperId);
    if (index >= 0) {
      final existing = _cache![index];
      _cache![index] = existing.copyWith(isFavorite: !existing.isFavorite);
      await _saveToStorage();
    }
  }

  @override
  Future<void> clearAllRecentPapers() async {
    _cache = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
