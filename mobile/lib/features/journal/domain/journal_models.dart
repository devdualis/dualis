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
  final String? persistence;
  final int? intensity;

  /// Text of an entry recorded before journal v2 (`legacy: true`).
  final String? legacyLabel;

  const JournalItem({
    required this.kind,
    this.optionKey,
    this.customLabel,
    this.conditionId,
    this.conditionLabel,
    this.bodySide,
    this.persistence,
    this.intensity,
    this.legacyLabel,
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
    bool clearPersistence = false,
  }) => JournalItem(
    kind: kind,
    optionKey: optionKey,
    customLabel: customLabel,
    conditionId: conditionId,
    conditionLabel: conditionLabel,
    bodySide: bodySide,
    persistence: clearPersistence ? null : (persistence ?? this.persistence),
    intensity: intensity ?? this.intensity,
    legacyLabel: legacyLabel,
  );

  /// Request body item (`POST /v1/journal/entries`).
  Map<String, dynamic> toRequestJson() => {
    'kind': kind,
    if (optionKey != null) 'optionKey': optionKey,
    if (customLabel != null) 'customLabel': customLabel,
    if (conditionId != null) 'conditionId': conditionId,
    if (bodySide != null) 'bodySide': bodySide,
    if (persistence != null) 'persistence': persistence,
    if (intensity != null) 'intensity': intensity,
  };

  /// Local copy (outbox and offline display): keeps the condition label.
  Map<String, dynamic> toLocalJson() => {
    ...toRequestJson(),
    if (conditionLabel != null) 'label': conditionLabel,
  };

  factory JournalItem.fromJson(Map<String, dynamic> json) => JournalItem(
    kind: json['kind'] as String? ?? JournalKeys.kindEmotional,
    optionKey: json['optionKey'] as String?,
    customLabel: json['customLabel'] as String?,
    conditionId: json['conditionId'] as String?,
    conditionLabel: (json['label'] ?? json['conditionLabel']) as String?,
    bodySide: json['bodySide'] as String?,
    persistence: json['persistence'] as String?,
    intensity: (json['intensity'] as num?)?.toInt(),
    legacyLabel: json['legacyLabel'] as String?,
  );
}

/// A day's journal entry (`JournalEntryDto`).
@immutable
class JournalEntry {
  final String? id;
  final String clientId;
  final DateTime recordedAt;
  final String mood;
  final List<String> triggers;
  final String? triggerNote;
  final String? note;
  final List<String> transitionVariantIds;
  final List<JournalItem> items;
  final bool legacy;

  /// Saved on the device and waiting to reach the server.
  final bool pendingSync;

  const JournalEntry({
    this.id,
    required this.clientId,
    required this.recordedAt,
    required this.mood,
    this.triggers = const [],
    this.triggerNote,
    this.note,
    this.transitionVariantIds = const [],
    this.items = const [],
    this.legacy = false,
    this.pendingSync = false,
  });

  bool get hasPhysicalItem =>
      items.any((i) => i.kind == JournalKeys.kindPhysical);
  bool get hasEmotionalItem =>
      items.any((i) => i.kind == JournalKeys.kindEmotional);

  JournalEntry copyWith({String? id, bool? pendingSync}) => JournalEntry(
    id: id ?? this.id,
    clientId: clientId,
    recordedAt: recordedAt,
    mood: mood,
    triggers: triggers,
    triggerNote: triggerNote,
    note: note,
    transitionVariantIds: transitionVariantIds,
    items: items,
    legacy: legacy,
    pendingSync: pendingSync ?? this.pendingSync,
  );

  /// `POST /v1/journal/entries` body. Condition labels are not included.
  Map<String, dynamic> toRequestJson() => {
    'clientId': clientId,
    'recordedAt': recordedAt.toUtc().toIso8601String(),
    'mood': mood,
    'triggers': triggers,
    if (triggerNote != null && triggerNote!.isNotEmpty)
      'triggerNote': triggerNote,
    if (note != null && note!.isNotEmpty) 'note': note,
    'transitionVariantIds': transitionVariantIds,
    'items': [for (final i in items) i.toRequestJson()],
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
    triggers: _stringList(json['triggers']),
    triggerNote: json['triggerNote'] as String?,
    note: json['note'] as String?,
    transitionVariantIds: _stringList(json['transitionVariantIds']),
    items: [
      for (final raw in (json['items'] as List? ?? const []))
        if (raw is Map) JournalItem.fromJson(Map<String, dynamic>.from(raw)),
    ],
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

  const UserCondition({required this.id, required this.label, this.createdAt});

  factory UserCondition.fromJson(Map<String, dynamic> json) => UserCondition(
    id: json['id'] as String,
    label: json['label'] as String? ?? '',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
  };
}
