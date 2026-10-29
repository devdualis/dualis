import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../journal/presentation/journal_labels.dart';

/// Visual tokens of handoff "Dualis | Gráficos do aplicativo" v2.0. Colour
/// tells a series apart; it never grades how strong or serious it is.
class ChartTokens {
  ChartTokens._();

  static const Color passado = Color(0xFF8055AD);
  static const Color presente = Color(0xFF178779);
  static const Color futuro = Color(0xFFDE8A28);

  /// Emotional record without an axis (never inferred).
  static const Color neutral = Color(0xFF94A3B8);

  static const Map<String, Color> regions = {
    'cabeca': Color(0xFF537FB8),
    'peito': Color(0xFFA17BB1),
    'barriga': Color(0xFFD69A44),
    'costas': Color(0xFF268E82),
    'membros': Color(0xFF7F8F54),
    // Whole-body areas are not in the handoff; muted, distinct hues.
    'pele': Color(0xFFC0657E),
    'musculos': Color(0xFF7A6A58),
    'hormonios': Color(0xFF4A5D8F),
  };

  /// C1 figure and drop.
  static const Color body = Color(0xFF536E89);
  static const Color water = Color(0xFF278DC1);
  static const Color waterTrack = Color(0xFFE3ECF4);

  /// Neutral silhouette of the body map (F1).
  static const Color silhouette = Color(0xFFDCE4EC);
  static const Color silhouetteOutline = Color(0xFFB8C6D4);

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
