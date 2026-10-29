import '../../../l10n/app_localizations.dart';
import '../../journal/domain/journal_models.dart';
import '../../journal/presentation/journal_labels.dart';

/// One item of a journal entry as returned by `GET /v1/journal/entries`
/// (contract: docs/bienestar/CONTRATO-JOURNAL-V2.md).
class JournalItemView {
  final String kind;
  final String? optionKey;
  final String? customLabel;
  final String? conditionId;
  final String? conditionLabel;
  final String? bodySide;
  final String? persistence;
  final int? intensity;

  /// `dor` or `incomodo` for physical items of journal v2.1; null for old
  /// items and for emotional or condition items.
  final String? sensation;

  /// Text of an entry saved before journal v2 (`legacy: true`).
  final String? legacyLabel;

  const JournalItemView({
    required this.kind,
    this.optionKey,
    this.customLabel,
    this.conditionId,
    this.conditionLabel,
    this.bodySide,
    this.persistence,
    this.intensity,
    this.sensation,
    this.legacyLabel,
  });

  factory JournalItemView.fromItem(JournalItem item) => JournalItemView(
        kind: item.kind,
        optionKey: item.optionKey,
        customLabel: item.customLabel,
        conditionId: item.conditionId,
        conditionLabel: item.conditionLabel,
        bodySide: item.bodySide,
        persistence: item.persistence,
        intensity: item.intensity,
        legacyLabel: item.legacyLabel,
      );

  factory JournalItemView.fromJson(Map<String, dynamic> json) {
    return JournalItemView(
      kind: json['kind'] as String? ?? '',
      optionKey: json['optionKey'] as String?,
      customLabel: json['customLabel'] as String?,
      conditionId: json['conditionId'] as String?,
      conditionLabel:
          json['label'] as String? ?? json['conditionLabel'] as String?,
      bodySide: json['bodySide'] as String?,
      persistence: json['persistence'] as String?,
      intensity: (json['intensity'] as num?)?.toInt(),
      sensation: json['sensation'] as String?,
      legacyLabel: json['legacyLabel'] as String?,
    );
  }

  bool get isCustom => optionKey?.endsWith('.custom') ?? false;

  /// First segment of the key: time for emotional items, region for
  /// physical ones.
  String? get _head {
    final key = optionKey;
    if (key == null || key.isEmpty) return null;
    return key.split('.').first;
  }

  String? get time => kind == 'emotional' ? _head : null;
  String? get region => kind == 'physical' ? _head : null;

  /// Stable identity of the item across days, used for one line per item.
  String get seriesKey {
    if (legacyLabel != null) return 'legacy:${legacyLabel!.toLowerCase()}';
    if (kind == 'condition') return 'condition:${conditionId ?? conditionLabel}';
    if (isCustom) return '$optionKey:${(customLabel ?? '').toLowerCase()}';
    return optionKey ?? kind;
  }

  /// What the person chose or wrote, in their words.
  String label(AppLocalizations l10n) {
    if (legacyLabel != null && legacyLabel!.isNotEmpty) return legacyLabel!;
    if (kind == 'condition') return conditionLabel ?? '';
    if (customLabel != null && customLabel!.isNotEmpty) return customLabel!;
    final key = optionKey;
    if (key == null) return '';
    final option = JournalLabels.option(l10n, key);
    if (option.isEmpty) return '';
    final region = this.region;
    final regionText =
        region != null ? JournalLabels.region(l10n, region) : null;
    return regionText != null ? '$regionText · $option' : option;
  }
}

class JournalEntryView {
  final String id;
  final DateTime recordedAt;
  final String? mood;

  /// `emotional`, `physical` or null (entries saved before journal v2.1).
  final String? area;
  final List<String> triggers;
  final bool legacy;
  final List<JournalItemView> items;
  final bool pendingSync;

  const JournalEntryView({
    required this.id,
    required this.recordedAt,
    this.mood,
    this.area,
    this.triggers = const [],
    this.legacy = false,
    this.items = const [],
    this.pendingSync = false,
  });

  factory JournalEntryView.fromEntry(JournalEntry entry) => JournalEntryView(
        id: entry.id ?? entry.clientId,
        recordedAt: entry.recordedAt,
        mood: entry.mood,
        triggers: entry.triggers,
        legacy: entry.legacy,
        items: [for (final item in entry.items) JournalItemView.fromItem(item)],
        pendingSync: entry.pendingSync,
      );

  factory JournalEntryView.fromJson(Map<String, dynamic> json) {
    return JournalEntryView(
      id: json['id']?.toString() ?? '',
      recordedAt:
          DateTime.tryParse(json['recordedAt'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      mood: json['mood'] as String?,
      area: json['area'] as String?,
      triggers: (json['triggers'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      legacy: json['legacy'] as bool? ?? false,
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((e) => JournalItemView.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  DateTime get day =>
      DateTime(recordedAt.year, recordedAt.month, recordedAt.day);

  /// Markers counted in the summary. Same set as `dayMarkers` on the server:
  /// physical → region (`cabeca`), emotional → branch (`futuro.mente`) or the
  /// time (`futuro`) for a written item, plus `trigger:<key>`.
  Set<String> get markers {
    final result = <String>{};
    for (final item in items) {
      final key = item.optionKey;
      if (key == null || key.isEmpty) continue;
      final parts = key.split('.');
      if (item.kind == 'physical') {
        result.add(parts.first);
      } else if (item.kind == 'emotional') {
        result.add(
          item.isCustom || parts.length < 2
              ? parts.first
              : '${parts[0]}.${parts[1]}',
        );
      }
    }
    for (final t in triggers) {
      result.add('trigger:$t');
    }
    return result;
  }
}

class JournalCooccurrence {
  final String a;
  final String b;
  final int days;

  const JournalCooccurrence({
    required this.a,
    required this.b,
    required this.days,
  });

  factory JournalCooccurrence.fromJson(Map<String, dynamic> json) {
    return JournalCooccurrence(
      a: json['a']?.toString() ?? '',
      b: json['b']?.toString() ?? '',
      days: (json['days'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Counts only (`GET /v1/journal/summary`). No labels, no interpretation.
class JournalSummary {
  final Map<String, int> byTime;
  final Map<String, int> byRegion;
  final Map<String, int> byOptionKey;
  final Map<String, int> byTrigger;
  final List<JournalCooccurrence> cooccurrence;

  const JournalSummary({
    this.byTime = const {},
    this.byRegion = const {},
    this.byOptionKey = const {},
    this.byTrigger = const {},
    this.cooccurrence = const [],
  });

  static Map<String, int> _counts(dynamic raw) {
    if (raw is! Map) return const {};
    return {
      for (final e in raw.entries)
        if (e.value is num) e.key.toString(): (e.value as num).toInt(),
    };
  }

  factory JournalSummary.fromJson(Map<String, dynamic> json) {
    return JournalSummary(
      byTime: _counts(json['byTime']),
      byRegion: _counts(json['byRegion']),
      byOptionKey: _counts(json['byOptionKey']),
      byTrigger: _counts(json['byTrigger']),
      cooccurrence: (json['cooccurrence'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((e) =>
              JournalCooccurrence.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  /// Same counts computed on the device, used when the summary endpoint is
  /// not reachable. Each count is the number of days with that marker.
  factory JournalSummary.compute(List<JournalEntryView> entries) {
    final daysByMarker = markerDays(entries);
    final timeDays = <String, Set<DateTime>>{};
    final regionDays = <String, Set<DateTime>>{};
    final optionDays = <String, Set<DateTime>>{};
    final triggerDays = <String, Set<DateTime>>{};
    void mark(Map<String, Set<DateTime>> map, String key, DateTime day) {
      map.putIfAbsent(key, () => <DateTime>{}).add(day);
    }

    for (final entry in entries) {
      for (final item in entry.items) {
        final key = item.optionKey;
        if (key == null || key.isEmpty) continue;
        final root = key.split('.').first;
        if (item.kind == 'emotional') mark(timeDays, root, entry.day);
        if (item.kind == 'physical') mark(regionDays, root, entry.day);
        if (!item.isCustom) mark(optionDays, key, entry.day);
      }
      for (final t in entry.triggers) {
        mark(triggerDays, t, entry.day);
      }
    }

    final byTime = {for (final e in timeDays.entries) e.key: e.value.length};
    final byRegion = {
      for (final e in regionDays.entries) e.key: e.value.length,
    };
    final byOptionKey = {
      for (final e in optionDays.entries) e.key: e.value.length,
    };
    final byTrigger = {
      for (final e in triggerDays.entries) e.key: e.value.length,
    };

    // Pairs of markers recorded on the same day, counted in days.
    final pairs = <JournalCooccurrence>[];
    final keys = daysByMarker.keys
        .where((k) => !JournalLabels.times.contains(k))
        .toList()
      ..sort();
    for (var i = 0; i < keys.length; i++) {
      for (var j = i + 1; j < keys.length; j++) {
        final a = keys[i];
        final b = keys[j];
        if (a.startsWith('$b.') || b.startsWith('$a.')) continue;
        final both = daysByMarker[a]!.intersection(daysByMarker[b]!).length;
        if (both >= 2) {
          pairs.add(JournalCooccurrence(a: a, b: b, days: both));
        }
      }
    }
    pairs.sort((x, y) => y.days.compareTo(x.days));

    return JournalSummary(
      byTime: byTime,
      byRegion: byRegion,
      byOptionKey: byOptionKey,
      byTrigger: byTrigger,
      cooccurrence: pairs,
    );
  }

  bool get isEmpty =>
      byTime.isEmpty && byRegion.isEmpty && byOptionKey.isEmpty;
}

/// Days (local dates) on which each marker was recorded.
Map<String, Set<DateTime>> markerDays(List<JournalEntryView> entries) {
  final result = <String, Set<DateTime>>{};
  for (final entry in entries) {
    for (final marker in entry.markers) {
      result.putIfAbsent(marker, () => <DateTime>{}).add(entry.day);
    }
  }
  return result;
}
