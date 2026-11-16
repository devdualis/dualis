import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/duotone_icon_tile.dart';
import '../../../journal/domain/journal_keys.dart';
import '../../../journal/presentation/journal_labels.dart';
import '../../../journal_insights/domain/journal_insights_models.dart';
import '../../../journal_insights/presentation/controllers/journal_insights_controller.dart';
import '../../../journal_insights/presentation/widgets/chart_tokens.dart';
import '../../../journal_insights/presentation/widgets/combined_calendar.dart';
import '../../../journal_insights/presentation/widgets/entry_details.dart';
import '../../../profile/domain/models/share_category.dart';
import '../../../profile/presentation/widgets/active_profile_banner.dart';

/// How many entries the card shows before "Ver todos".
const int kJournalEntriesPreview = 3;

/// The "Registros" card body: the newest entries as one-line rows and, when
/// there are more, a "Ver todos (N)" button that opens the whole period in a
/// sheet. A row opens that entry in full, where it can be deleted.
class JournalEntriesCard extends StatelessWidget {
  final List<JournalEntryView> entries;

  const JournalEntriesCard({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (entries.isEmpty) {
      return Text(
        l10n.xv2DashNoEntries,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondaryLight,
        ),
      );
    }
    final shown = entries.take(kJournalEntriesPreview).toList();
    return Column(
      children: [
        for (final entry in shown)
          JournalEntryRow(
            entry: entry,
            onTap: () => showJournalEntrySheet(context, entry),
          ),
        if (entries.length > kJournalEntriesPreview)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('journal_entries_see_all'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.dualisNavy,
                minimumSize: const Size.fromHeight(44),
                shape: const StadiumBorder(),
                side: BorderSide(
                  color: AppColors.dualisNavy.withValues(alpha: 0.18),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => _showAllSheet(context, entries),
              child: Text(l10n.xv2DashSeeAll(entries.length)),
            ),
          ),
      ],
    );
  }
}

/// True when this person may delete the entry: not view-only and with write
/// access to the entry's journal branch (physical entries: physical journal;
/// everything else: emotional). Legacy and not-yet-synced entries never are.
bool _canDelete(WidgetRef ref, JournalEntryView entry) {
  if (entry.legacy || entry.pendingSync) return false;
  if (activeProfileIsViewOnly(ref)) return false;
  return activeProfileCanWrite(
    ref,
    entry.area == JournalKeys.areaPhysical
        ? ShareCategory.physicalJournal
        : ShareCategory.emotionalJournal,
  );
}

/// Neutral mark of the entry's branch: the head in profile for the emotional
/// journal, the body figure for the physical one. No faces.
Widget _entryMark(JournalEntryView entry) {
  final physical = entry.area == JournalKeys.areaPhysical ||
      (entry.area == null && entry.items.any((i) => i.kind == 'physical'));
  return DuotoneIconTile(
    size: 36,
    radius: 10,
    child: physical
        ? const BodyFigureIcon(size: 20, color: ChartTokens.body)
        : const HeadProfileIcon(size: 20, color: AppColors.dualisNavy),
  );
}

/// One line: up to two items in the person's words, or the mood for a "Bem".
String _entryLabel(AppLocalizations l10n, JournalEntryView entry) {
  if (entry.items.isEmpty) {
    return entry.mood == null ? '' : JournalLabels.mood(l10n, entry.mood!);
  }
  return entry.items
      .take(2)
      .map((i) => entryItemTitle(l10n, i, withEmoji: false))
      .join(', ');
}

/// A single-line entry: date, neutral mark, ellipsized label, chevron.
class JournalEntryRow extends StatelessWidget {
  final JournalEntryView entry;
  final VoidCallback onTap;

  /// Keeps keys unique when the same entry is listed twice (card + sheet).
  final String keySuffix;

  const JournalEntryRow({
    super.key,
    required this.entry,
    required this.onTap,
    this.keySuffix = '',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateFormat.Md(locale).add_Hm().format(entry.recordedAt);
    final label = _entryLabel(l10n, entry);
    final spoken = [
      date,
      if (label.isNotEmpty) label,
      if (entry.pendingSync) l10n.jv2PendingSync,
    ].join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        container: true,
        label: spoken,
        child: ExcludeSemantics(
          child: Material(
            color: AppColors.dualisNavy.withValues(alpha: 0.04),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: AppColors.dualisNavy.withValues(alpha: 0.06),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: Key('journal_entry_$keySuffix${entry.id}'),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                child: Row(
                  children: [
                    _entryMark(entry),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  date,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                              if (entry.pendingSync) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.iconTileTint,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    l10n.jv2PendingSync,
                                    key: Key(
                                        'journal_entry_pending_$keySuffix${entry.id}'),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.dualisNavy,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (label.isNotEmpty)
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: AppColors.textSecondaryLight,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the full entry in a glass sheet, with the delete action when the
/// person may delete it. Resolves to true when the entry was deleted.
Future<bool?> showJournalEntrySheet(
  BuildContext context,
  JournalEntryView entry,
) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _EntryDetailSheet(entry: entry),
  );
}

Future<void> _showAllSheet(
  BuildContext context,
  List<JournalEntryView> entries,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, controller) => _AllEntriesSheet(
        entries: entries,
        controller: controller,
      ),
    ),
  );
}

class _AllEntriesSheet extends StatelessWidget {
  final List<JournalEntryView> entries;
  final ScrollController controller;

  const _AllEntriesSheet({required this.entries, required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      key: const Key('journal_entries_all_sheet'),
      controller: controller,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            l10n.xv2DashEntriesTitle,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
            ),
          ),
        ),
        for (final entry in entries)
          JournalEntryRow(
            entry: entry,
            keySuffix: 'all_',
            onTap: () async {
              final deleted = await showJournalEntrySheet(context, entry);
              // The list below is a snapshot: close it once an entry is gone.
              if (deleted == true && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
      ],
    );
  }
}

class _EntryDetailSheet extends ConsumerWidget {
  final JournalEntryView entry;

  const _EntryDetailSheet({required this.entry});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(journalInsightsControllerProvider.notifier);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.xv2DashDeleteTitle),
        content: Text(l10n.xv2DashDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('dashboard_delete_confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.dualisNavy,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.xv2DashDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await controller.deleteEntry(entry.id);
    if (context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateFormat.yMd(locale).add_Hm().format(entry.recordedAt);
    return SafeArea(
      child: SingleChildScrollView(
        key: Key('journal_entry_sheet_${entry.id}'),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _entryMark(entry),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    date,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                if (entry.pendingSync)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.iconTileTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      l10n.jv2PendingSync,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dualisNavy,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            JournalEntryDetails(entry: entry),
            if (_canDelete(ref, entry)) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: Key('journal_entry_delete_${entry.id}'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondaryLight,
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: Text(l10n.xv2DashDeleteTitle),
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
