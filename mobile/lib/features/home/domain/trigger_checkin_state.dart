import 'package:flutter/foundation.dart';

enum TriggerStatus {
  goodNormal,
  soSo,
  badSick,
}

enum RoutingOutcome {
  none,
  wellnessConfirmation,
  psicoEmocionalOnly,
  fisicaOnly,
  dualOrganicPrimacy,
}

@immutable
class TriggerCheckInState {
  final TriggerStatus? emotionalStatus;
  final TriggerStatus? physicalStatus;
  final String naturalLanguageText;
  final bool isSubmitting;
  final bool isCompletedToday;
  final DateTime? completedAt;
  final String? checkInDate;
  final bool isModifiedAfterCompletion;
  final bool emotionalTouched;
  final bool physicalTouched;
  final bool textTouched;

  const TriggerCheckInState({
    this.emotionalStatus,
    this.physicalStatus,
    this.naturalLanguageText = '',
    this.isSubmitting = false,
    this.isCompletedToday = false,
    this.completedAt,
    this.checkInDate,
    this.isModifiedAfterCompletion = false,
    this.emotionalTouched = false,
    this.physicalTouched = false,
    this.textTouched = false,
  });

  bool get isReadyToSubmit => emotionalStatus != null && physicalStatus != null;

  /// When editing an already-completed check-in, only the axis the user
  /// actually touched this session should drive routing — the other axis's
  /// carried-over value must not pull it into a combined/dual outcome.
  RoutingOutcome get routingOutcome {
    if (!isReadyToSubmit) return RoutingOutcome.none;

    final emotionalOk = emotionalStatus == TriggerStatus.goodNormal;
    final physicalOk = physicalStatus == TriggerStatus.goodNormal;

    if (emotionalOk && physicalOk) {
      return RoutingOutcome.wellnessConfirmation;
    }

    if (isCompletedToday && emotionalTouched != physicalTouched) {
      final touchedEmotional = emotionalTouched;
      final touchedStatus = touchedEmotional ? emotionalStatus : physicalStatus;
      if (touchedStatus == TriggerStatus.goodNormal) {
        return RoutingOutcome.none;
      }
      return touchedEmotional
          ? RoutingOutcome.psicoEmocionalOnly
          : RoutingOutcome.fisicaOnly;
    }

    if (!emotionalOk && physicalOk) {
      return RoutingOutcome.psicoEmocionalOnly;
    }
    if (emotionalOk && !physicalOk) {
      return RoutingOutcome.fisicaOnly;
    }
    return RoutingOutcome.dualOrganicPrimacy;
  }

  TriggerCheckInState copyWith({
    TriggerStatus? emotionalStatus,
    TriggerStatus? physicalStatus,
    String? naturalLanguageText,
    bool? isSubmitting,
    bool? isCompletedToday,
    DateTime? completedAt,
    String? checkInDate,
    bool? isModifiedAfterCompletion,
    bool? emotionalTouched,
    bool? physicalTouched,
    bool? textTouched,
  }) {
    return TriggerCheckInState(
      emotionalStatus: emotionalStatus ?? this.emotionalStatus,
      physicalStatus: physicalStatus ?? this.physicalStatus,
      naturalLanguageText: naturalLanguageText ?? this.naturalLanguageText,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
      completedAt: completedAt ?? this.completedAt,
      checkInDate: checkInDate ?? this.checkInDate,
      isModifiedAfterCompletion:
          isModifiedAfterCompletion ?? this.isModifiedAfterCompletion,
      emotionalTouched: emotionalTouched ?? this.emotionalTouched,
      physicalTouched: physicalTouched ?? this.physicalTouched,
      textTouched: textTouched ?? this.textTouched,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emotionalStatus': emotionalStatus?.name,
      'physicalStatus': physicalStatus?.name,
      'naturalLanguageText': naturalLanguageText,
      'isCompletedToday': isCompletedToday,
      'completedAt': completedAt?.toIso8601String(),
      'checkInDate': checkInDate,
      'isModifiedAfterCompletion': isModifiedAfterCompletion,
      'emotionalTouched': emotionalTouched,
      'physicalTouched': physicalTouched,
      'textTouched': textTouched,
    };
  }

  factory TriggerCheckInState.fromJson(Map<String, dynamic> json) {
    TriggerStatus? parseStatus(dynamic value) {
      if (value == null) return null;
      final str = value.toString();
      for (final s in TriggerStatus.values) {
        if (s.name == str) return s;
      }
      return null;
    }

    return TriggerCheckInState(
      emotionalStatus: parseStatus(json['emotionalStatus']),
      physicalStatus: parseStatus(json['physicalStatus']),
      naturalLanguageText: (json['naturalLanguageText'] as String?) ?? '',
      isSubmitting: false,
      isCompletedToday: (json['isCompletedToday'] as bool?) ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      checkInDate: json['checkInDate'] as String?,
      isModifiedAfterCompletion:
          (json['isModifiedAfterCompletion'] as bool?) ?? false,
      emotionalTouched: (json['emotionalTouched'] as bool?) ?? false,
      physicalTouched: (json['physicalTouched'] as bool?) ?? false,
      textTouched: (json['textTouched'] as bool?) ?? false,
    );
  }
}
