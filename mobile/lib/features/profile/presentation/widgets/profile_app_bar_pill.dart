import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/profile.dart';
import '../controllers/active_profile_controller.dart';
import 'profile_selection_sheet.dart';

/// Top AppBar Profile Pill (PREM-06 / UI-SPEC 1.1)
/// Displays active profile name + initial avatar + relationship/scope badge.
/// Gated by [premiumProfilesEnabledProvider].
class ProfileAppBarPill extends ConsumerWidget {
  const ProfileAppBarPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(premiumProfilesEnabledProvider);
    if (!enabled) return const SizedBox.shrink();

    final state = ref.watch(activeProfileControllerProvider);
    final profile = state.activeProfile;
    if (profile == null) return const SizedBox.shrink();

    final Color accentColor;
    final Widget? badgeIcon;

    if (profile.ownership == ProfileOwnership.shared) {
      if (profile.accessLevel == ProfileAccessLevel.viewOnly) {
        accentColor = AppColors.textSecondaryLight;
        badgeIcon = const Icon(
          Icons.visibility,
          size: 14,
          color: AppColors.textSecondaryLight,
        );
      } else {
        accentColor = AppColors.dualisNavy;
        badgeIcon = const Icon(
          Icons.people_outline,
          size: 14,
          color: AppColors.dualisNavy,
        );
      }
    } else if (profile.ownership == ProfileOwnership.dependent ||
        !profile.isPrimary) {
      accentColor = AppColors.dualisNavy;
      badgeIcon = const Icon(
        Icons.family_restroom,
        size: 14,
        color: AppColors.dualisNavy,
      );
    } else {
      accentColor = AppColors.dualisSymbolBlue;
      badgeIcon = null;
    }

    final initial = profile.name.trim().isNotEmpty
        ? profile.name.trim()[0].toUpperCase()
        : '?';

    return Tooltip(
      message: profile.name,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('profile-app-bar-pill'),
          borderRadius: BorderRadius.circular(20),
          onTap: () => ProfileSelectionSheet.show(context),
          child: Container(
            height: 40,
            padding: const EdgeInsets.fromLTRB(6, 0, 8, 0),
            decoration: BoxDecoration(
              color: AppColors.iconTileTint,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white),
              boxShadow: AppColors.glassShadow(blur: 16, alpha: 0.18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: accentColor,
                  child: Text(
                    initial,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Text(
                      profile.name,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dualisNavy,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                if (badgeIcon != null) ...[
                  const SizedBox(width: 4),
                  badgeIcon,
                ],
                const SizedBox(width: 2),
                const Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: AppColors.dualisNavy,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
