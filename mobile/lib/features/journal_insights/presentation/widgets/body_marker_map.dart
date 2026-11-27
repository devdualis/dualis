import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../journal/domain/journal_keys.dart';
import '../../../journal/presentation/widgets/body_geometry.dart';
import '../../domain/chart_data.dart';
import '../../domain/history_series.dart' show historySensationLabel;
import '../../../journal/presentation/journal_labels.dart';
import 'chart_tokens.dart';
import 'entry_details.dart';
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Center(
              child: Text(
                l10n.histNoPhysical,
                textAlign: TextAlign.center,
                style: chartCaptionStyle,
              ),
            ),
          )
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
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    if (top != null)
                      Text(
                        '${top.answers.map((a) => '“$a”').join(' · ')} · ${l10n.gxMarks(top.count)}',
                        style: GoogleFonts.inter(
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
        style: GoogleFonts.inter(
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

  /// Marker anchor of each region as a fraction of the silhouette box: the
  /// centre of the region's shape in the check-in body map. Arms and legs are
  /// one region; its marker sits on the viewer's right leg.
  static Offset anchor(String region, String side) {
    final Path path = region == 'membros'
        ? BodyGeometry.legR
        : BodyGeometry.pathsOf(region).first;
    final c = path.getBounds().center;
    return Offset(c.dx / BodyGeometry.width, c.dy / BodyGeometry.height);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final box = _fit(Size(constraints.maxWidth, constraints.maxHeight));
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _SilhouettePainter(side: side)),
          ),
          for (final r in regions)
            Positioned(
              // 48 × 48 touch target around a 26 px marker.
              left: box.left + anchor(r.region, side).dx * box.width - 24,
              top: box.top + anchor(r.region, side).dy * box.height - 24,
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

/// The 200 x 346 body space scaled into [size], centred, aspect kept.
Rect _fit(Size size) {
  final scale = (size.width / BodyGeometry.width) <
          (size.height / BodyGeometry.height)
      ? size.width / BodyGeometry.width
      : size.height / BodyGeometry.height;
  final w = BodyGeometry.width * scale;
  final h = BodyGeometry.height * scale;
  return Rect.fromLTWH((size.width - w) / 2, (size.height - h) / 2, w, h);
}

/// The check-in body silhouette (front or back) in its unselected look.
class _SilhouettePainter extends CustomPainter {
  final String side;
  _SilhouettePainter({required this.side});

  static const Color _baseTop = Color(0xFFFFFFFF);
  static const Color _baseBottom = Color(0xFFDCEAF4);
  static const Color _outline = Color(0xFFB7CBDB);

  @override
  void paint(Canvas canvas, Size size) {
    final box = _fit(size);
    canvas.translate(box.left, box.top);
    canvas.scale(box.width / BodyGeometry.width);
    final regions = side == JournalKeys.sideBack
        ? const ['cabeca', 'costas', 'membros']
        : const ['cabeca', 'peito', 'barriga', 'pelve', 'membros'];
    final paths = [
      for (final region in regions) ...BodyGeometry.pathsOf(region),
    ];
    final shadow = Paint()
      ..color = AppColors.dualisNavy.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2);
    for (final p in paths) {
      canvas.drawPath(p.shift(const Offset(0, 3)), shadow);
    }
    for (final p in paths) {
      canvas.drawPath(
        p,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_baseTop, _baseBottom],
          ).createShader(p.getBounds()),
      );
      canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 1.2
          ..color = _outline,
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
    final text = GoogleFonts.inter(
      fontSize: 14,
      height: 1.4,
      color: AppColors.textPrimaryLight,
    );
    final marks = summary.marks.reversed.toList();
    return ListView(
      key: Key('region_marks_${summary.region}'),
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        Text(
          seriesLabel(l10n, summary.region),
          style: GoogleFonts.inter(
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
              border: Border.all(color: AppColors.dualisNavy.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd/MM · HH:mm', locale).format(m.at),
                  style: GoogleFonts.inter(
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
                    // Where exactly, in the person's words (not the map side).
                    if (m.branchKey != null) JournalLabels.branch(l10n, m.branchKey!),
                    if (m.persistence != null)
                      l10n.jv24EntryPersistence(
                          JournalLabels.persistence(l10n, m.persistence!)),
                    m.intensity != null
                        ? l10n.gxIntensityValue(m.intensity!)
                        : l10n.gxIntensityNotInformed,
                  ].join(' · '),
                  style: chartCaptionStyle,
                ),
                if (m.entry != null) ...[
                  const SizedBox(height: 4),
                  JournalEntryDetails(entry: m.entry!, showItems: false),
                ],
              ],
            ),
          ),
      ],
    );
  }

  static String _capitalized(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}
