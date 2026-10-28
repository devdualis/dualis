import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../journal/presentation/journal_labels.dart';
import '../../domain/history_series.dart';
import 'journal_overview_widgets.dart';

/// Two-option segmented control (Psicoemocional | Físico, Mapa | Conexões).
class HistorySegmented<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool compact;
  final String keyPrefix;

  const HistorySegmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.keyPrefix,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.outlineLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          for (final (value, label) in options)
            _wrap(
              Semantics(
                button: true,
                selected: value == selected,
                child: GestureDetector(
                  key: Key('${keyPrefix}_$value'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    constraints:
                        BoxConstraints(minHeight: compact ? 36 : 44),
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(
                        horizontal: compact ? 12 : 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: value == selected
                          ? AppColors.surfaceLight
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(compact ? 9 : 10),
                      boxShadow: value == selected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: compact ? 13 : 14,
                        fontWeight: value == selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: value == selected
                            ? AppColors.textPrimaryLight
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _wrap(Widget child) => compact ? child : Expanded(child: child);
}

/// Period chips: 7 / 30 / 90 dias.
class HistoryPeriodChips extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const HistoryPeriodChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      children: [
        for (final days in historyPeriods)
          ChoiceChip(
            key: Key('history_period_$days'),
            label: Text(l10n.histPeriodDays(days)),
            selected: days == selected,
            showCheckmark: false,
            selectedColor: AppColors.textPrimaryLight,
            backgroundColor: AppColors.surfaceLight,
            side: BorderSide(
              color: days == selected
                  ? AppColors.textPrimaryLight
                  : AppColors.outlineLight,
            ),
            labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: days == selected
                  ? Colors.white
                  : AppColors.textPrimaryLight,
            ),
            onSelected: (_) => onChanged(days),
          ),
      ],
    );
  }
}

const List<Color> emotionalLineColors = [
  Color(0xFF7E57C2),
  Color(0xFFFF7043),
  Color(0xFF26A69A),
  Color(0xFF5C6BC0),
  Color(0xFFEC407A),
  Color(0xFF00ACC1),
];

const List<Color> physicalLineColors = [
  Color(0xFF0B7FC6),
  Color(0xFFE0A34A),
  Color(0xFF2E8B57),
  Color(0xFF8D6E63),
  Color(0xFF5F6B7A),
  Color(0xFF1F4A85),
];

/// A line shown on a [HistoryLineChart].
class ChartLine {
  final HistoryLine line;
  final Color color;
  final bool dashed;

  const ChartLine(this.line, this.color, {this.dashed = false});
}

/// Intensity (1..5) per day for the visible lines of the period.
class HistoryLineChart extends StatelessWidget {
  final List<ChartLine> lines;
  final int days;
  final DateTime start;

  /// Dots on every day with a value (always on for 7 days).
  final bool showDots;

  const HistoryLineChart({
    super.key,
    required this.lines,
    required this.days,
    required this.start,
    this.showDots = false,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final step = days <= 7 ? 1 : (days <= 30 ? 7 : 30);
    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (days - 1).toDouble(),
          minY: 0,
          maxY: 5,
          lineTouchData: const LineTouchData(enabled: false),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 1,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.outlineLight, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (value, meta) => value == 0
                    ? const SizedBox.shrink()
                    : Text(value.toInt().toString(), style: _axisStyle),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (value != index || (days - 1 - index) % step != 0) {
                    return const SizedBox.shrink();
                  }
                  final day = start.add(Duration(days: index));
                  final text = days <= 7
                      ? DateFormat.E(locale).format(day).substring(0, 1)
                          .toUpperCase()
                      : DateFormat('dd/MM').format(day);
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(text, style: _axisStyle),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            for (final l in lines) _bar(l),
          ],
        ),
      ),
    );
  }

  static final TextStyle _axisStyle = GoogleFonts.plusJakartaSans(
    fontSize: 10,
    color: AppColors.textSecondaryLight,
  );

  LineChartBarData _bar(ChartLine l) {
    final dayIndexes = l.line.points.keys.toList()..sort();
    return LineChartBarData(
      spots: [
        for (final d in dayIndexes)
          FlSpot(d.toDouble(), l.line.points[d]!.toDouble()),
      ],
      color: l.color,
      barWidth: l.dashed ? 2 : 3,
      dashArray: l.dashed ? [6, 4] : null,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: showDots || dayIndexes.length == 1 || days <= 7,
      ),
    );
  }
}

/// Legend chip that shows or hides a line (old trend-chart chip pattern).
class LineToggleChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool shown;
  final bool dashed;
  final VoidCallback onTap;

  const LineToggleChip({
    super.key,
    required this.label,
    required this.color,
    required this.shown,
    required this.onTap,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final borderColor = shown ? color : AppColors.outlineLight;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: dashed
          ? null
          : BoxDecoration(
              color: shown
                  ? color.withValues(alpha: 0.08)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1.4),
            ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: shown ? color : color.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: shown
                    ? AppColors.textPrimaryLight
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
    return Semantics(
      button: true,
      toggled: shown,
      label: shown ? l10n.histLineShown(label) : l10n.histLineHidden(label),
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Center(
            widthFactor: 1,
            child: dashed
                ? CustomPaint(
                    painter: _DashedPillPainter(color: borderColor),
                    child: chip,
                  )
                : chip,
          ),
        ),
      ),
    );
  }
}

class _DashedPillPainter extends CustomPainter {
  final Color color;

  _DashedPillPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(20),
      ));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedPillPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Line chart with one chip per line. The first [initiallyShown] lines start
/// visible; tapping a chip shows or hides its line. An optional [overlay]
/// line (dashed) can be added on top with its own chip.
class ToggleableLines extends StatefulWidget {
  final List<HistoryLine> lines;
  final List<Color> palette;
  final int days;
  final DateTime start;
  final HistoryLine? overlay;
  final Color overlayColor;
  final int initiallyShown;
  final String keyPrefix;

  const ToggleableLines({
    super.key,
    required this.lines,
    required this.palette,
    required this.days,
    required this.start,
    required this.keyPrefix,
    this.overlay,
    this.overlayColor = const Color(0xFF7E57C2),
    this.initiallyShown = 3,
  });

  @override
  State<ToggleableLines> createState() => _ToggleableLinesState();
}

class _ToggleableLinesState extends State<ToggleableLines> {
  /// Lines the person changed from their default (shown/hidden).
  final Map<String, bool> _toggled = {};
  bool _overlayOn = false;

  bool _isShown(int index) =>
      _toggled[widget.lines[index].key] ?? index < widget.initiallyShown;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final overlay = widget.overlay;
    final shown = <ChartLine>[
      for (var i = 0; i < widget.lines.length; i++)
        if (_isShown(i))
          ChartLine(widget.lines[i], widget.palette[i % widget.palette.length]),
      if (overlay != null && _overlayOn)
        ChartLine(overlay, widget.overlayColor, dashed: true),
    ];
    return Column(
      key: Key('${widget.keyPrefix}_lines'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HistoryLineChart(
          lines: shown,
          days: widget.days,
          start: widget.start,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (var i = 0; i < widget.lines.length; i++)
              LineToggleChip(
                key: Key('${widget.keyPrefix}_chip_${widget.lines[i].key}'),
                label: widget.lines[i].label,
                color: widget.palette[i % widget.palette.length],
                shown: _isShown(i),
                onTap: () => setState(() =>
                    _toggled[widget.lines[i].key] = !_isShown(i)),
              ),
            if (overlay != null)
              LineToggleChip(
                key: Key('${widget.keyPrefix}_overlay_chip'),
                label: l10n.histOverlayChip(overlay.label),
                color: widget.overlayColor,
                shown: _overlayOn,
                dashed: true,
                onTap: () => setState(() => _overlayOn = !_overlayOn),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          l10n.histChipHint,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

/// Body map plus the list of regions marked in the period, most days first.
class HistoryBodyMap extends StatelessWidget {
  final Map<String, int> byRegion;

  /// Opens the timeline of a region, from the map or its count chip.
  final ValueChanged<String>? onRegionTap;

  const HistoryBodyMap({super.key, required this.byRegion, this.onRegionTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final marked = [
      for (final region in historyRegions)
        if ((byRegion[region] ?? 0) > 0) region,
    ]..sort((a, b) => byRegion[b]!.compareTo(byRegion[a]!));
    final maxCount = byRegion.values.fold<int>(0, (a, b) => b > a ? b : a);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        JournalBodyMap(byRegion: byRegion, onRegionTap: onRegionTap),
        const SizedBox(height: 12),
        if (marked.isEmpty)
          Text(
            l10n.histNoPhysical,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSecondaryLight,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final region in marked)
                ActionChip(
                  key: Key('body_map_count_$region'),
                  onPressed:
                      onRegionTap == null ? null : () => onRegionTap!(region),
                  avatar: onRegionTap == null
                      ? null
                      : const Icon(
                          Icons.show_chart_rounded,
                          size: 16,
                          color: AppColors.softIndigo,
                        ),
                  visualDensity: VisualDensity.compact,
                  backgroundColor:
                      regionShade(byRegion[region]!, maxCount)
                          .withValues(alpha: 0.25),
                  side: BorderSide.none,
                  label: Text(
                    l10n.xv2DashRegionDays(
                      historyRegionLabel(l10n, region) ?? region,
                      byRegion[region]!,
                    ),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 8),
        Text(
          l10n.histMapCaption,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

/// Sankey-like view: emotional time (left) to body region (right), each
/// band as wide as the number of days both were marked. Counts only.
class TimeRegionFlow extends StatelessWidget {
  final Map<(String, String), int> links;

  const TimeRegionFlow({super.key, required this.links});

  static const List<Color> timeColors = TimeDistributionBar.colors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimaryLight,
    );
    if (links.isEmpty) {
      return Text(
        l10n.histLinksEmpty,
        key: const Key('time_region_flow_empty'),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: AppColors.textSecondaryLight,
        ),
      );
    }
    final times = [
      for (final t in JournalLabels.times)
        if (links.keys.any((k) => k.$1 == t)) t,
    ];
    final regionOrder = historyRegions;
    final regions = links.keys.map((k) => k.$2).toSet().toList()
      ..sort((a, b) {
        final ia = regionOrder.indexOf(a);
        final ib = regionOrder.indexOf(b);
        return (ia < 0 ? 99 : ia).compareTo(ib < 0 ? 99 : ib);
      });
    final top = links.entries.reduce((a, b) => b.value > a.value ? b : a);
    final height = 40.0 + 34.0 * (times.length > regions.length
        ? times.length
        : regions.length);
    return Column(
      key: const Key('time_region_flow'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: CustomPaint(
            painter: _FlowPainter(
              links: links,
              times: times,
              regions: regions,
              timeLabel: (t) => JournalLabels.timeShort(l10n, t) ?? t,
              regionLabel: (r) => historyRegionLabel(l10n, r) ?? r,
              labelStyle: style,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.histLinksTop(
            JournalLabels.timeShort(l10n, top.key.$1) ?? top.key.$1,
            historyRegionLabel(l10n, top.key.$2) ?? top.key.$2,
            top.value,
          ),
          key: const Key('time_region_flow_top'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}

class _FlowPainter extends CustomPainter {
  final Map<(String, String), int> links;
  final List<String> times;
  final List<String> regions;
  final String Function(String) timeLabel;
  final String Function(String) regionLabel;
  final TextStyle labelStyle;

  _FlowPainter({
    required this.links,
    required this.times,
    required this.regions,
    required this.timeLabel,
    required this.regionLabel,
    required this.labelStyle,
  });

  static const double _nodeWidth = 10;
  static const double _gap = 8;
  static const Color _regionColor = Color(0xFF0B7FC6);

  @override
  void paint(Canvas canvas, Size size) {
    final total = links.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return;
    int timeTotal(String t) => links.entries
        .where((e) => e.key.$1 == t)
        .fold(0, (a, e) => a + e.value);
    int regionTotal(String r) => links.entries
        .where((e) => e.key.$2 == r)
        .fold(0, (a, e) => a + e.value);

    double unitFor(int nodes) => (size.height - _gap * (nodes - 1)) / total;
    final unit = [unitFor(times.length), unitFor(regions.length)]
        .reduce((a, b) => a < b ? a : b);

    // Node positions (top y) on each side.
    final timeY = <String, double>{};
    var y = 0.0;
    for (final t in times) {
      timeY[t] = y;
      y += timeTotal(t) * unit + _gap;
    }
    final regionY = <String, double>{};
    y = 0.0;
    for (final r in regions) {
      regionY[r] = y;
      y += regionTotal(r) * unit + _gap;
    }

    // Bands, filled from the top of each node.
    final timeOffset = {for (final t in times) t: 0.0};
    final regionOffset = {for (final r in regions) r: 0.0};
    const left = _nodeWidth;
    final right = size.width - _nodeWidth;
    for (var ti = 0; ti < times.length; ti++) {
      final t = times[ti];
      for (final r in regions) {
        final count = links[(t, r)] ?? 0;
        if (count == 0) continue;
        final h = count * unit;
        final y0 = timeY[t]! + timeOffset[t]!;
        final y1 = regionY[r]! + regionOffset[r]!;
        timeOffset[t] = timeOffset[t]! + h;
        regionOffset[r] = regionOffset[r]! + h;
        final midX = (left + right) / 2;
        final path = Path()
          ..moveTo(left, y0)
          ..cubicTo(midX, y0, midX, y1, right, y1)
          ..lineTo(right, y1 + h)
          ..cubicTo(midX, y1 + h, midX, y0 + h, left, y0 + h)
          ..close();
        canvas.drawPath(
          path,
          Paint()
            ..color = TimeRegionFlow.timeColors[
                    JournalLabels.times.indexOf(t) %
                        TimeRegionFlow.timeColors.length]
                .withValues(alpha: 0.35),
        );
      }
    }

    // Nodes and labels.
    for (final t in times) {
      final h = timeTotal(t) * unit;
      canvas.drawRect(
        Rect.fromLTWH(0, timeY[t]!, _nodeWidth, h),
        Paint()
          ..color = TimeRegionFlow.timeColors[
              JournalLabels.times.indexOf(t) % TimeRegionFlow.timeColors.length],
      );
      _label(canvas, timeLabel(t), Offset(_nodeWidth + 6, timeY[t]! + h / 2),
          alignRight: false, maxWidth: size.width / 2 - 20);
    }
    for (final r in regions) {
      final h = regionTotal(r) * unit;
      canvas.drawRect(
        Rect.fromLTWH(right, regionY[r]!, _nodeWidth, h),
        Paint()..color = _regionColor,
      );
      _label(canvas, regionLabel(r), Offset(right - 6, regionY[r]! + h / 2),
          alignRight: true, maxWidth: size.width / 2 - 20);
    }
  }

  void _label(Canvas canvas, String text, Offset anchor,
      {required bool alignRight, required double maxWidth}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    final dx = alignRight ? anchor.dx - painter.width : anchor.dx;
    painter.paint(canvas, Offset(dx, anchor.dy - painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _FlowPainter oldDelegate) =>
      oldDelegate.links != links;
}
