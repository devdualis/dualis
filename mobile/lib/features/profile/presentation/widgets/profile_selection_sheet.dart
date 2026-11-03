import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/profile_repository.dart';
import '../../domain/models/profile.dart';
import '../controllers/active_profile_controller.dart';
import '../screens/add_dependent_modal.dart';
import 'claim_profile_sheet.dart';
import 'family_sharing_dialogs.dart' show familySharingDateFormat;

/// Modal bottom sheet for switching active profiles, renaming, deleting,
/// adding legal dependents, opening family sharing management, claiming a
/// profile with a transfer code, and the guardian's hand-over and legal basis
/// notices on each owned dependent.
class ProfileSelectionSheet extends ConsumerWidget {
  const ProfileSelectionSheet({super.key});

  static Future<void> show(BuildContext context) {
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
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.profileSwitcherSheetTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: l10n.profileSwitcherClose,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionHeader(l10n.profileSwitcherMyProfile),
                      ...primaryProfiles.map(
                        (p) => _buildProfileTile(
                          context,
                          ref,
                          p,
                          p.id == active?.id,
                          l10n,
                        ),
                      ),
                      _buildSectionHeader(l10n.profileSwitcherDependents),
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
                      _buildSectionHeader(l10n.profileSwitcherShared),
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
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      key: const ValueKey('profile-add-dependent'),
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: Text(l10n.profileSwitcherAddDependent),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.clinicalTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                    OutlinedButton.icon(
                      key: const ValueKey('profile-manage-sharing'),
                      icon: const Icon(Icons.people_alt_outlined),
                      label: Text(l10n.profileSwitcherManageSharing),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.softIndigo,
                        side: const BorderSide(color: AppColors.softIndigo),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push(RoutePaths.familySharing);
                      },
                    ),
                    if (premiumEnabled) ...[
                      const SizedBox(height: 4),
                      TextButton.icon(
                        key: const ValueKey('profile-claim-entry'),
                        icon: const Icon(Icons.vpn_key_outlined),
                        label: Text(l10n.profileClaimEntry),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.softIndigo,
                        ),
                        onPressed: () async {
                          final claimed = await showClaimProfileSheet(context);
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
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.clinicalTealDark,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildEmptyMessage(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        message,
        style: GoogleFonts.plusJakartaSans(
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
    final Color avatarBgColor;
    if (profile.ownership == ProfileOwnership.shared) {
      avatarBgColor = profile.accessLevel == ProfileAccessLevel.viewOnly
          ? const Color(0xFFD97706)
          : AppColors.softIndigo;
    } else if (profile.isPrimary) {
      avatarBgColor = AppColors.clinicalTeal;
    } else {
      avatarBgColor = AppColors.softIndigo;
    }

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: avatarBgColor,
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      title: Text(
        profile.name,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
          color: AppColors.textPrimaryLight,
        ),
      ),
      subtitle: Text(
        _subtitleFor(profile, l10n),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: AppColors.textSecondaryLight,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (profile.canEdit)
            IconButton(
              key: ValueKey('profile-edit-${profile.id}'),
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: AppColors.textSecondaryLight,
              tooltip: l10n.profileSwitcherRenameTitle,
              onPressed: () => _showRenameDialog(context, ref, profile, l10n),
            ),
          if (profile.canDelete)
            IconButton(
              key: ValueKey('profile-delete-${profile.id}'),
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.emergencyCrimson,
              tooltip: l10n.profileSwitcherDeleteTitle,
              onPressed: () => _showDeleteDialog(context, ref, profile, l10n),
            ),
          if (isActive)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(
                Icons.check_circle_rounded,
                color: AppColors.clinicalTeal,
                size: 22,
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
    return Container(
      key: key,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 4),
      decoration: BoxDecoration(
        color: AppColors.softIndigo.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: AppColors.softIndigo),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
          Align(alignment: Alignment.centerRight, child: action),
        ],
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
            SelectableText(
              handover.code,
              key: const ValueKey('handover-code-value'),
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: AppColors.softIndigo,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('handover-code-copy'),
              icon: const Icon(Icons.copy),
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
              value: accepted,
              onChanged: (v) => setDialogState(() => accepted = v ?? false),
              title: Text(
                l10n.addDependentLgpdArt11Consent,
                style: const TextStyle(fontSize: 13),
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
