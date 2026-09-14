import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Fallback modal displayed on tablets or devices lacking telephony hardware/dialers.
/// Displays the emergency phone number in large 36pt font with a 1-tap clipboard copy button.
class TelephonyFallbackDialog extends StatelessWidget {
  final String phoneNumber;
  final String? serviceName;

  const TelephonyFallbackDialog({
    super.key,
    required this.phoneNumber,
    this.serviceName,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      icon: const Icon(
        Icons.phone_disabled_rounded,
        color: AppColors.emergencyDarkRed,
        size: 36,
      ),
      title: Text(
        serviceName != null
            ? '${loc.emergencyFallbackTitle} ($serviceName)'
            : loc.emergencyFallbackTitle,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.emergencyDarkRed,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            loc.emergencyFallbackBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.emergencySurfaceRed,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.emergencyCrimson.withValues(alpha: 0.3)),
            ),
            child: Text(
              phoneNumber,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                color: AppColors.emergencyDarkRed,
              ),
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: phoneNumber));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(loc.emergencyCopiedToast),
                    duration: const Duration(seconds: 2),
                    backgroundColor: AppColors.emergencyDarkRed,
                  ),
                );
                Navigator.of(context).pop();
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emergencyCrimson,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.copy, size: 18),
            label: Text(
              loc.emergencyCopyNumber,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
