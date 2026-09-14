import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/antiburla_remote_data_source.dart';

enum AntiburlaUserChoice {
  recurring,
  newSymptom,
}

class AntiburlaVerificationBottomSheet extends StatelessWidget {
  final AntiburlaCheckResult result;

  const AntiburlaVerificationBottomSheet({
    super.key,
    required this.result,
  });

  static Future<AntiburlaUserChoice?> show(
    BuildContext context, {
    required AntiburlaCheckResult result,
  }) {
    return showModalBottomSheet<AntiburlaUserChoice>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AntiburlaVerificationBottomSheet(result: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final days = result.daysAgo ?? 3;

    final promptText = result.empatheticPrompt ??
        l10n.antiburlaDialogPrompt(days);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top drag handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Icon + Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.clinicalTeal.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: AppColors.clinicalTeal,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l10n.antiburlaTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Empathetic dialog container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.softIndigo.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.softIndigo.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                promptText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimaryLight,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Biological Discordance Alert (if detected)
            if (result.biologicalDiscordance) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: Colors.amber.shade900, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        result.biologicalNotice ??
                            l10n.antiburlaBiologicalDiscordanceDesc,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Binary Choice 1: "É a mesma sensação que voltou"
            FilledButton(
              key: const Key('antiburla_recurring_button'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.clinicalTeal,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () =>
                  Navigator.of(context).pop(AntiburlaUserChoice.recurring),
              child: Column(
                children: [
                  Text(
                    l10n.antiburlaOptionRecurring,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.antiburlaOptionRecurringDesc,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Binary Choice 2: "É um sentimento completamente novo"
            OutlinedButton(
              key: const Key('antiburla_new_button'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.softIndigo, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () =>
                  Navigator.of(context).pop(AntiburlaUserChoice.newSymptom),
              child: Column(
                children: [
                  Text(
                    l10n.antiburlaOptionNew,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.softIndigo,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.antiburlaOptionNewDesc,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
