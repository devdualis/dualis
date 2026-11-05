import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../data/ai_consent_repository.dart';
import 'ai_consent_controller.dart';

/// How [ensureAiConsent] asks when consent is missing.
enum AiConsentAsk {
  /// Always show the dialog (the person turned an AI feature on).
  always,

  /// Show it unless the person already said "Agora não" on this device for
  /// the current consent version (features offered without being asked).
  unlessDeclined,
}

void _say(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            error ? AppColors.emergencyCrimson : AppColors.clinicalTeal,
        duration: const Duration(seconds: 3),
      ),
    );
}

/// True only when the server says the AI consent is granted for its current
/// version, asking first when needed. Never grants without a tap on
/// "Permitir" and never throws. Without consent the caller simply keeps
/// the AI feature off; everything else goes on as usual.
Future<bool> ensureAiConsent(
  BuildContext context,
  WidgetRef ref, {
  required AiConsentAsk ask,
}) async {
  try {
    final controller = ref.read(aiConsentControllerProvider.notifier);
    final l10n = AppLocalizations.of(context);
    final status = await controller.load();
    if (!context.mounted) return false;
    if (status == null) {
      _say(context, l10n.aiConsentUnavailable);
      return false;
    }
    if (status.granted) return true;
    if (ask == AiConsentAsk.unlessDeclined &&
        await controller.declinedOnDevice()) {
      return false;
    }
    // A second try covers one consent version change on the server.
    for (var attempt = 0; attempt < 2; attempt++) {
      if (!context.mounted) return false;
      final accepted = await showAiConsentDialog(context);
      if (accepted != true) {
        if (accepted == false && ask == AiConsentAsk.unlessDeclined) {
          await controller.rememberDecline();
        }
        return false;
      }
      try {
        final ok = await controller.grant();
        if (!ok && context.mounted) {
          _say(context, l10n.aiConsentError, error: true);
        }
        return ok;
      } on AiConsentVersionMismatch {
        if (context.mounted) _say(context, l10n.aiConsentUpdated);
      }
    }
    if (context.mounted) _say(context, l10n.aiConsentError, error: true);
    return false;
  } catch (_) {
    return false;
  }
}

Future<bool> _confirmRevoke(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          key: const Key('ai_consent_revoke_dialog'),
          title: Text(l10n.aiConsentRevokeTitle),
          content: Text(l10n.aiConsentRevokeBody),
          actions: [
            TextButton(
              key: const Key('ai_consent_revoke_cancel'),
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.aiConsentRevokeCancel),
            ),
            FilledButton(
              key: const Key('ai_consent_revoke_confirm'),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.aiConsentRevokeConfirm),
            ),
          ],
        ),
  );
  return ok == true;
}

/// The AI-processing consent dialog (LGPD Art. 11, I). Names the provider
/// and region, what is sent, no training, what the AI does, and that it is
/// optional and revocable. True only when the person taps "Permitir".
Future<bool?> showAiConsentDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final paragraphs = [
    l10n.aiConsentIntro,
    l10n.aiConsentWhatIsSent,
    l10n.aiConsentNoTraining,
    l10n.aiConsentOnlyOptions,
    l10n.aiConsentOptional,
  ];
  return showDialog<bool>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          key: const Key('ai_consent_dialog'),
          title: Text(
            l10n.aiConsentTitle,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final p in paragraphs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      p,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              key: const Key('ai_consent_decline'),
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.aiConsentDecline),
            ),
            FilledButton(
              key: const Key('ai_consent_accept'),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.aiConsentAccept),
            ),
          ],
        ),
  );
}

/// "Sugestões com IA no diário" switch in Settings, for every signed-in
/// person. On asks for consent first; off confirms, then revokes. Errors
/// leave the switch as it was.
class AiConsentTile extends ConsumerStatefulWidget {
  const AiConsentTile({super.key});

  @override
  ConsumerState<AiConsentTile> createState() => _AiConsentTileState();
}

class _AiConsentTileState extends ConsumerState<AiConsentTile> {
  bool _busy = false;

  Future<void> _onChanged(bool value) async {
    final controller = ref.read(aiConsentControllerProvider.notifier);
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      if (value) {
        await ensureAiConsent(context, ref, ask: AiConsentAsk.always);
      } else if (await _confirmRevoke(context)) {
        final ok = await controller.revoke();
        if (!ok && mounted) _say(context, l10n.aiConsentError, error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(aiConsentControllerProvider);
    final status = async.asData?.value;
    final granted = status?.granted == true;
    final grantedAt = status?.grantedAt;
    final String subtitle;
    if (async.hasError && status == null) {
      subtitle = l10n.aiConsentTileUnknown;
    } else if (granted && grantedAt != null) {
      subtitle = l10n.aiConsentTileOn(
        DateFormat('dd/MM/yyyy').format(grantedAt),
      );
    } else {
      subtitle = l10n.aiConsentTileOff;
    }
    return Column(
      key: const Key('settings_ai_consent_tile'),
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          key: const Key('settings_ai_consent_switch'),
          value: granted,
          activeThumbColor: AppColors.clinicalTeal,
          secondary: const Icon(
            Icons.auto_awesome_outlined,
            color: AppColors.clinicalTeal,
          ),
          title: Text(
            l10n.aiConsentTileTitle,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textSecondaryLight,
            ),
          ),
          onChanged: _busy ? null : _onChanged,
        ),
        const Divider(height: 1, color: AppColors.outlineLight),
      ],
    );
  }
}
