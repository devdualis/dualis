import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/emergency/domain/emergency_context.dart';
import 'package:dualis_mobile/features/emergency/domain/emergency_trigger_category.dart';
import 'package:dualis_mobile/features/emergency/domain/red_flag_evaluator.dart';

void main() {
  group('RedFlagEvaluator - evaluateStructured', () {
    test('physical chest pain intensity 5 triggers chestPain with severity 5', () {
      final result = RedFlagEvaluator.evaluateStructured(
        systemOrDimension: 'cardiovascular_chest',
        intensity: 5,
        isEmotional: false,
      );

      expect(result, isNotNull);
      expect(result!.category, EmergencyTriggerCategory.chestPain);
      expect(result.severityLevel, 5);
      expect(result.isEmotional, isFalse);
      expect(result.primaryService, EmergencyServiceType.samu192);
    });

    test('physical dyspnea intensity 4 on respiratory triggers respiratoryDistress with severity 4', () {
      final result = RedFlagEvaluator.evaluateStructured(
        systemOrDimension: 'respiratory',
        intensity: 4,
        isEmotional: false,
      );

      expect(result, isNotNull);
      expect(result!.category, EmergencyTriggerCategory.respiratoryDistress);
      expect(result.severityLevel, 4);
      expect(result.isEmotional, isFalse);
      expect(result.primaryService, EmergencyServiceType.samu192);
    });

    test('physical neurological deficit intensity 4 triggers neurologicalStroke', () {
      final result = RedFlagEvaluator.evaluateStructured(
        systemOrDimension: 'neurological',
        intensity: 4,
        isEmotional: false,
      );

      expect(result, isNotNull);
      expect(result!.category, EmergencyTriggerCategory.neurologicalStroke);
      expect(result.severityLevel, 4);
    });

    test('physical head/neck airway compromise intensity 4 triggers anaphylaxisAirway', () {
      final result = RedFlagEvaluator.evaluateStructured(
        systemOrDimension: 'head_neck',
        intensity: 4,
        isEmotional: false,
      );

      expect(result, isNotNull);
      expect(result!.category, EmergencyTriggerCategory.anaphylaxisAirway);
      expect(result.severityLevel, 4);
    });

    test('physical level 5 on non-critical system triggers generalCriticalIntensity', () {
      final result = RedFlagEvaluator.evaluateStructured(
        systemOrDimension: 'gastrointestinal_abdomen',
        intensity: 5,
        isEmotional: false,
      );

      expect(result, isNotNull);
      expect(result!.category, EmergencyTriggerCategory.generalCriticalIntensity);
      expect(result.severityLevel, 5);
      expect(result.isEmotional, isFalse);
    });

    test('emotional depressive hopelessness intensity 4 triggers suicidalCrisis with severity 4', () {
      final result = RedFlagEvaluator.evaluateStructured(
        systemOrDimension: 'depressive_hopelessness',
        intensity: 4,
        isEmotional: true,
      );

      expect(result, isNotNull);
      expect(result!.category, EmergencyTriggerCategory.suicidalCrisis);
      expect(result.severityLevel, 4);
      expect(result.isEmotional, isTrue);
      expect(result.primaryService, EmergencyServiceType.cvv188);
    });

    test('emotional anxious agitation intensity 4 triggers anxiousPanicCollapse', () {
      final result = RedFlagEvaluator.evaluateStructured(
        systemOrDimension: 'anxious_agitation',
        intensity: 4,
        isEmotional: true,
      );

      expect(result, isNotNull);
      expect(result!.category, EmergencyTriggerCategory.anxiousPanicCollapse);
      expect(result.severityLevel, 4);
      expect(result.isEmotional, isTrue);
    });

    test('emotional stress burnout intensity 4 triggers severePsychosisDelirium', () {
      final result = RedFlagEvaluator.evaluateStructured(
        systemOrDimension: 'stress_burnout',
        intensity: 4,
        isEmotional: true,
      );

      expect(result, isNotNull);
      expect(result!.category, EmergencyTriggerCategory.severePsychosisDelirium);
      expect(result.severityLevel, 4);
      expect(result.isEmotional, isTrue);
    });

    test('emotional level 5 on general dimension triggers generalCriticalIntensity with isEmotional true', () {
      final result = RedFlagEvaluator.evaluateStructured(
        systemOrDimension: 'somatization_fatigue',
        intensity: 5,
        isEmotional: true,
      );

      expect(result, isNotNull);
      expect(result!.category, EmergencyTriggerCategory.generalCriticalIntensity);
      expect(result.severityLevel, 5);
      expect(result.isEmotional, isTrue);
      expect(result.primaryService, EmergencyServiceType.cvv188);
    });

    test('negative controls return null', () {
      // Mild knee pain (intensity 2)
      final knee = RedFlagEvaluator.evaluateStructured(
        systemOrDimension: 'musculoskeletal_limbs',
        intensity: 2,
        isEmotional: false,
      );
      expect(knee, isNull);

      // Mild stress (intensity 2)
      final stress = RedFlagEvaluator.evaluateStructured(
        systemOrDimension: 'stress_burnout',
        intensity: 2,
        isEmotional: true,
      );
      expect(stress, isNull);

      // Headache with intensity 3
      final headache = RedFlagEvaluator.evaluateStructured(
        systemOrDimension: 'head_neck',
        intensity: 3,
        isEmotional: false,
      );
      expect(headache, isNull);

      // Non-critical organ at intensity 4 (e.g. skin/dermatological)
      final skin = RedFlagEvaluator.evaluateStructured(
        systemOrDimension: 'dermatological',
        intensity: 4,
        isEmotional: false,
      );
      expect(skin, isNull);
    });
  });

  group('RedFlagEvaluator - evaluateText (Trilingual Regex)', () {
    test('stroke symptoms in Portuguese ("boca torta e dormência no braço") -> neurologicalStroke', () {
      final result = RedFlagEvaluator.evaluateText('boca torta e dormência no braço');

      expect(result, isNotNull);
      expect(result!.category, EmergencyTriggerCategory.neurologicalStroke);
      expect(result.severityLevel, 5);
      expect(result.isEmotional, isFalse);
    });

    test('stroke symptoms in Spanish ("cara torcida y dificultad para hablar") -> neurologicalStroke', () {
      final result = RedFlagEvaluator.evaluateText('cara torcida y dificultad para hablar');

      expect(result, isNotNull);
      expect(result!.category, EmergencyTriggerCategory.neurologicalStroke);
      expect(result.severityLevel, 5);
      expect(result.isEmotional, isFalse);
    });

    test('stroke symptoms in English ("facial droop and slurred speech") -> neurologicalStroke', () {
      final result = RedFlagEvaluator.evaluateText('facial droop and slurred speech');

      expect(result, isNotNull);
      expect(result!.category, EmergencyTriggerCategory.neurologicalStroke);
      expect(result.severityLevel, 5);
      expect(result.isEmotional, isFalse);
    });

    test('suicidal ideation in Portuguese ("quero me matar") -> suicidalCrisis', () {
      final result = RedFlagEvaluator.evaluateText('quero me matar');

      expect(result, isNotNull);
      expect(result!.category, EmergencyTriggerCategory.suicidalCrisis);
      expect(result.severityLevel, 5);
      expect(result.isEmotional, isTrue);
      expect(result.primaryService, EmergencyServiceType.cvv188);
    });

    test('suicidal ideation in Spanish ("quiero quitarme la vida") -> suicidalCrisis', () {
      final result = RedFlagEvaluator.evaluateText('quiero quitarme la vida');

      expect(result, isNotNull);
      expect(result!.category, EmergencyTriggerCategory.suicidalCrisis);
      expect(result.severityLevel, 5);
      expect(result.isEmotional, isTrue);
      expect(result.primaryService, EmergencyServiceType.cvv188);
    });

    test('suicidal ideation in English ("want to end my life") -> suicidalCrisis', () {
      final result = RedFlagEvaluator.evaluateText('want to end my life');

      expect(result, isNotNull);
      expect(result!.category, EmergencyTriggerCategory.suicidalCrisis);
      expect(result.severityLevel, 5);
      expect(result.isEmotional, isTrue);
      expect(result.primaryService, EmergencyServiceType.cvv188);
    });

    test('thunderclap headache ("pior dor de cabeça da minha vida") -> thunderclapHeadache', () {
      final result = RedFlagEvaluator.evaluateText('pior dor de cabeça da minha vida');

      expect(result, isNotNull);
      expect(result!.category, EmergencyTriggerCategory.thunderclapHeadache);
      expect(result.severityLevel, 5);
      expect(result.isEmotional, isFalse);
    });

    test('crushing chest pain ("crushing chest pain") -> chestPain', () {
      final result = RedFlagEvaluator.evaluateText('I have crushing chest pain and cold sweat');

      expect(result, isNotNull);
      expect(result!.category, EmergencyTriggerCategory.chestPain);
      expect(result.severityLevel, 5);
      expect(result.isEmotional, isFalse);
    });

    test('airway obstruction ("não consigo respirar") -> anaphylaxisAirway', () {
      final result = RedFlagEvaluator.evaluateText('socorro não consigo respirar');

      expect(result, isNotNull);
      expect(result!.category, EmergencyTriggerCategory.anaphylaxisAirway);
      expect(result.severityLevel, 5);
      expect(result.isEmotional, isFalse);
    });

    test('negative text controls return null', () {
      expect(RedFlagEvaluator.evaluateText('dor leve no joelho direito'), isNull);
      expect(RedFlagEvaluator.evaluateText('cansaco apos dia de trabalho'), isNull);
      expect(RedFlagEvaluator.evaluateText('headache after reading book'), isNull);
      expect(RedFlagEvaluator.evaluateText(''), isNull);
      expect(RedFlagEvaluator.evaluateText('   '), isNull);
    });

    test('performance invariant: evaluation completes in under 1ms', () {
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 500; i++) {
        RedFlagEvaluator.evaluateText('boca torta e dormência no braço');
        RedFlagEvaluator.evaluateStructured(
          systemOrDimension: 'cardiovascular_chest',
          intensity: 5,
          isEmotional: false,
        );
      }
      stopwatch.stop();

      // Average duration per evaluation should be well under 1000 microseconds (1 millisecond)
      final avgMicroseconds = stopwatch.elapsedMicroseconds / 1000;
      expect(avgMicroseconds, lessThan(1000));
    });
  });
}
