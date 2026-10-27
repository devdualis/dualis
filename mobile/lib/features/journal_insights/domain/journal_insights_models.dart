import '../../../l10n/app_localizations.dart';
import 'journal_labels.dart';

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
    this.legacyLabel,
  });

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
    if (option == null) return '';
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
  final List<String> triggers;
  final bool legacy;
  final List<JournalItemView> items;

  const JournalEntryView({
    required this.id,
    required this.recordedAt,
    this.mood,
    this.triggers = const [],
    this.legacy = false,
    this.items = const [],
  });

  factory JournalEntryView.fromJson(Map<String, dynamic> json) {
    return JournalEntryView(
      id: json['id']?.toString() ?? '',
      recordedAt:
          DateTime.tryParse(json['recordedAt'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      mood: json['mood'] as String?,
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

  /// Markers counted in the summary: times and option keys of emotional
  /// items, regions of physical items, and triggers.
  Set<String> get markers {
    final result = <String>{};
    for (final item in items) {
      if (item.time != null) {
        result.add(item.time!);
        if (!item.isCustom) result.add(item.optionKey!);
      }
      if (item.region != null) result.add(item.region!);
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
    final byTime = <String, int>{};
    final byRegion = <String, int>{};
    final byOptionKey = <String, int>{};
    final byTrigger = <String, int>{};
    daysByMarker.forEach((marker, days) {
      if (JournalLabels.times.contains(marker)) {
        byTime[marker] = days.length;
      } else if (JournalLabels.regions.contains(marker)) {
        byRegion[marker] = days.length;
      } else if (marker.startsWith('trigger:')) {
        byTrigger[marker.substring(8)] = days.length;
      } else {
        byOptionKey[marker] = days.length;
      }
    });

    // Pairs of markers recorded on the same day, counted in days.
    final pairs = <JournalCooccurrence>[];
    final keys = daysByMarker.keys
        .where((k) => !JournalLabels.times.contains(k))
        .toList()
      ..sort();
    for (var i = 0; i < keys.length; i++) {
      for (var j = i + 1; j < keys.length; j++) {
        final both = daysByMarker[keys[i]]!
            .intersection(daysByMarker[keys[j]]!)
            .length;
        if (both >= 2) {
          pairs.add(JournalCooccurrence(a: keys[i], b: keys[j], days: both));
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

/// Count sentences of the only form allowed in reports (strategy §9.2):
/// "Nos 7 dias em que você marcou 'Mente acelerada', também marcou 'Cabeça'
/// em 5." No cause, no trend, no advice.
List<String> cooccurrenceSentences(
  AppLocalizations l10n,
  JournalSummary summary,
  List<JournalEntryView> entries, {
  int max = 3,
}) {
  final days = markerDays(entries);
  final sentences = <String>[];
  for (final pair in summary.cooccurrence) {
    if (sentences.length >= max) break;
    var a = _normalizeMarker(pair.a);
    var b = _normalizeMarker(pair.b);
    final aDays = days[a]?.length ?? 0;
    final bDays = days[b]?.length ?? 0;
    // The marker seen on more days frames the sentence.
    if (bDays > aDays) {
      final swap = a;
      a = b;
      b = swap;
    }
    final total = days[a]?.length ?? 0;
    final labelA = JournalLabels.marker(l10n, a);
    final labelB = JournalLabels.marker(l10n, b);
    if (labelA == null || labelB == null || total < pair.days) continue;
    if (pair.days <= 0) continue;
    sentences.add(l10n.xv2DashCooccurrence(total, labelA, labelB, pair.days));
  }
  return sentences;
}

/// The summary endpoint may send triggers without the `trigger:` prefix.
String _normalizeMarker(String key) {
  if (JournalLabels.triggers.contains(key)) {
    return 'trigger:$key';
  }
  return key;
}
