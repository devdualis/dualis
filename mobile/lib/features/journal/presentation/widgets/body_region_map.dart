import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/journal_keys.dart';

/// Tappable body silhouette with the 5 journal regions, front and back.
///
/// Reuses the silhouette proportions of the dashboard map
/// (`anatomical_body_map.dart`) so both read as the same body, without
/// changing the dashboard widget. Selected regions use one hue; nothing on
/// the map changes colour by what was recorded.
class BodyRegionMap extends StatelessWidget {
  final String side;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const BodyRegionMap({
    super.key,
    required this.side,
    required this.selected,
    required this.onToggle,
  });

  /// Regions that can be tapped on each side.
  static List<String> regionsFor(String side) => side == JournalKeys.sideBack
      ? const ['cabeca', 'costas', 'membros']
      : const ['cabeca', 'peito', 'barriga', 'membros'];

  /// Relative rectangles of each region (x, y, width, height in 0..1).
  static List<Rect> shapesOf(String region, String side) {
    switch (region) {
      case 'cabeca':
        return const [
          Rect.fromLTWH(0.40, 0.04, 0.20, 0.12),
          Rect.fromLTWH(0.46, 0.155, 0.08, 0.03),
        ];
      case 'peito':
        return const [Rect.fromLTWH(0.35, 0.18, 0.30, 0.14)];
      case 'barriga':
        return const [
          Rect.fromLTWH(0.36, 0.33, 0.28, 0.13),
          Rect.fromLTWH(0.38, 0.47, 0.24, 0.10),
        ];
      case 'costas':
        return const [Rect.fromLTWH(0.35, 0.18, 0.30, 0.39)];
      case 'membros':
        return const [
          Rect.fromLTWH(0.18, 0.18, 0.15, 0.32),
          Rect.fromLTWH(0.67, 0.18, 0.15, 0.32),
          Rect.fromLTWH(0.32, 0.58, 0.16, 0.38),
          Rect.fromLTWH(0.52, 0.58, 0.16, 0.38),
        ];
    }
    return const [];
  }

  static String? regionAt(Offset position, Size size, String side) {
    final rel = Offset(position.dx / size.width, position.dy / size.height);
    for (final region in regionsFor(side)) {
      for (final r in shapesOf(region, side)) {
        if (r.inflate(0.01).contains(rel)) return region;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.62,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            key: Key('jv2_body_map_$side'),
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final region = regionAt(details.localPosition, size, side);
              if (region != null) onToggle(region);
            },
            child: CustomPaint(
              size: size,
              painter: _BodyRegionPainter(side: side, selected: selected),
            ),
          );
        },
      ),
    );
  }
}

class _BodyRegionPainter extends CustomPainter {
  final String side;
  final Set<String> selected;

  _BodyRegionPainter({required this.side, required this.selected});

  static const Color _base = Color(0xFFECEFF1);
  static const Color _outline = Color(0xFFB0BEC5);

  @override
  void paint(Canvas canvas, Size size) {
    final allRegions = ['cabeca', 'peito', 'barriga', 'costas', 'membros'];
    final visible = BodyRegionMap.regionsFor(side);
    for (final region in allRegions) {
      if (!visible.contains(region)) continue;
      final isSelected = selected.contains(region);
      final fill = Paint()
        ..color = isSelected
            ? AppColors.dualisSymbolBlue.withValues(alpha: 0.75)
            : _base
        ..style = PaintingStyle.fill;
      final stroke = Paint()
        ..color = isSelected ? AppColors.dualisSymbolBlue : _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.5 : 2.0;
      for (final r in BodyRegionMap.shapesOf(region, side)) {
        final rect = Rect.fromLTWH(
          r.left * size.width,
          r.top * size.height,
          r.width * size.width,
          r.height * size.height,
        );
        if (region == 'cabeca' && r.height > 0.05) {
          canvas.drawOval(rect, fill);
          canvas.drawOval(rect, stroke);
        } else {
          final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
          canvas.drawRRect(rrect, fill);
          canvas.drawRRect(rrect, stroke);
        }
      }
    }
    if (side == JournalKeys.sideBack) {
      // A simple spine line tells the back view apart from the front.
      final spine = Paint()
        ..color = selected.contains('costas') ? Colors.white : _outline
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(size.width * 0.5, size.height * 0.20),
        Offset(size.width * 0.5, size.height * 0.55),
        spine,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BodyRegionPainter oldDelegate) =>
      oldDelegate.side != side || oldDelegate.selected != selected;
}
