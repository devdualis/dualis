import 'package:flutter/foundation.dart';
import '../../../../core/clinical/clinical_intensity_tier.dart';

export '../../../../core/clinical/clinical_intensity_tier.dart';

enum TriggerStatus {
  goodNormal,
  soSo,
  badSick,
}

extension TriggerStatusTierExtension on TriggerStatus {
  int get defaultIntensity {
    switch (this) {
      case TriggerStatus.goodNormal:
        return 0;
      case TriggerStatus.soSo:
        return 3;
      case TriggerStatus.badSick:
        return 4;
    }
  }

  ClinicalIntensityTier get tier {
    switch (this) {
      case TriggerStatus.goodNormal:
        return ClinicalIntensityTier.none;
      case TriggerStatus.soSo:
        return ClinicalIntensityTier.moderate;
      case TriggerStatus.badSick:
        return ClinicalIntensityTier.intense;
    }
  }
}

const Object _unset = Object();

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
  final int? emotionalIntensity;
  final int? physicalIntensity;
  final String naturalLanguageText;
  final bool isSubmitting;
  final bool isCompletedToday;
  final bool isEmotionalCompleted;
  final bool isPhysicalCompleted;
  final String? emotionalSummary;
  final String? physicalSummary;
  final String? emotionalNarrative;
  final String? physicalNarrative;
  final DateTime? completedAt;
  final String? checkInDate;
  final bool isModifiedAfterCompletion;
  final bool emotionalTouched;
  final bool physicalTouched;
  final bool textTouched;

  const TriggerCheckInState({
    this.emotionalStatus,
    this.physicalStatus,
    this.emotionalIntensity,
    this.physicalIntensity,
    this.naturalLanguageText = '',
    this.isSubmitting = false,
    this.isCompletedToday = false,
    this.isEmotionalCompleted = false,
    this.isPhysicalCompleted = false,
    this.emotionalSummary,
    this.physicalSummary,
    this.emotionalNarrative,
    this.physicalNarrative,
    this.completedAt,
    this.checkInDate,
    this.isModifiedAfterCompletion = false,
    this.emotionalTouched = false,
    this.physicalTouched = false,
    this.textTouched = false,
  });

  bool get isReadyToSubmit => emotionalStatus != null && physicalStatus != null;

  /// Resolved Single-Source-of-Truth clinical tier for the emotional axis.
  ClinicalIntensityTier get resolvedEmotionalTier =>
      ClinicalIntensityTier.fromScore(emotionalIntensity ?? emotionalStatus?.defaultIntensity);

  /// Resolved Single-Source-of-Truth clinical tier for the physical axis.
  ClinicalIntensityTier get resolvedPhysicalTier =>
      ClinicalIntensityTier.fromScore(physicalIntensity ?? physicalStatus?.defaultIntensity);

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

  /// [emotionalNarrative] and [physicalNarrative] take an explicit `null` to
  /// clear a stage's description; omit them to keep the current value.
  TriggerCheckInState copyWith({
    TriggerStatus? emotionalStatus,
    TriggerStatus? physicalStatus,
    int? emotionalIntensity,
    int? physicalIntensity,
    String? naturalLanguageText,
    bool? isSubmitting,
    bool? isCompletedToday,
    bool? isEmotionalCompleted,
    bool? isPhysicalCompleted,
    String? emotionalSummary,
    String? physicalSummary,
    Object? emotionalNarrative = _unset,
    Object? physicalNarrative = _unset,
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
      emotionalIntensity: emotionalIntensity ?? this.emotionalIntensity,
      physicalIntensity: physicalIntensity ?? this.physicalIntensity,
      naturalLanguageText: naturalLanguageText ?? this.naturalLanguageText,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
      isEmotionalCompleted: isEmotionalCompleted ?? this.isEmotionalCompleted,
      isPhysicalCompleted: isPhysicalCompleted ?? this.isPhysicalCompleted,
      emotionalSummary: emotionalSummary ?? this.emotionalSummary,
      physicalSummary: physicalSummary ?? this.physicalSummary,
      emotionalNarrative: identical(emotionalNarrative, _unset)
          ? this.emotionalNarrative
          : emotionalNarrative as String?,
      physicalNarrative: identical(physicalNarrative, _unset)
          ? this.physicalNarrative
          : physicalNarrative as String?,
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
      'emotionalIntensity': emotionalIntensity,
      'physicalIntensity': physicalIntensity,
      'naturalLanguageText': naturalLanguageText,
      'isCompletedToday': isCompletedToday,
      'isEmotionalCompleted': isEmotionalCompleted,
      'isPhysicalCompleted': isPhysicalCompleted,
      'emotionalSummary': emotionalSummary,
      'physicalSummary': physicalSummary,
      'emotionalNarrative': emotionalNarrative,
      'physicalNarrative': physicalNarrative,
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

    final isCompleted = (json['isCompletedToday'] as bool?) ?? false;
    final isEmotCompleted = (json['isEmotionalCompleted'] as bool?) ?? isCompleted;
    final isPhysCompleted = (json['isPhysicalCompleted'] as bool?) ?? isCompleted;

    String? cleanNarrative(dynamic value) {
      if (value is! String) return null;
      final trimmed = value.trim();
      if (trimmed.isEmpty || int.tryParse(trimmed) != null) return null;
      return trimmed;
    }

    final rawText = (json['naturalLanguageText'] as String?) ?? '';
    final sanitizedText = int.tryParse(rawText.trim()) != null ? '' : rawText;

    return TriggerCheckInState(
      emotionalStatus: parseStatus(json['emotionalStatus']),
      physicalStatus: parseStatus(json['physicalStatus']),
      emotionalIntensity: (json['emotionalIntensity'] as num?)?.toInt(),
      physicalIntensity: (json['physicalIntensity'] as num?)?.toInt(),
      naturalLanguageText: sanitizedText,
      isSubmitting: false,
      isCompletedToday: isCompleted || (isEmotCompleted || isPhysCompleted),
      isEmotionalCompleted: isEmotCompleted,
      isPhysicalCompleted: isPhysCompleted,
      emotionalSummary: json['emotionalSummary'] as String?,
      physicalSummary: json['physicalSummary'] as String?,
      emotionalNarrative: cleanNarrative(json['emotionalNarrative']),
      physicalNarrative: cleanNarrative(json['physicalNarrative']),
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
