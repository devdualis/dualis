import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/security/biometric_lock_controller.dart';
import '../../../../l10n/app_localizations.dart';

/// "Desbloquear com biometria" switch. Premium builds only, and only on
/// devices that can ask for a fingerprint, face or device PIN. Renders
/// nothing otherwise (including the divider that follows it).
class BiometricLockTile extends ConsumerStatefulWidget {
  const BiometricLockTile({super.key});

  @override
  ConsumerState<BiometricLockTile> createState() => _BiometricLockTileState();
}

class _BiometricLockTileState extends ConsumerState<BiometricLockTile> {
  bool _busy = false;

  Future<void> _onChanged(bool value) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(biometricLockControllerProvider.notifier);
    setState(() => _busy = true);
    final bool ok;
    if (value) {
      ok = await controller.enable(l10n.bioLockEnableReason);
    } else {
      await controller.disable();
      ok = true;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            !ok
                ? l10n.bioLockEnableFailed
                : value
                ? l10n.bioLockEnabled
                : l10n.bioLockDisabled,
          ),
          backgroundColor:
              ok ? AppColors.clinicalTeal : AppColors.emergencyCrimson,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(premiumProfilesEnabledProvider)) {
      return const SizedBox.shrink();
    }
    final supported = ref.watch(biometricSupportedProvider).asData?.value;
    if (supported != true) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final enabled = ref.watch(
      biometricLockControllerProvider.select((s) => s.enabled),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          key: const Key('settings_biometric_lock_switch'),
          value: enabled,
          activeThumbColor: AppColors.clinicalTeal,
          secondary: const Icon(
            Icons.fingerprint,
            color: AppColors.clinicalTeal,
          ),
          title: Text(
            l10n.bioLockSettingsTitle,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            l10n.bioLockSettingsSubtitle,
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
