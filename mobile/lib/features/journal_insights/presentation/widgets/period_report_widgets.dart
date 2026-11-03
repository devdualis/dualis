import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../journal/presentation/journal_labels.dart';
import '../../domain/journal_insights_models.dart';
import '../../domain/period_report.dart';
import 'chart_tokens.dart';

/// One colour for every bar: the length is a count, never a grade.
const Color _barColor = ChartTokens.body;
const Color _trackColor = Color(0xFFEFF3F7);

TextStyle get _textStyle => GoogleFonts.plusJakartaSans(
      fontSize: 13,
      color: AppColors.textPrimaryLight,
    );

TextStyle get _smallStyle => GoogleFonts.plusJakartaSans(
      fontSize: 11,
      color: AppColors.textSecondaryLight,
    );

const List<String> _weekdayKeys = [
  'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun', //
];

/// "A, B e C" in the current language.
String _joinList(AppLocalizations l10n, List<String> items) {
  if (items.length == 1) return items.first;
  return l10n.histListAnd(
    items.sublist(0, items.length - 1).join(', '),
    items.last,
  );
}

/// D16: the "não tão bem" sentence and records per weekday for the period.
class PeriodSummary extends StatelessWidget {
  /// Entries of the selected period.
  final List<JournalEntryView> entries;
  final int days;

  const PeriodSummary({super.key, required this.entries, required this.days});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final notWell = NotWellTimeSummary.compute(entries);
    final weekdays = recordsByWeekday(entries);
    final most = mostRecordedWeekdays(weekdays);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (notWell != null)
          for (final time in notWell.times)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l10n.histNotWellTimeSummary(
                    days, notWell.count, notWell.total, time),
                key: Key('period_not_well_$time'),
                style: _textStyle,
              ),
            ),
        if (most.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.histWeekdayMost(_joinList(l10n, [
                for (final d in most) l10n.histWeekdayOn(_weekdayKeys[d - 1]),
              ])),
              key: const Key('period_weekday_most'),
              style: _textStyle,
            ),
          ),
        WeekdayBars(counts: weekdays),
      ],
    );
  }
}

/// Seven bars, Monday first, with the number of records above each one.
class WeekdayBars extends StatelessWidget {
  final Map<int, int> counts;
  static const double maxBarHeight = 56;

  const WeekdayBars({super.key, required this.counts});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final short = DateFormat.E(locale);
    final max = counts.values.fold(0, (a, b) => a > b ? a : b);
    return Row(
      key: const Key('period_weekday_bars'),
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var d = DateTime.monday; d <= DateTime.sunday; d++)
          Expanded(
            child: Semantics(
              label: l10n.histWeekdayBar(
                // 2024-01-01 is a Monday.
                DateFormat.EEEE(locale).format(DateTime(2024, 1, d)),
                counts[d] ?? 0,
              ),
              excludeSemantics: true,
              child: Column(
                key: Key('period_weekday_$d'),
                children: [
                  Text('${counts[d] ?? 0}', style: _smallStyle),
                  const SizedBox(height: 4),
                  Container(
                    width: 18,
                    height: max == 0
                        ? 2
                        : 2 + (maxBarHeight - 2) * (counts[d] ?? 0) / max,
                    decoration: BoxDecoration(
                      color: (counts[d] ?? 0) == 0 ? _trackColor : _barColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    short.format(DateTime(2024, 1, d)),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: _smallStyle,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// D17: "Como você se sentiu", records per everyday feeling, fixed order.
class EverydayFeelingsSummary extends StatelessWidget {
  final EverydayFeelingCounts counts;

  const EverydayFeelingsSummary({super.key, required this.counts});

  static String label(AppLocalizations l10n, EverydayFeeling feeling) =>
      switch (feeling) {
        EverydayFeeling.pesado => l10n.histFeelingPesado,
        EverydayFeeling.agitado => l10n.histFeelingAgitado,
        EverydayFeeling.irritado => l10n.histFeelingIrritado,
        EverydayFeeling.tranquilo => l10n.histFeelingTranquilo,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final feeling in EverydayFeeling.values)
          Padding(
            key: Key('feeling_${feeling.name}'),
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label(l10n, feeling),
                        style: _textStyle.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      l10n.histFeelingCount(
                          counts.records[feeling] ?? 0, counts.total),
                      key: Key('feeling_count_${feeling.name}'),
                      style: _smallStyle,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: counts.total == 0
                        ? 0
                        : (counts.records[feeling] ?? 0) / counts.total,
                    minHeight: 6,
                    color: _barColor,
                    backgroundColor: _trackColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// D15: emotional choice and body region recorded on the same day.
class BodyMindCoincidenceList extends StatelessWidget {
  final List<BodyMindCoincidence> coincidences;
  final int days;

  /// Lines shown; the rest is summed up in one line.
  static const int maxLines = 5;

  const BodyMindCoincidenceList({
    super.key,
    required this.coincidences,
    required this.days,
  });

  /// Pairs whose keys have text in this version of the app.
  static List<(BodyMindCoincidence, String, String)> labelled(
    AppLocalizations l10n,
    List<BodyMindCoincidence> coincidences,
  ) =>
      [
        for (final c in coincidences)
          if (JournalLabels.marker(l10n, c.emotional) case final emotion?)
            if (JournalLabels.region(l10n, c.region) case final body?)
              (c, emotion, body),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lines = labelled(l10n, coincidences);
    final shown = lines.take(maxLines).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (c, emotion, body) in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.histCoincidenceLine(c.days, days, emotion, body),
              key: Key('coincidence_${c.emotional}_${c.region}'),
              style: _textStyle,
            ),
          ),
        if (lines.length > shown.length)
          Text(
            l10n.histCoincidenceMore(lines.length - shown.length),
            key: const Key('coincidence_more'),
            style: _smallStyle,
          ),
        const SizedBox(height: 4),
        Text(l10n.gxSameDayNote, style: _smallStyle),
      ],
    );
  }
}
