import '../../dashboard/domain/models/triage_history_models.dart';
import '../../triage_outcome/domain/triage_outcome_models.dart';
import 'trigger_checkin_state.dart';

/// The two check-in axes shown on Home and "Resultado do Dia".
enum CheckInAxis {
  emotional,
  physical;

  /// Matches the `TriageOutcome.vertical` string for this axis.
  String get outcomeVertical =>
      this == CheckInAxis.emotional ? 'emotional' : 'physical';

  CheckInAxis get other =>
      this == CheckInAxis.emotional ? CheckInAxis.physical : CheckInAxis.emotional;
}

/// The single score -> [TriggerStatus] mapping.
///
/// null or <= 0 -> goodNormal; 1-3 -> soSo; 4-5 -> badSick.
TriggerStatus triggerStatusFromIntensity(int? score) {
  if (score == null || score <= 0) return TriggerStatus.goodNormal;
  if (score >= 4) return TriggerStatus.badSick;
  return TriggerStatus.soSo;
}

/// Single source of truth for per-axis intensity: the most recent real history
/// record for that axis today. Derived values (the outcome's secondary score,
/// status defaults) are fallbacks only when no record exists for the axis.
abstract final class AxisIntensityResolver {
  static const String _emotionalGeneralCode = 'geral_emocional';

  static bool isDailyCheckIn(TriageHistoryEntry log) =>
      log.stepAnswers?['type'] == 'daily_checkin';

  /// The axis the record was submitted under.
  ///
  /// Backend persistence rule (TriageOutcomeService.processOutcome): the
  /// primary-axis column gets the mapped category code, and the other column
  /// is filled only for a cross-vertical narrative. An emotional-vertical
  /// record with a physical cross-vertical tag always has
  /// `organicPrimacyApplied = true`, while the physical vertical never sets it.
  /// That is why `organicPrimacyApplied` disambiguates dual-tagged records.
  static CheckInAxis? primaryAxisOf(TriageHistoryEntry log) {
    if (isDailyCheckIn(log)) return null;
    if (log.anatomicalSystem == _emotionalGeneralCode) return CheckInAxis.emotional;
    final hasPhysical = log.anatomicalSystem != null;
    final hasEmotional = log.emotionalDimension != null;
    if (hasPhysical && hasEmotional) {
      return log.organicPrimacyApplied ? CheckInAxis.emotional : CheckInAxis.physical;
    }
    if (hasEmotional) return CheckInAxis.emotional;
    if (hasPhysical) return CheckInAxis.physical;
    return null;
  }

  /// Mirrors Histórico axis membership. `organicPrimacyApplied` alone does not
  /// tag a record as physical.
  static bool isTaggedWith(TriageHistoryEntry log, CheckInAxis axis) {
    switch (axis) {
      case CheckInAxis.physical:
        return log.anatomicalSystem != null &&
            log.anatomicalSystem != _emotionalGeneralCode;
      case CheckInAxis.emotional:
        return log.emotionalDimension != null ||
            log.anatomicalSystem == _emotionalGeneralCode;
    }
  }

  /// The category column value for [axis] on this record.
  static String? categoryCodeFor(TriageHistoryEntry log, CheckInAxis axis) {
    switch (axis) {
      case CheckInAxis.physical:
        return log.anatomicalSystem == _emotionalGeneralCode
            ? null
            : log.anatomicalSystem;
      case CheckInAxis.emotional:
        return log.emotionalDimension ??
            (log.anatomicalSystem == _emotionalGeneralCode
                ? log.anatomicalSystem
                : null);
    }
  }

  /// Most recent record for [axis]: a record whose own (primary) axis is
  /// [axis] beats one that is only cross-vertically tagged with it.
  /// Daily check-in logs are never returned.
  static TriageHistoryEntry? latestRecordFor(
    CheckInAxis axis,
    Iterable<TriageHistoryEntry> logs,
  ) {
    final sorted = logs.where((l) => !isDailyCheckIn(l)).toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    for (final log in sorted) {
      if (primaryAxisOf(log) == axis) return log;
    }
    for (final log in sorted) {
      if (isTaggedWith(log, axis)) return log;
    }
    return null;
  }

  /// Intensity to display for [axis].
  ///
  /// Precedence: (1) the outcome's own score when the outcome is this axis;
  /// (2) the state's per-axis intensity (seeded from real records);
  /// (3) derived: the outcome's secondary score when the outcome is the other
  /// axis; (4) derived: the state's status default.
  static int? resolveDisplayIntensity({
    required CheckInAxis axis,
    required TriggerCheckInState state,
    TriageOutcome? outcome,
  }) {
    if (outcome != null && outcome.vertical == axis.outcomeVertical) {
      return outcome.intensityScore;
    }
    final stateIntensity = axis == CheckInAxis.emotional
        ? state.emotionalIntensity
        : state.physicalIntensity;
    if (stateIntensity != null) return stateIntensity;
    if (outcome != null &&
        outcome.vertical == axis.other.outcomeVertical &&
        outcome.secondaryIntensityScore != null) {
      return outcome.secondaryIntensityScore;
    }
    final status = axis == CheckInAxis.emotional
        ? state.emotionalStatus
        : state.physicalStatus;
    return status?.defaultIntensity;
  }
}
