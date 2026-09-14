import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// High-contrast card rendering actionable clinical steps for the patient
/// while waiting for or dispatching emergency assistance.
class EmergencyInstructionsCard extends StatelessWidget {
  final bool isEmotional;

  const EmergencyInstructionsCard({
    super.key,
    required this.isEmotional,
  });

  String _getHeadingText(Locale locale) {
    switch (locale.languageCode) {
      case 'es':
        return 'Qué hacer ahora';
      case 'en':
        return 'What to do now';
      case 'pt':
      default:
        return 'O que fazer agora';
    }
  }

  Widget _buildStepItem({
    required int number,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.emergencyDarkRed,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.emergencyTextDark,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);

    final step1 = isEmotional
        ? loc.emergencyInstructionEmotional1
        : loc.emergencyInstructionPhysical1;
    final step2 = isEmotional
        ? loc.emergencyInstructionEmotional2
        : loc.emergencyInstructionPhysical2;
    final step3 = isEmotional
        ? loc.emergencyInstructionEmotional3
        : loc.emergencyInstructionPhysical3;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.emergencySurfaceRed,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.health_and_safety,
                color: AppColors.emergencyDarkRed,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                _getHeadingText(locale),
                style: const TextStyle(
                  color: AppColors.emergencyTextDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildStepItem(number: 1, text: step1),
          const SizedBox(height: 10),
          _buildStepItem(number: 2, text: step2),
          const SizedBox(height: 10),
          _buildStepItem(number: 3, text: step3),
        ],
      ),
    );
  }
}
