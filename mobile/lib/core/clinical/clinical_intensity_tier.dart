import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_colors.dart';

/// Single Source of Truth for clinical intensity levels and pain scales across Dualis.
///
/// Standardized 4-tier clinical scale:
/// - [none]: Score 0 ("Sem dor")
/// - [mild]: Scores 1-2 ("Leve (1-2)")
/// - [moderate]: Score 3 ("Moderada (3)")
/// - [intense]: Scores 4-5 ("Intensa (4-5)")
enum ClinicalIntensityTier {
  none(
    scoreMin: 0,
    scoreMax: 0,
    label: 'Sem dor',
    color: AppColors.intensityNone,
    textColor: AppColors.intensityNoneText,
    cardBgColor: AppColors.intensityNoneBg,
    borderColor: AppColors.intensityNoneBorder,
  ),
  mild(
    scoreMin: 1,
    scoreMax: 2,
    label: 'Leve (1-2)',
    color: AppColors.intensityMild,
    textColor: AppColors.intensityMildText,
    cardBgColor: AppColors.intensityMildBg,
    borderColor: AppColors.intensityMildBorder,
  ),
  moderate(
    scoreMin: 3,
    scoreMax: 3,
    label: 'Moderada (3)',
    color: AppColors.intensityModerate,
    textColor: AppColors.intensityModerateText,
    cardBgColor: AppColors.intensityModerateBg,
    borderColor: AppColors.intensityModerateBorder,
  ),
  intense(
    scoreMin: 4,
    scoreMax: 5,
    label: 'Intensa (4-5)',
    color: AppColors.intensityIntense,
    textColor: AppColors.intensityIntenseText,
    cardBgColor: AppColors.intensityIntenseBg,
    borderColor: AppColors.intensityIntenseBorder,
  );

  const ClinicalIntensityTier({
    required this.scoreMin,
    required this.scoreMax,
    required this.label,
    required this.color,
    required this.textColor,
    required this.cardBgColor,
    required this.borderColor,
  });

  final int scoreMin;
  final int scoreMax;
  final String label;
  final Color color;
  final Color textColor;
  final Color cardBgColor;
  final Color borderColor;

  /// True when the intensity reaches acute / emergency critical thresholds (scores 4-5).
  bool get isCritical => this == ClinicalIntensityTier.intense;

  /// Human-readable score range representation (e.g., '0', '1-2', '3', '4-5').
  String get scoreRangeDescription {
    if (scoreMin == scoreMax) return '$scoreMin';
    return '$scoreMin-$scoreMax';
  }

  /// Whether a specific numerical score falls into this tier.
  bool containsScore(int score) => score >= scoreMin && score <= scoreMax;

  /// Returns the localized label if [AppLocalizations] is available in [context],
  /// otherwise returns the canonical Brazilian Portuguese [label].
  String localizedLabel(BuildContext? context) {
    if (context == null) return label;
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case ClinicalIntensityTier.none:
        return l10n.heatLegendNone;
      case ClinicalIntensityTier.mild:
        return l10n.heatLegendMild;
      case ClinicalIntensityTier.moderate:
        return l10n.heatLegendModerate;
      case ClinicalIntensityTier.intense:
        return l10n.heatLegendSevere;
    }
  }

  /// Resolves the canonical tier from an integer score (0 to 5).
  ///
  /// - `<= 0` -> [ClinicalIntensityTier.none]
  /// - `1..2` -> [ClinicalIntensityTier.mild]
  /// - `3`    -> [ClinicalIntensityTier.moderate]
  /// - `>= 4` -> [ClinicalIntensityTier.intense]
  static ClinicalIntensityTier fromScore(int? score) {
    if (score == null || score <= 0) return ClinicalIntensityTier.none;
    if (score <= 2) return ClinicalIntensityTier.mild;
    if (score == 3) return ClinicalIntensityTier.moderate;
    return ClinicalIntensityTier.intense;
  }

  /// Alias for [fromScore].
  static ClinicalIntensityTier fromIntensity(int? intensity) => fromScore(intensity);
}
