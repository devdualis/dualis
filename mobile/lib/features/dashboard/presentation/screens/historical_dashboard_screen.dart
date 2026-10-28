import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/domain/home_greeting.dart';
import '../../../journal_insights/domain/history_series.dart';
import '../../../journal_insights/domain/journal_insights_models.dart';
import '../../../journal/presentation/journal_labels.dart';
import '../../../journal_insights/presentation/controllers/journal_insights_controller.dart';
import '../../../journal_insights/presentation/widgets/history_widgets.dart';
import '../../../journal_insights/presentation/widgets/region_timeline_sheet.dart';
import '../../../journal_insights/presentation/widgets/journal_overview_widgets.dart';
import '../../../profile/presentation/widgets/active_profile_banner.dart';
import '../../../profile/presentation/widgets/profile_app_bar_pill.dart';

/// History of the last 7 / 30 / 90 days (strategy §9): what the person
/// recorded, counted and drawn, never interpreted. Everything is computed on
/// the device from the loaded entries.
///
/// Psicoemocional: one intensity line per emotional branch with chips that
/// show or hide each line, then the Passado · Presente · Futuro bar.
/// Físico: body map or time-to-region flow for the period, then one line per
/// region (optional dashed emotional line) and count-only sentences (§9.2).
/// Water lives on the Água tab only.
class HistoricalDashboardScreen extends ConsumerWidget {
  final bool isEmbedded;
  const HistoricalDashboardScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final insightsAsync = ref.watch(journalInsightsControllerProvider);

    final content = insightsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.errorLoadHistory,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                key: const Key('dashboard_retry_button'),
                onPressed: () => ref
                    .read(journalInsightsControllerProvider.notifier)
                    .refresh(),
                child: Text(l10n.xv2DashRetry),
              ),
            ],
          ),
        ),
      ),
      data: (state) => RefreshIndicator(
        onRefresh: () =>
            ref.read(journalInsightsControllerProvider.notifier).refresh(),
        child: _DashboardBody(state: state),
      ),
    );

    if (isEmbedded) return content;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          l10n.xv2DashTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimaryLight,
        actions: [
          if (ref.watch(premiumProfilesEnabledProvider)) ...[
            const ProfileAppBarPill(),
            const SizedBox(width: 4),
          ],
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () =>
                ref.read(journalInsightsControllerProvider.notifier).refresh(),
          ),
          // Space for the global urgent-help button (UrgentHelpOverlay).
          const SizedBox(width: 56),
        ],
      ),
      body: content,
    );
  }
}

enum HistoryTab { emotional, physical }

enum _PhysicalView { map, links }

class _DashboardBody extends ConsumerStatefulWidget {
  final JournalInsightsState state;

  const _DashboardBody({required this.state});

  @override
  ConsumerState<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends ConsumerState<_DashboardBody> {
  HistoryTab _tab = HistoryTab.emotional;
  int _days = 30;
  _PhysicalView _physicalView = _PhysicalView.map;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final today = ref.read(homeClockProvider)();
    final entries =
        entriesInPeriod(widget.state.entries, today: today, days: _days);
    final start = periodStart(today, _days);

    return ListView(
      key: const Key('journal_dashboard'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        const ActiveProfileBanner(),
        HistorySegmented<HistoryTab>(
          keyPrefix: 'history_tab',
          options: [
            (HistoryTab.emotional, l10n.histTabEmotional),
            (HistoryTab.physical, l10n.histTabPhysical),
          ],
          selected: _tab,
          onChanged: (tab) => setState(() => _tab = tab),
        ),
        const SizedBox(height: 12),
        HistoryPeriodChips(
          selected: _days,
          onChanged: (days) => setState(() => _days = days),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 10),
          child: Text(
            l10n.xv2DashWindow(_days),
            key: const Key('dashboard_window_label'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
        if (_tab == HistoryTab.emotional)
          ..._emotionalTab(l10n, entries, today, start)
        else
          ..._physicalTab(l10n, entries, today, start),
        InsightsCard(
          title: l10n.xv2DashEntriesTitle,
          child: _EntriesList(entries: entries),
        ),
      ],
    );
  }

  List<Widget> _emotionalTab(
    AppLocalizations l10n,
    List<JournalEntryView> entries,
    DateTime today,
    DateTime start,
  ) {
    final lines = emotionalLines(l10n, entries, today: today, days: _days);
    final summary = JournalSummary.compute(entries);
    return [
      InsightsCard(
        title: _days == 7
            ? l10n.histEmotionalTitleWeek
            : l10n.histEmotionalTitle(_days),
        subtitle: l10n.histIntensitySubtitle,
        child: lines.isEmpty
            ? _emptyText(l10n.xv2DashNoEmotional)
            : ToggleableLines(
                key: ValueKey('emotional_$_days'),
                keyPrefix: 'emotional',
                lines: lines,
                palette: emotionalLineColors,
                days: _days,
                start: start,
              ),
      ),
      InsightsCard(
        title: l10n.histTimeBarTitle,
        child: TimeDistributionBar(byTime: summary.byTime),
      ),
    ];
  }

  List<Widget> _physicalTab(
    AppLocalizations l10n,
    List<JournalEntryView> entries,
    DateTime today,
    DateTime start,
  ) {
    final lines = physicalLines(l10n, entries, today: today, days: _days);
    final summary = JournalSummary.compute(entries);
    final overlay = _overlayFor(
      lines,
      emotionalLines(l10n, entries, today: today, days: _days),
    );
    bool isRegion(String key) => historyRegions.contains(key);
    final sentences = cooccurrenceSentences(
      l10n,
      summary,
      entries,
      where: (a, b) => isRegion(a) || isRegion(b),
      labelOf: (key) => historyMarkerLabel(l10n, key),
    );
    final title = switch (_days) {
      7 => l10n.histPhysicalTitleWeek,
      30 => l10n.histPhysicalTitleMonth,
      _ => l10n.histPhysicalTitle(_days),
    };
    return [
      Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                HistorySegmented<_PhysicalView>(
                  keyPrefix: 'physical_view',
                  compact: true,
                  options: [
                    (_PhysicalView.map, l10n.histViewMap),
                    (_PhysicalView.links, l10n.histViewLinks),
                  ],
                  selected: _physicalView,
                  onChanged: (v) => setState(() => _physicalView = v),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_physicalView == _PhysicalView.map)
              HistoryBodyMap(
                byRegion: summary.byRegion,
                onRegionTap: (region) => showRegionTimelineSheet(
                  context,
                  timeline: regionTimeline(
                    l10n,
                    entries,
                    region,
                    today: today,
                    days: _days,
                  ),
                  days: _days,
                  start: start,
                ),
              )
            else
              TimeRegionFlow(links: timeRegionDays(entries)),
          ],
        ),
      ),
      InsightsCard(
        title: l10n.histTimelineTitle,
        subtitle: l10n.histIntensitySubtitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (lines.isEmpty)
              _emptyText(l10n.histNoPhysical)
            else
              ToggleableLines(
                key: ValueKey('physical_$_days'),
                keyPrefix: 'physical',
                lines: lines,
                palette: physicalLineColors,
                days: _days,
                start: start,
                overlay: overlay,
              ),
            if (sentences.isNotEmpty) ...[
              const SizedBox(height: 12),
              Column(
                key: const Key('cooccurrence_sentences'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final s in sentences)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        s,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    ];
  }

  /// Emotional line offered as a dashed overlay: the one sharing the most
  /// days with the first physical line, then the one with most days.
  HistoryLine? _overlayFor(
    List<HistoryLine> physical,
    List<HistoryLine> emotional,
  ) {
    if (physical.isEmpty || emotional.isEmpty) return null;
    final reference = physical.first.days;
    HistoryLine? best;
    var bestShared = -1;
    for (final line in emotional) {
      final shared = line.days.intersection(reference).length;
      if (shared > bestShared ||
          (shared == bestShared && line.days.length > best!.days.length)) {
        best = line;
        bestShared = shared;
      }
    }
    return best;
  }

  Widget _emptyText(String text) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: AppColors.textSecondaryLight,
        ),
      );
}

class _EntriesList extends ConsumerWidget {
  final List<JournalEntryView> entries;

  const _EntriesList({required this.entries});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    JournalEntryView entry,
  ) async {
    final l10n = AppLocalizations.of(context);
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
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.xv2DashDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(journalInsightsControllerProvider.notifier)
          .deleteEntry(entry.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (entries.isEmpty) {
      return Text(
        l10n.xv2DashNoEntries,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: AppColors.textSecondaryLight,
        ),
      );
    }
    final canDelete = !activeProfileIsViewOnly(ref);
    final dateFormat =
        DateFormat.yMd(Localizations.localeOf(context).toLanguageTag());
    return Column(
      children: [
        for (final entry in entries)
          Container(
            key: Key('journal_entry_${entry.id}'),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFormat.format(entry.recordedAt),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      if (entry.pendingSync) ...[
                        const SizedBox(height: 2),
                        Text(
                          l10n.jv2PendingSync,
                          key: Key('journal_entry_pending_${entry.id}'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      if (entry.items.isEmpty && entry.mood != null)
                        _line(l10n.xv2DashMoodLine(
                            JournalLabels.mood(l10n, entry.mood!))),
                      for (final item in entry.items)
                        _line(
                          item.intensity != null
                              ? '${item.label(l10n)} · ${l10n.xv2ReportedIntensity(item.intensity!)}'
                              : item.label(l10n),
                        ),
                    ],
                  ),
                ),
                if (canDelete && !entry.legacy && !entry.pendingSync)
                  IconButton(
                    key: Key('journal_entry_delete_${entry.id}'),
                    tooltip: l10n.xv2DashDeleteTitle,
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: AppColors.textSecondaryLight),
                    onPressed: () => _confirmDelete(context, ref, entry),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _line(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.textPrimaryLight,
          ),
        ),
      );
}
