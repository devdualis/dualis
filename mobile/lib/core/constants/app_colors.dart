import 'package:flutter/material.dart';

class AppColors {
  // Official Dualis Brand Palette (Manual de Uso da Marca Dualis - Setembro 2026)
  /// Nome "Dualis" (#0E3E6C) - Logotipo e textos institucionais de destaque
  static const Color dualisNavy = Color(0xFF0E3E6C);

  /// Símbolo — azul (#0B83C9) - Segmentos azulados do símbolo
  static const Color dualisSymbolBlue = Color(0xFF0B83C9);

  /// Símbolo — ciano (#26B7D7) - Transição do símbolo
  static const Color dualisSymbolCyan = Color(0xFF26B7D7);

  /// Símbolo — verde (#66BE71) - Segmentos verdes do símbolo
  static const Color dualisSymbolGreen = Color(0xFF66BE71);

  /// Tagline (#2B9ED0) - "continuous check up"
  static const Color dualisTagline = Color(0xFF2B9ED0);

  // Recommended Brand Backgrounds (Manual Section 5)
  static const Color brandBgWhite = Color(0xFFFFFFFF);
  static const Color brandBgLightGray = Color(0xFFF8FAFC);
  static const Color brandBgLightBlue = Color(0xFFF0F7FB);
  static const Color brandBgDarkNavy = Color(0xFF0E3E6C);

  // Harmonized Brand Anchors
  static const Color softIndigo = Color(0xFF0E3E6C);
  static const Color softIndigoDark = Color(0xFF092847);
  static const Color softIndigoLight = Color(0xFFE6F0F8);

  static const Color clinicalTeal = Color(0xFF0B83C9);
  static const Color clinicalTealDark = Color(0xFF085B8C);
  static const Color clinicalTealLight = Color(0xFFE0F4FB);

  static const Color emergencyCrimson = Color(0xFFD32F2F);
  static const Color emergencyDarkRed = Color(0xFFB71C1C);
  static const Color emergencySurfaceRed = Color(0xFFFFEBEE);
  static const Color emergencyTextDark = Color(0xFF5A0C0C);

  // Surfaces & Backgrounds
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0F172A);

  // Text & Typography Neutrals
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Borders & Dividers
  static const Color outlineLight = Color(0xFFE2E8F0);
  static const Color outlineDark = Color(0xFF334155);

  // Clinical Intensity & Heat Scale Palette (Single Source of Truth)
  /// Tier 0: Sem dor / Ausência de sintomas
  static const Color intensityNone = Color(0xFFCFD8DC);
  static const Color intensityNoneText = Color(0xFF37474F);
  static const Color intensityNoneBg = Color(0xFFF5F7F8);
  static const Color intensityNoneBorder = Color(0xFFCFD8DC);

  /// Tier 1-2: Leve
  static const Color intensityMild = Color(0xFFFFD54F);
  static const Color intensityMildText = Color(0xFF3E2723);
  static const Color intensityMildBg = Color(0xFFFFFDE7);
  static const Color intensityMildBorder = Color(0xFFFFE082);

  /// Tier 3: Moderada
  static const Color intensityModerate = Color(0xFFFF8A65);
  static const Color intensityModerateText = Color(0xFFFFFFFF);
  static const Color intensityModerateBg = Color(0xFFFBE9E7);
  static const Color intensityModerateBorder = Color(0xFFFFAB91);

  /// Tier 4-5: Intensa / Crítico
  static const Color intensityIntense = Color(0xFFE53935);
  static const Color intensityIntenseText = Color(0xFFFFFFFF);
  static const Color intensityIntenseBg = Color(0xFFFFEBEE);
  static const Color intensityIntenseBorder = Color(0xFFEF9A9A);
}
