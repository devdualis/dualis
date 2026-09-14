import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/triage/domain/triage_question_bank.dart';
import 'package:dualis_mobile/features/triage/domain/triage_vertical.dart';

void main() {
  group('TriageQuestionBank', () {
    test('Vertical A (psicoEmocional) has exactly 5 clinical steps', () {
      final questions = TriageQuestionBank.psicoEmocional;
      expect(questions.length, equals(5));

      for (var i = 0; i < 5; i++) {
        expect(questions[i].stepIndex, equals(i));
      }

      // Step 0: Nature (4 options)
      expect(questions[0].options.length, equals(4));
      expect(questions[0].isPreview, isFalse);

      // Step 1: Persistence (3 options)
      expect(questions[1].options.length, equals(3));
      expect(questions[1].isPreview, isFalse);

      // Step 2: Intensity (3 options with intensity values)
      expect(questions[2].options.length, equals(3));
      expect(questions[2].options.every((o) => o.intensityValue != null), isTrue);

      // Step 3: Triggers (4 options)
      expect(questions[3].options.length, equals(4));
      expect(questions[3].isPreview, isFalse);

      // Step 4: Preview
      expect(questions[4].isPreview, isTrue);
      expect(questions[4].options, isEmpty);
    });

    test('Vertical B (fisica) has exactly 5 clinical steps', () {
      final questions = TriageQuestionBank.fisica;
      expect(questions.length, equals(5));

      for (var i = 0; i < 5; i++) {
        expect(questions[i].stepIndex, equals(i));
      }

      // Step 0: Location (4 options with system keys)
      expect(questions[0].options.length, equals(4));
      expect(questions[0].options.every((o) => o.systemKey != null), isTrue);

      // Step 1: Duration (3 options)
      expect(questions[1].options.length, equals(3));

      // Step 2: Intensity (numeric 1-5 scale)
      expect(questions[2].isNumericScale, isTrue);

      // Step 3: Triggers (3 options)
      expect(questions[3].options.length, equals(3));

      // Step 4: Preview
      expect(questions[4].isPreview, isTrue);
      expect(questions[4].options, isEmpty);
    });

    test('forVertical returns matching list for both verticals', () {
      expect(
        TriageQuestionBank.forVertical(TriageVertical.psicoEmocional),
        same(TriageQuestionBank.psicoEmocional),
      );
      expect(
        TriageQuestionBank.forVertical(TriageVertical.fisica),
        same(TriageQuestionBank.fisica),
      );
    });
  });
}
