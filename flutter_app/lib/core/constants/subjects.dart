import 'package:flutter/material.dart';

/// Enum representing the mandatory 5 supported subjects in ExamCraft AI.
enum ExamSubject {
  physics,
  chemistry,
  mathematics,
  biology,
  computerScience,
}

extension ExamSubjectExtension on ExamSubject {
  /// User-facing display name.
  String get displayName {
    switch (this) {
      case ExamSubject.physics:
        return 'Physics';
      case ExamSubject.chemistry:
        return 'Chemistry';
      case ExamSubject.mathematics:
        return 'Mathematics';
      case ExamSubject.biology:
        return 'Biology';
      case ExamSubject.computerScience:
        return 'Computer Science';
    }
  }

  /// Exact API serialization string required by the backend.
  String get apiString {
    switch (this) {
      case ExamSubject.physics:
        return 'Physics';
      case ExamSubject.chemistry:
        return 'Chemistry';
      case ExamSubject.mathematics:
        return 'Mathematics';
      case ExamSubject.biology:
        return 'Biology';
      case ExamSubject.computerScience:
        return 'Computer Science';
    }
  }

  /// Primary color associated with the subject in Light Mode.
  Color get color {
    switch (this) {
      case ExamSubject.physics:
        return const Color(0xFF005BBF);
      case ExamSubject.chemistry:
        return const Color(0xFF006E2C);
      case ExamSubject.mathematics:
        return const Color(0xFF805600);
      case ExamSubject.biology:
        return const Color(0xFF673AB7);
      case ExamSubject.computerScience:
        return const Color(0xFF00838F);
    }
  }

  /// Dark mode variant color associated with the subject.
  Color get darkColor {
    switch (this) {
      case ExamSubject.physics:
        return const Color(0xFFADC7FF);
      case ExamSubject.chemistry:
        return const Color(0xFF86F898);
      case ExamSubject.mathematics:
        return const Color(0xFFFFBA45);
      case ExamSubject.biology:
        return const Color(0xFFD1C4E9);
      case ExamSubject.computerScience:
        return const Color(0xFF80DEEA);
    }
  }

  /// Icon representing the subject.
  IconData get icon {
    switch (this) {
      case ExamSubject.physics:
        return Icons.science_outlined;
      case ExamSubject.chemistry:
        return Icons.biotech_outlined;
      case ExamSubject.mathematics:
        return Icons.calculate_outlined;
      case ExamSubject.biology:
        return Icons.eco_outlined;
      case ExamSubject.computerScience:
        return Icons.computer_outlined;
    }
  }

  /// Brief description of the subject domain.
  String get description {
    switch (this) {
      case ExamSubject.physics:
        return 'Classical Mechanics, Electromagnetism, Optics, and Modern Physics';
      case ExamSubject.chemistry:
        return 'Physical Chemistry, Organic, Inorganic, and Chemical Reactions';
      case ExamSubject.mathematics:
        return 'Algebra, Geometry, Trigonometry, Calculus, and Statistics';
      case ExamSubject.biology:
        return 'Cell Biology, Genetics, Physiology, Ecology, and Evolution';
      case ExamSubject.computerScience:
        return 'Algorithms, Programming, Data Structures, Networks, and Databases';
    }
  }

  /// Alias for apiString serialization.
  String toJson() => apiString;
}

/// Helper methods and static utilities for [ExamSubject].
abstract class SubjectUtils {
  /// All 5 mandatory subjects list.
  static List<ExamSubject> get allSubjects => ExamSubject.values;

  /// Returns subject from API serialization string (case-insensitive fallback).
  static ExamSubject fromApiString(String apiString) {
    final clean = apiString.trim().toLowerCase();
    for (final subject in ExamSubject.values) {
      if (subject.apiString.toLowerCase() == clean ||
          subject.name.toLowerCase() == clean) {
        return subject;
      }
    }
    throw ArgumentError('Unsupported subject API string: "$apiString"');
  }

  /// Returns subject from display name.
  static ExamSubject fromDisplayName(String displayName) {
    final clean = displayName.trim().toLowerCase();
    for (final subject in ExamSubject.values) {
      if (subject.displayName.toLowerCase() == clean) {
        return subject;
      }
    }
    throw ArgumentError('Unsupported subject display name: "$displayName"');
  }

  /// Tries to parse [input] as API string or display name, returning null if invalid.
  static ExamSubject? tryParse(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    try {
      return fromApiString(input);
    } catch (_) {
      try {
        return fromDisplayName(input);
      } catch (_) {
        return null;
      }
    }
  }

  /// Validates if given subject string is supported.
  static bool isValidSubject(String subjectStr) {
    return tryParse(subjectStr) != null;
  }

  /// List of all subject display names.
  static List<String> get displayNames =>
      ExamSubject.values.map((s) => s.displayName).toList();

  /// List of all subject API strings.
  static List<String> get apiStrings =>
      ExamSubject.values.map((s) => s.apiString).toList();
}
