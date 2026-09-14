import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../features/emergency/domain/emergency_context.dart';
import '../../../../features/emergency/domain/red_flag_evaluator.dart';
import '../../../../features/emergency/presentation/controllers/emergency_controller.dart';
import '../../domain/triage_question_bank.dart';
import '../../domain/triage_vertical.dart';
import '../../domain/triage_wizard_state.dart';

part 'triage_wizard_notifier.g.dart';

final triageWizardNotifierProvider = triageWizardProvider;

@riverpod
class TriageWizardNotifier extends _$TriageWizardNotifier {
  @override
  TriageWizardState build() => const TriageWizardState();

  void setVertical(TriageVertical vertical) {
    state = state.copyWith(activeVertical: vertical, currentStep: 0, answers: {});
  }

  bool selectOption(BuildContext context, int stepIndex, String optionKey) {
    final emergency = _evaluateGate(stepIndex, optionKey);
    if (emergency != null) {
      ref
          .read(emergencyControllerProvider.notifier)
          .triggerEmergency(context, emergency);
      return true;
    }
    state = state.copyWith(answers: {...state.answers, stepIndex: optionKey});
    return false;
  }

  void updateAnswer(int stepIndex, String optionKey) {
    state = state.copyWith(answers: {...state.answers, stepIndex: optionKey});
  }

  void advance() {
    if (!state.canAdvance) return;
    final maxStep = TriageQuestionBank.forVertical(state.activeVertical).length - 1;
    if (state.currentStep < maxStep) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    } else {
      state = state.copyWith(isCompleting: true);
    }
  }

  void goBack() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void reset() {
    state = const TriageWizardState();
  }

  EmergencyContext? _evaluateGate(int stepIndex, String optionKey) {
    final vertical = state.activeVertical;

    if (vertical == TriageVertical.psicoEmocional) {
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
      'depressiva_desanimo': 'depressive_hopelessness',
      'ansiedade_agitacao': 'anxious_agitation',
      'ansiosa_agitacao': 'anxious_agitation',
      'estresse_irritabilidade': 'stress_burnout',
      'estresse_burnout': 'stress_burnout',
      'somatica': 'somatica',
      'sono': 'sono',
      'cognitiva_foco': 'cognitiva_foco',
      'autoestima': 'autoestima',
    };
    return map[step0Answer] ?? 'emotional_general';
  }

  String _physicalSystemFromStep0() {
    final step0Answer = state.answers[0] ?? '';
    const map = {
      'cabeca': 'head_neck',
      'cabeca_pescoco': 'head_neck',
      'costas_coluna': 'musculoskeletal_back',
      'coluna_dor_dorsal': 'musculoskeletal_back',
      'articulacoes': 'musculoskeletal_joints',
      'membros_superiores': 'musculoskeletal_joints',
      'membros_inferiores': 'musculoskeletal_joints',
      'abdomen_estomago': 'gastrointestinal',
      'gastrointestinal_abdomen': 'gastrointestinal',
      'cardiovascular_torax': 'cardiovascular_chest',
      'respiratorio': 'respiratory',
      'neurologico': 'neurological',
      'geniturinario_pelvico': 'general_somatic',
      'dermatologico': 'general_somatic',
      'muscular_geral_sistemico': 'general_somatic',
      'endocrino_metabolico': 'general_somatic',
    };
    return map[step0Answer] ?? 'general_somatic';
  }
}
