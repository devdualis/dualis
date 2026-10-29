import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/domain/home_greeting.dart';
import '../../../hydration/presentation/controllers/hydration_controller.dart';
import '../../../journal/domain/journal_keys.dart';
import '../../../journal/presentation/journal_labels.dart';
import '../../../journal_insights/domain/chart_data.dart';
import '../../../journal_insights/domain/history_series.dart';
import '../../../journal_insights/domain/journal_insights_models.dart';
import '../../../journal_insights/presentation/controllers/journal_insights_controller.dart';
import '../../../journal_insights/presentation/widgets/body_marker_map.dart';
import '../../../journal_insights/presentation/widgets/combined_calendar.dart';
import '../../../journal_insights/presentation/widgets/history_widgets.dart';
import '../../../journal_insights/presentation/widgets/journal_overview_widgets.dart';
import '../../../journal_insights/presentation/widgets/record_series_chart.dart';
import '../../../journal_insights/presentation/widgets/temporal_pie.dart';
import '../../../journal_insights/presentation/widgets/water_charts.dart';
import '../../../profile/presentation/widgets/active_profile_banner.dart';
import '../../../profile/presentation/widgets/profile_app_bar_pill.dart';

/// History of the last 7 / 30 days (handoff "Dualis | Gráficos do aplicativo"
/// v2.0): what the person recorded, counted and drawn, never interpreted.
/// Everything is computed on the device from one filtered base.
///
/// Emoções: E1 pie, E2 lines per time, E3 answers per time.
/// Corpo: F1 body map, F2 lines per region, F3 answers per region.
/// Água: H1 ring and H2 steps of the picked day, H3 bars, H4 calendar.
/// Juntos: C1 combined calendar. No crossing of times × regions.
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

enum HistoryTab { emotions, body, water, together }

class _DashboardBody extends ConsumerStatefulWidget {
  final JournalInsightsState state;

  const _DashboardBody({required this.state});

  @override
  ConsumerState<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends ConsumerState<_DashboardBody> {
  HistoryTab _tab = HistoryTab.emotions;
  int _days = 30;

  /// Region picked on F3 from "Ver evolução" on the body map.
  String? _bodyRegion;
  final GlobalKey _bodyAnswersKey = GlobalKey();

  /// Day shown on H1/H2 (null = today).
  DateTime? _waterDay;

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
            (HistoryTab.emotions, l10n.gxTabEmotions),
            (HistoryTab.body, l10n.gxTabBody),
            (HistoryTab.water, l10n.gxTabWater),
            (HistoryTab.together, l10n.gxTabTogether),
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
        ...switch (_tab) {
          HistoryTab.emotions => _emotionsTab(l10n, entries, start),
          HistoryTab.body => _bodyTab(l10n, entries, start),
          HistoryTab.water => _waterTab(l10n, today, start),
          HistoryTab.together => _togetherTab(l10n, entries, start),
        },
        if (_tab != HistoryTab.water)
          InsightsCard(
            title: l10n.xv2DashEntriesTitle,
            child: _EntriesList(entries: entries),
          ),
      ],
    );
  }

  /// E1–E3.
  List<Widget> _emotionsTab(
    AppLocalizations l10n,
    List<JournalEntryView> entries,
    DateTime start,
  ) {
    final points = emotionalPoints(l10n, entries);
    final series = emotionalSeries(l10n, points);
    final hasIntensity = points.any((p) => p.intensity != null);
    return [
      InsightsCard(
        title: l10n.gxPieTitle,
        subtitle: l10n.gxPieSubtitle,
        child: TemporalPieChart(pie: TemporalPie.compute(points, entries)),
      ),
      InsightsCard(
        title: l10n.gxLinesTitleEmotional,
        subtitle: l10n.gxLinesSubtitle,
        child: hasIntensity
            ? SeriesLinesCard(
                key: ValueKey('emotional_$_days'),
                keyPrefix: 'emotional',
                series: series,
                start: start,
                days: _days,
              )
            : _emptyText(l10n.xv2DashNoEmotional),
      ),
      if (series.isNotEmpty)
        InsightsCard(
          title: l10n.gxAnswersTitleEmotional,
          subtitle: l10n.gxAnswersSubtitle,
          child: SeriesAnswersCard(
            key: ValueKey('emotional_answers_$_days'),
            keyPrefix: 'emotional',
            series: series,
            tree: JournalKeys.emotionalTree,
            start: start,
            days: _days,
          ),
        ),
    ];
  }

  /// F1–F3.
  List<Widget> _bodyTab(
    AppLocalizations l10n,
    List<JournalEntryView> entries,
    DateTime start,
  ) {
    final points = physicalPoints(l10n, entries);
    final series = physicalSeries(l10n, points);
    final hasIntensity = points.any((p) => p.intensity != null);
    return [
      InsightsCard(
        title: l10n.gxBodyMapTitle,
        child: BodyMarkerMap(
          regions: regionSummaries(points),
          onSeeEvolution: (region) {
            setState(() => _bodyRegion = region);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final target = _bodyAnswersKey.currentContext;
              if (target != null && target.mounted) {
                Scrollable.ensureVisible(target,
                    duration: const Duration(milliseconds: 300));
              }
            });
          },
        ),
      ),
      InsightsCard(
        title: l10n.gxLinesTitlePhysical,
        subtitle: l10n.gxLinesSubtitle,
        child: hasIntensity
            ? SeriesLinesCard(
                key: ValueKey('physical_$_days'),
                keyPrefix: 'physical',
                series: series,
                start: start,
                days: _days,
              )
            : _emptyText(l10n.histNoPhysical),
      ),
      if (series.isNotEmpty)
        InsightsCard(
          key: _bodyAnswersKey,
          title: l10n.gxAnswersTitlePhysical,
          subtitle: l10n.gxAnswersSubtitle,
          child: SeriesAnswersCard(
            key: ValueKey('physical_answers_$_days'),
            keyPrefix: 'physical',
            series: series,
            tree: JournalKeys.physicalTree,
            selected: _bodyRegion,
            start: start,
            days: _days,
          ),
        ),
    ];
  }

  /// Daily totals with today's live total (same base for H1–H4 and C1).
  Map<DateTime, int> _waterTotals(HydrationState water, DateTime today) => {
        ...normalizeWaterTotals(water.last30DaysTotals),
        if (water.todayTotalMl > 0)
          DateTime(today.year, today.month, today.day): water.todayTotalMl,
      };

  int? _goal(HydrationState water) =>
      water.dailyTargetMl > 0 ? water.dailyTargetMl : null;

  /// H1–H4 for the period; H1/H2 follow the day picked on H3/H4.
  List<Widget> _waterTab(
    AppLocalizations l10n,
    DateTime today,
    DateTime start,
  ) {
    final water = ref.watch(hydrationControllerProvider);
    final totals = _waterTotals(water, today);
    final goal = _goal(water);
    final todayDay = DateTime(today.year, today.month, today.day);
    final selected = _waterDay != null && inPeriod(_waterDay!, start, _days)
        ? _waterDay!
        : todayDay;
    final isToday = selected == todayDay;
    final logs = ref.watch(waterLogsForDayProvider(selected));
    final locale = Localizations.localeOf(context).toLanguageTag();
    void pick(DateTime day) => setState(() => _waterDay = day);
    return [
      InsightsCard(
        title: l10n.gxWaterDayTitle(DateFormat('dd/MM', locale).format(selected)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: WaterDayRing(totalMl: totals[selected] ?? 0, goalMl: goal),
            ),
            const SizedBox(height: 16),
            Text(l10n.gxWaterStepTitle, style: _subtitleStyle),
            const SizedBox(height: 8),
            logs.when(
              loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => _emptyText(l10n.gxNoWaterRecord),
              data: (list) => WaterStepChart(
                steps: waterSteps(list),
                goalMl: goal,
                endHour: isToday ? today.hour + today.minute / 60 : 24,
              ),
            ),
          ],
        ),
      ),
      InsightsCard(
        title: l10n.gxWaterBarsTitle,
        child: WaterPeriodBars(
          totals: totals,
          start: start,
          days: _days,
          goalMl: goal,
          today: today,
          selected: selected,
          onDayTap: pick,
        ),
      ),
      InsightsCard(
        title: l10n.gxWaterCalendarTitle,
        subtitle: l10n.gxWaterCalendarHint,
        child: WaterCalendar(
          totals: totals,
          start: start,
          days: _days,
          goalMl: goal,
          selected: selected,
          onDayTap: pick,
        ),
      ),
    ];
  }

  /// C1.
  List<Widget> _togetherTab(
    AppLocalizations l10n,
    List<JournalEntryView> entries,
    DateTime start,
  ) {
    final water = ref.watch(hydrationControllerProvider);
    final today = ref.read(homeClockProvider)();
    return [
      InsightsCard(
        title: l10n.gxCalendarTitle,
        subtitle: l10n.gxCalendarSubtitle,
        child: CombinedCalendar(
          days: calendarDays(
            emotional: emotionalPoints(l10n, entries),
            physical: physicalPoints(l10n, entries),
            waterTotals: _waterTotals(water, today),
          ),
          start: start,
          periodDays: _days,
          goalMl: _goal(water),
        ),
      ),
    ];
  }

  TextStyle get _subtitleStyle => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryLight,
      );

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
