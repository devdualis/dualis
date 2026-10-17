import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/shared_access_grant.dart';
import '../controllers/active_profile_controller.dart';

final familySharingDateFormat = DateFormat('dd/MM/yyyy HH:mm');

/// Invite dialog: pick one of my own profiles + scope, then show the code.
class FamilySharingInviteDialog extends ConsumerStatefulWidget {
  const FamilySharingInviteDialog({super.key});

  @override
  ConsumerState<FamilySharingInviteDialog> createState() =>
      _FamilySharingInviteDialogState();
}

class _FamilySharingInviteDialogState
    extends ConsumerState<FamilySharingInviteDialog> {
  String? _profileId;
  ProfileShareLevel _level = ProfileShareLevel.viewOnly;
  bool _submitting = false;
  bool _failed = false;
  SharedAccessGrant? _invite;

  @override
  void initState() {
    super.initState();
    final state = ref.read(activeProfileControllerProvider);
    final own = state.ownProfiles;
    final active = state.activeProfile;
    _profileId = own.any((p) => p.id == active?.id)
        ? active!.id
        : (own.isEmpty ? null : own.first.id);
  }

  Future<void> _generate() async {
    final profileId = _profileId;
    if (profileId == null) return;
    setState(() {
      _submitting = true;
      _failed = false;
    });
    try {
      final invite = await ref
          .read(activeProfileControllerProvider.notifier)
          .createInvite(targetProfileId: profileId, accessLevel: _level);
      if (mounted) setState(() => _invite = invite);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final invite = _invite;
    return AlertDialog(
      title: Text(l10n.familySharingInviteTitle),
      content: SingleChildScrollView(
        child: invite == null ? _buildForm(l10n) : _buildCode(l10n, invite),
      ),
      actions: invite == null
          ? [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.familySharingCancel),
              ),
              FilledButton(
                key: const ValueKey('family-share-invite-generate'),
                onPressed:
                    _submitting || _profileId == null ? null : _generate,
                child: Text(l10n.familySharingInviteGenerate),
              ),
            ]
          : [
              FilledButton(
                key: const ValueKey('family-share-invite-done'),
                onPressed: () => Navigator.of(context).pop(invite),
                child: Text(l10n.familySharingDone),
              ),
            ],
    );
  }

  Widget _buildForm(AppLocalizations l10n) {
    final own = ref.watch(activeProfileControllerProvider).ownProfiles;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: const ValueKey('family-share-invite-profile'),
          initialValue: _profileId,
          isExpanded: true,
          decoration:
              InputDecoration(labelText: l10n.familySharingInviteProfileLabel),
          items: [
            for (final p in own)
              DropdownMenuItem(value: p.id, child: Text(p.name)),
          ],
          onChanged: (id) => setState(() => _profileId = id),
        ),
        const SizedBox(height: 16),
        Text(l10n.familySharingInviteScopeLabel,
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        _scopeOption(ProfileShareLevel.viewOnly,
            l10n.familySharingScopeViewOnlyOption, Icons.visibility_outlined),
        _scopeOption(ProfileShareLevel.coManage,
            l10n.familySharingScopeCoManageOption, Icons.edit_note),
        if (_failed)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l10n.familySharingInviteError,
                style: const TextStyle(color: AppColors.emergencyCrimson)),
          ),
      ],
    );
  }

  Widget _scopeOption(ProfileShareLevel level, String label, IconData icon) {
    final selected = _level == level;
    return ListTile(
      key: ValueKey('family-share-scope-${level.name}'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      trailing: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? AppColors.clinicalTeal : null,
      ),
      selected: selected,
      onTap: () => setState(() => _level = level),
    );
  }

  Widget _buildCode(AppLocalizations l10n, SharedAccessGrant invite) {
    final code = invite.inviteCode ?? '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.familySharingInviteCodeHint, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        SelectableText(
          code,
          key: const ValueKey('family-share-invite-code'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            letterSpacing: 6,
            color: AppColors.softIndigo,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.familySharingInviteDeadline(
              familySharingDateFormat.format(invite.expiresAt.toLocal())),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const ValueKey('family-share-invite-copy'),
          icon: const Icon(Icons.copy),
          label: Text(l10n.familySharingCopyCode),
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            await Clipboard.setData(ClipboardData(text: code));
            messenger.showSnackBar(
                SnackBar(content: Text(l10n.familySharingCodeCopied)));
          },
        ),
      ],
    );
  }
}

/// Bottom sheet to enter and accept a 6-char invite code. Pops `true` on success.
class FamilySharingAcceptSheet extends ConsumerStatefulWidget {
  const FamilySharingAcceptSheet({super.key});

  @override
  ConsumerState<FamilySharingAcceptSheet> createState() =>
      _FamilySharingAcceptSheetState();
}

class _FamilySharingAcceptSheetState
    extends ConsumerState<FamilySharingAcceptSheet> {
  static const _codeLength = 6;
  final _controller = TextEditingController();
  bool _submitting = false;
  bool _failed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _failed = false;
    });
    try {
      await ref
          .read(activeProfileControllerProvider.notifier)
          .acceptInvite(_controller.text.trim().toUpperCase());
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ready = _controller.text.length == _codeLength && !_submitting;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.familySharingAcceptTitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('invite-code-field'),
            controller: _controller,
            autofocus: true,
            maxLength: _codeLength,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: 4),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
              const _UpperCaseFormatter(),
            ],
            decoration: InputDecoration(
              labelText: l10n.familySharingAcceptFieldLabel,
              errorText: _failed ? l10n.familySharingAcceptError : null,
            ),
            onChanged: (_) => setState(() => _failed = false),
            onSubmitted: (_) => ready ? _submit() : null,
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('invite-code-submit'),
            onPressed: ready ? _submit : null,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.familySharingAcceptSubmit),
          ),
        ],
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  const _UpperCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
          TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
