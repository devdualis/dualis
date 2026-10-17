import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_colors.dart';

/// Self-reported intensity bands (1–5) for journal entries — not a clinical scale.
enum SelfReportedIntensityBand {
  none(
    scoreMin: 0,
    scoreMax: 0,
    label: 'Sem registro',
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

  const SelfReportedIntensityBand({
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

  String get scoreRangeDescription {
    if (scoreMin == scoreMax) return '$scoreMin';
    return '$scoreMin-$scoreMax';
  }

  bool containsScore(int score) => score >= scoreMin && score <= scoreMax;

  String localizedLabel(BuildContext? context) {
    if (context == null) return label;
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case SelfReportedIntensityBand.none:
        return l10n.heatLegendNone;
      case SelfReportedIntensityBand.mild:
        return l10n.heatLegendMild;
      case SelfReportedIntensityBand.moderate:
        return l10n.heatLegendModerate;
      case SelfReportedIntensityBand.intense:
        return l10n.heatLegendSevere;
    }
  }

  static SelfReportedIntensityBand fromScore(int? score) {
    if (score == null || score <= 0) return SelfReportedIntensityBand.none;
    if (score <= 2) return SelfReportedIntensityBand.mild;
    if (score == 3) return SelfReportedIntensityBand.moderate;
    return SelfReportedIntensityBand.intense;
  }

  static SelfReportedIntensityBand fromIntensity(int? intensity) => fromScore(intensity);

  @Deprecated('Wellness journal does not use critical thresholds')
  bool get isCritical => false;
}
