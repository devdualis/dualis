import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// 1-to-5 visual numeric scale selector used in physical triage Step 2.
class TriageIntensitySelector extends StatelessWidget {
  final int? selectedValue;
  final Color activeColor;
  final ValueChanged<int> onSelect;

  const TriageIntensitySelector({
    super.key,
    required this.selectedValue,
    required this.activeColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selectedValue != null) ...[
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: (selectedValue! >= 4
                        ? AppColors.emergencyCrimson
                        : activeColor)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selectedValue! >= 4
                      ? AppColors.emergencyCrimson
                      : activeColor,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selectedValue! >= 4) ...[
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.emergencyCrimson,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    l10n.triageIntensityLabel(selectedValue!),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selectedValue! >= 4
                          ? AppColors.emergencyCrimson
                          : activeColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ] else
          const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            final value = index + 1;
            final isSelected = selectedValue == value;
            final isCritical = value >= 4;

            final itemColor = isCritical && isSelected
                ? AppColors.emergencyCrimson
                : activeColor;

            return InkWell(
              onTap: () => onSelect(value),
              borderRadius: BorderRadius.circular(28),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isSelected
                      ? itemColor
                      : (isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? itemColor : itemColor.withValues(alpha: 0.4),
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: itemColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$value',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '1: ${l10n.triageIntensityMin}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            Text(
              '5: ${l10n.triageIntensityMax}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
