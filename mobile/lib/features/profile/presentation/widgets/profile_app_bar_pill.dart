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

    final Color borderColor;
    final Color backgroundColor;
    final Widget? badgeIcon;

    if (profile.ownership == ProfileOwnership.shared) {
      if (profile.accessLevel == ProfileAccessLevel.viewOnly) {
        borderColor = const Color(0xFFD97706);
        backgroundColor = const Color(0xFFD97706).withAlpha(25);
        badgeIcon = const Icon(
          Icons.visibility,
          size: 14,
          color: Color(0xFFD97706),
        );
      } else {
        borderColor = AppColors.softIndigo;
        backgroundColor = AppColors.softIndigo.withAlpha(25);
        badgeIcon = const Icon(
          Icons.people_outline,
          size: 14,
          color: AppColors.softIndigo,
        );
      }
    } else if (profile.ownership == ProfileOwnership.dependent ||
        !profile.isPrimary) {
      borderColor = AppColors.softIndigo;
      backgroundColor = AppColors.softIndigo.withAlpha(25);
      badgeIcon = const Icon(
        Icons.family_restroom,
        size: 14,
        color: AppColors.softIndigo,
      );
    } else {
      borderColor = AppColors.clinicalTeal;
      backgroundColor = AppColors.clinicalTeal.withAlpha(20);
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: borderColor,
                  backgroundImage: (profile.avatarUrl != null &&
                          profile.avatarUrl!.isNotEmpty)
                      ? NetworkImage(profile.avatarUrl!)
                      : null,
                  child: (profile.avatarUrl == null ||
                          profile.avatarUrl!.isEmpty)
                      ? Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Text(
                      profile.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryLight,
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
                  size: 16,
                  color: AppColors.textSecondaryLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
