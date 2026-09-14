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
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<Gender>(
            segments: const [
              ButtonSegment<Gender>(
                value: Gender.masculino,
                label: Text('Masculino'),
                icon: Icon(Icons.male, size: 18),
              ),
              ButtonSegment<Gender>(
                value: Gender.feminino,
                label: Text('Feminino'),
                icon: Icon(Icons.female, size: 18),
              ),
              ButtonSegment<Gender>(
                value: Gender.outro,
                label: Text('Outro'),
                icon: Icon(Icons.person_outline, size: 18),
              ),
            ],
            selected: {selectedGender},
            onSelectionChanged: (Set<Gender> newSelection) {
              if (newSelection.isNotEmpty) {
                onGenderChanged(newSelection.first);
              }
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.comfortable,
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
