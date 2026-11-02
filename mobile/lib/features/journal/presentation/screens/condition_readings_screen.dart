import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/presentation/controllers/active_profile_controller.dart';
import '../../domain/journal_keys.dart';
import '../../domain/journal_models.dart';
import '../controllers/condition_readings_controller.dart';
import '../controllers/journal_flow_controller.dart' show userConditionsProvider;
import '../widgets/readings_chart.dart';

/// Periods the history can show, in days.
const List<int> conditionReadingsRanges = [7, 30, 90];

/// History of one condition's readings (Premium): a raw-value chart per
/// reading kind and the readings listed by day. Values are shown exactly as
/// the person typed them, with no label, range, average or comparison.
class ConditionReadingsScreen extends ConsumerStatefulWidget {
  final String conditionId;

  /// Name to show when the condition is no longer in the active list.
  final String? label;

  /// Clock for tests.
  final DateTime Function()? now;

  const ConditionReadingsScreen({
    super.key,
    required this.conditionId,
    this.label,
    this.now,
  });

  @override
  ConsumerState<ConditionReadingsScreen> createState() =>
      _ConditionReadingsScreenState();
}

class _ConditionReadingsScreenState
    extends ConsumerState<ConditionReadingsScreen> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final history = ref.watch(conditionReadingsProvider(widget.conditionId));
    final conditions = ref.watch(userConditionsProvider).value ?? const [];
    UserCondition? condition;
    for (final c in conditions) {
      if (c.id == widget.conditionId) condition = c;
    }
    final name = condition?.label ?? widget.label ?? l10n.chronicHistoryTitle;
    final profile = ref.watch(
      activeProfileControllerProvider.select((s) => s.activeProfile?.name),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.chronicHistoryTitle,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(conditionReadingsProvider(widget.conditionId));
            await ref
                .read(conditionReadingsProvider(widget.conditionId).future)
                .catchError((_) => const ConditionReadingsHistory());
          },
          child: ListView(
            key: const Key('chronic_history_list'),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text(
                name,
                key: const Key('chronic_history_name'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              if (profile != null && profile.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  l10n.chronicHistoryProfile(profile),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              SegmentedButton<int>(
                key: const Key('chronic_history_range'),
                segments: [
                  for (final d in conditionReadingsRanges)
                    ButtonSegment(
                      value: d,
                      label: Text(
                        l10n.chronicHistoryDays(d),
                        key: Key('chronic_history_range_$d'),
                      ),
                    ),
                ],
                selected: {_days},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _days = s.first),
              ),
              const SizedBox(height: 16),
              ...history.when(
                data: (h) => _content(context, l10n, h),
                loading: () => const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
                error: (_, __) => [
                  Text(
                    l10n.chronicHistoryError,
                    key: const Key('chronic_history_error'),
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      key: const Key('chronic_history_retry'),
                      onPressed: () => ref.invalidate(
                          conditionReadingsProvider(widget.conditionId)),
                      child: Text(l10n.chronicHistoryRetry),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    AppLocalizations l10n,
    ConditionReadingsHistory history,
  ) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = (widget.now ?? DateTime.now)();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(today.year, today.month, today.day - (_days - 1));
    final shown = [
      for (final r in history.readings)
        if (!r.measuredAt.toLocal().isBefore(start)) r,
    ];
    // Kinds with readings in the period, in the usual order.
    final kinds = [
      for (final k in JournalKeys.trackingKinds)
        if (shown.any((r) => r.kind == k)) k,
    ];

    return [
      if (!history.complete)
        Container(
          key: const Key('chronic_history_offline'),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.brandBgLightBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 18, color: AppColors.textSecondaryLight),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.chronicHistoryOffline,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      if (shown.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            l10n.chronicHistoryEmpty(_days),
            key: const Key('chronic_history_empty'),
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textSecondaryLight,
            ),
          ),
        )
      else ...[
        for (final kind in kinds)
          _Section(
            key: Key('chronic_history_chart_$kind'),
            title: readingKindLabel(l10n, kind),
            trailing: l10n.chronicHistoryCount(
                shown.where((r) => r.kind == kind).length),
            child: ReadingsChart(
              kind: kind,
              readings: shown,
              start: start,
              days: _days,
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            l10n.chronicHistoryChartHint,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
        for (final day in readingsByDay(shown))
          _DayBlock(day: day, today: today, locale: locale),
      ],
    ];
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String trailing;
  final Widget child;

  const _Section({
    super.key,
    required this.title,
    required this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
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
                  ),
                ),
              ),
              Text(
                trailing,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// One local day: its title and the readings of that day, newest first.
class _DayBlock extends StatelessWidget {
  final ReadingsDay day;
  final DateTime today;
  final String locale;

  const _DayBlock({
    required this.day,
    required this.today,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final date = DateFormat.MMMMd(locale).format(day.day);
    final diff = today.difference(day.day).inDays;
    final title = diff == 0
        ? l10n.chronicHistoryToday(date)
        : diff == 1
            ? l10n.chronicHistoryYesterday(date)
            : DateFormat.yMMMMEEEEd(locale).format(day.day);
    final key = DateFormat('yyyyMMdd').format(day.day);
    return Padding(
      key: Key('chronic_history_day_$key'),
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
          for (final r in day.readings)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineLight),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      DateFormat('HH:mm', locale).format(r.measuredAt.toLocal()),
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          readingKindLabel(l10n, r.kind),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        Text(
                          readingValueText(l10n, locale, r),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (r.pendingSync)
                    Tooltip(
                      message: l10n.chronicHistoryPending,
                      child: const Icon(
                        Icons.cloud_upload_outlined,
                        size: 18,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
