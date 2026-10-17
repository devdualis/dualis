import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dualis_mobile/features/triage/domain/triage_vertical.dart';
import 'package:dualis_mobile/features/triage/presentation/controllers/triage_wizard_notifier.dart';

class MockBuildContext extends Mock implements BuildContext {}

void main() {
  setUpAll(() {
    registerFallbackValue(MockBuildContext());
  });

  group('TriageWizardNotifier', () {
    late ProviderContainer container;
    late MockBuildContext mockContext;

    setUp(() {
      mockContext = MockBuildContext();
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('1. Initial state is step 0, psicoEmocional vertical, empty answers', () {
      final state = container.read(triageWizardNotifierProvider);
      expect(state.currentStep, equals(0));
      expect(state.activeVertical, equals(TriageVertical.psicoEmocional));
      expect(state.answers, isEmpty);
      expect(state.canAdvance, isFalse);
      expect(state.isCompleting, isFalse);
    });

    test('2. advance() is blocked when current step is unanswered', () {
      final notifier = container.read(triageWizardNotifierProvider.notifier);
      notifier.advance();

      final state = container.read(triageWizardNotifierProvider);
      expect(state.currentStep, equals(0));
    });

    test('3. After selecting option, advance() increments step to 1', () {
      final notifier = container.read(triageWizardNotifierProvider.notifier);
      final triggered = notifier.selectOption(mockContext, 0, 'cansaco_mental');

      expect(triggered, isFalse);
      expect(container.read(triageWizardNotifierProvider).canAdvance, isTrue);

      notifier.advance();
      expect(container.read(triageWizardNotifierProvider).currentStep, equals(1));
    });

    test('4. goBack() returns to previous step preserving answers', () {
      final notifier = container.read(triageWizardNotifierProvider.notifier);
      notifier.selectOption(mockContext, 0, 'cansaco_mental');
      notifier.advance();

      expect(container.read(triageWizardNotifierProvider).currentStep, equals(1));

      notifier.goBack();
      final state = container.read(triageWizardNotifierProvider);
      expect(state.currentStep, equals(0));
      expect(state.answers[0], equals('cansaco_mental'));
    });

    test('5. Step 0 selection with tristeza_desanimo shows no safety notice (only intensity steps can)', () {
      final notifier = container.read(triageWizardNotifierProvider.notifier);
      final triggered = notifier.selectOption(mockContext, 0, 'tristeza_desanimo');

      expect(triggered, isFalse);
      expect(container.read(triageWizardNotifierProvider).answers[0], equals('tristeza_desanimo'));
    });

    test('6. Emotional muito_forte (self-reported 4) saves the answer without a notice; crisis text is handled by checkFreeText', () {
      final notifier = container.read(triageWizardNotifierProvider.notifier);
      notifier.selectOption(mockContext, 0, 'tristeza_desanimo');
      notifier.advance(); // to step 1
      notifier.selectOption(mockContext, 1, 'ja_faz_alguns_dias');
      notifier.advance(); // to step 2

      final triggered = notifier.selectOption(mockContext, 2, 'muito_forte');
      expect(triggered, isFalse);
      final state = container.read(triageWizardNotifierProvider);
      expect(state.answers[2], equals('muito_forte'));
      expect(state.currentStep, equals(2), reason: 'the notice never interrupts the entry flow');
      expect(state.canAdvance, isTrue);
    });

    test('7. Step 2 physical selection with intensity 5 shows the generic safety notice and keeps the answer', () {
      final notifier = container.read(triageWizardNotifierProvider.notifier);
      notifier.setVertical(TriageVertical.fisica);
      notifier.selectOption(mockContext, 0, 'cabeca');
      notifier.advance(); // to step 1
      notifier.selectOption(mockContext, 1, 'ha_alguns_dias');
      notifier.advance(); // to step 2

      final triggered = notifier.selectOption(mockContext, 2, '5');
      expect(triggered, isTrue);
      final state = container.read(triageWizardNotifierProvider);
      expect(state.answers[2], equals('5'));
      expect(state.currentStep, equals(2), reason: 'the notice never interrupts the entry flow');
      expect(state.canAdvance, isTrue);
    });

    test('8. Step 2 physical selection with intensity 3 (costas_coluna) shows no safety notice', () {
      final notifier = container.read(triageWizardNotifierProvider.notifier);
      notifier.setVertical(TriageVertical.fisica);
      notifier.selectOption(mockContext, 0, 'costas_coluna');
      notifier.advance(); // to step 1
      notifier.selectOption(mockContext, 1, 'ha_alguns_dias');
      notifier.advance(); // to step 2

      final triggered = notifier.selectOption(mockContext, 2, '3');
      expect(triggered, isFalse);
      expect(container.read(triageWizardNotifierProvider).answers[2], equals('3'));
    });

    test('8b. Step 2 physical intensity 4 shows the notice only for chest, breathing or head', () {
      final notifier = container.read(triageWizardNotifierProvider.notifier);
      notifier.setVertical(TriageVertical.fisica);
      notifier.selectOption(mockContext, 0, 'costas_coluna');
      expect(notifier.selectOption(mockContext, 2, '4'), isFalse);

      notifier.setVertical(TriageVertical.fisica);
      notifier.selectOption(mockContext, 0, 'cabeca');
      expect(notifier.selectOption(mockContext, 2, '4'), isTrue);
    });

    test('8c. checkFreeText flags self-harm and warning-sign text, ignores neutral text', () {
      final notifier = container.read(triageWizardNotifierProvider.notifier);
      expect(notifier.checkFreeText(mockContext, 'hoje eu quero morrer'), isTrue);
      expect(notifier.checkFreeText(mockContext, 'dor forte no peito'), isTrue);
      expect(notifier.checkFreeText(mockContext, 'dormi pouco e estou cansado'), isFalse);
      expect(notifier.checkFreeText(mockContext, '   '), isFalse);
    });

    test('9. AutoDispose semantics: fresh container starts with clean initial state', () {
      final freshContainer = ProviderContainer();
      final state = freshContainer.read(triageWizardNotifierProvider);
      expect(state.currentStep, equals(0));
      expect(state.answers, isEmpty);
      freshContainer.dispose();
    });
  });
}
