import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/triage/domain/symptom_classification.dart';

void main() {
  group('SymptomClassification', () {
    test('parses wellness tagging schema', () {
      final c = SymptomClassification.fromJson({
        'isOffTopic': false,
        'vertical': 'physical',
        'bodyAreaOrMood': 'cabeca_pescoco',
        'layTerm': 'dor de cabeça',
        'mentionsSelfHarm': false,
      });

      expect(c.vertical, 'physical');
      expect(c.layTerm, 'dor de cabeça');
      expect(c.wizardCategoryKey, 'cabeca_pescoco');
    });

    test('tolerates legacy triage schema', () {
      final c = SymptomClassification.fromJson({
        'primaryVertical': 'physical',
        'systemOrDimension': 'head_neck',
        'mappedLayTerm': 'cefaleia',
        'urgencyScore': 5,
        'clinicalConcept': 'ignored',
        'isEmergencyCandidate': true,
      });

      expect(c.systemOrDimension, 'head_neck');
      expect(c.wizardCategoryKey, 'cabeca_pescoco');
    });
  });
}
