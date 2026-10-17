class TriageHistoryEntry {
  final String id;
  final int intensity;
  final String? anatomicalSystem;
  final String? emotionalDimension;
  /// Vertical the person chose for the entry ('physical' | 'emotional'), or
  /// null when unknown. Tells the primary axis of a dual-tagged entry.
  final String? vertical;
  /// Legacy field from old cached payloads; never shown.
  final String? disposition;
  /// Legacy flag from old cached payloads; the API no longer returns it.
  final bool organicPrimacyApplied;
  final String? narrative;
  final Map<String, dynamic>? stepAnswers;
  final DateTime recordedAt;

  const TriageHistoryEntry({
    required this.id,
    required this.intensity,
    this.anatomicalSystem,
    this.emotionalDimension,
    this.vertical,
    this.disposition,
    this.organicPrimacyApplied = false,
    this.narrative,
    this.stepAnswers,
    required this.recordedAt,
  });

  factory TriageHistoryEntry.fromJson(Map<String, dynamic> json) {
    return TriageHistoryEntry(
      id: json['id'] as String,
      intensity: (json['intensity'] as num).toInt(),
      anatomicalSystem: json['anatomicalSystem'] as String?,
      emotionalDimension: json['emotionalDimension'] as String?,
      vertical: switch (json['vertical']) {
        'physical' => 'physical',
        'emotional' => 'emotional',
        _ => null,
      },
      disposition: json['disposition'] as String?,
      organicPrimacyApplied: json['organicPrimacyApplied'] as bool? ?? false,
      narrative: json['narrative'] as String?,
      stepAnswers: json['stepAnswers'] != null && json['stepAnswers'] is Map
          ? Map<String, dynamic>.from(json['stepAnswers'] as Map)
          : null,
      recordedAt: DateTime.parse(json['recordedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'intensity': intensity,
      'anatomicalSystem': anatomicalSystem,
      'emotionalDimension': emotionalDimension,
      'vertical': vertical,
      if (disposition != null) 'disposition': disposition,
      if (organicPrimacyApplied) 'organicPrimacyApplied': organicPrimacyApplied,
      if (narrative != null) 'narrative': narrative,
      'stepAnswers': stepAnswers,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }
}

class JournalPatternItem {
  final String category;
  final String vertical;
  final int count;
  final int windowDays;

  const JournalPatternItem({
    required this.category,
    required this.vertical,
    required this.count,
    required this.windowDays,
  });

  factory JournalPatternItem.fromJson(Map<String, dynamic> json) {
    return JournalPatternItem(
      category: json['category'] as String? ?? '',
      vertical: json['vertical'] as String? ?? 'physical',
      count: (json['count'] as num?)?.toInt() ??
          (json['frequencyCount'] as num?)?.toInt() ??
          0,
      windowDays: (json['windowDays'] as num?)?.toInt() ?? 10,
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'vertical': vertical,
        'count': count,
        'windowDays': windowDays,
      };
}

@Deprecated('Use JournalPatternItem')
typedef CriticalRecurrenceItem = JournalPatternItem;

class EmotionalDayData {
  final String date;
  final Map<String, int> dimensions;

  const EmotionalDayData({
    required this.date,
    required this.dimensions,
  });

  factory EmotionalDayData.fromJson(Map<String, dynamic> json) {
    final rawDims = json['dimensions'] as Map<String, dynamic>? ?? {};
    final mappedDims = <String, int>{};
    for (final entry in rawDims.entries) {
      mappedDims[entry.key] = (entry.value as num).toInt();
    }
    return EmotionalDayData(
      date: json['date'] as String,
      dimensions: mappedDims,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'dimensions': dimensions,
    };
  }
}

class TriageHistoryResponse {
  final List<TriageHistoryEntry> logs;
  final Map<String, int> physicalSummary;
  final List<EmotionalDayData> emotionalSummary;
  final List<JournalPatternItem> journalPatterns;

  const TriageHistoryResponse({
    required this.logs,
    required this.physicalSummary,
    required this.emotionalSummary,
    required this.journalPatterns,
  });

  factory TriageHistoryResponse.fromJson(Map<String, dynamic> json) {
    final rawLogs = json['logs'] as List<dynamic>? ?? [];
    final logs = rawLogs
        .map((e) => TriageHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    final rawPhys = json['physicalSummary'] as Map<String, dynamic>? ?? {};
    final physicalSummary = <String, int>{};
    for (final entry in rawPhys.entries) {
      physicalSummary[entry.key] = (entry.value as num).toInt();
    }

    final rawEmo = json['emotionalSummary'] as List<dynamic>? ?? [];
    final emotionalSummary = rawEmo
        .map((e) => EmotionalDayData.fromJson(e as Map<String, dynamic>))
        .toList();

    final rawPatterns = json['journalPatterns'] as List<dynamic>? ??
        json['criticalRecurrences'] as List<dynamic>? ??
        [];
    final journalPatterns = rawPatterns
        .map((e) => JournalPatternItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return TriageHistoryResponse(
      logs: logs,
      physicalSummary: physicalSummary,
      emotionalSummary: emotionalSummary,
      journalPatterns: journalPatterns,
    );
  }

  TriageHistoryResponse copyWith({
    List<TriageHistoryEntry>? logs,
    Map<String, int>? physicalSummary,
    List<EmotionalDayData>? emotionalSummary,
    List<JournalPatternItem>? journalPatterns,
  }) {
    return TriageHistoryResponse(
      logs: logs ?? this.logs,
      physicalSummary: physicalSummary ?? this.physicalSummary,
      emotionalSummary: emotionalSummary ?? this.emotionalSummary,
      journalPatterns: journalPatterns ?? this.journalPatterns,
    );
  }

  factory TriageHistoryResponse.empty() {
    return const TriageHistoryResponse(
      logs: [],
      physicalSummary: {},
      emotionalSummary: [],
      journalPatterns: [],
    );
  }

  @Deprecated('Use journalPatterns')
  List<JournalPatternItem> get criticalRecurrences => journalPatterns;
}
