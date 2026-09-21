import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/error_message_resolver.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/privacy_controller.dart';

class PrivacyCenterScreen extends ConsumerStatefulWidget {
  const PrivacyCenterScreen({super.key});

  @override
  ConsumerState<PrivacyCenterScreen> createState() =>
      _PrivacyCenterScreenState();
}

class _PrivacyCenterScreenState extends ConsumerState<PrivacyCenterScreen> {
  void _showExportPreviewDialog(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final l10n = AppLocalizations.of(context);
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            l10n.previewDataTitle,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 380,
            child: SingleChildScrollView(
              child: SelectableText(
                jsonStr,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.close),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isValid = passwordController.text.length >= 8;

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.emergencyCrimson,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.deleteConfirmTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.deleteConfirmDesc,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('delete_account_password_field'),
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: l10n.enterPassword,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  key: const Key('confirm_permanent_deletion_button'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.emergencyCrimson,
                  ),
                  onPressed: isValid
                      ? () async {
                          final nav = Navigator.of(dialogContext);
                          nav.pop();
                          final success = await ref
                              .read(privacyControllerProvider.notifier)
                              .deleteAccount(passwordController.text);
                          if (success && mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.deleteSuccessMessage),
                                backgroundColor: AppColors.clinicalTeal,
                              ),
                            );
                            try {
                              GoRouter.of(this.context).go(RoutePaths.onboarding);
                            } catch (_) {}
                          }
                        }
                      : null,
                  child: Text(l10n.confirmPermanentDeletion),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final privacyState = ref.watch(privacyControllerProvider);

    ref.listen<PrivacyState>(privacyControllerProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        final errorText = ErrorMessageResolver.resolve(next.errorMessage!, l10n);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorText),
            backgroundColor: AppColors.emergencyCrimson,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.privacyCenterTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.clinicalTeal.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.download_rounded,
                            color: AppColors.clinicalTeal,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.exportDataTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.exportDataDesc,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      key: const Key('export_data_button'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.clinicalTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: privacyState.isExporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.download_rounded),
                      label: Text(l10n.exportDataButton),
                      onPressed: privacyState.isExporting
                          ? null
                          : () async {
                              final data = await ref
                                  .read(privacyControllerProvider.notifier)
                                  .exportData();
                              if (data != null && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.exportSuccessMessage),
                                    backgroundColor: AppColors.clinicalTeal,
                                  ),
                                );
                                _showExportPreviewDialog(context, data);
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFFCDD2),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.emergencyCrimson.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_forever_rounded,
                          color: AppColors.emergencyCrimson,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.deleteAccountTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.emergencyCrimson,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.deleteAccountDesc,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    key: const Key('delete_account_button'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.emergencyCrimson,
                      side: const BorderSide(
                        color: AppColors.emergencyCrimson,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: privacyState.isDeleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.emergencyCrimson,
                            ),
                          )
                        : const Icon(Icons.delete_forever_rounded),
                    label: Text(l10n.deleteAccountButton),
                    onPressed: privacyState.isDeleting
                        ? null
                        : () => _showDeleteConfirmationDialog(context),
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
