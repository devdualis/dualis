import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../features/emergency/domain/red_flag_evaluator.dart';
import '../../../../features/emergency/presentation/widgets/safety_notice_banner.dart';
import '../../domain/triage_question_bank.dart';
import '../../domain/triage_vertical.dart';
import '../../domain/triage_wizard_state.dart';

part 'triage_wizard_notifier.g.dart';

final triageWizardNotifierProvider = triageWizardProvider;

@riverpod
class TriageWizardNotifier extends _$TriageWizardNotifier {
  @override
  TriageWizardState build() {
    ref.onDispose(SafetyNotice.hide);
    return const TriageWizardState();
  }

  void setVertical(TriageVertical vertical) {
    state = state.copyWith(activeVertical: vertical, currentStep: 0, answers: {});
  }

  /// Pre-fills the step-0 category from an AI/vector classification of the typed
  /// symptom text and jumps straight to step 1 (onset), so free text always
  /// reaches the onset/severity questions instead of requiring a manual pick.
  void presetCategoryAndSkip(String categoryKey) {
    state = state.copyWith(answers: {0: categoryKey}, currentStep: 1);
  }

  /// Saves the answer. If it is a high self-reported intensity, shows the
  /// generic, non-blocking safety notice (same text for everyone) and returns
  /// true. The entry flow is never interrupted.
  bool selectOption(BuildContext context, int stepIndex, String optionKey) {
    state = state.copyWith(answers: {...state.answers, stepIndex: optionKey});

    final notice = _safetyNoticeFor(stepIndex, optionKey);
    if (notice != null) {
      SafetyNotice.show(context, notice);
      return true;
    }
    return false;
  }

  /// Checks free text the user typed; self-harm mentions show crisis
  /// resources, warning-sign expressions show the generic notice.
  bool checkFreeText(BuildContext context, String text) {
    final notice = RedFlagEvaluator.evaluateText(text);
    if (notice != null) {
      SafetyNotice.show(context, notice);
      return true;
    }
    return false;
  }

  void updateAnswer(int stepIndex, String optionKey) {
    state = state.copyWith(answers: {...state.answers, stepIndex: optionKey});
  }

  void advance() {
    if (!state.canAdvance) return;
    final maxStep = TriageQuestionBank.forVertical(
          state.activeVertical,
          systemKey: state.answers[0],
        ).length -
        1;
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

  SafetyNoticeKind? _safetyNoticeFor(int stepIndex, String optionKey) {
    if (stepIndex != 2 && stepIndex != 3) return null;
    const emotionalIntensity = {
      'leve_controlavel': 2,
      'moderada': 3,
      'muito_forte': 4,
    };
    final intensity = int.tryParse(optionKey) ?? emotionalIntensity[optionKey];
    if (intensity == null) return null;
    return RedFlagEvaluator.evaluateIntensity(
      intensity: intensity,
      bodyAreaKey: state.activeVertical == TriageVertical.fisica ? state.answers[0] : null,
    );
  }
}
