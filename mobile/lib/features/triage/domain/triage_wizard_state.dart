import 'package:freezed_annotation/freezed_annotation.dart';
import 'triage_question_bank.dart';
import 'triage_vertical.dart';

part 'triage_wizard_state.freezed.dart';

@freezed
abstract class TriageWizardState with _$TriageWizardState {
  const factory TriageWizardState({
    @Default(TriageVertical.psicoEmocional) TriageVertical activeVertical,
    @Default(0) int currentStep,
    // stepIndex -> selectedOptionKey (or numeric string '1'..'5' for intensity step)
    @Default(<int, String>{}) Map<int, String> answers,
    @Default(false) bool isCompleting,
  }) = _TriageWizardState;

  const TriageWizardState._();

  /// Whether the current step has been answered and wizard can advance.
  bool get canAdvance {
    final questions = TriageQuestionBank.forVertical(activeVertical);
    if (currentStep >= questions.length) return true;
    final q = questions[currentStep];
    if (q.isPreview) return true;
    return answers.containsKey(currentStep);
  }
}
