import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/profile_repository.dart';
import '../controllers/active_profile_controller.dart';

/// Opens the claim sheet as a regular modal bottom sheet, like the profile
/// sheet, so the urgent-help button stays on screen. On success shows
/// `profileClaimSuccess` and returns true.
Future<bool> showClaimProfileSheet(BuildContext context) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l10n = AppLocalizations.of(context);
  final claimed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => const ClaimProfileSheet(),
  );
  if (claimed == true) {
    messenger?.showSnackBar(SnackBar(content: Text(l10n.profileClaimSuccess)));
    return true;
  }
  return false;
}

/// The young adult enters the transfer code their guardian generated. On
/// success the claimed profile becomes this account's active own profile and
/// the sheet pops `true`. The code is never logged or stored.
class ClaimProfileSheet extends ConsumerStatefulWidget {
  const ClaimProfileSheet({super.key});

  @override
  ConsumerState<ClaimProfileSheet> createState() => _ClaimProfileSheetState();
}

class _ClaimProfileSheetState extends ConsumerState<ClaimProfileSheet> {
  /// Codes are 10 characters; the API accepts 10-12.
  static const _minLength = 10;
  static const _maxLength = 12;

  final _controller = TextEditingController();
  bool _submitting = false;
  ProfileClaimError? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _ready =>
      !_submitting && _controller.text.trim().length >= _minLength;

  Future<void> _submit() async {
    if (!_ready) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(activeProfileControllerProvider.notifier)
          .claimProfile(_controller.text.trim().toUpperCase());
      if (mounted) Navigator.of(context).pop(true);
    } on ProfileClaimException catch (e) {
      if (mounted) setState(() => _error = e.reason);
    } catch (_) {
      if (mounted) setState(() => _error = ProfileClaimError.other);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _errorText(AppLocalizations l10n, ProfileClaimError error) =>
      switch (error) {
        ProfileClaimError.invalidCode => l10n.profileClaimErrorInvalid,
        ProfileClaimError.byGuardian => l10n.profileClaimErrorGuardian,
        ProfileClaimError.notAdult => l10n.profileClaimErrorNotAdult,
        ProfileClaimError.accountHasData => l10n.profileClaimErrorAccountHasData,
        ProfileClaimError.tooManyAttempts => l10n.profileClaimErrorTooMany,
        ProfileClaimError.other => l10n.profileSwitcherActionError,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = _error;
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.profileClaimTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.profileClaimBody,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const ValueKey('claim-code-field'),
                  controller: _controller,
                  autofocus: true,
                  maxLength: _maxLength,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                    const _UpperCaseFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.profileClaimCodeLabel,
                  ),
                  onChanged: (_) => setState(() => _error = null),
                  onSubmitted: (_) => _submit(),
                ),
                if (error != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _errorText(l10n, error),
                    key: const ValueKey('claim-code-error'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.emergencyCrimson,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  key: const ValueKey('claim-code-submit'),
                  onPressed: _ready ? _submit : null,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.profileClaimSubmit),
                ),
              ],
            ),
          ),
        ),
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
