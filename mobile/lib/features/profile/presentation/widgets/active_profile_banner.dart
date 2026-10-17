import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/profile.dart';
import '../controllers/active_profile_controller.dart';

Profile? _ownPrimaryProfile(ActiveProfileState state) {
  for (final p in state.profiles) {
    if (p.isPrimary && p.ownership == ProfileOwnership.own) return p;
  }
  return null;
}

/// Premium on and the active clinical context is not the signed-in user's primary profile.
bool showsDelegatedActiveProfile(WidgetRef ref) {
  if (!ref.watch(premiumProfilesEnabledProvider)) return false;
  final state = ref.watch(activeProfileControllerProvider);
  final active = state.activeProfile;
  final ownPrimary = _ownPrimaryProfile(state);
  if (active == null || ownPrimary == null) return false;
  return active.id != ownPrimary.id;
}

bool activeProfileIsViewOnly(WidgetRef ref) {
  if (!showsDelegatedActiveProfile(ref)) return false;
  final profile = ref.watch(activeProfileControllerProvider).activeProfile;
  return profile != null && !profile.canEdit;
}

String profileContextSubtitle(Profile profile, AppLocalizations l10n) {
  if (profile.isPrimary) {
    return l10n.profileSwitcherBadgePrimary;
  }
  if (profile.ownership == ProfileOwnership.shared) {
    return profile.accessLevel == ProfileAccessLevel.viewOnly
        ? l10n.profileSwitcherBadgeViewOnly
        : l10n.profileSwitcherBadgeCoManage;
  }
  if (profile.profileType == ProfileType.dependentMinor) {
    return l10n.profileSwitcherBadgeMinor;
  }
  if (profile.profileType == ProfileType.dependentAdult) {
    return l10n.profileSwitcherBadgeAdult;
  }
  return '';
}

void switchActiveProfileToPrimary(WidgetRef ref) {
  final profiles = ref.read(activeProfileControllerProvider).profiles;
  final primary = profiles.where((p) => p.isPrimary).firstOrNull;
  if (primary != null) {
    ref.read(activeProfileControllerProvider.notifier).selectProfile(primary.id);
  }
}

/// Banner shown on home, history, and hydration when viewing another profile's data.
class ActiveProfileBanner extends ConsumerWidget {
  const ActiveProfileBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!showsDelegatedActiveProfile(ref)) {
      return const SizedBox.shrink();
    }

    final profile = ref.watch(activeProfileControllerProvider).activeProfile!;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        key: const ValueKey('active-profile-banner'),
        color: AppColors.softIndigo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => switchActiveProfileToPrimary(ref),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.softIndigo.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.switch_account_outlined,
                  size: 20,
                  color: AppColors.softIndigo,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.activeProfileBannerDataOf(profile.name),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                Text(
                  l10n.activeProfileBannerSwitchToMine,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.clinicalTealDark,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.clinicalTealDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ActiveProfileReadOnlyNote extends ConsumerWidget {
  const ActiveProfileReadOnlyNote({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!activeProfileIsViewOnly(ref)) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        key: const ValueKey('active-profile-readonly-note'),
        children: [
          Icon(
            Icons.visibility_outlined,
            size: 16,
            color: const Color(0xFFD97706),
          ),
          const SizedBox(width: 6),
          Text(
            l10n.activeProfileReadOnlyNote,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }
}
