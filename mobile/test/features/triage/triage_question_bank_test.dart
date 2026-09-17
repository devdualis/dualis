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

      expect(questions[0].options.length, equals(7));
      expect(questions[0].isPreview, isFalse);

      expect(questions[1].options.length, equals(3));
      expect(questions[1].isPreview, isFalse);

      expect(questions[2].options.length, equals(3));
      expect(questions[2].options.every((o) => o.intensityValue != null), isTrue);

      expect(questions[3].options.length, equals(4));
      expect(questions[3].isPreview, isFalse);

      expect(questions[4].isPreview, isTrue);
      expect(questions[4].options, isEmpty);
    });

    test('Vertical B (fisica) has exactly 5 clinical steps', () {
      final questions = TriageQuestionBank.fisica;
      expect(questions.length, equals(5));

      for (var i = 0; i < 5; i++) {
        expect(questions[i].stepIndex, equals(i));
      }

      expect(questions[0].options.length, equals(12));
      expect(questions[0].options.every((o) => o.systemKey != null), isTrue);

      expect(questions[1].options.length, equals(3));

      expect(questions[2].isNumericScale, isTrue);

      expect(questions[3].options.length, equals(3));

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

    test('forVertical returns specialized Step 3 question for each of the 12 physical systems', () {
      final expectedQuestions = {
        'cabeca_pescoco': 'triageQ4CabecaPescoco',
        'cardiovascular_torax': 'triageQ4CardiovascularTorax',
        'respiratorio': 'triageQ4Respiratorio',
        'gastrointestinal_abdomen': 'triageQ4Gastrointestinal',
        'coluna_dor_dorsal': 'triageQ4ColunaDorDorsal',
        'membros_superiores': 'triageQ4MembrosSuperiores',
        'membros_inferiores': 'triageQ4MembrosInferiores',
        'neurologico': 'triageQ4Neurologico',
        'geniturinario_pelvico': 'triageQ4Geniturinario',
        'dermatologico': 'triageQ4Dermatological',
        'muscular_geral_sistemico': 'triageQ4MuscularGeral',
        'endocrino_metabolico': 'triageQ4EndocrinoMetabolico',
      };

      for (final entry in expectedQuestions.entries) {
        final questions = TriageQuestionBank.forVertical(
          TriageVertical.fisica,
          systemKey: entry.key,
        );

        expect(questions.length, equals(5));
        expect(questions[3].stepIndex, equals(3));
        expect(
          questions[3].questionKey,
          equals(entry.value),
          reason: 'Failed for system ${entry.key}',
        );
        expect(questions[3].options.length, greaterThanOrEqualTo(3));
        expect(questions[3].options.every((o) => o.key.isNotEmpty), isTrue);
        expect(questions[3].options.every((o) => o.labelKey.isNotEmpty), isTrue);
      }
    });

    test('forVertical supports clinical aliases/synonyms for physical systems', () {
      expect(
        TriageQuestionBank.forVertical(TriageVertical.fisica, systemKey: 'gastrointestinal')[3].questionKey,
        equals('triageQ4Gastrointestinal'),
      );
      expect(
        TriageQuestionBank.forVertical(TriageVertical.fisica, systemKey: 'respiratory')[3].questionKey,
        equals('triageQ4Respiratorio'),
      );
      expect(
        TriageQuestionBank.forVertical(TriageVertical.fisica, systemKey: 'head_neck')[3].questionKey,
        equals('triageQ4CabecaPescoco'),
      );
      expect(
        TriageQuestionBank.forVertical(TriageVertical.fisica, systemKey: 'dermatological')[3].questionKey,
        equals('triageQ4Dermatological'),
      );
    });

    test('forVertical returns specialized Step 3 question for each of the 7 emotional dimensions', () {
      final expectedQuestions = {
        'ansiosa_agitacao': 'triageQ4Ansiedade',
        'depressiva_desanimo': 'triageQ4Depressao',
        'estresse_burnout': 'triageQ4EstresseBurnout',
        'somatica': 'triageQ4Somatica',
        'sono': 'triageQ4Sono',
        'cognitiva_foco': 'triageQ4CognitivaFoco',
        'autoestima': 'triageQ4Autoestima',
      };

      for (final entry in expectedQuestions.entries) {
        final questions = TriageQuestionBank.forVertical(
          TriageVertical.psicoEmocional,
          systemKey: entry.key,
        );

        expect(questions.length, equals(5));
        expect(questions[3].stepIndex, equals(3));
        expect(
          questions[3].questionKey,
          equals(entry.value),
          reason: 'Failed for emotional dimension ${entry.key}',
        );
        expect(questions[3].options.length, greaterThanOrEqualTo(4));
        expect(questions[3].options.every((o) => o.key.isNotEmpty), isTrue);
        expect(questions[3].options.every((o) => o.labelKey.isNotEmpty), isTrue);
      }
    });

    test('forVertical supports clinical aliases/synonyms for emotional dimensions', () {
      expect(
        TriageQuestionBank.forVertical(TriageVertical.psicoEmocional, systemKey: 'ansiedade')[3].questionKey,
        equals('triageQ4Ansiedade'),
      );
      expect(
        TriageQuestionBank.forVertical(TriageVertical.psicoEmocional, systemKey: 'anxious_agitation')[3].questionKey,
        equals('triageQ4Ansiedade'),
      );
      expect(
        TriageQuestionBank.forVertical(TriageVertical.psicoEmocional, systemKey: 'tristeza_desanimo')[3].questionKey,
        equals('triageQ4Depressao'),
      );
      expect(
        TriageQuestionBank.forVertical(TriageVertical.psicoEmocional, systemKey: 'burnout')[3].questionKey,
        equals('triageQ4EstresseBurnout'),
      );
      expect(
        TriageQuestionBank.forVertical(TriageVertical.psicoEmocional, systemKey: 'psychosomatic')[3].questionKey,
        equals('triageQ4Somatica'),
      );
      expect(
        TriageQuestionBank.forVertical(TriageVertical.psicoEmocional, systemKey: 'sono_repouso')[3].questionKey,
        equals('triageQ4Sono'),
      );
      expect(
        TriageQuestionBank.forVertical(TriageVertical.psicoEmocional, systemKey: 'foco')[3].questionKey,
        equals('triageQ4CognitivaFoco'),
      );
      expect(
        TriageQuestionBank.forVertical(TriageVertical.psicoEmocional, systemKey: 'autoimagem')[3].questionKey,
        equals('triageQ4Autoestima'),
      );
    });
  });
}
