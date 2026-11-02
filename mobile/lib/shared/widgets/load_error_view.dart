import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/error_message_resolver.dart';
import '../../l10n/app_localizations.dart';

/// Full-area "could not load" state with the reason and a retry button.
class LoadErrorView extends StatelessWidget {
  const LoadErrorView({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.textSecondaryLight),
            const SizedBox(height: 12),
            Text(l10n.commonLoadFailed, textAlign: TextAlign.center, style: theme.titleMedium),
            const SizedBox(height: 6),
            Text(
              ErrorMessageResolver.resolve(error, l10n),
              textAlign: TextAlign.center,
              style: theme.bodyMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              key: const Key('load_error_retry'),
              onPressed: onRetry,
              child: Text(l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tells the person a change was not saved.
void showSaveFailedSnackBar(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      key: const Key('save_failed_snack'),
      content: Text(l10n.commonSaveFailed),
      backgroundColor: AppColors.emergencyCrimson,
    ));
}
