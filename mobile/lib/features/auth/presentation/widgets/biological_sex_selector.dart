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
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.outlineLight, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.hardEdge,
          child: IntrinsicHeight(
            child: Row(
              children: [
                _GenderOption(
                  label: 'Masculino',
                  icon: Icons.male_rounded,
                  value: Gender.masculino,
                  selected: selectedGender == Gender.masculino,
                  onTap: () => onGenderChanged(Gender.masculino),
                  isFirst: true,
                ),
                _Divider(visible: selectedGender != Gender.masculino && selectedGender != Gender.feminino),
                _GenderOption(
                  label: 'Feminino',
                  icon: Icons.female_rounded,
                  value: Gender.feminino,
                  selected: selectedGender == Gender.feminino,
                  onTap: () => onGenderChanged(Gender.feminino),
                ),
                _Divider(visible: selectedGender != Gender.feminino && selectedGender != Gender.outro),
                _GenderOption(
                  label: 'Outro',
                  icon: Icons.person_outline_rounded,
                  value: Gender.outro,
                  selected: selectedGender == Gender.outro,
                  onTap: () => onGenderChanged(Gender.outro),
                  isLast: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  final bool visible;
  const _Divider({required this.visible});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 1,
      color: visible ? AppColors.outlineLight : Colors.transparent,
    );
  }
}

class _GenderOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Gender value;
  final bool selected;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _GenderOption({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.horizontal(
      left: isFirst ? const Radius.circular(11) : Radius.zero,
      right: isLast ? const Radius.circular(11) : Radius.zero,
    );

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        color: selected ? AppColors.softIndigo : Colors.transparent,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            splashColor: AppColors.softIndigo.withValues(alpha: 0.15),
            highlightColor: AppColors.softIndigo.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: selected ? Colors.white : AppColors.textSecondaryLight,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? Colors.white : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
