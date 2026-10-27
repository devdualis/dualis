import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/journal_repository.dart';
import '../../domain/journal_keys.dart';
import '../../domain/journal_models.dart';
import '../controllers/journal_flow_controller.dart';

/// "Minhas condições (informadas por você)" (strategy section 18.4): free text
/// written by the user, no list of illnesses, no logic attached to the name.
class MyConditionsScreen extends ConsumerStatefulWidget {
  const MyConditionsScreen({super.key});

  @override
  ConsumerState<MyConditionsScreen> createState() => _MyConditionsScreenState();
}

class _MyConditionsScreenState extends ConsumerState<MyConditionsScreen> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(userConditionsProvider);
    } on JournalOfflineException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.jv2ConditionsOffline)));
    } on JournalConditionLimitException {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.jv2ConditionsLimit(JournalKeys.maxActiveConditions)),
      ));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.jv2ConditionsError)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add() async {
    final label = _controller.text.trim();
    if (label.isEmpty) return;
    await _run(() async {
      await ref.read(journalRepositoryProvider).addCondition(label);
      _controller.clear();
    });
  }

  Future<void> _archive(UserCondition condition) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.jv2ConditionsArchiveConfirm(condition.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.jv2Cancel),
          ),
          FilledButton(
            key: const Key('jv2_conditions_archive_confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.jv2ConditionsArchive),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(
      () => ref.read(journalRepositoryProvider).archiveCondition(condition.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final conditions = ref.watch(userConditionsProvider);
    final list = conditions.value ?? const <UserCondition>[];
    final atLimit = list.length >= JournalKeys.maxActiveConditions;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.jv2ConditionsTitle,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              l10n.jv2ConditionsSubtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.textSecondaryLight,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('jv2_conditions_field'),
                    controller: _controller,
                    enabled: !atLimit && !_busy,
                    maxLength: JournalKeys.conditionLabelMaxLength,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: l10n.jv2ConditionsFieldHint,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: FilledButton.icon(
                    key: const Key('jv2_conditions_add'),
                    onPressed: atLimit || _busy ? null : _add,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.jv2ConditionsAdd),
                  ),
                ),
              ],
            ),
            if (atLimit)
              Text(
                l10n.jv2ConditionsLimit(JournalKeys.maxActiveConditions),
                style: GoogleFonts.plusJakartaSans(fontSize: 12),
              ),
            const SizedBox(height: 12),
            if (conditions.isLoading && list.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (list.isEmpty)
              Text(
                l10n.jv2ConditionsEmpty,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondaryLight,
                ),
              )
            else
              for (final c in list)
                Card(
                  key: Key('jv2_condition_row_${c.id}'),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.outlineLight),
                  ),
                  child: ListTile(
                    leading: const Text('📝', style: TextStyle(fontSize: 22)),
                    title: Text(c.label),
                    trailing: IconButton(
                      key: Key('jv2_condition_archive_${c.id}'),
                      tooltip: l10n.jv2ConditionsArchive,
                      icon: const Icon(Icons.archive_outlined),
                      onPressed: _busy ? null : () => _archive(c),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
