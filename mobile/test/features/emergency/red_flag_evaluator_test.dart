import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/emergency/domain/red_flag_evaluator.dart';

void main() {
  group('RedFlagEvaluator.evaluateText', () {
    test('self-harm mentions show crisis resources (pt, es, en)', () {
      for (final text in [
        'não aguento mais, quero morrer',
        'penso em tirar a minha vida',
        'quiero quitarme la vida',
        'I want to end my life',
      ]) {
        expect(RedFlagEvaluator.evaluateText(text), SafetyNoticeKind.selfHarm, reason: text);
      }
    });

    test('warning-sign expressions show the same generic notice', () {
      for (final text in [
        'estou com dor forte no peito',
        'acordei com a boca torta',
        'não consigo respirar direito',
        'a pior dor de cabeça da minha vida',
        'dolor en el pecho desde ayer',
        'slurred speech since this morning',
      ]) {
        expect(RedFlagEvaluator.evaluateText(text), SafetyNoticeKind.general, reason: text);
      }
    });

    test('ordinary journal text shows nothing', () {
      expect(RedFlagEvaluator.evaluateText(''), isNull);
      expect(RedFlagEvaluator.evaluateText('dormi mal e estou cansado'), isNull);
      expect(RedFlagEvaluator.evaluateText('leve dor nas costas'), isNull);
    });
  });

  group('RedFlagEvaluator.evaluateIntensity', () {
    test('intensity 5 shows the generic notice for any area or mood', () {
      expect(RedFlagEvaluator.evaluateIntensity(intensity: 5, bodyAreaKey: 'costas_coluna'),
          SafetyNoticeKind.general);
      expect(RedFlagEvaluator.evaluateIntensity(intensity: 5), SafetyNoticeKind.general);
    });

    test('intensity 4 only on chest, breathing or head', () {
      for (final area in ['cardiovascular_torax', 'respiratorio', 'cabeca', 'cabeca_pescoco', 'neurologico']) {
        expect(RedFlagEvaluator.evaluateIntensity(intensity: 4, bodyAreaKey: area),
            SafetyNoticeKind.general, reason: area);
      }
      expect(RedFlagEvaluator.evaluateIntensity(intensity: 4, bodyAreaKey: 'costas_coluna'), isNull);
      expect(RedFlagEvaluator.evaluateIntensity(intensity: 4), isNull);
    });

    test('intensity below 4 shows nothing', () {
      for (var i = 1; i <= 3; i++) {
        expect(RedFlagEvaluator.evaluateIntensity(intensity: i, bodyAreaKey: 'cardiovascular_torax'), isNull);
      }
    });
  });
}
