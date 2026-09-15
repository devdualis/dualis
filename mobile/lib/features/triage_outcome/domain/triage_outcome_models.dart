enum CareDisposition {
  selfCare('auto_cuidado'),
  routineConsultation('consulta_rotina'),
  urgentCare('pronto_atendimento'),
  emergency('emergencia');

  final String code;
  const CareDisposition(this.code);

  static CareDisposition fromCode(String? code) {
    return CareDisposition.values.firstWhere(
      (e) => e.code == code,
      orElse: () => CareDisposition.routineConsultation,
    );
  }
}

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
  final CareDisposition careDisposition;
  final String primaryCategory;
  final String categoryLabel;
  final String somaticMapping;
  final bool organicPrimacyApplied;
  final String? organicPrimacyNotice;
  final List<RecommendedArticle> recommendedArticles;
  final DateTime recordedAt;
  final String? secondaryCategoryLabel;
  final String? secondarySomaticMapping;
  final int? secondaryIntensityScore;
  final String? aiMappedLayTerm;
  final String? aiClinicalConcept;
  final String? aiSource;
  final double? aiConfidence;

  const TriageOutcome({
    required this.id,
    required this.vertical,
    required this.intensityScore,
    required this.careDisposition,
    required this.primaryCategory,
    required this.categoryLabel,
    required this.somaticMapping,
    required this.organicPrimacyApplied,
    this.organicPrimacyNotice,
    required this.recommendedArticles,
    required this.recordedAt,
    this.secondaryCategoryLabel,
    this.secondarySomaticMapping,
    this.secondaryIntensityScore,
    this.aiMappedLayTerm,
    this.aiClinicalConcept,
    this.aiSource,
    this.aiConfidence,
  });

  factory TriageOutcome.fromJson(Map<String, dynamic> json) {
    return TriageOutcome(
      id: json['id'] as String? ?? '',
      vertical: json['vertical'] as String? ?? 'physical',
      intensityScore: (json['intensityScore'] as num?)?.toInt() ?? 2,
      careDisposition: CareDisposition.fromCode(json['careDisposition'] as String?),
      primaryCategory: json['primaryCategory'] as String? ?? '',
      categoryLabel: json['categoryLabel'] as String? ?? '',
      somaticMapping: json['somaticMapping'] as String? ?? '',
      organicPrimacyApplied: json['organicPrimacyApplied'] as bool? ?? false,
      organicPrimacyNotice: json['organicPrimacyNotice'] as String?,
      recommendedArticles: (json['recommendedArticles'] as List<dynamic>?)
              ?.map((item) => RecommendedArticle.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      recordedAt: DateTime.tryParse(json['recordedAt'] as String? ?? '') ?? DateTime.now(),
      secondaryCategoryLabel: json['secondaryCategoryLabel'] as String?,
      secondarySomaticMapping: json['secondarySomaticMapping'] as String?,
      secondaryIntensityScore: (json['secondaryIntensityScore'] as num?)?.toInt(),
      aiMappedLayTerm: json['aiMappedLayTerm'] as String?,
      aiClinicalConcept: json['aiClinicalConcept'] as String?,
      aiSource: json['aiSource'] as String?,
      aiConfidence: (json['aiConfidence'] as num?)?.toDouble(),
    );
  }

  TriageOutcome copyWith({
    String? id,
    String? vertical,
    int? intensityScore,
    CareDisposition? careDisposition,
    String? primaryCategory,
    String? categoryLabel,
    String? somaticMapping,
    bool? organicPrimacyApplied,
    String? organicPrimacyNotice,
    List<RecommendedArticle>? recommendedArticles,
    DateTime? recordedAt,
    String? secondaryCategoryLabel,
    String? secondarySomaticMapping,
    int? secondaryIntensityScore,
    String? aiMappedLayTerm,
    String? aiClinicalConcept,
    String? aiSource,
    double? aiConfidence,
  }) {
    return TriageOutcome(
      id: id ?? this.id,
      vertical: vertical ?? this.vertical,
      intensityScore: intensityScore ?? this.intensityScore,
      careDisposition: careDisposition ?? this.careDisposition,
      primaryCategory: primaryCategory ?? this.primaryCategory,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      somaticMapping: somaticMapping ?? this.somaticMapping,
      organicPrimacyApplied: organicPrimacyApplied ?? this.organicPrimacyApplied,
      organicPrimacyNotice: organicPrimacyNotice ?? this.organicPrimacyNotice,
      recommendedArticles: recommendedArticles ?? this.recommendedArticles,
      recordedAt: recordedAt ?? this.recordedAt,
      secondaryCategoryLabel: secondaryCategoryLabel ?? this.secondaryCategoryLabel,
      secondarySomaticMapping: secondarySomaticMapping ?? this.secondarySomaticMapping,
      secondaryIntensityScore: secondaryIntensityScore ?? this.secondaryIntensityScore,
      aiMappedLayTerm: aiMappedLayTerm ?? this.aiMappedLayTerm,
      aiClinicalConcept: aiClinicalConcept ?? this.aiClinicalConcept,
      aiSource: aiSource ?? this.aiSource,
      aiConfidence: aiConfidence ?? this.aiConfidence,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'vertical': vertical,
        'intensityScore': intensityScore,
        'careDisposition': careDisposition.code,
        'primaryCategory': primaryCategory,
        'categoryLabel': categoryLabel,
        'somaticMapping': somaticMapping,
        'organicPrimacyApplied': organicPrimacyApplied,
        'organicPrimacyNotice': organicPrimacyNotice,
        'recommendedArticles': recommendedArticles.map((a) => a.toJson()).toList(),
        'recordedAt': recordedAt.toIso8601String(),
        if (secondaryCategoryLabel != null) 'secondaryCategoryLabel': secondaryCategoryLabel,
        if (secondarySomaticMapping != null) 'secondarySomaticMapping': secondarySomaticMapping,
        if (secondaryIntensityScore != null) 'secondaryIntensityScore': secondaryIntensityScore,
        if (aiMappedLayTerm != null) 'aiMappedLayTerm': aiMappedLayTerm,
        if (aiClinicalConcept != null) 'aiClinicalConcept': aiClinicalConcept,
        if (aiSource != null) 'aiSource': aiSource,
        if (aiConfidence != null) 'aiConfidence': aiConfidence,
      };
}
