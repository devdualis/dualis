import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
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

/// Full 1-5 scale with the description of every level (single item).
class IntensityScaleFull extends StatelessWidget {
  final int? value;
  final bool physical;
  final ValueChanged<int> onChanged;
  final String keyPrefix;

  const IntensityScaleFull({
    super.key,
    required this.value,
    required this.physical,
    required this.onChanged,
    this.keyPrefix = 'jv2_intensity',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var level = 1; level <= 5; level++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Semantics(
              selected: value == level,
              button: true,
              child: InkWell(
                key: Key('${keyPrefix}_$level'),
                borderRadius: BorderRadius.circular(14),
                onTap: () => onChanged(level),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: value == level
                        ? intensityShade(level).withValues(alpha: 0.25)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: value == level
                          ? AppColors.dualisSymbolBlue
                          : AppColors.outlineLight,
                      width: value == level ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      _LevelDot(level: level),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          intensityText(l10n, level, physical: physical),
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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

  const IntensityScaleCompact({
    super.key,
    required this.value,
    required this.physical,
    required this.onChanged,
    required this.keyPrefix,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var level = 1; level <= 5; level++)
              Semantics(
                selected: value == level,
                button: true,
                label: l10n.jv2IntensityLevel(level),
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
          const SizedBox(height: 6),
          Text(
            intensityText(l10n, value!, physical: physical),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ],
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
