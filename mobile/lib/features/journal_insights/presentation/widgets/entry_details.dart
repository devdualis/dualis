import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../journal/domain/journal_keys.dart';
import '../../../journal/presentation/journal_item_text.dart';
import '../../../journal/presentation/journal_labels.dart';
import '../../domain/journal_insights_models.dart';

/// Title of one item in the person's words: "🔥 Barriga · Incômodo · Gases
/// ou barriga estufada", "🛑 O que já passou · Culpa ou arrependimento".
String entryItemTitle(AppLocalizations l10n, JournalItemView item) {
  final key = item.optionKey;
  final parts = key?.split('.') ?? const <String>[];
  final emoji = key == null
      ? null
      : journalEmojis[key] ??
          (parts.length >= 2 ? journalEmojis['${parts[0]}.${parts[1]}'] : null) ??
          journalEmojis[parts.first];
  final answer = item.customLabel?.isNotEmpty == true
      ? item.customLabel!
      : (key == null || item.isCustom
          ? item.label(l10n)
          : JournalLabels.option(l10n, key));
  final head = <String>[
    if (item.region != null) JournalLabels.region(l10n, item.region!) ?? item.region!,
    if (item.region != null && item.sensation != null)
      JournalLabels.sensation(l10n, item.sensation!),
    if (item.time != null) JournalLabels.time(l10n, item.time!) ?? item.time!,
    if (answer.isNotEmpty) answer,
  ];
  final text = head.join(' · ');
  return emoji == null ? text : '$emoji $text';
}

/// "Há quanto tempo: Meses ou anos · Intensidade 3/5", or null.
String? entryItemAnswers(AppLocalizations l10n, JournalItemView item) {
  final parts = [
    if (item.persistence != null)
      l10n.jv24EntryPersistence(JournalLabels.persistence(l10n, item.persistence!)),
    if (item.intensity != null) l10n.gxIntensityValue(item.intensity!),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// Everything the person recorded in one entry, in their words: each item
/// with how long and how much, then what may have contributed, how it was
/// to deal with it, what helped and the note. Nothing is interpreted.
class JournalEntryDetails extends StatelessWidget {
  final JournalEntryView entry;

  /// False on screens that already list the items (body map marks).
  final bool showItems;

  const JournalEntryDetails({
    super.key,
    required this.entry,
    this.showItems = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final strong = GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.35,
      color: AppColors.textPrimaryLight,
    );
    final soft = GoogleFonts.plusJakartaSans(
      fontSize: 13,
      height: 1.35,
      color: AppColors.textSecondaryLight,
    );
    final triggers = [
      for (final t in entry.triggers)
        t == JournalKeys.triggerOutro && (entry.triggerNote?.isNotEmpty ?? false)
            ? '${JournalLabels.trigger(l10n, t)} (${entry.triggerNote})'
            : JournalLabels.trigger(l10n, t),
    ];
    Widget line(String text, TextStyle style, [Key? key]) => Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(text, key: key, style: style),
        );
    return Column(
      key: Key('entry_details_${entry.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showItems) ...[
          if (entry.items.isEmpty && entry.mood != null)
            line(l10n.xv2DashMoodLine(JournalLabels.mood(l10n, entry.mood!)), strong),
          for (final item in entry.items) ...[
            line(entryItemTitle(l10n, item), strong),
            if (entryItemAnswers(l10n, item) case final answers?)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(answers, style: soft),
              ),
          ],
        ],
        if (triggers.isNotEmpty)
          line(l10n.jv24EntryTriggers(triggers.join(', ')), soft,
              Key('entry_triggers_${entry.id}')),
        if (entry.coping != null)
          line(l10n.jv22EntryCoping(JournalLabels.coping(l10n, entry.coping!)), soft,
              Key('entry_coping_${entry.id}')),
        if (entry.helpers.isNotEmpty)
          line(
            l10n.jv22EntryHelpers(
                entry.helpers.map((h) => JournalLabels.helper(l10n, h)).join(', ')),
            soft,
            Key('entry_helpers_${entry.id}'),
          ),
        if (entry.note?.trim().isNotEmpty ?? false)
          line(l10n.jv24EntryNote(entry.note!.trim()), soft, Key('entry_note_${entry.id}')),
      ],
    );
  }
}
