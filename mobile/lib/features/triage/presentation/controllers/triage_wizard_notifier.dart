import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../features/emergency/domain/emergency_context.dart';
import '../../../../features/emergency/domain/red_flag_evaluator.dart';
import '../../../../features/emergency/presentation/controllers/emergency_controller.dart';
import '../../domain/triage_question_bank.dart';
import '../../domain/triage_vertical.dart';
import '../../domain/triage_wizard_state.dart';

part 'triage_wizard_notifier.g.dart';

/// Alias matching plan naming conventions
final triageWizardNotifierProvider = triageWizardProvider;

@riverpod
class TriageWizardNotifier extends _$TriageWizardNotifier {
  @override
  TriageWizardState build() => const TriageWizardState();

  void setVertical(TriageVertical vertical) {
    state = state.copyWith(activeVertical: vertical, currentStep: 0, answers: {});
  }

  /// Selects an option for [stepIndex]. Runs deterministic emergency gate before saving.
  /// Returns true if emergency was triggered (caller should not advance wizard).
  bool selectOption(BuildContext context, int stepIndex, String optionKey) {
    final emergency = _evaluateGate(stepIndex, optionKey);
    if (emergency != null) {
      ref
          .read(emergencyControllerProvider.notifier)
          .triggerEmergency(context, emergency);
      return true; // emergency triggered
    }
    state = state.copyWith(answers: {...state.answers, stepIndex: optionKey});
    return false;
  }

  /// Updates an answer directly without running emergency evaluation (e.g. Antiburla reconciliation).
  void updateAnswer(int stepIndex, String optionKey) {
    state = state.copyWith(answers: {...state.answers, stepIndex: optionKey});
  }

  /// Advances to the next step. Blocked if current step is unanswered.
  void advance() {
    if (!state.canAdvance) return;
    final maxStep = TriageQuestionBank.forVertical(state.activeVertical).length - 1;
    if (state.currentStep < maxStep) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    } else {
      state = state.copyWith(isCompleting: true);
    }
  }

  /// Goes back to the previous step.
  void goBack() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// Resets all wizard state (used on completion or explicit cancel).
  void reset() {
    state = const TriageWizardState();
  }

  // ── Private emergency gate ──────────────────────────────────────────────
  //
  // DESIGN NOTE (W1 fix): The gate fires ONLY at Step 2 (Intensity), not at
  // Step 0 (Nature). EMRG-01 requires "high intensity ASSOCIATED WITH critical
  // red-flag areas" — nature selection alone lacks intensity context.
  // _emotionalDimensionFromStep0() carries the nature dimension into Step 2.

  EmergencyContext? _evaluateGate(int stepIndex, String optionKey) {
    final vertical = state.activeVertical;

    if (vertical == TriageVertical.psicoEmocional) {
      // Step 2 (Intensity): map verbal intensity to numeric + use nature from Step 0
      if (stepIndex == 2) {
        final intensityMap = {
          'leve_controlavel': 2,
          'moderada': 3,
          'muito_forte': 4,
        };
        final intensity = intensityMap[optionKey] ?? 2;
        final dim = _emotionalDimensionFromStep0();
        return RedFlagEvaluator.evaluateStructured(
          systemOrDimension: dim,
          intensity: intensity,
          isEmotional: true,
          selectedSymptom: optionKey,
        );
      }
    } else {
      // Vertical B Physical — Step 2 (Intensity): direct numeric 1–5
      if (stepIndex == 2) {
        final intensity = int.tryParse(optionKey) ?? 1;
        final sys = _physicalSystemFromStep0();
        return RedFlagEvaluator.evaluateStructured(
          systemOrDimension: sys,
          intensity: intensity,
          isEmotional: false,
          selectedSymptom: optionKey,
        );
      }
    }
    return null;
  }

  String _emotionalDimensionFromStep0() {
    final step0Answer = state.answers[0] ?? '';
    const map = {
      'tristeza_desanimo': 'depressive_hopelessness',
      'ansiedade_agitacao': 'anxious_agitation',
      'estresse_irritabilidade': 'stress_burnout',
    };
    return map[step0Answer] ?? 'emotional_general';
  }

  String _physicalSystemFromStep0() {
    final step0Answer = state.answers[0] ?? '';
    const map = {
      'cabeca': 'head_neck',
      'costas_coluna': 'musculoskeletal_back',
      'articulacoes': 'musculoskeletal_joints',
      'abdomen_estomago': 'gastrointestinal',
    };
    return map[step0Answer] ?? 'general_somatic';
  }
}
