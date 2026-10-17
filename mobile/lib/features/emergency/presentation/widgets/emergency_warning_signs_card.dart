import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Static list of public warning signs (same for everyone) with its source.
class EmergencyWarningSignsCard extends StatelessWidget {
  final String emergencyNumber;

  const EmergencyWarningSignsCard({super.key, required this.emergencyNumber});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final signs = [
      loc.safetyWarningSign1,
      loc.safetyWarningSign2,
      loc.safetyWarningSign3,
      loc.safetyWarningSign4,
      loc.safetyWarningSign5,
      loc.safetyWarningSign6,
    ];

    return Container(
      key: const Key('emergency_warning_signs_card'),
      decoration: BoxDecoration(
        color: AppColors.emergencySurfaceRed,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.safetyWarningSignsTitle(emergencyNumber),
            style: const TextStyle(
              color: AppColors.emergencyTextDark,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          for (final sign in signs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 7, color: AppColors.emergencyDarkRed),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      sign,
                      style: const TextStyle(
                        color: AppColors.emergencyTextDark,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text(
            loc.safetyWarningSignsSource,
            style: TextStyle(
              color: AppColors.emergencyTextDark.withValues(alpha: 0.75),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
