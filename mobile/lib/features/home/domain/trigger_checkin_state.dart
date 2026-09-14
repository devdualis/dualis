import 'package:flutter/foundation.dart';

/// 3-option clinical triage status for each axis of the unified trigger question.
enum TriggerStatus {
  goodNormal, // [Bem / Normal]
  soSo,       // [Mais ou menos] -> Standard triage
  badSick,    // [Mal / Ruim] -> High-sensitivity triage
}

/// Clinical routing determination based on the unified dual-axis matrix.
enum RoutingOutcome {
  none,
  wellnessConfirmation, // Both good/normal -> zero friction
  psicoEmocionalOnly,   // Emotional distress only
  fisicaOnly,           // Physical discomfort only
  dualOrganicPrimacy,   // Both distressed -> Organic Primacy (Physical evaluated first)
}

/// State of the Screen 3 Unified Trigger Check-in.
@immutable
class TriggerCheckInState {
  final TriggerStatus? emotionalStatus;
  final TriggerStatus? physicalStatus;
  final String naturalLanguageText;
  final bool isSubmitting;

  const TriggerCheckInState({
    this.emotionalStatus,
    this.physicalStatus,
    this.naturalLanguageText = '',
    this.isSubmitting = false,
  });

  bool get isReadyToSubmit => emotionalStatus != null && physicalStatus != null;

  RoutingOutcome get routingOutcome {
    if (!isReadyToSubmit) return RoutingOutcome.none;

    final emotionalOk = emotionalStatus == TriggerStatus.goodNormal;
    final physicalOk = physicalStatus == TriggerStatus.goodNormal;

    if (emotionalOk && physicalOk) {
      return RoutingOutcome.wellnessConfirmation;
    }
    if (!emotionalOk && physicalOk) {
      return RoutingOutcome.psicoEmocionalOnly;
    }
    if (emotionalOk && !physicalOk) {
      return RoutingOutcome.fisicaOnly;
    }
    // Both axes report distress: Organic Primacy enforces physical evaluation first.
    return RoutingOutcome.dualOrganicPrimacy;
  }

  TriggerCheckInState copyWith({
    TriggerStatus? emotionalStatus,
    TriggerStatus? physicalStatus,
    String? naturalLanguageText,
    bool? isSubmitting,
  }) {
    return TriggerCheckInState(
      emotionalStatus: emotionalStatus ?? this.emotionalStatus,
      physicalStatus: physicalStatus ?? this.physicalStatus,
      naturalLanguageText: naturalLanguageText ?? this.naturalLanguageText,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
