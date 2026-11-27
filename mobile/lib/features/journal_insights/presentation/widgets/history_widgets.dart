import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/history_series.dart';

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

  static const double _outerPad = 3;

  double get _fontSize => compact ? 13 : (options.length > 4 ? 12 : 14);
  double get _hPad => compact ? 12 : (options.length > 4 ? 4 : 8);

  TextStyle _style(bool isSelected) => GoogleFonts.inter(
    fontSize: _fontSize,
    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
    color: isSelected ? AppColors.dualisNavy : AppColors.textSecondaryLight,
  );

  /// True when every label fits whole in an equal-width slot. Measured at
  /// the bold weight and the user's text size, so large text never ends
  /// in "Emocio…".
  bool _labelsFit(BuildContext context, double maxWidth) {
    final slot = (maxWidth - _outerPad * 2) / options.length - _hPad * 2;
    final scaler = MediaQuery.textScalerOf(context);
    for (final (_, label) in options) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: _style(true)),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      if (width > slot) return false;
    }
    return true;
  }

  Widget _segment(T value, String label, {required bool expanded}) {
    final isSelected = value == selected;
    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        key: Key('${keyPrefix}_$value'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: BoxConstraints(minHeight: compact ? 36 : 44),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(
            horizontal: expanded ? _hPad : 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceLight : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: AppColors.dualisNavy.withValues(alpha: 0.14),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                    : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: expanded ? TextOverflow.ellipsis : TextOverflow.visible,
            softWrap: false,
            style: _style(isSelected),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: AppColors.dualisNavy.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
    );
    if (compact) {
      return Container(
        padding: const EdgeInsets.all(_outerPad),
        decoration: decoration,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (value, label) in options)
              _segment(value, label, expanded: false),
          ],
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_labelsFit(context, constraints.maxWidth)) {
          return Container(
            padding: const EdgeInsets.all(_outerPad),
            decoration: decoration,
            child: Row(
              children: [
                for (final (value, label) in options)
                  Expanded(child: _segment(value, label, expanded: true)),
              ],
            ),
          );
        }
        // Labels too long for equal slots: whole words, scrolled sideways.
        return Container(
          padding: const EdgeInsets.all(_outerPad),
          decoration: decoration,
          child: SingleChildScrollView(
            key: Key('${keyPrefix}_scroll'),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (value, label) in options)
                  _segment(value, label, expanded: false),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Period chips: 7 / 14 / 30 dias.
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
            selectedColor: AppColors.dualisNavy,
            backgroundColor: AppColors.surfaceLight,
            side: BorderSide(
              color:
                  days == selected
                      ? AppColors.dualisNavy
                      : AppColors.dualisNavy.withValues(alpha: 0.14),
            ),
            labelStyle: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: days == selected ? Colors.white : AppColors.dualisNavy,
            ),
            onSelected: (_) => onChanged(days),
          ),
      ],
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
    final borderColor =
        shown ? color : AppColors.dualisNavy.withValues(alpha: 0.14);
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration:
          dashed
              ? null
              : BoxDecoration(
                color:
                    shown
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
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color:
                    shown
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
            child:
                dashed
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
    final path =
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Offset.zero & size,
            const Radius.circular(20),
          ),
        );
    final paint =
        Paint()
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
