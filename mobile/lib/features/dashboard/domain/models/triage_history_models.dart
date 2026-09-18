class TriageHistoryEntry {
  final String id;
  final int intensity;
  final String? anatomicalSystem;
  final String? emotionalDimension;
  final String? disposition;
  final bool organicPrimacyApplied;
  final String? narrative;
  final Map<String, dynamic>? stepAnswers;
  final DateTime recordedAt;

  const TriageHistoryEntry({
    required this.id,
    required this.intensity,
    this.anatomicalSystem,
    this.emotionalDimension,
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
      'disposition': disposition,
      'organicPrimacyApplied': organicPrimacyApplied,
      if (narrative != null) 'narrative': narrative,
      'stepAnswers': stepAnswers,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }
}

class CriticalRecurrenceItem {
  final String id;
  final String vertical;
  final String category;
  final String categoryLabel;
  final String title;
  final String description;
  final int intensity;
  final int frequencyCount;
  final int windowDays;
  final String recommendedArticleTitle;
  final String recommendedArticleUrl;

  const CriticalRecurrenceItem({
    required this.id,
    required this.vertical,
    required this.category,
    required this.categoryLabel,
    required this.title,
    required this.description,
    required this.intensity,
    required this.frequencyCount,
    required this.windowDays,
    required this.recommendedArticleTitle,
    required this.recommendedArticleUrl,
  });

  factory CriticalRecurrenceItem.fromJson(Map<String, dynamic> json) {
    return CriticalRecurrenceItem(
      id: json['id'] as String,
      vertical: json['vertical'] as String,
      category: json['category'] as String,
      categoryLabel: json['categoryLabel'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      intensity: (json['intensity'] as num).toInt(),
      frequencyCount: (json['frequencyCount'] as num).toInt(),
      windowDays: (json['windowDays'] as num).toInt(),
      recommendedArticleTitle: json['recommendedArticleTitle'] as String,
      recommendedArticleUrl: json['recommendedArticleUrl'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vertical': vertical,
      'category': category,
      'categoryLabel': categoryLabel,
      'title': title,
      'description': description,
      'intensity': intensity,
      'frequencyCount': frequencyCount,
      'windowDays': windowDays,
      'recommendedArticleTitle': recommendedArticleTitle,
      'recommendedArticleUrl': recommendedArticleUrl,
    };
  }
}

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
  final List<CriticalRecurrenceItem> criticalRecurrences;

  const TriageHistoryResponse({
    required this.logs,
    required this.physicalSummary,
    required this.emotionalSummary,
    required this.criticalRecurrences,
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

    final rawRec = json['criticalRecurrences'] as List<dynamic>? ?? [];
    final criticalRecurrences = rawRec
        .map((e) => CriticalRecurrenceItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return TriageHistoryResponse(
      logs: logs,
      physicalSummary: physicalSummary,
      emotionalSummary: emotionalSummary,
      criticalRecurrences: criticalRecurrences,
    );
  }

  factory TriageHistoryResponse.empty() {
    return const TriageHistoryResponse(
      logs: [],
      physicalSummary: {},
      emotionalSummary: [],
      criticalRecurrences: [],
    );
  }
}
