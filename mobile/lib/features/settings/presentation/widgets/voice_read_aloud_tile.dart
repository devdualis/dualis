import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/voice/voice_output_service.dart';
import '../../../../l10n/app_localizations.dart';

/// "Ler as perguntas em voz alta" switch for the voice check-in. Premium
/// builds only, on by default. Renders nothing on Free builds (including
/// the divider that follows it).
class VoiceReadAloudTile extends ConsumerStatefulWidget {
  const VoiceReadAloudTile({super.key});

  @override
  ConsumerState<VoiceReadAloudTile> createState() => _VoiceReadAloudTileState();
}

class _VoiceReadAloudTileState extends ConsumerState<VoiceReadAloudTile> {
  @override
  void initState() {
    super.initState();
    // Loads the saved choice once, so a stored "off" shows here. In a
    // microtask: the provider must not change while the tree builds.
    Future.microtask(() {
      if (mounted && ref.read(premiumProfilesEnabledProvider)) {
        ref.read(voiceReadAloudProvider.notifier).isEnabled();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(premiumProfilesEnabledProvider)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final on = ref.watch(voiceReadAloudProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          key: const Key('settings_voice_read_aloud_switch'),
          value: on,
          activeThumbColor: AppColors.clinicalTeal,
          secondary: const Icon(
            Icons.record_voice_over_outlined,
            color: AppColors.clinicalTeal,
          ),
          title: Text(
            l10n.voiceReadAloudTitle,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            l10n.voiceReadAloudSubtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textSecondaryLight,
            ),
          ),
          onChanged: (value) => ref.read(voiceReadAloudProvider.notifier).set(value),
        ),
        const Divider(height: 1, color: AppColors.outlineLight),
      ],
    );
  }
}
