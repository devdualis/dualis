import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../journal/presentation/journal_labels.dart';

/// Visual tokens of handoff "Dualis | Gráficos do aplicativo" v2.0. Colour
/// tells a series apart; it never grades how strong or serious it is.
class ChartTokens {
  ChartTokens._();

  /// The three times take the brand navy, cyan and green.
  static const Color passado = AppColors.dualisNavy;
  static const Color presente = AppColors.dualisSymbolCyan;
  static const Color futuro = AppColors.dualisSymbolGreen;

  /// Good moments of a "Bem" entry (v2.2).
  static const Color good = Color(0xFF2E9E5B);

  /// Emotional record without an axis (never inferred).
  static const Color neutral = AppColors.textSecondaryDark;

  static const Map<String, Color> regions = {
    'cabeca': Color(0xFF537FB8),
    'peito': Color(0xFFA17BB1),
    'barriga': Color(0xFFD69A44),
    'pelve': Color(0xFFB0705A),
    'costas': Color(0xFF268E82),
    'membros': Color(0xFF7F8F54),
    // Nine regions need nine distinct hues, more than the brand palette has;
    // these stay muted so they sit quietly next to the brand colours.
    // Whole-body areas are not in the handoff either.
    'pele': Color(0xFFC0657E),
    'musculos': Color(0xFF7A6A58),
    'hormonios': Color(0xFF4A5D8F),
  };

  /// C1 figure and drop.
  static const Color body = Color(0xFF536E89);
  static const Color water = AppColors.dualisSymbolBlue;
  static const Color waterTrack = AppColors.iconTileTint;

  /// Grid lines and axis labels: navy hairlines and the muted text colour.
  static Color get grid => AppColors.dualisNavy.withValues(alpha: 0.08);
  static const Color axisLabel = AppColors.textSecondaryLight;

  static Color time(String key) => switch (key) {
        'passado' => passado,
        'presente' => presente,
        'futuro' => futuro,
        _ => neutral,
      };

  static Color region(String key) => regions[key] ?? neutral;
}

/// Name of a time or region for a chart legend.
String seriesLabel(AppLocalizations l10n, String key) =>
    JournalLabels.time(l10n, key) ?? JournalLabels.region(l10n, key) ?? key;
