import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../consent/presentation/ai_consent_controller.dart';
import '../../../consent/presentation/ai_consent_widgets.dart';
import '../../../profile/domain/models/profile.dart';
import '../../../profile/presentation/controllers/active_profile_controller.dart';
import '../../../voice/presentation/voice_widgets.dart';
import '../../data/journal_repository.dart';
import '../controllers/journal_flow_controller.dart';
import '../controllers/journal_flow_state.dart';
import '../journal_labels.dart';

/// Most characters the description may have (server limit).
const int describeTextMaxLength = 1000;

/// What the person decided in "Descrever com minhas palavras".
class DescribeSheetResult {
  const DescribeSheetResult({
    required this.keys,
    required this.keepAsNote,
    required this.text,
  });

  /// Only the options the person turned on. Empty: go on with the normal
  /// steps.
  final List<String> keys;

  /// "Guardar este texto como nota" was checked.
  final bool keepAsNote;

  /// The description as written (kept only when [keepAsNote]).
  final String text;
}

/// Opens "Descrever com minhas palavras" (Premium). The person writes or
/// dictates how they feel; the app shows existing options of [area] that
/// look similar, every one OFF, and returns only the ones turned on with
/// "Usar as selecionadas". Null when the person cancels.
///
/// The text lives only in this sheet's field and is never logged. It leaves
/// the device only after the AI consent, and it is stored only when the
/// person checks "Guardar este texto como nota".
Future<DescribeSheetResult?> showDescribeSheet(
  BuildContext context, {
  required JournalArea area,
  required bool isMale,
}) {
  return showModalBottomSheet<DescribeSheetResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => DescribeSheet(area: area, isMale: isMale),
  );
}

enum _Phase { input, searching, review, message }

class DescribeSheet extends ConsumerStatefulWidget {
  const DescribeSheet({super.key, required this.area, required this.isMale});

  final JournalArea area;
  final bool isMale;

  @override
  ConsumerState<DescribeSheet> createState() => _DescribeSheetState();
}

class _DescribeSheetState extends ConsumerState<DescribeSheet> {
  final _text = TextEditingController();
  bool _keepNote = false;
  _Phase _phase = _Phase.input;
  List<String> _keys = const [];
  final Set<String> _on = {};
  String? _message;

  @override
  void initState() {
    super.initState();
    _text.addListener(_onText);
  }

  @override
  void dispose() {
    _text.removeListener(_onText);
    _text.dispose();
    super.dispose();
  }

  void _onText() {
    if (mounted) setState(() {});
  }

  /// At most [describeTextMaxLength] UTF-16 units, cut between characters.
  String get _clean {
    final value = _text.text.trim();
    if (value.length <= describeTextMaxLength) return value;
    final out = StringBuffer();
    for (final c in value.characters) {
      if (out.length + c.length > describeTextMaxLength) break;
      out.write(c);
    }
    return out.toString();
  }

  void _close({List<String> keys = const []}) {
    Navigator.of(context).pop(
      DescribeSheetResult(keys: keys, keepAsNote: _keepNote, text: _clean),
    );
  }

  void _show(String message) {
    setState(() {
      _phase = _Phase.message;
      _message = message;
    });
  }

  Future<void> _suggest() async {
    final text = _clean;
    if (text.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final repository = ref.read(journalRepositoryProvider);
    // Offline nothing is sent and no consent dialog opens.
    if (!await repository.isOnline()) {
      if (mounted) _show(l10n.jv2DescribeOffline);
      return;
    }
    if (!mounted) return;
    final allowed =
        await ensureAiConsent(context, ref, ask: AiConsentAsk.always);
    if (!mounted) return;
    if (!allowed) {
      _close();
      return;
    }
    setState(() => _phase = _Phase.searching);
    List<String> keys;
    try {
      keys = await repository.suggestEntry(
        text: text,
        area: widget.area.key,
      );
    } on AiSuggestException catch (e) {
      if (!mounted) return;
      if (e.reason == AiSuggestFailure.consentRequired) {
        // The server is the authority: read the consent state again.
        await ref.read(aiConsentControllerProvider.notifier).refresh();
        if (!mounted) return;
      }
      _show(_failureMessage(l10n, e.reason));
      return;
    } catch (_) {
      if (mounted) _show(l10n.jv2DescribeFailed);
      return;
    }
    if (!mounted) return;
    final usable =
        describeUsableKeys(keys, area: widget.area, isMale: widget.isMale);
    if (usable.isEmpty) {
      _show(l10n.jv2DescribeEmpty);
      return;
    }
    setState(() {
      _keys = usable;
      _on.clear();
      _phase = _Phase.review;
    });
  }

  /// A calm line for every failure; the normal steps stay as they were.
  String _failureMessage(AppLocalizations l10n, AiSuggestFailure reason) =>
      switch (reason) {
        AiSuggestFailure.offline => l10n.jv2DescribeOffline,
        AiSuggestFailure.busy => l10n.jv2DescribeBusy,
        AiSuggestFailure.profileNotAllowed => l10n.jv2DescribeProfileNotAllowed,
        AiSuggestFailure.consentRequired ||
        AiSuggestFailure.timeout ||
        AiSuggestFailure.unavailable =>
          l10n.jv2DescribeFailed,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          key: const Key('jv2_describe_sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: switch (_phase) {
            _Phase.input => _input(l10n),
            _Phase.searching => _searching(l10n),
            _Phase.review => _review(l10n),
            _Phase.message => _messageView(l10n),
          },
        ),
      ),
    );
  }

  Widget _title(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

  Widget _hint(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppColors.textSecondaryLight,
          ),
        ),
      );

  Widget _manualButton(AppLocalizations l10n) => TextButton(
        key: const Key('jv2_describe_manual'),
        onPressed: _close,
        child: Text(l10n.jv2DescribeManual),
      );

  List<Widget> _input(AppLocalizations l10n) => [
        _title(l10n.jv2DescribeTitle),
        _hint(l10n.jv2DescribeHint),
        TextField(
          key: const Key('jv2_describe_field'),
          controller: _text,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          maxLength: describeTextMaxLength,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            suffixIcon: voiceAvailable(ref)
                ? VoiceDictationButton(controller: _text, fieldKey: 'describe')
                : null,
          ),
        ),
        CheckboxListTile(
          key: const Key('jv2_describe_keep_note'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _keepNote,
          onChanged: (v) => setState(() => _keepNote = v ?? false),
          title: Text(l10n.jv2DescribeKeepNote),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextButton(
                key: const Key('jv2_describe_cancel'),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.jv2DescribeCancel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                key: const Key('jv2_describe_suggest'),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                onPressed: _clean.isEmpty ? null : _suggest,
                child: Text(l10n.jv2DescribeSuggest),
              ),
            ),
          ],
        ),
      ];

  List<Widget> _searching(AppLocalizations l10n) => [
        _title(l10n.jv2DescribeTitle),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Row(
            key: const Key('jv2_describe_searching'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 14),
              Flexible(child: Text(l10n.jv2DescribeSearching)),
            ],
          ),
        ),
      ];

  String _subtitle(AppLocalizations l10n, String key) {
    final parts = key.split('.');
    final root = JournalLabels.root(l10n, parts[0]);
    final branch = JournalLabels.branch(l10n, '${parts[0]}.${parts[1]}');
    return '$root · $branch';
  }

  List<Widget> _review(AppLocalizations l10n) => [
        _title(l10n.jv2DescribeReviewTitle),
        _hint(l10n.jv2DescribeReviewHint),
        Column(
          key: const Key('jv2_describe_review'),
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final key in _keys)
              SwitchListTile(
                key: Key('jv2_describe_option_$key'),
                contentPadding: EdgeInsets.zero,
                value: _on.contains(key),
                onChanged: (v) => setState(() {
                  v ? _on.add(key) : _on.remove(key);
                }),
                title: Text(JournalLabels.option(l10n, key)),
                subtitle: Text(_subtitle(l10n, key)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('jv2_describe_use'),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
          onPressed: _on.isEmpty
              ? null
              : () => _close(keys: [for (final k in _keys) if (_on.contains(k)) k]),
          child: Text(l10n.jv2DescribeUse),
        ),
        _manualButton(l10n),
      ];

  List<Widget> _messageView(AppLocalizations l10n) => [
        _title(l10n.jv2DescribeTitle),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.dualisSymbolBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _message ?? l10n.jv2DescribeFailed,
            key: const Key('jv2_describe_message'),
            style: GoogleFonts.plusJakartaSans(fontSize: 15),
          ),
        ),
        const SizedBox(height: 12),
        _manualButton(l10n),
      ];
}

/// "Descrever com minhas palavras" is offered on Premium builds, on the
/// account holder's own profile and on dependents they manage. Profiles
/// shared by another account never get AI suggestions (the server refuses
/// them as well).
bool describeAvailable(WidgetRef ref) {
  if (!ref.watch(premiumProfilesEnabledProvider)) return false;
  return aiProfileAllowed(ref.watch(activeProfileControllerProvider).activeProfile);
}

/// AI suggestions are only for the holder's own profile or a dependent
/// they manage. A profile shared by another account gets none: no consent
/// dialog and no request (the server refuses it too).
bool aiProfileAllowed(Profile? profile) =>
    profile == null ||
    (!profile.isShared && profile.accessLevel == ProfileAccessLevel.owner);
