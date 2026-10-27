import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/triage/domain/symptom_classification.dart';

void main() {
  group('SymptomClassification', () {
    test('parses the tagging schema', () {
      final c = SymptomClassification.fromJson({
        'isOffTopic': false,
        'vertical': 'physical',
        'bodyAreaOrMood': 'cabeca_pescoco',
        'layTerm': 'dor de cabeça',
      });

      expect(c.vertical, 'physical');
      expect(c.bodyAreaOrMood, 'cabeca_pescoco');
      expect(c.layTerm, 'dor de cabeça');
    });

    test('ignores fields that are not tags', () {
      final c = SymptomClassification.fromJson({
        'vertical': 'emotional',
        'mentionsSelfHarm': true,
        'urgencyScore': 5,
      });

      expect(c.vertical, 'emotional');
      expect(c.isOffTopic, isFalse);
    });
  });
}
