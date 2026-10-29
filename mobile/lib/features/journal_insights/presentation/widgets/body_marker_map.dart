import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../journal/domain/journal_keys.dart';
import '../../domain/chart_data.dart';
import '../../domain/history_series.dart' show historySensationLabel;
import 'chart_tokens.dart';
import 'record_series_chart.dart' show chartCaptionStyle;

/// F1: one body map, front and back, with a fixed-size numbered marker per
/// region. Number = distinct days with at least one mark in the period.
/// Colour only tells regions apart; there is no scale of seriousness. The
/// list below is the textual equivalent and opens the same detail.
class BodyMarkerMap extends StatelessWidget {
  final List<RegionSummary> regions;

  /// "Ver evolução": picks the region on F3.
  final ValueChanged<String> onSeeEvolution;

  const BodyMarkerMap({
    super.key,
    required this.regions,
    required this.onSeeEvolution,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onMap = [
      for (final r in regions)
        if (mapRegions.contains(r.region)) r,
    ];
    final wholeBody = [
      for (final r in regions)
        if (!mapRegions.contains(r.region)) r,
    ];
    void open(RegionSummary r) => showRegionMarksSheet(
          context,
          summary: r,
          onSeeEvolution: () => onSeeEvolution(r.region),
        );
    return Column(
      key: const Key('body_marker_map'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 220,
          child: Row(
            children: [
              for (final side in [JournalKeys.sideFront, JournalKeys.sideBack])
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: _MarkedSilhouette(
                          side: side,
                          regions: [
                            for (final r in onMap)
                              if (r.mapView == side) r,
                          ],
                          onTap: open,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        side == JournalKeys.sideFront
                            ? l10n.xv2DashFront
                            : l10n.xv2DashBack,
                        style: chartCaptionStyle.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (regions.isEmpty)
          Text(l10n.histNoPhysical, style: chartCaptionStyle)
        else ...[
          for (final r in onMap) _RegionRow(summary: r, onTap: () => open(r)),
          if (wholeBody.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(l10n.gxWholeBody, style: chartCaptionStyle),
            const SizedBox(height: 6),
            for (final r in wholeBody)
              _RegionRow(summary: r, onTap: () => open(r)),
          ],
        ],
        const SizedBox(height: 6),
        Text(l10n.gxBodyMapCaption, style: chartCaptionStyle),
      ],
    );
  }
}

class _RegionRow extends StatelessWidget {
  final RegionSummary summary;
  final VoidCallback onTap;

  const _RegionRow({required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = ChartTokens.region(summary.region);
    final top = summary.top;
    return InkWell(
      key: Key('body_region_row_${summary.region}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              _Marker(days: summary.days, color: color, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${seriesLabel(l10n, summary.region)} · ${l10n.gxRegionDays(summary.days)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    if (top != null)
                      Text(
                        '${top.answers.map((a) => '“$a”').join(' · ')} · ${l10n.gxMarks(top.count)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondaryLight),
            ],
          ),
        ),
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  final int days;
  final Color color;
  final double size;

  const _Marker({required this.days, required this.color, this.size = 26});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        '$days',
        style: GoogleFonts.plusJakartaSans(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Neutral silhouette with markers placed on their region.
class _MarkedSilhouette extends StatelessWidget {
  final String side;
  final List<RegionSummary> regions;
  final ValueChanged<RegionSummary> onTap;

  const _MarkedSilhouette({
    required this.side,
    required this.regions,
    required this.onTap,
  });

  /// Marker anchor of each region, relative to the silhouette box.
  static Offset anchor(String region, String side) => switch (region) {
        'cabeca' => const Offset(0.5, 0.075),
        'peito' => const Offset(0.5, 0.26),
        'barriga' => const Offset(0.5, 0.43),
        'costas' => const Offset(0.5, 0.33),
        _ => const Offset(0.6, 0.76),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final h = constraints.maxHeight;
      final w = h * 0.5;
      final left = (constraints.maxWidth - w) / 2;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _SilhouettePainter(side: side)),
          ),
          for (final r in regions)
            Positioned(
              // 48 × 48 touch target around a 26 px marker.
              left: left + anchor(r.region, side).dx * w - 24,
              top: anchor(r.region, side).dy * h - 24,
              child: Semantics(
                button: true,
                label:
                    '${seriesLabel(l10n, r.region)}, ${l10n.gxRegionDays(r.days)}',
                excludeSemantics: true,
                child: GestureDetector(
                  key: Key('body_marker_${r.region}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(r),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: _Marker(
                        days: r.days,
                        color: ChartTokens.region(r.region),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _SilhouettePainter extends CustomPainter {
  final String side;
  _SilhouettePainter({required this.side});

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = h * 0.5;
    final left = (size.width - w) / 2;
    Rect r(double x, double y, double rw, double rh) =>
        Rect.fromLTWH(left + x * w, y * h, rw * w, rh * h);
    final fill = Paint()..color = ChartTokens.silhouette;
    final stroke = Paint()
      ..color = ChartTokens.silhouetteOutline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final radius = Radius.circular(w * 0.1);
    final body = Path()
      ..addOval(r(0.36, 0.0, 0.28, 0.14))
      ..addRRect(RRect.fromRectAndRadius(r(0.44, 0.12, 0.12, 0.07), radius))
      // Torso and hips.
      ..addRRect(RRect.fromRectAndRadius(r(0.25, 0.17, 0.5, 0.41), radius))
      // Arms.
      ..addRRect(RRect.fromRectAndRadius(r(0.09, 0.18, 0.14, 0.38), radius))
      ..addRRect(RRect.fromRectAndRadius(r(0.77, 0.18, 0.14, 0.38), radius))
      // Legs.
      ..addRRect(RRect.fromRectAndRadius(r(0.28, 0.56, 0.2, 0.44), radius))
      ..addRRect(RRect.fromRectAndRadius(r(0.52, 0.56, 0.2, 0.44), radius));
    canvas.drawPath(body, fill);
    canvas.drawPath(body, stroke);
    if (side == JournalKeys.sideBack) {
      canvas.drawLine(
        Offset(left + w * 0.5, h * 0.2),
        Offset(left + w * 0.5, h * 0.52),
        Paint()
          ..color = ChartTokens.silhouetteOutline
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SilhouettePainter old) => old.side != side;
}

/// Every mark of one region in the period: date, time, what was chosen,
/// side and intensity, plus "Ver evolução".
Future<void> showRegionMarksSheet(
  BuildContext context, {
  required RegionSummary summary,
  required VoidCallback onSeeEvolution,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surfaceLight,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, controller) => RegionMarksView(
        summary: summary,
        controller: controller,
        onSeeEvolution: () {
          Navigator.of(sheetContext).pop();
          onSeeEvolution();
        },
      ),
    ),
  );
}

class RegionMarksView extends StatelessWidget {
  final RegionSummary summary;
  final ScrollController? controller;
  final VoidCallback onSeeEvolution;

  const RegionMarksView({
    super.key,
    required this.summary,
    required this.onSeeEvolution,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final color = ChartTokens.region(summary.region);
    final text = GoogleFonts.plusJakartaSans(
      fontSize: 14,
      height: 1.4,
      color: AppColors.textPrimaryLight,
    );
    String viewLabel(String? view) => switch (view) {
          JournalKeys.sideFront => l10n.xv2DashFront,
          JournalKeys.sideBack => l10n.xv2DashBack,
          _ => l10n.gxViewUnspecified,
        };
    final marks = summary.marks.reversed.toList();
    final byView = summary.byView;
    final isWholeBody = JournalKeys.isWholeBody(summary.region);
    return ListView(
      key: Key('region_marks_${summary.region}'),
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        Text(
          seriesLabel(l10n, summary.region),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${l10n.gxRegionDays(summary.days)} · ${l10n.gxMarks(summary.marks.length)}',
          key: const Key('region_marks_headline'),
          style: text,
        ),
        if (!isWholeBody) ...[
          const SizedBox(height: 4),
          Text(
            [
              for (final view in [JournalKeys.sideFront, JournalKeys.sideBack, null])
                if ((byView[view] ?? 0) > 0)
                  '${viewLabel(view)}: ${byView[view]}',
            ].join(' · '),
            style: chartCaptionStyle,
          ),
        ],
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          key: const Key('region_marks_see_evolution'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: onSeeEvolution,
          icon: const Icon(Icons.show_chart_rounded),
          label: Text(l10n.gxSeeEvolution),
        ),
        const SizedBox(height: 16),
        for (final m in marks)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd/MM · HH:mm', locale).format(m.at),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (historySensationLabel(l10n, m.sensation) != null)
                      _capitalized(historySensationLabel(l10n, m.sensation)!),
                    '“${m.answer}”',
                  ].join(' · '),
                  style: text,
                ),
                Text(
                  [
                    if (!isWholeBody) viewLabel(m.view),
                    m.intensity != null
                        ? l10n.gxIntensityValue(m.intensity!)
                        : l10n.gxIntensityNotInformed,
                  ].join(' · '),
                  style: chartCaptionStyle,
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _capitalized(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}
