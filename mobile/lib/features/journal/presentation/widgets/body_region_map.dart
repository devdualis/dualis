import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/journal_keys.dart';
import '../../../../core/voice/voice_targets.dart';
import 'body_geometry.dart';

/// Tappable body silhouette with the journal regions, front and back.
///
/// The body is drawn as a soft glass figure: pale gradient, light outline,
/// muscle lines and a cyan glow on the selected regions, all vector paths (sharp at
/// any size) in a 200 x 346 design space. Each region is its own labelled button (`jv2_region_<region>`)
/// and is hit-tested by its real shape, so the map works with a screen reader
/// and needs no chips underneath. Selected regions use one hue; nothing on the
/// map changes colour by what was recorded.
class BodyRegionMap extends StatelessWidget {
  final String side;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  /// Text read out for each region.
  final String Function(String region) labelOf;

  const BodyRegionMap({
    super.key,
    required this.side,
    required this.selected,
    required this.onToggle,
    required this.labelOf,
  });

  /// Regions that can be tapped on each side.
  static List<String> regionsFor(String side) =>
      side == JournalKeys.sideBack
          ? const ['cabeca', 'costas', 'membros']
          : const ['cabeca', 'peito', 'barriga', 'pelve', 'membros'];

  /// Bounding rectangles of each region (x, y, width, height in 0..1). The
  /// centre of every rectangle lies inside its shape.
  static List<Rect> shapesOf(String region, String side) => [
    for (final p in BodyGeometry.pathsOf(region))
      BodyGeometry.normalized(p.getBounds()),
  ];

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: BodyGeometry.width / BodyGeometry.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return Stack(
            key: Key('jv2_body_map_$side'),
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _BodyRegionPainter(side: side, selected: selected),
                ),
              ),
              for (final region in regionsFor(side))
                for (final (i, path) in BodyGeometry.pathsOf(region).indexed)
                  _regionTarget(region, i, path, size),
            ],
          );
        },
      ),
    );
  }

  Widget _regionTarget(String region, int i, Path path, Size size) {
    final r = BodyGeometry.normalized(path.getBounds());
    return Positioned(
      left: r.left * size.width,
      top: r.top * size.height,
      width: r.width * size.width,
      height: r.height * size.height,
      child: VoiceTarget(
        labels: [labelOf(region)],
        // Arms and legs are one region: one voice target.
        onSelect: i == 0 ? () => onToggle(region) : null,
        child: ClipPath(
          key: i == 0 ? Key('jv2_region_$region') : null,
          clipper: _PathClipper(path),
          child: _RegionTarget(
            label: labelOf(region),
            selected: selected.contains(region),
            // Arms and legs are one region: read it out once.
            excludeSemantics: i > 0,
            onTap: () => onToggle(region),
          ),
        ),
      ),
    );
  }
}

/// Clips (and so hit-tests) a child to a region path.
class _PathClipper extends CustomClipper<Path> {
  final Path path;
  _PathClipper(this.path);

  @override
  Path getClip(Size size) {
    final b = path.getBounds();
    return path.transform(
      (Matrix4.identity()
            ..scaleByDouble(size.width / b.width, size.height / b.height, 1, 1)
            ..translateByDouble(-b.left, -b.top, 0, 1))
          .storage,
    );
  }

  @override
  bool shouldReclip(covariant _PathClipper oldClipper) => false;
}

class _RegionTarget extends StatelessWidget {
  final String label;
  final bool selected;
  final bool excludeSemantics;
  final VoidCallback onTap;

  const _RegionTarget({
    required this.label,
    required this.selected,
    required this.excludeSemantics,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final target = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
    );
    if (excludeSemantics) return ExcludeSemantics(child: target);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: target,
    );
  }
}


class _BodyRegionPainter extends CustomPainter {
  final String side;
  final Set<String> selected;

  _BodyRegionPainter({required this.side, required this.selected});

  static const Color _baseTop = Color(0xFFFFFFFF);
  static const Color _baseBottom = Color(0xFFDCEAF4);
  static const Color _outline = Color(0xFFB7CBDB);
  static const Color _detail = Color(0xFF9DB6C9);
  static const Color _detailOn = Color(0xBFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(
      size.width / BodyGeometry.width,
      size.height / BodyGeometry.height,
    );

    final front = side != JournalKeys.sideBack;
    final regions =
        front
            ? const ['cabeca', 'peito', 'barriga', 'pelve', 'membros']
            : const ['cabeca', 'costas', 'membros'];

    // Soft drop shadow under the whole body, then each region on top.
    final shadow =
        Paint()
          ..color = AppColors.dualisNavy.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2);
    for (final region in regions) {
      for (final p in BodyGeometry.pathsOf(region)) {
        canvas.drawPath(p.shift(const Offset(0, 3)), shadow);
      }
    }

    for (final region in regions) {
      final on = selected.contains(region);
      for (final p in BodyGeometry.pathsOf(region)) {
        final b = p.getBounds();
        if (on) {
          canvas.drawPath(
            p,
            Paint()
              ..color = AppColors.dualisSymbolCyan.withValues(alpha: 0.7)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
          );
        }
        canvas.drawPath(
          p,
          Paint()
            ..shader = (on
                    ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.dualisSymbolCyan,
                        AppColors.dualisSymbolBlue,
                      ],
                    )
                    : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_baseTop, _baseBottom],
                    ))
                .createShader(b),
        );
        canvas.drawPath(
          p,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = on ? 1.5 : 1.2
            ..color = on ? Colors.white : _outline,
        );
      }
    }

    if (front) {
      _paintFrontMuscles(canvas);
    } else {
      _paintBackMuscles(canvas);
    }
  }

  /// Draws [d] (left side) and its mirror image on the right side.
  void _m(Canvas canvas, String d, bool on) {
    final p = BodyGeometry.parse(d);
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 0.85
          ..color = on ? _detailOn : _detail;
    canvas.drawPath(p, paint);
    canvas.drawPath(p.transform(BodyGeometry.mirror.storage), paint);
  }

  /// Draws [d] once (centre-line details).
  void _c(Canvas canvas, String d, bool on) {
    canvas.drawPath(
      BodyGeometry.parse(d),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 0.85
        ..color = on ? _detailOn : _detail,
    );
  }

  void _node(Canvas canvas, Offset o, bool on) => canvas.drawCircle(
    o,
    1.1,
    Paint()..color = on ? Colors.white : const Color(0xCC9BE6FF),
  );

  void _paintFrontMuscles(Canvas canvas) {
    final chest = selected.contains('peito');
    final belly = selected.contains('barriga');
    final pelvis = selected.contains('pelve');
    final limbs = selected.contains('membros');
    final head = selected.contains('cabeca');
    // Neck.
    _m(canvas, 'M95 40C97 46 99 50 100 54', head);
    // Collarbones, sternum, pectorals.
    _m(canvas, 'M98 62C90 64 80 63 70 66', chest);
    _c(canvas, 'M100 66V100', chest);
    _m(canvas, 'M99 96C90 101 78 100 70 92', chest);
    _m(canvas, 'M70 72C78 78 90 82 98 82', chest);
    // Abdomen: centre line, rows, obliques, navel.
    _c(canvas, 'M100 106V142', belly);
    for (final y in const [114, 123, 132]) {
      _m(canvas, 'M88 ${y}C93 ${y + 2} 97 ${y + 2} 99 ${y + 1}', belly);
    }
    _m(canvas, 'M77 108C81 118 83 130 83 140', belly);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(100, 138), width: 3, height: 4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = belly ? _detailOn : _detail,
    );
    // Hip lines.
    _m(canvas, 'M82 148C88 158 95 166 99 172', pelvis);
    // Arms: shoulder, biceps, forearm. Legs: thigh, knee, calf. Hands: fingers.
    _m(canvas, 'M64 80C60 88 58 96 56 102', limbs);
    _m(canvas, 'M56 106C52 114 49 122 47 128', limbs);
    _m(canvas, 'M44 136C40 148 36 158 32 166', limbs);
    _m(canvas, 'M90 178C86 196 84 216 86 232', limbs);
    _m(canvas, 'M73 182C70 198 72 214 74 226', limbs);
    _m(canvas, 'M74 238C77 233 83 233 87 238', limbs);
    _m(canvas, 'M74 262C72 280 74 296 78 310', limbs);
    _m(canvas, 'M87 262C87 280 86 296 86 310', limbs);
  }

  void _paintBackMuscles(Canvas canvas) {
    final back = selected.contains('costas');
    final limbs = selected.contains('membros');
    final head = selected.contains('cabeca');
    // Spine with vertebrae.
    _c(canvas, 'M100 58V172', back);
    for (var y = 66; y <= 166; y += 10) {
      _node(canvas, Offset(100, y.toDouble()), back);
    }
    // Trapezius, shoulder blades, lower back, glutes.
    _m(canvas, 'M98 60C88 64 76 68 68 72', back);
    _m(canvas, 'M85 72C77 80 77 94 87 100C93 92 92 80 85 72', back);
    _m(canvas, 'M98 132C88 128 78 120 72 108', back);
    _m(canvas, 'M76 166C86 171 94 171 99 168', back);
    // Neck and skull.
    _m(canvas, 'M95 40C97 46 99 50 100 54', head);
    _m(canvas, 'M92 16C94 22 94 32 92 38', head);
    // Arms and legs.
    _m(canvas, 'M64 80C60 88 58 96 56 102', limbs);
    _m(canvas, 'M44 136C40 148 36 158 32 166', limbs);
    _m(canvas, 'M82 190C79 210 79 226 82 236', limbs);
    _m(canvas, 'M74 240C78 244 84 244 88 240', limbs);
    _m(canvas, 'M80 254C77 272 77 292 80 308', limbs);
  }

  @override
  bool shouldRepaint(covariant _BodyRegionPainter oldDelegate) =>
      oldDelegate.side != side || oldDelegate.selected != selected;
}
