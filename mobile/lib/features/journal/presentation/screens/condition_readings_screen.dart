import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/duotone_icon_tile.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../care/presentation/widgets/care_widgets.dart' show careAppBar;
import '../../../profile/domain/models/share_category.dart';
import '../../../profile/presentation/controllers/active_profile_controller.dart';
import '../../../profile/presentation/widgets/active_profile_banner.dart';
import '../../../profile/presentation/widgets/not_shared_placeholder.dart';
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
    if (!activeProfileCanRead(ref, ShareCategory.conditions)) {
      // This screen only reads; adding readings happens in the journal.
      return Scaffold(
        backgroundColor: AppColors.backgroundDepth,
        appBar: careAppBar(context, l10n.chronicHistoryTitle),
        body: SafeArea(
          child: NotSharedPlaceholder(
            profileName: ref.watch(activeProfileControllerProvider
                    .select((s) => s.activeProfile?.name)) ??
                '',
          ),
        ),
      );
    }
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
      backgroundColor: AppColors.backgroundDepth,
      appBar: careAppBar(context, l10n.chronicHistoryTitle),
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                name,
                key: const Key('chronic_history_name'),
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppColors.dualisNavy,
                ),
              ),
              if (profile != null && profile.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  l10n.chronicHistoryProfile(profile),
                  style: GoogleFonts.inter(
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
                  GlassCard(
                    radius: 22,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(
                          child: DuotoneIconTile(
                            size: 48,
                            radius: 14,
                            child: Icon(
                              Icons.error_outline_rounded,
                              size: 24,
                              color: AppColors.dualisNavy,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.chronicHistoryError,
                          key: const Key('chronic_history_error'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            height: 1.4,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 14),
                        FilledButton(
                          key: const Key('chronic_history_retry'),
                          onPressed: () => ref.invalidate(
                              conditionReadingsProvider(widget.conditionId)),
                          child: Text(l10n.chronicHistoryRetry),
                        ),
                      ],
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
        Padding(
          key: const Key('chronic_history_offline'),
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            radius: 18,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const DuotoneIconTile(
                  size: 32,
                  radius: 10,
                  child: Icon(Icons.cloud_off_outlined,
                      size: 18, color: AppColors.dualisNavy),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.chronicHistoryOffline,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.35,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      if (shown.isEmpty)
        GlassCard(
          radius: 22,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: Column(
            children: [
              const DuotoneIconTile(
                size: 48,
                radius: 14,
                child: Icon(Icons.show_chart_rounded,
                    size: 24, color: AppColors.dualisNavy),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.chronicHistoryEmpty(_days),
                key: const Key('chronic_history_empty'),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
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
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 18),
          child: Text(
            l10n.chronicHistoryChartHint,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.4,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        radius: 22,
        padding: const EdgeInsets.fromLTRB(12, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  Text(
                    trailing,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
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
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
                color: AppColors.textPrimaryLight,
              ),
            ),
          ),
          for (final r in day.readings)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
              decoration: BoxDecoration(
                color: AppColors.dualisNavy.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.dualisNavy.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                children: [
                  DuotoneIconTile(
                    size: 36,
                    radius: 10,
                    child: Icon(
                      _kindIcon(r.kind),
                      size: 20,
                      color: AppColors.dualisNavy,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          readingValueText(l10n, locale, r),
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          readingKindLabel(l10n, r.kind),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('HH:mm', locale).format(r.measuredAt.toLocal()),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dualisNavy,
                        ),
                      ),
                      if (r.pendingSync)
                        Tooltip(
                          message: l10n.chronicHistoryPending,
                          child: Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.iconTileTint,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.cloud_upload_outlined,
                              size: 14,
                              color: AppColors.dualisNavy,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static IconData _kindIcon(String kind) => switch (kind) {
        JournalKeys.trackingBloodPressure => Icons.favorite_border_rounded,
        JournalKeys.trackingGlucose => Icons.water_drop_outlined,
        _ => Icons.monitor_weight_outlined,
      };
}
