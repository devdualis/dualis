import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/user_profile.dart';

class BiologicalSexSelector extends StatelessWidget {
  final Gender selectedGender;
  final ValueChanged<Gender> onGenderChanged;

  const BiologicalSexSelector({
    super.key,
    required this.selectedGender,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sexo Biológico',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _GenderOption(
              label: 'Masculino',
              icon: Icons.male_rounded,
              value: Gender.masculino,
              selected: selectedGender == Gender.masculino,
              onTap: () => onGenderChanged(Gender.masculino),
            ),
            const SizedBox(width: 8),
            _GenderOption(
              label: 'Feminino',
              icon: Icons.female_rounded,
              value: Gender.feminino,
              selected: selectedGender == Gender.feminino,
              onTap: () => onGenderChanged(Gender.feminino),
            ),
            const SizedBox(width: 8),
            _GenderOption(
              label: 'Outro',
              icon: Icons.person_outline_rounded,
              value: Gender.outro,
              selected: selectedGender == Gender.outro,
              onTap: () => onGenderChanged(Gender.outro),
            ),
          ],
        ),
      ],
    );
  }
}

/// Wizard-style option chip: rounded, navy border and cyan tint when selected.
class _GenderOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Gender value;
  final bool selected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: 'Sexo biológico: $label',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            borderRadius: radius,
            color: selected
                ? AppColors.dualisSymbolCyan.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.86),
            border: Border.all(
              color: selected
                  ? AppColors.dualisNavy
                  : AppColors.dualisNavy.withValues(alpha: 0.08),
              width: selected ? 2 : 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: selected
                          ? AppColors.dualisNavy
                          : AppColors.textSecondaryLight,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? AppColors.dualisNavy
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
