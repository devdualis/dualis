import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import 'ai_consent_controller.dart';

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
/// person. On asks for consent first; off revokes it.
class AiConsentTile extends ConsumerStatefulWidget {
  const AiConsentTile({super.key});

  @override
  ConsumerState<AiConsentTile> createState() => _AiConsentTileState();
}

class _AiConsentTileState extends ConsumerState<AiConsentTile> {
  bool _busy = false;

  Future<void> _onChanged(bool value) async {
    final controller = ref.read(aiConsentControllerProvider.notifier);
    setState(() => _busy = true);
    try {
      if (value) {
        final accepted = await showAiConsentDialog(context);
        if (accepted == true) await controller.grant();
      } else {
        await controller.revoke();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(aiConsentControllerProvider).asData?.value;
    final granted = status?.granted == true;
    final grantedAt = status?.grantedAt;
    final subtitle =
        granted && grantedAt != null
            ? l10n.aiConsentTileOn(DateFormat('dd/MM/yyyy').format(grantedAt))
            : l10n.aiConsentTileOff;
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
