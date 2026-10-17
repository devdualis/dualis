class RecommendedArticle {
  final String id;
  final String title;
  final String category;
  final String author;
  final String authorRole;
  final int readTimeMinutes;
  final String summary;
  final String url;

  const RecommendedArticle({
    required this.id,
    required this.title,
    required this.category,
    required this.author,
    required this.authorRole,
    required this.readTimeMinutes,
    required this.summary,
    required this.url,
  });

  factory RecommendedArticle.fromJson(Map<String, dynamic> json) {
    return RecommendedArticle(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      author: json['author'] as String? ?? '',
      authorRole: json['authorRole'] as String? ?? '',
      readTimeMinutes: (json['readTimeMinutes'] as num?)?.toInt() ?? 3,
      summary: json['summary'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'author': author,
        'authorRole': authorRole,
        'readTimeMinutes': readTimeMinutes,
        'summary': summary,
        'url': url,
      };
}

class TriageOutcome {
  final String id;
  final String vertical;
  final int intensityScore;
  final String primaryCategory;
  final String categoryLabel;
  final String somaticMapping;
  /// True when body and emotional entries exist the same day (static note only).
  final bool loggedBothAxesToday;
  final List<RecommendedArticle> recommendedArticles;
  final DateTime recordedAt;
  final String? secondaryCategoryLabel;
  final String? secondarySomaticMapping;
  final int? secondaryIntensityScore;
  final String? aiMappedLayTerm;
  final String? aiBodyAreaOrMood;
  final String? aiSource;
  final double? aiConfidence;
  final bool isCrossVerticalSomatic;
  final String? crossVerticalContextNote;

  const TriageOutcome({
    required this.id,
    required this.vertical,
    required this.intensityScore,
    required this.primaryCategory,
    required this.categoryLabel,
    required this.somaticMapping,
    this.loggedBothAxesToday = false,
    required this.recommendedArticles,
    required this.recordedAt,
    this.secondaryCategoryLabel,
    this.secondarySomaticMapping,
    this.secondaryIntensityScore,
    this.aiMappedLayTerm,
    this.aiBodyAreaOrMood,
    this.aiSource,
    this.aiConfidence,
    this.isCrossVerticalSomatic = false,
    this.crossVerticalContextNote,
  });

  factory TriageOutcome.fromJson(Map<String, dynamic> json) {
    final hasSecondary = json['secondaryCategoryLabel'] != null;

    return TriageOutcome(
      id: json['id'] as String? ?? '',
      vertical: json['vertical'] as String? ?? 'physical',
      intensityScore: (json['intensityScore'] as num?)?.toInt() ?? 2,
      primaryCategory: json['primaryCategory'] as String? ?? '',
      categoryLabel: json['categoryLabel'] as String? ?? '',
      somaticMapping: json['somaticMapping'] as String? ?? '',
      loggedBothAxesToday: (json['loggedBothAxesToday'] as bool?) ?? hasSecondary,
      recommendedArticles: (json['recommendedArticles'] as List<dynamic>?)
              ?.map((item) => RecommendedArticle.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      recordedAt: DateTime.tryParse(json['recordedAt'] as String? ?? '') ?? DateTime.now(),
      secondaryCategoryLabel: json['secondaryCategoryLabel'] as String?,
      secondarySomaticMapping: json['secondarySomaticMapping'] as String?,
      secondaryIntensityScore: (json['secondaryIntensityScore'] as num?)?.toInt(),
      aiMappedLayTerm: json['aiMappedLayTerm'] as String? ?? json['layTerm'] as String?,
      aiBodyAreaOrMood:
          json['aiBodyAreaOrMood'] as String? ?? json['bodyAreaOrMood'] as String?,
      aiSource: json['aiSource'] as String?,
      aiConfidence: (json['aiConfidence'] as num?)?.toDouble(),
      isCrossVerticalSomatic: json['isCrossVerticalSomatic'] as bool? ?? false,
      crossVerticalContextNote: json['crossVerticalContextNote'] as String?,
    );
  }

  TriageOutcome copyWith({
    String? id,
    String? vertical,
    int? intensityScore,
    String? primaryCategory,
    String? categoryLabel,
    String? somaticMapping,
    bool? loggedBothAxesToday,
    List<RecommendedArticle>? recommendedArticles,
    DateTime? recordedAt,
    String? secondaryCategoryLabel,
    String? secondarySomaticMapping,
    int? secondaryIntensityScore,
    String? aiMappedLayTerm,
    String? aiBodyAreaOrMood,
    String? aiSource,
    double? aiConfidence,
    bool? isCrossVerticalSomatic,
    String? crossVerticalContextNote,
  }) {
    return TriageOutcome(
      id: id ?? this.id,
      vertical: vertical ?? this.vertical,
      intensityScore: intensityScore ?? this.intensityScore,
      primaryCategory: primaryCategory ?? this.primaryCategory,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      somaticMapping: somaticMapping ?? this.somaticMapping,
      loggedBothAxesToday: loggedBothAxesToday ?? this.loggedBothAxesToday,
      recommendedArticles: recommendedArticles ?? this.recommendedArticles,
      recordedAt: recordedAt ?? this.recordedAt,
      secondaryCategoryLabel: secondaryCategoryLabel ?? this.secondaryCategoryLabel,
      secondarySomaticMapping: secondarySomaticMapping ?? this.secondarySomaticMapping,
      secondaryIntensityScore: secondaryIntensityScore ?? this.secondaryIntensityScore,
      aiMappedLayTerm: aiMappedLayTerm ?? this.aiMappedLayTerm,
      aiBodyAreaOrMood: aiBodyAreaOrMood ?? this.aiBodyAreaOrMood,
      aiSource: aiSource ?? this.aiSource,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      isCrossVerticalSomatic: isCrossVerticalSomatic ?? this.isCrossVerticalSomatic,
      crossVerticalContextNote: crossVerticalContextNote ?? this.crossVerticalContextNote,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'vertical': vertical,
        'intensityScore': intensityScore,
        'primaryCategory': primaryCategory,
        'categoryLabel': categoryLabel,
        'somaticMapping': somaticMapping,
        'loggedBothAxesToday': loggedBothAxesToday,
        'recommendedArticles': recommendedArticles.map((a) => a.toJson()).toList(),
        'recordedAt': recordedAt.toIso8601String(),
        if (secondaryCategoryLabel != null) 'secondaryCategoryLabel': secondaryCategoryLabel,
        if (secondarySomaticMapping != null) 'secondarySomaticMapping': secondarySomaticMapping,
        if (secondaryIntensityScore != null) 'secondaryIntensityScore': secondaryIntensityScore,
        if (aiMappedLayTerm != null) 'aiMappedLayTerm': aiMappedLayTerm,
        if (aiBodyAreaOrMood != null) 'aiBodyAreaOrMood': aiBodyAreaOrMood,
        if (aiSource != null) 'aiSource': aiSource,
        if (aiConfidence != null) 'aiConfidence': aiConfidence,
        if (isCrossVerticalSomatic) 'isCrossVerticalSomatic': isCrossVerticalSomatic,
        if (crossVerticalContextNote != null) 'crossVerticalContextNote': crossVerticalContextNote,
      };
}
