import 'dart:math' show pow;

import 'package:flutter/foundation.dart';

import 'journal_keys.dart';

/// One thing the user recorded in an entry: an option they chose, something
/// they wrote themselves, or a condition they track. Stored in their words.
@immutable
class JournalItem {
  final String kind;
  final String? optionKey;
  final String? customLabel;
  final String? conditionId;

  /// Name of the condition as the user wrote it. Display only: never part of
  /// the POST body and never sent to the AI.
  final String? conditionLabel;
  final String? bodySide;

  /// `dor` or `incomodo` on physical items of new entries; null otherwise.
  final String? sensation;
  final String? persistence;
  final int? intensity;

  /// Text of an entry recorded before journal v2 (`legacy: true`).
  final String? legacyLabel;

  /// Self-reported readings of a tracked condition (v2.4). Only on condition
  /// items; a condition item with a reading may have no intensity.
  final List<ConditionReading> readings;

  const JournalItem({
    required this.kind,
    this.optionKey,
    this.customLabel,
    this.conditionId,
    this.conditionLabel,
    this.bodySide,
    this.sensation,
    this.persistence,
    this.intensity,
    this.legacyLabel,
    this.readings = const [],
  });

  /// Identity inside a draft: same choice, same row.
  String get draftId =>
      conditionId != null
          ? 'condition:$conditionId'
          : '$kind:${optionKey ?? ''}:${customLabel ?? ''}:${bodySide ?? ''}';

  bool get isCustom => optionKey != null && JournalKeys.isCustomKey(optionKey!);

  JournalItem copyWith({
    String? persistence,
    int? intensity,
    List<ConditionReading>? readings,
    bool clearPersistence = false,
    bool clearIntensity = false,
  }) => JournalItem(
    kind: kind,
    optionKey: optionKey,
    customLabel: customLabel,
    conditionId: conditionId,
    conditionLabel: conditionLabel,
    bodySide: bodySide,
    sensation: sensation,
    persistence: clearPersistence ? null : (persistence ?? this.persistence),
    intensity: clearIntensity ? null : (intensity ?? this.intensity),
    legacyLabel: legacyLabel,
    readings: readings ?? this.readings,
  );

  /// Request body item (`POST /v1/journal/entries`).
  Map<String, dynamic> toRequestJson() => {
    'kind': kind,
    if (optionKey != null) 'optionKey': optionKey,
    if (customLabel != null) 'customLabel': customLabel,
    if (conditionId != null) 'conditionId': conditionId,
    if (bodySide != null) 'bodySide': bodySide,
    if (sensation != null) 'sensation': sensation,
    if (persistence != null) 'persistence': persistence,
    if (intensity != null) 'intensity': intensity,
    if (readings.isNotEmpty) 'readings': [for (final r in readings) r.toJson()],
  };

  /// Local copy (outbox and offline display): keeps the condition label.
  Map<String, dynamic> toLocalJson() => {
    ...toRequestJson(),
    if (conditionLabel != null) 'label': conditionLabel,
    if (readings.isNotEmpty)
      'readings': [for (final r in readings) r.toLocalJson()],
  };

  factory JournalItem.fromJson(Map<String, dynamic> json) => JournalItem(
    kind: json['kind'] as String? ?? JournalKeys.kindEmotional,
    optionKey: json['optionKey'] as String?,
    customLabel: json['customLabel'] as String?,
    conditionId: json['conditionId'] as String?,
    conditionLabel: (json['label'] ?? json['conditionLabel']) as String?,
    bodySide: json['bodySide'] as String?,
    sensation: json['sensation'] as String?,
    persistence: json['persistence'] as String?,
    intensity: (json['intensity'] as num?)?.toInt(),
    legacyLabel: json['legacyLabel'] as String?,
    readings: [
      for (final raw in (json['readings'] as List? ?? const []))
        if (raw is Map) ConditionReading.fromJson(Map<String, dynamic>.from(raw)),
    ],
  );
}

/// One self-reported reading of a tracked condition, as the person typed it,
/// with its own time. Stored and shown raw: no range, label or comparison.
@immutable
class ConditionReading {
  /// Server id; null until the entry reaches the server.
  final String? id;
  final String? entryId;
  final String? conditionId;

  /// `blood_pressure` | `glucose` | `weight` ([JournalKeys.trackingKinds]).
  final String kind;
  final DateTime measuredAt;

  // Blood pressure (mmHg; pulse in bpm, optional).
  final int? systolic;
  final int? diastolic;
  final int? pulse;

  // Glucose (mg/dL) and the moment the person picked.
  final int? mgdl;
  final String? moment;

  // Weight (kg, up to two decimals).
  final double? kg;

  /// Saved on the device and waiting to reach the server.
  final bool pendingSync;

  const ConditionReading({
    this.id,
    this.entryId,
    this.conditionId,
    required this.kind,
    required this.measuredAt,
    this.systolic,
    this.diastolic,
    this.pulse,
    this.mgdl,
    this.moment,
    this.kg,
    this.pendingSync = false,
  });

  const ConditionReading.bloodPressure({
    required this.measuredAt,
    required int this.systolic,
    required int this.diastolic,
    this.pulse,
    this.id,
    this.entryId,
    this.conditionId,
    this.pendingSync = false,
  }) : kind = JournalKeys.trackingBloodPressure,
       mgdl = null,
       moment = null,
       kg = null;

  const ConditionReading.glucose({
    required this.measuredAt,
    required int this.mgdl,
    required String this.moment,
    this.id,
    this.entryId,
    this.conditionId,
    this.pendingSync = false,
  }) : kind = JournalKeys.trackingGlucose,
       systolic = null,
       diastolic = null,
       pulse = null,
       kg = null;

  const ConditionReading.weight({
    required this.measuredAt,
    required double this.kg,
    this.id,
    this.entryId,
    this.conditionId,
    this.pendingSync = false,
  }) : kind = JournalKeys.trackingWeight,
       systolic = null,
       diastolic = null,
       pulse = null,
       mgdl = null,
       moment = null;

  /// Every value the kind needs is present and inside the input limits (typo
  /// guard only, never a judgement of the value).
  bool get valuesAccepted {
    switch (kind) {
      case JournalKeys.trackingBloodPressure:
        return systolic != null &&
            diastolic != null &&
            JournalKeys.systolicLimit.accepts(systolic!) &&
            JournalKeys.diastolicLimit.accepts(diastolic!) &&
            (pulse == null || JournalKeys.pulseLimit.accepts(pulse!));
      case JournalKeys.trackingGlucose:
        return mgdl != null &&
            JournalKeys.mgdlLimit.accepts(mgdl!) &&
            JournalKeys.glucoseMoments.contains(moment);
      case JournalKeys.trackingWeight:
        return kg != null && JournalKeys.kgLimit.accepts(kg!);
      default:
        return false;
    }
  }

  /// [measuredAt] is not too far ahead of [now] nor too far before
  /// [recordedAt] (the entry time).
  bool timeAccepted({required DateTime recordedAt, DateTime? now}) {
    final clock = now ?? DateTime.now();
    return !measuredAt.isAfter(clock.add(JournalKeys.readingMaxAhead)) &&
        !measuredAt.isBefore(recordedAt.subtract(JournalKeys.readingMaxBefore));
  }

  /// Same kind, time and values (ids and sync state aside).
  bool sameReadingAs(ConditionReading other) =>
      kind == other.kind &&
      measuredAt.isAtSameMomentAs(other.measuredAt) &&
      systolic == other.systolic &&
      diastolic == other.diastolic &&
      pulse == other.pulse &&
      mgdl == other.mgdl &&
      moment == other.moment &&
      kg == other.kg;

  ConditionReading copyWith({
    String? conditionId,
    DateTime? measuredAt,
    bool? pendingSync,
  }) => ConditionReading(
    id: id,
    entryId: entryId,
    conditionId: conditionId ?? this.conditionId,
    kind: kind,
    measuredAt: measuredAt ?? this.measuredAt,
    systolic: systolic,
    diastolic: diastolic,
    pulse: pulse,
    mgdl: mgdl,
    moment: moment,
    kg: kg,
    pendingSync: pendingSync ?? this.pendingSync,
  );

  /// Request body reading (`items[].readings[]`): kind, time and the values
  /// of that kind only.
  Map<String, dynamic> toJson() => {
    'kind': kind,
    'measuredAt': measuredAt.toUtc().toIso8601String(),
    if (kind == JournalKeys.trackingBloodPressure) ...{
      'systolic': systolic,
      'diastolic': diastolic,
      if (pulse != null) 'pulse': pulse,
    },
    if (kind == JournalKeys.trackingGlucose) ...{
      'mgdl': mgdl,
      'moment': moment,
    },
    if (kind == JournalKeys.trackingWeight) 'kg': _roundKg(kg),
  };

  /// Local copy (outbox): the request body plus the ids, when known.
  Map<String, dynamic> toLocalJson() => {
    ...toJson(),
    if (id != null) 'id': id,
    if (entryId != null) 'entryId': entryId,
    if (conditionId != null) 'conditionId': conditionId,
  };

  factory ConditionReading.fromJson(Map<String, dynamic> json) =>
      ConditionReading(
        id: json['id'] as String?,
        entryId: json['entryId'] as String?,
        conditionId: json['conditionId'] as String?,
        kind: json['kind'] as String? ?? '',
        measuredAt:
            DateTime.tryParse(json['measuredAt'] as String? ?? '')?.toLocal() ??
            DateTime.fromMillisecondsSinceEpoch(0),
        systolic: (json['systolic'] as num?)?.toInt(),
        diastolic: (json['diastolic'] as num?)?.toInt(),
        pulse: (json['pulse'] as num?)?.toInt(),
        mgdl: (json['mgdl'] as num?)?.toInt(),
        moment: json['moment'] as String?,
        kg: (json['kg'] as num?)?.toDouble(),
      );

  static double? _roundKg(double? value) {
    if (value == null) return null;
    final factor = pow(10, JournalKeys.kgDecimals);
    return (value * factor).round() / factor;
  }

  @override
  bool operator ==(Object other) =>
      other is ConditionReading &&
      other.id == id &&
      other.entryId == entryId &&
      other.conditionId == conditionId &&
      other.pendingSync == pendingSync &&
      sameReadingAs(other);

  @override
  int get hashCode => Object.hash(
    id,
    entryId,
    conditionId,
    kind,
    measuredAt.microsecondsSinceEpoch,
    systolic,
    diastolic,
    pulse,
    mgdl,
    moment,
    kg,
    pendingSync,
  );
}

/// A day's journal entry (`JournalEntryDto`).
@immutable
class JournalEntry {
  final String? id;
  final String clientId;
  final DateTime recordedAt;
  final String mood;

  /// Axis this entry records (`emotional` / `physical`); null on old entries.
  final String? area;
  final List<String> triggers;
  final String? triggerNote;
  final String? note;
  final List<String> transitionVariantIds;
  final List<JournalItem> items;

  /// "Como foi lidar com isso?" (v2.2); null when skipped or on older entries.
  final String? coping;

  /// "O que te ajudou hoje?" (v2.2); empty when skipped or on older entries.
  final List<String> helpers;
  final bool legacy;

  /// Saved on the device and waiting to reach the server.
  final bool pendingSync;

  const JournalEntry({
    this.id,
    required this.clientId,
    required this.recordedAt,
    required this.mood,
    this.area,
    this.triggers = const [],
    this.triggerNote,
    this.note,
    this.transitionVariantIds = const [],
    this.items = const [],
    this.coping,
    this.helpers = const [],
    this.legacy = false,
    this.pendingSync = false,
  });

  bool get hasPhysicalItem =>
      items.any((i) => i.kind == JournalKeys.kindPhysical);
  bool get hasEmotionalItem =>
      items.any((i) => i.kind == JournalKeys.kindEmotional);
  bool get hasPositiveItem =>
      items.any((i) => i.kind == JournalKeys.kindPositive);

  JournalEntry copyWith({String? id, bool? pendingSync}) => JournalEntry(
    id: id ?? this.id,
    clientId: clientId,
    recordedAt: recordedAt,
    mood: mood,
    area: area,
    triggers: triggers,
    triggerNote: triggerNote,
    note: note,
    transitionVariantIds: transitionVariantIds,
    items: items,
    coping: coping,
    helpers: helpers,
    legacy: legacy,
    pendingSync: pendingSync ?? this.pendingSync,
  );

  /// `POST /v1/journal/entries` body. Condition labels are not included.
  Map<String, dynamic> toRequestJson() => {
    'clientId': clientId,
    'recordedAt': recordedAt.toUtc().toIso8601String(),
    'mood': mood,
    if (area != null) 'area': area,
    'triggers': triggers,
    if (triggerNote != null && triggerNote!.isNotEmpty)
      'triggerNote': triggerNote,
    if (note != null && note!.isNotEmpty) 'note': note,
    'transitionVariantIds': transitionVariantIds,
    'items': [for (final i in items) i.toRequestJson()],
    if (coping != null) 'coping': coping,
    if (helpers.isNotEmpty) 'helpers': helpers,
  };

  Map<String, dynamic> toLocalJson() => {
    ...toRequestJson(),
    'items': [for (final i in items) i.toLocalJson()],
  };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
    id: json['id'] as String?,
    clientId: json['clientId'] as String? ?? json['id'] as String? ?? '',
    recordedAt:
        DateTime.tryParse(json['recordedAt'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
    mood: json['mood'] as String? ?? JournalKeys.moodNaoTaoBem,
    area: json['area'] as String?,
    triggers: _stringList(json['triggers']),
    triggerNote: json['triggerNote'] as String?,
    note: json['note'] as String?,
    transitionVariantIds: _stringList(json['transitionVariantIds']),
    items: [
      for (final raw in (json['items'] as List? ?? const []))
        if (raw is Map) JournalItem.fromJson(Map<String, dynamic>.from(raw)),
    ],
    coping: json['coping'] as String?,
    helpers: _stringList(json['helpers']),
    legacy: json['legacy'] as bool? ?? false,
  );

  static List<String> _stringList(Object? raw) => [
    for (final v in (raw as List? ?? const [])) v.toString(),
  ];
}

/// A condition the user tracks, named in their own words (`userConditions`).
@immutable
class UserCondition {
  final String id;
  final String label;
  final DateTime? createdAt;

  /// Reading kinds the person chose to record for this condition (v2.4,
  /// subset of [JournalKeys.trackingKinds]). Empty: the 1-5 card.
  final List<String> tracking;

  const UserCondition({
    required this.id,
    required this.label,
    this.createdAt,
    this.tracking = const [],
  });

  bool get isTracked => tracking.isNotEmpty;

  UserCondition copyWith({String? label, List<String>? tracking}) =>
      UserCondition(
        id: id,
        label: label ?? this.label,
        createdAt: createdAt,
        tracking: tracking ?? this.tracking,
      );

  /// Known kinds only, in [JournalKeys.trackingKinds] order, no repeats.
  static List<String> cleanTracking(Iterable<Object?> raw) {
    final set = {for (final v in raw) v.toString()};
    return [
      for (final k in JournalKeys.trackingKinds)
        if (set.contains(k)) k,
    ];
  }

  factory UserCondition.fromJson(Map<String, dynamic> json) => UserCondition(
    id: json['id'] as String,
    label: json['label'] as String? ?? '',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    tracking: cleanTracking(json['tracking'] as List? ?? const []),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    'tracking': tracking,
  };
}

/// Readings of one condition, newest first. [complete] is false when the
/// server could not be reached and only readings saved on the device show.
@immutable
class ConditionReadingsHistory {
  final List<ConditionReading> readings;
  final bool complete;

  const ConditionReadingsHistory({
    this.readings = const [],
    this.complete = true,
  });
}
