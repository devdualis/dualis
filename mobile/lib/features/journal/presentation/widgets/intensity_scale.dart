import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/voice/voice_matcher.dart';
import '../../../../core/voice/voice_targets.dart';
import '../../../../l10n/app_localizations.dart';

/// Shade of the single-hue intensity scale (light to strong). Not a traffic
/// light: no level is shown as good or bad.
Color intensityShade(int level) =>
    AppColors.dualisSymbolBlue.withValues(alpha: 0.18 + 0.16 * (level - 1));

/// Self-reported description of a level (strategy section 8).
String intensityText(AppLocalizations l10n, int level, {required bool physical}) {
  if (physical) {
    switch (level) {
      case 1:
        return l10n.jv2IntensityPhysical1;
      case 2:
        return l10n.jv2IntensityPhysical2;
      case 3:
        return l10n.jv2IntensityPhysical3;
      case 4:
        return l10n.jv2IntensityPhysical4;
      default:
        return l10n.jv2IntensityPhysical5;
    }
  }
  switch (level) {
    case 1:
      return l10n.jv2IntensityEmotional1;
    case 2:
      return l10n.jv2IntensityEmotional2;
    case 3:
      return l10n.jv2IntensityEmotional3;
    case 4:
      return l10n.jv2IntensityEmotional4;
    default:
      return l10n.jv2IntensityEmotional5;
  }
}

/// Short name of a level, the same on the emotional and the physical scale
/// (client wording where it is not alarming; strategy section 8). A word the
/// person picks for themselves; the app never grades it.
String intensityName(AppLocalizations l10n, int level) => switch (level) {
      1 => l10n.jv25IntensityName1,
      2 => l10n.jv25IntensityName2,
      3 => l10n.jv25IntensityName3,
      4 => l10n.jv25IntensityName4,
      _ => l10n.jv25IntensityName5,
    };

/// "3 · Desgastante": the number and its name.
String intensityTitle(AppLocalizations l10n, int level) =>
    '$level · ${intensityName(l10n, level)}';

/// What can be said to pick [level]: the number, its words ("três") and
/// its description ("Forte").
List<String> intensityVoiceLabels(AppLocalizations l10n, int level, {required bool physical}) {
  return [
    ...intensityNumberLabels(l10n, level),
    intensityName(l10n, level),
    intensityText(l10n, level, physical: physical),
  ];
}

/// What picks [level] in a phrase carried from an earlier step: only its
/// number ("3", "três", "3 de 5"), never a word of its description.
List<String> intensityNumberLabels(AppLocalizations l10n, int level) {
  final words = VoiceMatcher.aliases(l10n.voiceNumberWords);
  return [
    '$level',
    if (level <= words.length) ...words[level - 1].split(','),
    l10n.jv2IntensityLevel(level),
  ];
}

/// Big 1-5 scale (single item, v2.3): five numbers, and the description of
/// the chosen level in a box underneath. Before a choice, the box says how
/// the scale works.
class IntensityScaleFull extends StatelessWidget {
  final int? value;
  final bool physical;
  final ValueChanged<int> onChanged;
  final String keyPrefix;

  /// Pickable by voice (only one row of a compact list at a time).
  final bool voice;

  const IntensityScaleFull({
    super.key,
    required this.value,
    required this.physical,
    required this.onChanged,
    this.keyPrefix = 'jv2_intensity',
    this.voice = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Zero-size voice targets; the Row below keeps its spacing.
        for (var level = 1; level <= 5; level++)
          VoiceTarget(
            labels: intensityVoiceLabels(l10n, level, physical: physical),
            carryLabels: intensityNumberLabels(l10n, level),
            onSelect: voice ? () => onChanged(level) : null,
            child: const SizedBox.shrink(),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 8, 2, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var level = 1; level <= 5; level++) ...[
                if (level > 1) const SizedBox(width: 8),
                Expanded(
                  child: Semantics(
                    selected: value == level,
                    button: true,
                    label: '${l10n.jv2IntensityLevel(level)}, ${intensityName(l10n, level)}: '
                        '${intensityText(l10n, level, physical: physical)}',
                    excludeSemantics: true,
                    child: InkWell(
                      key: Key('${keyPrefix}_$level'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onChanged(level),
                      child: _LevelBar(level: level, value: value, unit: 12, base: 10),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          key: Key('${keyPrefix}_text'),
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: value == null
                ? AppColors.dualisNavy.withValues(alpha: 0.05)
                : AppColors.iconTileTint,
            borderRadius: BorderRadius.circular(16),
          ),
          child: value == null
              ? Text(
                  l10n.jv23IntensityPickHint,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryLight,
                    height: 1.3,
                  ),
                )
              : _LevelText(level: value!, physical: physical, fontSize: 14),
        ),
      ],
    );
  }
}

/// Compact row of 5 dots (one item per row).
class IntensityScaleCompact extends StatelessWidget {
  final int? value;
  final bool physical;
  final ValueChanged<int> onChanged;
  final String keyPrefix;

  /// Pickable by voice (only one row of a compact list at a time).
  final bool voice;

  const IntensityScaleCompact({
    super.key,
    required this.value,
    required this.physical,
    required this.onChanged,
    required this.keyPrefix,
    this.voice = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Zero-size voice targets; the Row below keeps its spacing.
        for (var level = 1; level <= 5; level++)
          VoiceTarget(
            labels: intensityVoiceLabels(l10n, level, physical: physical),
            carryLabels: intensityNumberLabels(l10n, level),
            onSelect: voice ? () => onChanged(level) : null,
            child: const SizedBox.shrink(),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var level = 1; level <= 5; level++) ...[
              if (level > 1) const SizedBox(width: 6),
              Expanded(
                child: Semantics(
                  selected: value == level,
                  button: true,
                  label: '${l10n.jv2IntensityLevel(level)}, ${intensityName(l10n, level)}',
                  child: InkWell(
                    key: Key('${keyPrefix}_$level'),
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onChanged(level),
                    child: _LevelBar(level: level, value: value, unit: 7, base: 8),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (value != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.iconTileTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _LevelText(level: value!, physical: physical, fontSize: 13),
          ),
        ],
      ],
    );
  }
}

/// "3 · Desgastante" in bold, then the description of the level.
class _LevelText extends StatelessWidget {
  final int level;
  final bool physical;
  final double fontSize;

  const _LevelText({required this.level, required this.physical, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Text.rich(
      TextSpan(children: [
        TextSpan(
          text: intensityTitle(l10n, level),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        TextSpan(text: ' — ${intensityText(l10n, level, physical: physical)}'),
      ]),
      style: GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: AppColors.dualisNavy,
        height: 1.3,
      ),
    );
  }
}

/// One bar of the 1-5 scale: taller with each level, blue-cyan up to the
/// chosen level and a soft navy tint above it, the number underneath.
class _LevelBar extends StatelessWidget {
  final int level;
  final int? value;

  /// Height of the first bar and the growth per level.
  final double base;
  final double unit;

  const _LevelBar({
    required this.level,
    required this.value,
    required this.base,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final on = value != null && level <= value!;
    final current = value == level;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: base + level * unit,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: on ? AppColors.gradientBlueCyan : null,
            color: on ? null : AppColors.dualisNavy.withValues(alpha: 0.1),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$level',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: current ? FontWeight.w800 : FontWeight.w600,
            color: current ? AppColors.dualisNavy : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

/// Static line shown under every intensity scale, the same for everyone and
/// never depending on what was chosen (strategy sections 8 and 10).
class JournalEmergencyLine extends StatelessWidget {
  const JournalEmergencyLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('jv2_emergency_line'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        AppLocalizations.of(context).jv2EmergencyLine,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}
