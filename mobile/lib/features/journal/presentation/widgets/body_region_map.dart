import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/journal_keys.dart';
import '../../../../core/voice/voice_targets.dart';

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
    for (final p in _BodyGeometry.pathsOf(region))
      _BodyGeometry.normalized(p.getBounds()),
  ];

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _BodyGeometry.width / _BodyGeometry.height,
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
                for (final (i, path) in _BodyGeometry.pathsOf(region).indexed)
                  _regionTarget(region, i, path, size),
            ],
          );
        },
      ),
    );
  }

  Widget _regionTarget(String region, int i, Path path, Size size) {
    final r = _BodyGeometry.normalized(path.getBounds());
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

/// Body outlines in the 200 x 346 design space (SVG path syntax). Torso
/// pieces are described by their left half (top centre to bottom centre) and
/// mirrored; limbs are drawn for the viewer's left side and mirrored.
abstract final class _BodyGeometry {
  static const double width = 200;
  static const double height = 346;

  static const _head =
      'M98.0 6.0C100.9 5.7 105.4 6.5 107.9 7.3C110.4 8.2 111.9 9.9 113.0 11.1C114.1 12.3 113.9 11.1 114.6 14.3C115.3 17.5 117.6 25.6 117.0 30.4C116.4 35.3 112.1 40.9 111.1 43.6C110.1 46.3 110.8 45.5 111.1 46.5C111.4 47.6 112.6 49.0 112.7 50.0C112.8 51.1 111.7 52.7 111.7 52.7C111.7 52.7 94.3 53.2 90.4 53.0C86.5 52.8 88.3 51.6 88.3 51.6C88.3 51.6 90.6 47.1 89.9 43.6C89.2 40.1 84.6 35.3 84.0 30.4C83.4 25.6 85.4 17.9 86.4 14.3C87.4 10.7 88.2 10.3 90.2 9.0C92.1 7.6 95.0 6.3 98.0 6.0Z';
  static const _chest =
      'M87.5 53.3C93.2 52.4 109.1 52.6 114.6 53.5C120.2 54.5 117.5 57.2 120.8 58.9C124.0 60.5 131.4 62.2 134.2 63.5C137.0 64.7 137.0 64.9 137.7 66.1C138.4 67.3 139.4 65.1 138.2 70.7C137.1 76.3 132.3 94.3 130.7 99.7C129.1 105.1 128.6 102.9 128.6 102.9C128.6 102.9 83.4 103.7 73.8 103.5C64.2 103.2 72.7 107.0 70.8 101.6C69.0 96.1 63.9 76.5 62.5 70.7C61.2 64.9 62.1 67.9 62.8 66.7C63.5 65.5 63.9 64.8 66.8 63.5C69.7 62.2 76.8 60.6 80.2 58.9C83.7 57.2 81.8 54.1 87.5 53.3Z';
  static const _belly =
      'M74.6 103.7C83.7 103.6 127.2 104.3 127.2 104.3C127.2 104.3 128.4 104.4 127.8 107.0C127.1 109.5 124.0 116.3 123.5 119.8C122.9 123.4 124.4 124.7 124.5 128.4C124.7 132.1 124.3 142.1 124.3 142.1C124.3 142.1 130.1 143.1 122.1 143.2C114.1 143.3 76.2 142.7 76.2 142.7C76.2 142.7 75.1 143.2 75.1 139.4C75.2 135.6 77.0 125.3 76.5 119.8C76.0 114.3 72.9 108.9 72.2 106.4C71.5 103.9 72.1 105.3 72.5 104.8C72.9 104.4 65.5 103.8 74.6 103.7Z';
  static const _pelvis =
      'M76.7 143.5C84.9 143.3 114.9 143.1 123.2 143.5C131.5 143.8 125.6 144.3 126.4 145.6C127.2 146.9 128.3 149.6 128.0 151.3C127.8 152.9 129.0 151.5 124.8 155.3C120.6 159.1 107.0 170.8 102.8 174.1C98.6 177.3 99.8 174.9 99.8 174.9C99.8 174.9 77.2 156.7 72.7 152.1C68.2 147.4 72.5 148.5 72.7 147.2C73.0 146.0 73.7 145.2 74.3 144.5C75.0 143.9 68.6 143.6 76.7 143.5Z';
  static const _torsoBack =
      'M87.5 53.3C93.9 52.0 109.1 52.6 114.6 53.5C120.2 54.5 117.2 57.1 120.8 58.9C124.3 60.7 132.9 62.8 135.8 64.3C138.7 65.7 137.8 66.4 138.2 67.5C138.6 68.6 139.6 65.0 138.2 70.7C136.9 76.4 132.3 94.9 130.2 101.9C128.0 108.8 126.5 109.6 125.3 112.6C124.2 115.6 123.6 115.5 123.5 119.8C123.3 124.2 123.8 134.0 124.5 138.9C125.3 143.8 127.5 147.2 128.0 149.4C128.6 151.6 132.2 147.8 127.8 152.1C123.3 156.3 101.2 174.9 101.2 174.9C101.2 174.9 99.7 175.0 98.2 174.1C96.8 173.1 96.7 173.1 92.3 169.2C88.0 165.4 72.2 151.0 72.2 151.0C72.2 151.0 74.7 144.1 75.4 138.9C76.1 133.7 77.2 125.7 76.5 119.8C75.8 114.0 73.4 112.2 71.1 104.0C68.8 95.8 63.9 76.9 62.5 70.7C61.1 64.5 62.3 67.8 62.8 66.7C63.2 65.6 63.0 65.2 65.2 64.3C67.4 63.3 72.2 62.9 75.9 61.0C79.7 59.2 81.0 54.5 87.5 53.3Z';
  static const _arm =
      'M60.6 70.7C60.6 70.7 61.8 70.9 62.3 71.5C62.7 72.1 62.0 69.0 63.3 74.2C64.7 79.4 70.3 96.3 70.3 102.7C70.3 109.1 64.8 109.7 63.1 112.6C61.3 115.5 60.6 117.8 59.8 120.1C59.1 122.4 59.4 124.1 58.8 126.3C58.1 128.5 57.2 130.8 56.1 133.3C55.0 135.7 53.6 138.6 52.0 141.0C50.5 143.5 48.3 145.7 46.9 148.0C45.6 150.4 44.4 153.4 43.7 155.0C43.1 156.6 43.1 156.0 43.2 157.7C43.2 159.4 44.3 162.4 44.0 165.2C43.7 168.0 41.8 171.4 41.3 174.6C40.8 177.8 41.0 182.6 40.8 184.3C40.6 186.0 40.2 184.8 40.2 184.8C40.2 184.8 38.4 184.3 38.4 184.3C38.4 184.3 37.5 179.7 37.5 179.7C37.5 179.7 36.4 186.2 35.9 187.8C35.5 189.3 34.9 189.1 34.9 189.1C34.9 189.1 33.3 188.8 33.3 188.8C33.3 188.8 32.6 189.1 32.7 187.0C32.8 184.9 33.8 176.2 33.8 176.2C33.8 176.2 31.6 186.6 31.1 188.8C30.6 191.1 30.9 189.7 30.6 189.9C30.2 190.1 29.0 190.2 29.0 190.2C29.0 190.2 27.8 189.9 27.9 188.3C28.0 186.7 29.2 182.4 29.5 180.5C29.8 178.6 29.5 176.8 29.5 176.8C29.5 176.8 29.0 176.4 28.4 177.8C27.9 179.2 27.0 183.7 26.3 185.1C25.6 186.5 24.1 186.2 24.1 186.2C24.1 186.2 23.5 185.8 23.3 185.4C23.2 184.9 22.8 185.6 23.3 183.7C23.8 181.9 25.8 176.3 26.3 174.1C26.7 171.9 26.0 170.6 26.0 170.6C26.0 170.6 25.5 169.6 24.4 169.8C23.3 170.0 20.4 171.5 19.3 171.7C18.2 171.8 17.7 170.6 17.7 170.6C17.7 170.6 17.7 169.2 17.7 169.2C17.7 169.2 29.0 164.1 29.0 164.1C29.0 164.1 29.5 163.7 29.0 163.1C28.4 162.4 25.5 160.4 25.5 160.4C25.5 160.4 25.0 158.1 25.7 156.9C26.5 155.7 29.0 154.4 30.0 153.4C31.1 152.4 30.6 155.3 31.9 150.7C33.3 146.1 35.4 132.8 38.1 125.7C40.7 118.7 45.3 113.8 47.8 108.6C50.2 103.3 51.7 97.4 52.6 94.1C53.5 90.7 52.6 90.4 53.1 88.4C53.7 86.5 55.2 84.3 55.8 82.3C56.4 80.2 56.3 77.8 56.9 76.1C57.4 74.4 58.4 72.9 59.0 72.0C59.7 71.2 60.6 70.7 60.6 70.7Z';
  static const _leg =
      'M71.1 154.7C71.1 154.7 69.6 152.2 73.5 155.3C77.5 158.4 90.8 169.8 94.7 173.3C98.7 176.7 96.8 175.0 97.4 176.0C98.1 176.9 98.6 177.2 98.8 179.2C98.9 181.1 99.4 182.6 98.5 187.8C97.6 192.9 94.2 203.2 93.4 210.1C92.5 216.9 93.6 224.5 93.4 229.1C93.2 233.7 93.0 234.4 92.3 237.7C91.6 241.0 89.6 245.5 89.1 248.7C88.6 251.9 88.7 253.5 89.1 257.0C89.5 260.6 92.0 263.6 91.2 269.9C90.5 276.2 85.9 289.2 84.8 294.9C83.7 300.6 84.6 302.0 84.8 304.3C85.0 306.6 85.7 305.1 85.9 308.9C86.0 312.7 86.3 322.3 85.6 327.1C84.9 331.9 82.6 335.5 81.6 337.6C80.6 339.7 80.3 339.2 79.4 339.7C78.5 340.3 78.5 340.9 76.2 340.8C73.9 340.7 68.1 339.9 65.7 339.2C63.4 338.5 62.9 337.2 62.3 336.5C61.6 335.8 61.7 335.6 61.7 334.9C61.7 334.2 60.8 334.8 62.3 332.5C63.7 330.2 68.5 325.7 70.3 321.2C72.1 316.7 72.8 309.0 73.3 305.4C73.8 301.7 73.7 302.6 73.3 299.2C72.9 295.7 71.9 289.7 70.8 284.7C69.8 279.6 67.5 273.1 66.8 268.9C66.1 264.6 66.1 263.7 66.8 259.5C67.5 255.2 70.4 247.6 71.1 243.1C71.8 238.6 72.0 239.2 71.1 232.6C70.2 226.0 66.6 211.2 65.7 203.3C64.8 195.5 64.8 193.4 65.7 185.4C66.6 177.3 71.1 154.7 71.1 154.7Z';

  static final Matrix4 _mirror =
      Matrix4.identity()
        ..translateByDouble(200.0, 0.0, 0, 1)
        ..scaleByDouble(-1.0, 1.0, 1, 1);

  static final Path headPath = parse(_head);
  static final Path chestPath = parse(_chest);
  static final Path bellyPath = parse(_belly);
  static final Path pelvisPath = parse(_pelvis);
  static final Path torsoBackPath = parse(_torsoBack);
  static final Path armL = parse(_arm);
  static final Path armR = armL.transform(_mirror.storage);
  static final Path legL = parse(_leg);
  static final Path legR = legL.transform(_mirror.storage);

  /// Paths of a region. For limbs, the first path carries the voice target
  /// and the key.
  static List<Path> pathsOf(String region) {
    switch (region) {
      case 'cabeca':
        return [headPath];
      case 'peito':
        return [chestPath];
      case 'barriga':
        return [bellyPath];
      case 'pelve':
        return [pelvisPath];
      case 'costas':
        return [torsoBackPath];
      case 'membros':
        return [armL, armR, legL, legR];
    }
    return const [];
  }

  static Rect normalized(Rect r) => Rect.fromLTWH(
    r.left / width,
    r.top / height,
    r.width / width,
    r.height / height,
  );

  static final _token = RegExp(r'[MLHVCZ]|-?\d*\.?\d+');

  /// Absolute SVG path data (M L H V C Z) to a [Path].
  static Path parse(String d) {
    final path = Path();
    final t = _token.allMatches(d).map((m) => m[0]!).toList();
    var i = 0;
    var cmd = '';
    double n() => double.parse(t[i++]);
    var x = 0.0, y = 0.0;
    while (i < t.length) {
      if (RegExp(r'[A-Z]').hasMatch(t[i])) cmd = t[i++];
      switch (cmd) {
        case 'M':
          x = n();
          y = n();
          path.moveTo(x, y);
          cmd = 'L';
        case 'L':
          x = n();
          y = n();
          path.lineTo(x, y);
        case 'H':
          x = n();
          path.lineTo(x, y);
        case 'V':
          y = n();
          path.lineTo(x, y);
        case 'C':
          final x1 = n(), y1 = n(), x2 = n(), y2 = n();
          x = n();
          y = n();
          path.cubicTo(x1, y1, x2, y2, x, y);
        case 'Z':
          path.close();
        default:
          return path;
      }
    }
    return path;
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
      size.width / _BodyGeometry.width,
      size.height / _BodyGeometry.height,
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
      for (final p in _BodyGeometry.pathsOf(region)) {
        canvas.drawPath(p.shift(const Offset(0, 3)), shadow);
      }
    }

    for (final region in regions) {
      final on = selected.contains(region);
      for (final p in _BodyGeometry.pathsOf(region)) {
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
    final p = _BodyGeometry.parse(d);
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 0.85
          ..color = on ? _detailOn : _detail;
    canvas.drawPath(p, paint);
    canvas.drawPath(p.transform(_BodyGeometry._mirror.storage), paint);
  }

  /// Draws [d] once (centre-line details).
  void _c(Canvas canvas, String d, bool on) {
    canvas.drawPath(
      _BodyGeometry.parse(d),
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
