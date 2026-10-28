import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/history_series.dart';
import 'history_widgets.dart';

/// Opens the timeline of one body region: how many times and on how many
/// days it was marked, a line per sensation and each mark. Counts only.
Future<void> showRegionTimelineSheet(
  BuildContext context, {
  required RegionTimeline timeline,
  required int days,
  required DateTime start,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surfaceLight,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, controller) => RegionTimelineView(
        timeline: timeline,
        days: days,
        start: start,
        controller: controller,
      ),
    ),
  );
}

class RegionTimelineView extends StatelessWidget {
  final RegionTimeline timeline;
  final int days;
  final DateTime start;
  final ScrollController? controller;

  const RegionTimelineView({
    super.key,
    required this.timeline,
    required this.days,
    required this.start,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textStyle = GoogleFonts.plusJakartaSans(
      fontSize: 14,
      height: 1.4,
      color: AppColors.textPrimaryLight,
    );
    final secondary = GoogleFonts.plusJakartaSans(
      fontSize: 12,
      color: AppColors.textSecondaryLight,
    );
    final sensations = timeline.bySensation.entries
        .where((e) => e.key != null)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ListView(
      key: Key('region_timeline_${timeline.region}'),
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        Text(
          timeline.label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        if (timeline.marks.isEmpty)
          Text(l10n.histRegionEmpty, style: textStyle)
        else ...[
          Text(
            l10n.histRegionHeadline(
              days,
              timeline.label,
              timeline.times,
              timeline.dayCount,
            ),
            key: const Key('region_timeline_headline'),
            style: textStyle,
          ),
          if (sensations.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in sensations)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                    backgroundColor: AppColors.softIndigoLight,
                    label: Text(
                      l10n.histRegionSensationTimes(
                        _capitalized(historySensationLabel(l10n, e.key) ?? ''),
                        e.value,
                      ),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.softIndigo,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (timeline.lines.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(l10n.histIntensitySubtitle, style: secondary),
            const SizedBox(height: 8),
            HistoryLineChart(
              lines: [
                for (var i = 0; i < timeline.lines.length; i++)
                  ChartLine(
                    timeline.lines[i],
                    physicalLineColors[i % physicalLineColors.length],
                  ),
              ],
              days: days,
              start: start,
              showDots: true,
            ),
            if (timeline.lines.length > 1) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  for (var i = 0; i < timeline.lines.length; i++)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: physicalLineColors[
                                i % physicalLineColors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(timeline.lines[i].label, style: secondary),
                      ],
                    ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 20),
          Text(
            l10n.histRegionMarksTitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          for (final mark in timeline.marks)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineLight),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      DateFormat('dd/MM').format(mark.day),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.softIndigo,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                            if (mark.sensation != null)
                              _capitalized(
                                historySensationLabel(l10n, mark.sensation) ??
                                    '',
                              ),
                            mark.text,
                          ].where((t) => t.isNotEmpty).join(' · '),
                          style: textStyle,
                        ),
                        if (mark.intensity != null)
                          Text(
                            l10n.histRegionIntensity(mark.intensity!),
                            style: secondary,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  static String _capitalized(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}
