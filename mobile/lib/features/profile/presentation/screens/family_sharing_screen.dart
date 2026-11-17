import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/profile_repository.dart';
import '../../domain/models/shared_access_grant.dart';
import '../../../../shared/widgets/duotone_icon_tile.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../controllers/active_profile_controller.dart';
import '../widgets/family_sharing_dialogs.dart';
import '../widgets/profile_ui.dart';

/// Family sharing management (PREM-07): who sees my data vs. data shared
/// with me, invite generation, invite acceptance and instant revocation.
class FamilySharingScreen extends ConsumerWidget {
  const FamilySharingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // The route is reachable by deep link even when the premium flag is off.
    if (!ref.watch(premiumProfilesEnabledProvider)) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.familySharingTitle)),
        body: _UnavailableState(l10n: l10n),
      );
    }
    return const _FamilySharingBody();
  }
}

class _UnavailableState extends StatelessWidget {
  final AppLocalizations l10n;
  const _UnavailableState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DuotoneIconTile(
              size: 88,
              radius: 28,
              child: Icon(Icons.family_restroom,
                  size: 44, color: AppColors.dualisNavy),
            ),
            const SizedBox(height: 16),
            Text(l10n.familySharingUnavailableTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(l10n.familySharingUnavailableBody,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _FamilySharingBody extends ConsumerStatefulWidget {
  const _FamilySharingBody();

  @override
  ConsumerState<_FamilySharingBody> createState() => _FamilySharingBodyState();
}

class _FamilySharingBodyState extends ConsumerState<_FamilySharingBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(activeProfileControllerProvider.notifier).refresh();
      } catch (_) {
        // Lists keep their last known state; errorMessage is surfaced below.
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _openInvite() async {
    await showDialog<SharedAccessGrant>(
      context: context,
      builder: (_) => const FamilySharingInviteDialog(),
    );
  }

  Future<void> _openAccept() async {
    final l10n = AppLocalizations.of(context);
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => const FamilySharingAcceptSheet(),
    );
    if (accepted == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.familySharingAccepted)));
    }
  }

  Future<void> _confirmRevoke(SharedAccessGrant grant) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.familySharingRevokeConfirmTitle,
          style: GoogleFonts.inter(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.dualisNavy,
          ),
        ),
        content: Text(l10n.familySharingRevokeConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.familySharingCancel),
          ),
          FilledButton(
            key: const ValueKey('family-share-revoke-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emergencyCrimson,
              minimumSize: const Size(96, 46),
              textStyle: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.familySharingRevokeButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(activeProfileControllerProvider.notifier)
          .revokeGrant(grant.id);
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.familySharingRevoked)));
    } catch (_) {
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.familySharingRevokeError)));
    }
  }

  Future<void> _editCategories(SharedAccessGrant grant) async {
    final l10n = AppLocalizations.of(context);
    final isDependentTarget = ref
        .read(activeProfileControllerProvider)
        .ownProfiles
        .any((p) => p.id == grant.targetProfileId && !p.isPrimary);
    final edit = await showDialog<FamilySharingCategoryEdit>(
      context: context,
      builder: (_) => FamilySharingEditCategoriesDialog(
        grant: grant,
        isDependentTarget: isDependentTarget,
      ),
    );
    if (edit == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(activeProfileControllerProvider.notifier).updateGrant(
            grant.id,
            categories: edit.categories,
            dependentShareConfirmed: edit.dependentShareConfirmed,
          );
    } catch (e) {
      // e.g. 409 GRANT_SCOPE_LOCKED: the backend message says why.
      messenger.showSnackBar(SnackBar(
          content: Text(e is ProfileApiException && e.message.isNotEmpty
              ? e.message
              : l10n.familySharingEditError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(activeProfileControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.familySharingTitle)),
      body: Column(
        children: [
          if (state.isLoading) const LinearProgressIndicator(minHeight: 2),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.dualisNavy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: TabBar(
                controller: _tabs,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                splashBorderRadius: BorderRadius.circular(999),
                indicator: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.dualisNavy.withValues(alpha: 0.14),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                tabs: [
                  // Two-line labels: the pt-BR copy does not fit one line on
                  // narrow phones.
                  Tab(
                    key: const ValueKey('family-share-tab-outgoing'),
                    height: 52,
                    child: Text(l10n.familySharingTabOutgoing,
                        textAlign: TextAlign.center, maxLines: 2),
                  ),
                  Tab(
                    key: const ValueKey('family-share-tab-incoming'),
                    height: 52,
                    child: Text(l10n.familySharingTabIncoming,
                        textAlign: TextAlign.center, maxLines: 2),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _GrantList(
                  grants: state.outgoingGrants,
                  actionKey: const ValueKey('family-share-invite-button'),
                  actionIcon: Icons.person_add_alt_1,
                  actionLabel: l10n.familySharingInviteButton,
                  onAction: _openInvite,
                  emptyText: l10n.familySharingEmptyOutgoing,
                  onRevoke: _confirmRevoke,
                  onEditCategories: _editCategories,
                ),
                _GrantList(
                  grants: state.incomingGrants,
                  actionKey: const ValueKey('family-share-accept-button'),
                  actionIcon: Icons.vpn_key_outlined,
                  actionLabel: l10n.familySharingEnterCodeButton,
                  onAction: _openAccept,
                  emptyText: l10n.familySharingEmptyIncoming,
                  onRevoke: _confirmRevoke,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GrantList extends StatelessWidget {
  final List<SharedAccessGrant> grants;
  final Key actionKey;
  final IconData actionIcon;
  final String actionLabel;
  final VoidCallback onAction;
  final String emptyText;
  final ValueChanged<SharedAccessGrant> onRevoke;
  /// Outgoing list only; incoming grants are read-only.
  final ValueChanged<SharedAccessGrant>? onEditCategories;

  const _GrantList({
    required this.grants,
    required this.actionKey,
    required this.actionIcon,
    required this.actionLabel,
    required this.onAction,
    required this.emptyText,
    required this.onRevoke,
    this.onEditCategories,
  });

  @override
  Widget build(BuildContext context) {
    final visible =
        grants.where((g) => g.status != GrantStatus.revoked).toList();
    // Revoke key contract (Wave 3 live driver, 11-03): when exactly one active
    // grant is listed in this tab its button is ValueKey('family-share-revoke');
    // with several, each is ValueKey('family-share-revoke-<grantId>').
    final singleActive = visible.where((g) => g.isActive).length == 1;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          key: actionKey,
          onPressed: onAction,
          icon: Icon(actionIcon),
          label: Text(actionLabel),
        ),
        const SizedBox(height: 16),
        if (visible.isEmpty)
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DuotoneIconTile(
                  size: 56,
                  radius: 18,
                  child: Icon(Icons.family_restroom,
                      size: 30, color: AppColors.dualisNavy),
                ),
                const SizedBox(height: 12),
                Text(
                  emptyText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        for (final g in visible)
          _GrantTile(
            grant: g,
            revokeKey: ValueKey(singleActive
                ? 'family-share-revoke'
                : 'family-share-revoke-${g.id}'),
            onRevoke: () => onRevoke(g),
            onEditCategories: onEditCategories == null
                ? null
                : () => onEditCategories!(g),
          ),
      ],
    );
  }
}

class _GrantTile extends StatelessWidget {
  final SharedAccessGrant grant;
  final Key revokeKey;
  final VoidCallback onRevoke;
  final VoidCallback? onEditCategories;

  const _GrantTile({
    required this.grant,
    required this.revokeKey,
    required this.onRevoke,
    this.onEditCategories,
  });

  bool get _isExpired =>
      grant.status == GrantStatus.expired ||
      (grant.status == GrantStatus.pending &&
          grant.expiresAt.isBefore(DateTime.now()));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = grant.targetProfileName;
    final viewOnly = grant.accessLevel == ProfileShareLevel.viewOnly;
    final String subtitle;
    if (grant.isActive) {
      final since = grant.acceptedAt;
      subtitle = since == null
          ? l10n.familySharingActive
          : l10n.familySharingActiveSince(
              DateFormat('dd/MM/yyyy').format(since.toLocal()));
    } else if (_isExpired) {
      subtitle = l10n.familySharingExpired;
    } else {
      subtitle = l10n.familySharingPendingUntil(grant.inviteCode ?? '',
          familySharingDateFormat.format(grant.expiresAt.toLocal()));
    }
    final Color statusColor = grant.isActive
        ? AppColors.clinicalTealDark
        : _isExpired
            ? AppColors.emergencyCrimson
            : AppColors.dualisNavy;
    // Owners see who accepted, so a share with the wrong person can be revoked.
    final grantee = grant.isActive && grant.direction == GrantDirection.outgoing
        ? grant.granteeLabel
        : null;

    return Padding(
      key: ValueKey('family-share-grant-${grant.id}'),
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: AppColors.gradientNavy,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    name.isEmpty ? '?' : name[0].toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ProfilePill(subtitle, color: statusColor, maxLines: 3),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ProfilePill(
                  viewOnly
                      ? l10n.familySharingScopeViewOnly
                      : l10n.familySharingScopeCoManage,
                  color: viewOnly
                      ? AppColors.textSecondaryLight
                      : AppColors.clinicalTealDark,
                  icon:
                      viewOnly ? Icons.visibility_outlined : Icons.edit_note,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              relationshipLabel(l10n, grant.relationship),
              key: ValueKey('grant-relationship-${grant.id}'),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondaryLight,
              ),
            ),
            if (grant.categories.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in grant.categories)
                    ProfilePill(
                      shareCategoryLabel(l10n, c),
                      key: ValueKey('grant-category-${grant.id}-${c.apiValue}'),
                      color: AppColors.dualisNavy,
                    ),
                ],
              ),
            ],
            if (grantee != null) ...[
              const SizedBox(height: 10),
              Text(
                l10n.familySharingSharedWith(grantee),
                key: ValueKey('family-share-grantee-${grant.id}'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
            // The PATCH accepts PENDING and ACCEPTED grants only.
            if (onEditCategories != null &&
                (grant.isActive ||
                    (grant.status == GrantStatus.pending && !_isExpired))) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: ValueKey('grant-edit-categories-${grant.id}'),
                  onPressed: onEditCategories,
                  icon: const Icon(Icons.tune, size: 18),
                  label: Text(l10n.familySharingEditCategories),
                ),
              ),
            ],
            if (grant.isActive) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  key: revokeKey,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.emergencyCrimson,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    textStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: onRevoke,
                  icon: const Icon(Icons.block, size: 18),
                  label: Text(l10n.familySharingRevokeButton),
                ),
              ),
            ],
            // A pending invite can be cancelled before anyone uses the code.
            if (grant.status == GrantStatus.pending && !_isExpired) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  key: ValueKey('family-share-cancel-${grant.id}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.emergencyCrimson,
                    side: const BorderSide(
                      color: AppColors.emergencyCrimson,
                      width: 1.5,
                    ),
                    minimumSize: const Size(0, 44),
                    textStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: onRevoke,
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(l10n.familySharingCancelInvite),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
