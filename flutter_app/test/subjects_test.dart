import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/constants/subjects.dart';

void main() {
  group('ExamSubject & SubjectUtils Tests', () {
    test('Should support exactly mandatory 5 subjects', () {
      final subjects = SubjectUtils.allSubjects;
      expect(subjects.length, equals(5));
      expect(subjects, containsAll([
        ExamSubject.physics,
        ExamSubject.chemistry,
        ExamSubject.mathematics,
        ExamSubject.biology,
        ExamSubject.computerScience,
      ]));
    });

    test('Should correctly return display names for all subjects', () {
      expect(ExamSubject.physics.displayName, equals('Physics'));
      expect(ExamSubject.chemistry.displayName, equals('Chemistry'));
      expect(ExamSubject.mathematics.displayName, equals('Mathematics'));
      expect(ExamSubject.biology.displayName, equals('Biology'));
      expect(ExamSubject.computerScience.displayName, equals('Computer Science'));
    });

    test('Should correctly return API serialization strings', () {
      expect(ExamSubject.physics.apiString, equals('Physics'));
      expect(ExamSubject.chemistry.apiString, equals('Chemistry'));
      expect(ExamSubject.mathematics.apiString, equals('Mathematics'));
      expect(ExamSubject.biology.apiString, equals('Biology'));
      expect(ExamSubject.computerScience.apiString, equals('Computer Science'));
    });

    test('Should correctly parse subject from API string (case insensitive)', () {
      expect(SubjectUtils.fromApiString('Physics'), equals(ExamSubject.physics));
      expect(SubjectUtils.fromApiString('chemistry'), equals(ExamSubject.chemistry));
      expect(SubjectUtils.fromApiString('Mathematics'), equals(ExamSubject.mathematics));
      expect(SubjectUtils.fromApiString('biology'), equals(ExamSubject.biology));
      expect(SubjectUtils.fromApiString('Computer Science'), equals(ExamSubject.computerScience));
    });

    test('Should throw ArgumentError for unsupported subject string', () {
      expect(() => SubjectUtils.fromApiString('History'), throwsArgumentError);
      expect(() => SubjectUtils.fromApiString('English'), throwsArgumentError);
    });

    test('Should validate subjects correctly using isValidSubject', () {
      expect(SubjectUtils.isValidSubject('Physics'), isTrue);
      expect(SubjectUtils.isValidSubject('Chemistry'), isTrue);
      expect(SubjectUtils.isValidSubject('Mathematics'), isTrue);
      expect(SubjectUtils.isValidSubject('Biology'), isTrue);
      expect(SubjectUtils.isValidSubject('Computer Science'), isTrue);
      expect(SubjectUtils.isValidSubject('InvalidSubject'), isFalse);
    });

    test('Should provide valid non-null colors, darkColors, icons, and descriptions', () {
      for (final subject in SubjectUtils.allSubjects) {
        expect(subject.color, isNotNull);
        expect(subject.darkColor, isNotNull);
        expect(subject.icon, isNotNull);
        expect(subject.description, isNotEmpty);
      }
    });

    test('Should list all display names and API strings', () {
      final names = SubjectUtils.displayNames;
      final apiStrings = SubjectUtils.apiStrings;

      expect(names.length, equals(5));
      expect(apiStrings.length, equals(5));
      expect(names, contains('Biology'));
      expect(names, contains('Computer Science'));
    });
  });
}
