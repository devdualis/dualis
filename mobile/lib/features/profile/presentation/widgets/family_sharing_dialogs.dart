import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/profile_repository.dart';
import '../../domain/models/shared_access_grant.dart';
import '../controllers/active_profile_controller.dart';

final familySharingDateFormat = DateFormat('dd/MM/yyyy HH:mm');

String relationshipLabel(AppLocalizations l10n, GrantRelationship? r) =>
    switch (r) {
      GrantRelationship.spousePartner =>
        l10n.familySharingRelationshipSpousePartner,
      GrantRelationship.sibling => l10n.familySharingRelationshipSibling,
      GrantRelationship.parent => l10n.familySharingRelationshipParent,
      GrantRelationship.child => l10n.familySharingRelationshipChild,
      GrantRelationship.otherFamily =>
        l10n.familySharingRelationshipOtherFamily,
      GrantRelationship.caregiver => l10n.familySharingRelationshipCaregiver,
      GrantRelationship.friend => l10n.familySharingRelationshipFriend,
      GrantRelationship.other => l10n.familySharingRelationshipOther,
      null => l10n.familySharingRelationshipUnknown,
    };

String shareCategoryLabel(AppLocalizations l10n, ShareCategory c) =>
    switch (c) {
      ShareCategory.habits => l10n.familySharingCategoryHabits,
      ShareCategory.physicalJournal =>
        l10n.familySharingCategoryPhysicalJournal,
      ShareCategory.emotionalJournal =>
        l10n.familySharingCategoryEmotionalJournal,
      ShareCategory.conditions => l10n.familySharingCategoryConditions,
      ShareCategory.care => l10n.familySharingCategoryCare,
    };

/// Guardian confirmation required to share a dependent's data (gap 9).
Widget _dependentConfirmTile(
        AppLocalizations l10n, bool value, ValueChanged<bool> onChanged) =>
    CheckboxListTile(
      key: const ValueKey('family-share-dependent-confirm'),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      value: value,
      title: Text(l10n.familySharingDependentConfirm),
      onChanged: (v) => onChanged(v == true),
    );

/// One checkbox per category (D2), keyed `family-share-category-<apiValue>`.
class FamilySharingCategoryChecklist extends StatelessWidget {
  final Set<ShareCategory> selected;
  final ValueChanged<Set<ShareCategory>> onChanged;

  const FamilySharingCategoryChecklist({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.familySharingCategoriesLabel,
            style: Theme.of(context).textTheme.labelLarge),
        for (final c in ShareCategory.values) ...[
          CheckboxListTile(
            key: ValueKey('family-share-category-${c.apiValue}'),
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            value: selected.contains(c),
            title: Text(shareCategoryLabel(l10n, c)),
            onChanged: (checked) => onChanged(checked == true
                ? {...selected, c}
                : selected.where((x) => x != c).toSet()),
          ),
          // Opt-in only, explained (D2).
          if (c == ShareCategory.emotionalJournal)
            Padding(
              padding: const EdgeInsets.only(left: 48, bottom: 4),
              child: Text(
                l10n.familySharingEmotionalExplanation,
                key: const ValueKey('family-share-emotional-explanation'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
        if (selected.isEmpty)
          Text(l10n.familySharingCategoriesRequired,
              style: const TextStyle(color: AppColors.emergencyCrimson)),
        const SizedBox(height: 8),
        Text(
          l10n.familySharingSafetyNeverShared,
          key: const ValueKey('family-share-safety-never-shared'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

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
  GrantRelationship? _relationship;
  Set<ShareCategory> _categories = {...ShareCategory.defaults};
  bool _dependentConfirmed = false;
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

  /// Any owned profile other than the primary one is a dependent.
  bool get _isDependentTarget => ref
      .read(activeProfileControllerProvider)
      .ownProfiles
      .any((p) => p.id == _profileId && !p.isPrimary);

  bool get _canGenerate =>
      !_submitting &&
      _profileId != null &&
      _relationship != null &&
      _categories.isNotEmpty &&
      (!_isDependentTarget || _dependentConfirmed);

  Future<void> _generate() async {
    final profileId = _profileId;
    final relationship = _relationship;
    if (profileId == null || relationship == null || _categories.isEmpty) {
      return;
    }
    setState(() {
      _submitting = true;
      _failed = false;
    });
    try {
      final invite = await ref
          .read(activeProfileControllerProvider.notifier)
          .createInvite(
            targetProfileId: profileId,
            accessLevel: _level,
            relationship: relationship,
            // Enum order keeps the payload stable.
            categories: [
              for (final c in ShareCategory.values)
                if (_categories.contains(c)) c,
            ],
            dependentShareConfirmed: _isDependentTarget && _dependentConfirmed,
          );
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
                onPressed: _canGenerate ? _generate : null,
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
          // A new target needs a fresh confirmation.
          onChanged: (id) => setState(() {
            _profileId = id;
            _dependentConfirmed = false;
          }),
        ),
        const SizedBox(height: 16),
        Text(l10n.familySharingInviteScopeLabel,
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        _scopeOption(ProfileShareLevel.viewOnly,
            l10n.familySharingScopeViewOnlyOption, Icons.visibility_outlined),
        _scopeOption(ProfileShareLevel.coManage,
            l10n.familySharingScopeCoManageOption, Icons.edit_note),
        const SizedBox(height: 16),
        DropdownButtonFormField<GrantRelationship>(
          key: const ValueKey('family-share-relationship'),
          initialValue: _relationship,
          isExpanded: true,
          decoration:
              InputDecoration(labelText: l10n.familySharingRelationshipLabel),
          items: [
            for (final r in GrantRelationship.values)
              DropdownMenuItem(
                key: ValueKey('family-share-relationship-${r.apiValue}'),
                value: r,
                child: Text(relationshipLabel(l10n, r)),
              ),
          ],
          onChanged: (r) => setState(() => _relationship = r),
        ),
        const SizedBox(height: 16),
        FamilySharingCategoryChecklist(
          selected: _categories,
          onChanged: (next) => setState(() => _categories = next),
        ),
        if (_isDependentTarget)
          _dependentConfirmTile(l10n, _dependentConfirmed,
              (v) => setState(() => _dependentConfirmed = v)),
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
        // One line: 10 characters fit a 320 dp phone at this size.
        SelectableText(
          code,
          key: const ValueKey('family-share-invite-code'),
          textAlign: TextAlign.center,
          maxLines: 1,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
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

/// Result of [FamilySharingEditCategoriesDialog].
typedef FamilySharingCategoryEdit = ({
  List<ShareCategory> categories,
  bool dependentShareConfirmed,
});

/// Owner changes which categories an outgoing grant shares. Pops a
/// [FamilySharingCategoryEdit]; the caller sends the PATCH.
class FamilySharingEditCategoriesDialog extends StatefulWidget {
  final SharedAccessGrant grant;
  final bool isDependentTarget;

  const FamilySharingEditCategoriesDialog({
    super.key,
    required this.grant,
    required this.isDependentTarget,
  });

  @override
  State<FamilySharingEditCategoriesDialog> createState() =>
      _FamilySharingEditCategoriesDialogState();
}

class _FamilySharingEditCategoriesDialogState
    extends State<FamilySharingEditCategoriesDialog> {
  late Set<ShareCategory> _categories = {...widget.grant.categories};
  bool _dependentConfirmed = false;

  bool get _canSave =>
      _categories.isNotEmpty &&
      (!widget.isDependentTarget || _dependentConfirmed);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.familySharingEditCategories),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.grant.targetProfileName,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            FamilySharingCategoryChecklist(
              selected: _categories,
              onChanged: (next) => setState(() => _categories = next),
            ),
            if (widget.isDependentTarget)
              _dependentConfirmTile(l10n, _dependentConfirmed,
                  (v) => setState(() => _dependentConfirmed = v)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.familySharingCancel),
        ),
        FilledButton(
          key: const ValueKey('family-share-edit-save'),
          onPressed: _canSave
              ? () => Navigator.of(context).pop<FamilySharingCategoryEdit>((
                    categories: [
                      for (final c in ShareCategory.values)
                        if (_categories.contains(c)) c,
                    ],
                    dependentShareConfirmed:
                        widget.isDependentTarget && _dependentConfirmed,
                  ))
              : null,
          child: Text(l10n.familySharingSave),
        ),
      ],
    );
  }
}

/// Bottom sheet to enter and accept a 10-char invite code. Pops `true` on success.
class FamilySharingAcceptSheet extends ConsumerStatefulWidget {
  const FamilySharingAcceptSheet({super.key});

  @override
  ConsumerState<FamilySharingAcceptSheet> createState() =>
      _FamilySharingAcceptSheetState();
}

class _FamilySharingAcceptSheetState
    extends ConsumerState<FamilySharingAcceptSheet> {
  static const _codeLength = 10;
  final _controller = TextEditingController();
  bool _submitting = false;
  bool _failed = false;
  bool _tooManyAttempts = false;
  bool _ownCode = false;

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
    } catch (e) {
      if (mounted) {
        setState(() {
          _failed = true;
          // The server caps failed codes per account (429 for 15 minutes).
          _tooManyAttempts = e is ProfileApiException && e.statusCode == 429;
          _ownCode =
              e is ProfileApiException && e.code == 'INVITE_OWN_PROFILE';
        });
      }
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
              errorMaxLines: 3,
              errorText: _failed
                  ? (_tooManyAttempts
                      ? l10n.familySharingAcceptTooMany
                      : _ownCode
                          ? l10n.familySharingAcceptOwnCode
                          : l10n.familySharingAcceptError)
                  : null,
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
