import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/urgent_help_button.dart';
import '../../../settings/presentation/widgets/settings_row_icon.dart'
    show SettingsDivider;
import '../../data/profile_repository.dart';
import '../../domain/models/profile.dart';
import '../controllers/active_profile_controller.dart';
import '../screens/add_dependent_modal.dart';
import 'claim_profile_sheet.dart';
import 'family_sharing_dialogs.dart' show familySharingDateFormat;
import 'profile_ui.dart';

/// Modal bottom sheet for switching active profiles, renaming, deleting,
/// adding legal dependents, opening family sharing management, claiming a
/// profile with a transfer code, and the guardian's hand-over and legal basis
/// notices on each owned dependent.
class ProfileSelectionSheet extends ConsumerWidget {
  const ProfileSelectionSheet({super.key});

  static Future<void> show(BuildContext context) {
    // Pull the latest grants so changes made by the other person (new
    // categories, revocation) show without logging out. Never throws.
    unawaited(ProviderScope.containerOf(context, listen: false)
        .read(activeProfileControllerProvider.notifier)
        .refresh());
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (ctx) => const ProfileSelectionSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final premiumEnabled = ref.watch(premiumProfilesEnabledProvider);
    final state = ref.watch(activeProfileControllerProvider);
    final active = state.activeProfile;

    final primaryProfiles =
        state.ownProfiles.where((p) => p.isPrimary).toList();
    final dependentProfiles =
        state.ownProfiles.where((p) => !p.isPrimary).toList();
    final sharedProfiles = state.sharedProfiles;

    return Material(
      color: profileSheetFill,
      borderRadius: profileSheetRadius,
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ProfileSheetHandle(),
              Padding(
                // At full height the header reaches the top of the screen,
                // where the floating urgent-help button sits: keep the close
                // button out of that strip.
                padding: const EdgeInsets.fromLTRB(
                    20, 4, UrgentHelpButton.reservedEdgeWidth, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.profileSwitcherSheetTitle,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dualisNavy,
                      ),
                    ),
                    ProfileRoundIconButton(
                      icon: Icons.close,
                      tooltip: l10n.profileSwitcherClose,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ProfileSectionHeader(
                        l10n.profileSwitcherMyProfile,
                        padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                      ),
                      ...primaryProfiles.map(
                        (p) => _buildProfileTile(
                          context,
                          ref,
                          p,
                          p.id == active?.id,
                          l10n,
                        ),
                      ),
                      ProfileSectionHeader(
                        l10n.profileSwitcherDependents,
                        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                      ),
                      if (dependentProfiles.isEmpty)
                        _buildEmptyMessage(l10n.profileSwitcherNoDependents)
                      else
                        for (final p in dependentProfiles) ...[
                          _buildProfileTile(
                            context,
                            ref,
                            p,
                            p.id == active?.id,
                            l10n,
                          ),
                          ..._buildDependentNotices(context, ref, p, l10n),
                        ],
                      ProfileSectionHeader(
                        l10n.profileSwitcherShared,
                        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                      ),
                      if (sharedProfiles.isEmpty)
                        _buildEmptyMessage(l10n.profileSwitcherNoShared)
                      else
                        ...sharedProfiles.map(
                          (p) => _buildProfileTile(
                            context,
                            ref,
                            p,
                            p.id == active?.id,
                            l10n,
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      key: const ValueKey('profile-add-dependent'),
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: Text(l10n.profileSwitcherAddDependent),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.softIndigo,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(52),
                        shape: const StadiumBorder(),
                        textStyle: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () async {
                        final created = await showAddDependentModal(context);
                        if (created != null && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      radius: 22,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ProfileActionRow(
                            key: const ValueKey('profile-manage-sharing'),
                            icon: Icons.people_alt_outlined,
                            label: l10n.profileSwitcherManageSharing,
                            onTap: () {
                              Navigator.of(context).pop();
                              context.push(RoutePaths.familySharing);
                            },
                          ),
                          if (premiumEnabled) ...[
                            const SettingsDivider(),
                            ProfileActionRow(
                              key: const ValueKey('profile-claim-entry'),
                              icon: Icons.vpn_key_outlined,
                              label: l10n.profileClaimEntry,
                              onTap: () async {
                                final claimed =
                                    await showClaimProfileSheet(context);
                                if (claimed && context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyMessage(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Text(
        message,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.textSecondaryLight,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildProfileTile(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
    bool isActive,
    AppLocalizations l10n,
  ) {
    final initial = profile.name.trim().isNotEmpty
        ? profile.name.trim()[0].toUpperCase()
        : '?';

    // Shared first: someone else's primary profile is not "Titular" here.
    final Gradient avatarGradient;
    final Color badgeColor;
    if (profile.ownership == ProfileOwnership.shared) {
      final viewOnly = profile.accessLevel == ProfileAccessLevel.viewOnly;
      avatarGradient = viewOnly
          ? const LinearGradient(colors: [
              AppColors.textSecondaryLight,
              AppColors.textSecondaryLight,
            ])
          : AppColors.gradientNavy;
      badgeColor = viewOnly
          ? AppColors.textSecondaryLight
          : AppColors.clinicalTealDark;
    } else if (profile.isPrimary) {
      avatarGradient = AppColors.gradientBlueCyan;
      badgeColor = AppColors.clinicalTealDark;
    } else {
      avatarGradient = AppColors.gradientNavy;
      badgeColor = AppColors.dualisNavy;
    }
    final subtitle = _subtitleFor(profile, l10n);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white.withValues(alpha: isActive ? 0.95 : 0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isActive
                ? AppColors.dualisSymbolBlue
                : AppColors.dualisNavy.withValues(alpha: 0.08),
            width: isActive ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(12, 4, 10, 4),
          leading: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: avatarGradient,
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          title: Text(
            profile.name,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),
          subtitle: subtitle.isEmpty
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ProfilePill(subtitle, color: badgeColor),
                  ),
                ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (profile.canEdit)
                ProfileRoundIconButton(
                  key: ValueKey('profile-edit-${profile.id}'),
                  icon: Icons.edit_outlined,
                  tooltip: l10n.profileSwitcherRenameTitle,
                  onPressed: () =>
                      _showRenameDialog(context, ref, profile, l10n),
                ),
              if (profile.canDelete) ...[
                const SizedBox(width: 6),
                ProfileRoundIconButton(
                  key: ValueKey('profile-delete-${profile.id}'),
                  icon: Icons.delete_outline,
                  color: AppColors.emergencyCrimson,
                  tooltip: l10n.profileSwitcherDeleteTitle,
                  onPressed: () =>
                      _showDeleteDialog(context, ref, profile, l10n),
                ),
              ],
              if (isActive)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.dualisSymbolBlue,
                    size: 24,
                  ),
                ),
            ],
          ),
          onTap: () {
            ref
                .read(activeProfileControllerProvider.notifier)
                .selectProfile(profile.id);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  /// Hand-over (dependent turned 18) and legal basis (adult dependent still
  /// on Art. 14) notices, only for dependents this account owns.
  List<Widget> _buildDependentNotices(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
    AppLocalizations l10n,
  ) {
    if (!profile.isOwnedDependent) return const [];
    final expiry = profile.handoverCodeExpiresAt;
    return [
      if (profile.handoverStatus != HandoverStatus.none)
        _buildNotice(
          key: ValueKey('handover-banner-${profile.id}'),
          icon: Icons.cake_outlined,
          text: profile.handoverStatus == HandoverStatus.codeActive &&
                  expiry != null
              ? l10n.profileHandoverCodeActive(
                  familySharingDateFormat.format(expiry.toLocal()))
              : l10n.profileHandoverDueBanner(profile.name),
          action: TextButton(
            key: ValueKey('handover-generate-${profile.id}'),
            onPressed: () => _generateHandoverCode(context, ref, profile, l10n),
            child: Text(l10n.profileHandoverGenerate),
          ),
        ),
      if (profile.legalBasisNeedsConfirmation)
        _buildNotice(
          key: ValueKey('legal-basis-banner-${profile.id}'),
          icon: Icons.verified_user_outlined,
          text: l10n.profileLegalBasisBanner(profile.name),
          action: TextButton(
            key: ValueKey('legal-basis-confirm-${profile.id}'),
            onPressed: () =>
                _showLegalBasisDialog(context, ref, profile, l10n),
            child: Text(l10n.profileLegalBasisConfirm),
          ),
        ),
    ];
  }

  Widget _buildNotice({
    required Key key,
    required IconData icon,
    required String text,
    required Widget action,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 8),
      child: ProfileNoticePanel(
        icon: icon,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ),
            Align(alignment: Alignment.centerRight, child: action),
          ],
        ),
      ),
    );
  }

  /// Generates (or regenerates) the transfer code and shows it once. The code
  /// is only kept in this dialog: never logged or stored on the device.
  Future<void> _generateHandoverCode(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final HandoverCode handover;
    try {
      handover = await ref
          .read(activeProfileControllerProvider.notifier)
          .createHandoverCode(profile.id);
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.profileSwitcherActionError)),
      );
      return;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        key: const ValueKey('handover-code-dialog'),
        title: Text(l10n.profileHandoverCodeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.profileHandoverCodeBody(
              profile.name,
              familySharingDateFormat.format(handover.expiresAt.toLocal()),
            )),
            const SizedBox(height: 16),
            ProfileCodeBox(
              child: SelectableText(
                handover.code,
                key: const ValueKey('handover-code-value'),
                textAlign: TextAlign.center,
                maxLines: 1,
                style: profileCodeTextStyle(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('handover-code-copy'),
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: Text(l10n.profileHandoverCopy),
              onPressed: () async {
                final dialogMessenger = ScaffoldMessenger.of(dialogCtx);
                await Clipboard.setData(ClipboardData(text: handover.code));
                dialogMessenger.showSnackBar(
                  SnackBar(content: Text(l10n.familySharingCodeCopied)),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(l10n.profileSwitcherClose),
          ),
        ],
      ),
    );
  }

  /// Re-confirms an adult dependent's registration under LGPD Art. 11, I.
  /// The declaration must be checked before confirming.
  Future<void> _showLegalBasisDialog(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
    AppLocalizations l10n,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    var accepted = false;
    var submitting = false;
    return showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          key: const ValueKey('legal-basis-dialog'),
          title: Text(l10n.profileLegalBasisBanner(profile.name)),
          content: SingleChildScrollView(
            child: CheckboxListTile(
              key: const ValueKey('legal-basis-consent-checkbox'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.dualisNavy,
              value: accepted,
              onChanged: (v) => setDialogState(() => accepted = v ?? false),
              title: Text(
                l10n.addDependentLgpdArt11Consent,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(l10n.profileSwitcherRenameCancel),
            ),
            FilledButton(
              key: const ValueKey('legal-basis-confirm-submit'),
              onPressed: accepted && !submitting
                  ? () async {
                      setDialogState(() => submitting = true);
                      try {
                        await ref
                            .read(activeProfileControllerProvider.notifier)
                            .confirmLegalBasis(profile.id);
                        if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                      } catch (_) {
                        messenger.showSnackBar(
                          SnackBar(
                              content: Text(l10n.profileSwitcherActionError)),
                        );
                        if (dialogCtx.mounted) {
                          setDialogState(() => submitting = false);
                        }
                      }
                    }
                  : null,
              child: Text(l10n.profileLegalBasisConfirm),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitleFor(Profile profile, AppLocalizations l10n) {
    if (profile.ownership == ProfileOwnership.shared) {
      return profile.accessLevel == ProfileAccessLevel.viewOnly
          ? l10n.profileSwitcherBadgeViewOnly
          : l10n.profileSwitcherBadgeCoManage;
    }
    if (profile.isPrimary) {
      return l10n.profileSwitcherBadgePrimary;
    }
    if (profile.profileType == ProfileType.dependentMinor) {
      return l10n.profileSwitcherBadgeMinor;
    }
    if (profile.profileType == ProfileType.dependentAdult) {
      return l10n.profileSwitcherBadgeAdult;
    }
    return '';
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
    AppLocalizations l10n,
  ) async {
    final controller = TextEditingController(text: profile.name);
    return showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.profileSwitcherRenameTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.profileSwitcherRenameLabel,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(l10n.profileSwitcherRenameCancel),
          ),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              final messenger = ScaffoldMessenger.of(context);
              try {
                if (newName.isNotEmpty) {
                  await ref
                      .read(activeProfileControllerProvider.notifier)
                      .updateProfileName(profile.id, newName);
                }
              } catch (_) {
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.profileSwitcherActionError)),
                );
              }
              if (dialogCtx.mounted) {
                Navigator.of(dialogCtx).pop();
              }
            },
            child: Text(l10n.profileSwitcherRenameSave),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
    AppLocalizations l10n,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.profileSwitcherDeleteTitle),
        content: Text(l10n.profileSwitcherDeleteConfirm(profile.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(l10n.profileSwitcherRenameCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emergencyCrimson,
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref
                    .read(activeProfileControllerProvider.notifier)
                    .deleteProfile(profile.id);
              } catch (_) {
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.profileSwitcherActionError)),
                );
              }
              if (dialogCtx.mounted) {
                Navigator.of(dialogCtx).pop();
              }
            },
            child: Text(l10n.profileSwitcherDeleteAction),
          ),
        ],
      ),
    );
  }
}
