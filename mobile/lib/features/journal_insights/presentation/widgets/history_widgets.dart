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
