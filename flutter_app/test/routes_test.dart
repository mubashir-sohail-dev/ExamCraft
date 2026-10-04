import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/routes/app_routes.dart';

void main() {
  group('AppRoutes Architecture Tests', () {
    test('Should define 11 core route constants correctly', () {
      expect(AppRoutes.home, equals('/home'));
      expect(AppRoutes.generate, equals('/generate'));
      expect(AppRoutes.generating, equals('/generating'));
      expect(AppRoutes.review, equals('/review'));
      expect(AppRoutes.pdfPreview, equals('/pdf_preview'));
      expect(AppRoutes.questionBank, equals('/question_bank'));
      expect(AppRoutes.recentPapers, equals('/recent_papers'));
      expect(AppRoutes.upload, equals('/upload'));
      expect(AppRoutes.uploadStatus, equals('/upload/status'));
      expect(AppRoutes.settings, equals('/settings'));
      expect(AppRoutes.about, equals('/about'));
    });

    test('Should define sub-routes and screen aliases correctly', () {
      expect(AppRoutes.homeOverview, equals('/home/overview'));
      expect(AppRoutes.pdfPreviewActions, equals('/pdf_preview/actions'));
      expect(AppRoutes.questionBankFilters, equals('/question_bank/filters'));
      expect(AppRoutes.settingsAdvanced, equals('/settings/advanced'));
      expect(AppRoutes.aboutVersion, equals('/about/version'));
    });

    test('routesMap should contain widget builders for all routes', () {
      final routes = AppRoutes.routesMap;
      expect(routes.containsKey(AppRoutes.home), isTrue);
      expect(routes.containsKey(AppRoutes.generate), isTrue);
      expect(routes.containsKey(AppRoutes.generating), isTrue);
      expect(routes.containsKey(AppRoutes.review), isTrue);
      expect(routes.containsKey(AppRoutes.pdfPreview), isTrue);
      expect(routes.containsKey(AppRoutes.questionBank), isTrue);
      expect(routes.containsKey(AppRoutes.recentPapers), isTrue);
      expect(routes.containsKey(AppRoutes.upload), isTrue);
      expect(routes.containsKey(AppRoutes.uploadStatus), isTrue);
      expect(routes.containsKey(AppRoutes.settings), isTrue);
      expect(routes.containsKey(AppRoutes.about), isTrue);
    });

    test('onGenerateRoute should return valid MaterialPageRoute for known and unknown routes', () {
      final homeRoute = AppRoutes.onGenerateRoute(const RouteSettings(name: AppRoutes.home));
      expect(homeRoute, isA<MaterialPageRoute>());

      final unknownRoute = AppRoutes.onGenerateRoute(const RouteSettings(name: '/unknown_path'));
      expect(unknownRoute, isA<MaterialPageRoute>());
    });
  });
}
