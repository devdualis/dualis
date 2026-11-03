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
  final words = VoiceMatcher.aliases(l10n.voiceNumberWords);
  return [
    '$level',
    if (level <= words.length) ...words[level - 1].split(','),
    l10n.jv2IntensityLevel(level),
    intensityName(l10n, level),
    intensityText(l10n, level, physical: physical),
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
            onSelect: voice ? () => onChanged(level) : null,
            child: const SizedBox.shrink(),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var level = 1; level <= 5; level++)
              Semantics(
                selected: value == level,
                button: true,
                label: '${l10n.jv2IntensityLevel(level)}, ${intensityName(l10n, level)}: '
                    '${intensityText(l10n, level, physical: physical)}',
                excludeSemantics: true,
                child: InkWell(
                  key: Key('${keyPrefix}_$level'),
                  customBorder: const CircleBorder(),
                  onTap: () => onChanged(level),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: _LevelDot(level: level, selected: value == level, size: 54),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          key: Key('${keyPrefix}_text'),
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: value == null
                ? AppColors.backgroundLight
                : AppColors.dualisSymbolBlue.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: value == null
              ? Text(
                  l10n.jv23IntensityPickHint,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryLight,
                    height: 1.3,
                  ),
                )
              : _LevelText(level: value!, physical: physical, fontSize: 14.5),
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
            onSelect: voice ? () => onChanged(level) : null,
            child: const SizedBox.shrink(),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var level = 1; level <= 5; level++)
              Semantics(
                selected: value == level,
                button: true,
                label: '${l10n.jv2IntensityLevel(level)}, ${intensityName(l10n, level)}',
                child: InkWell(
                  key: Key('${keyPrefix}_$level'),
                  customBorder: const CircleBorder(),
                  onTap: () => onChanged(level),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _LevelDot(level: level, selected: value == level, size: 38),
                  ),
                ),
              ),
          ],
        ),
        if (value != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.dualisSymbolBlue.withValues(alpha: 0.10),
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
      style: GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: AppColors.dualisNavy,
        height: 1.3,
      ),
    );
  }
}

class _LevelDot extends StatelessWidget {
  final int level;
  final bool selected;
  final double size;

  const _LevelDot({required this.level, this.selected = true, this.size = 32});

  @override
  Widget build(BuildContext context) {
    final shade = intensityShade(level);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? shade : Colors.transparent,
        border: Border.all(color: shade, width: 2),
      ),
      child: Text(
        '$level',
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          color: selected && level >= 4 ? Colors.white : AppColors.dualisNavy,
        ),
      ),
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
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}
