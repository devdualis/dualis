import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Replaces a screen body when the active shared profile did not grant this
/// area, so an empty list never reads as "nothing recorded". Only the body is
/// replaced: the global urgent-help button stays on top.
class NotSharedPlaceholder extends StatelessWidget {
  const NotSharedPlaceholder({super.key, required this.profileName});

  final String profileName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context).textTheme;
    return Center(
      key: const ValueKey('category-not-shared'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 40,
              color: AppColors.textSecondaryLight,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.profileCategoryNotSharedTitle,
              textAlign: TextAlign.center,
              style: theme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.profileCategoryNotSharedBody(profileName),
              textAlign: TextAlign.center,
              style: theme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
