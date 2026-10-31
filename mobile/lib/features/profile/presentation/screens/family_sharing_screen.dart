import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/shared_access_grant.dart';
import '../controllers/active_profile_controller.dart';
import '../widgets/family_sharing_dialogs.dart';

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
            const Icon(Icons.family_restroom,
                size: 64, color: AppColors.softIndigo),
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
      showDragHandle: true,
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
        title: Text(l10n.familySharingRevokeConfirmTitle),
        content: Text(l10n.familySharingRevokeConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.familySharingCancel),
          ),
          FilledButton(
            key: const ValueKey('family-share-revoke-confirm'),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.emergencyCrimson),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(activeProfileControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.familySharingTitle),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            // Two-line labels: the pt-BR copy does not fit one line on
            // narrow phones.
            Tab(
              key: const ValueKey('family-share-tab-outgoing'),
              height: 56,
              child: Text(l10n.familySharingTabOutgoing,
                  textAlign: TextAlign.center, maxLines: 2),
            ),
            Tab(
              key: const ValueKey('family-share-tab-incoming'),
              height: 56,
              child: Text(l10n.familySharingTabIncoming,
                  textAlign: TextAlign.center, maxLines: 2),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (state.isLoading) const LinearProgressIndicator(minHeight: 2),
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

  const _GrantList({
    required this.grants,
    required this.actionKey,
    required this.actionIcon,
    required this.actionLabel,
    required this.onAction,
    required this.emptyText,
    required this.onRevoke,
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(emptyText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        for (final g in visible)
          _GrantTile(
            grant: g,
            revokeKey: ValueKey(singleActive
                ? 'family-share-revoke'
                : 'family-share-revoke-${g.id}'),
            onRevoke: () => onRevoke(g),
          ),
      ],
    );
  }
}

class _GrantTile extends StatelessWidget {
  final SharedAccessGrant grant;
  final Key revokeKey;
  final VoidCallback onRevoke;

  const _GrantTile({
    required this.grant,
    required this.revokeKey,
    required this.onRevoke,
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
    // Owners see who accepted, so a share with the wrong person can be revoked.
    final grantee = grant.isActive && grant.direction == GrantDirection.outgoing
        ? grant.granteeLabel
        : null;

    return Card(
      key: ValueKey('family-share-grant-${grant.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.softIndigoLight,
                  foregroundColor: AppColors.softIndigo,
                  child: Text(name.isEmpty ? '?' : name[0].toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: _isExpired
                              ? AppColors.emergencyCrimson
                              : Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(
                      viewOnly ? Icons.visibility_outlined : Icons.edit_note,
                      size: 16),
                  label: Text(viewOnly
                      ? l10n.familySharingScopeViewOnly
                      : l10n.familySharingScopeCoManage),
                ),
              ],
            ),
            if (grantee != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.familySharingSharedWith(grantee),
                key: ValueKey('family-share-grantee-${grant.id}'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (grant.isActive) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  key: revokeKey,
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.emergencyCrimson,
                      foregroundColor: Colors.white),
                  onPressed: onRevoke,
                  icon: const Icon(Icons.block, size: 18),
                  label: Text(l10n.familySharingRevokeButton),
                ),
              ),
            ],
            // A pending invite can be cancelled before anyone uses the code.
            if (grant.status == GrantStatus.pending && !_isExpired) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  key: ValueKey('family-share-cancel-${grant.id}'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.emergencyCrimson),
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
