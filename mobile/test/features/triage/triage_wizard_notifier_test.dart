import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dualis_mobile/features/emergency/domain/emergency_context.dart';
import 'package:dualis_mobile/features/emergency/domain/emergency_trigger_category.dart';
import 'package:dualis_mobile/features/emergency/presentation/controllers/emergency_controller.dart';
import 'package:dualis_mobile/features/triage/domain/triage_vertical.dart';
import 'package:dualis_mobile/features/triage/presentation/controllers/triage_wizard_notifier.dart';

class MockBuildContext extends Mock implements BuildContext {}

class FakeEmergencyContext extends Fake implements EmergencyContext {}

class TestEmergencyController extends EmergencyController {
  EmergencyContext? lastTriggered;
  int triggerCount = 0;

  @override
  void triggerEmergency(BuildContext context, EmergencyContext emergencyContext) {
    lastTriggered = emergencyContext;
    triggerCount++;
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeEmergencyContext());
    registerFallbackValue(MockBuildContext());
  });

  group('TriageWizardNotifier', () {
    late ProviderContainer container;
    late MockBuildContext mockContext;
    late TestEmergencyController testEmergencyController;

    setUp(() {
      mockContext = MockBuildContext();
      testEmergencyController = TestEmergencyController();
      container = ProviderContainer(
        overrides: [
          emergencyControllerProvider
              .overrideWith(() => testEmergencyController),
        ],
      );
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

    test('5. Step 0 selection with tristeza_desanimo does NOT trigger emergency (gate only at Step 2)', () {
      final notifier = container.read(triageWizardNotifierProvider.notifier);
      final triggered = notifier.selectOption(mockContext, 0, 'tristeza_desanimo');

      expect(triggered, isFalse);
      expect(testEmergencyController.triggerCount, equals(0));
      expect(container.read(triageWizardNotifierProvider).answers[0], equals('tristeza_desanimo'));
    });

    test('6. Step 2 selection with muito_forte (after tristeza_desanimo at Step 0) triggers emergency', () {
      final notifier = container.read(triageWizardNotifierProvider.notifier);
      notifier.selectOption(mockContext, 0, 'tristeza_desanimo');
      notifier.advance(); // to step 1
      notifier.selectOption(mockContext, 1, 'ja_faz_alguns_dias');
      notifier.advance(); // to step 2

      final triggered = notifier.selectOption(mockContext, 2, 'muito_forte');
      expect(triggered, isTrue);
      expect(testEmergencyController.triggerCount, equals(1));
      expect(testEmergencyController.lastTriggered?.category, equals(EmergencyTriggerCategory.suicidalCrisis));
      expect(testEmergencyController.lastTriggered?.severityLevel, equals(4));
    });

    test('7. Step 2 physical selection with intensity 5 (cabeca at Step 0) triggers emergency', () {
      final notifier = container.read(triageWizardNotifierProvider.notifier);
      notifier.setVertical(TriageVertical.fisica);
      notifier.selectOption(mockContext, 0, 'cabeca');
      notifier.advance(); // to step 1
      notifier.selectOption(mockContext, 1, 'ha_alguns_dias');
      notifier.advance(); // to step 2

      final triggered = notifier.selectOption(mockContext, 2, '5');
      expect(triggered, isTrue);
      expect(testEmergencyController.triggerCount, equals(1));
      expect(testEmergencyController.lastTriggered?.severityLevel, equals(5));
    });

    test('8. Step 2 physical selection with intensity 3 (costas_coluna) does NOT trigger emergency', () {
      final notifier = container.read(triageWizardNotifierProvider.notifier);
      notifier.setVertical(TriageVertical.fisica);
      notifier.selectOption(mockContext, 0, 'costas_coluna');
      notifier.advance(); // to step 1
      notifier.selectOption(mockContext, 1, 'ha_alguns_dias');
      notifier.advance(); // to step 2

      final triggered = notifier.selectOption(mockContext, 2, '3');
      expect(triggered, isFalse);
      expect(testEmergencyController.triggerCount, equals(0));
      expect(container.read(triageWizardNotifierProvider).answers[2], equals('3'));
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
