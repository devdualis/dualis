import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One bundled background (strategy §12): landscapes, never people.
///
/// Licensed photos are not chosen yet, so each spec is drawn in code from a
/// sky gradient, an optional sun and layered hills. To switch to a photo,
/// set [assetPath] to a bundled WebP (under 150 KB); the painter is then
/// skipped and the same overlay keeps the text contrast.
class LandscapeSpec {
  final String id;
  final List<Color> sky;
  final Color? sun;
  final double sunX;
  final double sunY;
  final List<Color> hills;
  final String? assetPath;

  const LandscapeSpec({
    required this.id,
    required this.sky,
    this.sun,
    this.sunX = 0.75,
    this.sunY = 0.22,
    required this.hills,
    this.assetPath,
  });
}

/// Small rotating set (strategy §12 asks for 8 to 12; placeholders for now).
const List<LandscapeSpec> kLandscapeBackgrounds = [
  LandscapeSpec(
    id: 'dawn_hills',
    sky: [Color(0xFFFDE7D6), Color(0xFFE3EEF9)],
    sun: Color(0xFFFFD7A8),
    hills: [Color(0xFFBFD8C9), Color(0xFF9CC3AE), Color(0xFF7FAF97)],
  ),
  LandscapeSpec(
    id: 'lake_mountains',
    sky: [Color(0xFFDDEBF7), Color(0xFFF4F8FB)],
    sun: Color(0xFFFFF1D0),
    sunX: 0.25,
    hills: [Color(0xFFC3D3E6), Color(0xFFA5BCD8), Color(0xFFCFE3EE)],
  ),
  LandscapeSpec(
    id: 'sea_horizon',
    sky: [Color(0xFFE6F2FA), Color(0xFFFFF6EC)],
    sun: Color(0xFFFFE2B8),
    sunY: 0.32,
    hills: [Color(0xFFB9DCEB), Color(0xFF9CCDE2), Color(0xFFF1E3C8)],
  ),
  LandscapeSpec(
    id: 'dunes',
    sky: [Color(0xFFFCEFE3), Color(0xFFF6F1FA)],
    sun: Color(0xFFFFD9B3),
    sunX: 0.3,
    hills: [Color(0xFFF1D9BC), Color(0xFFE7C7A3), Color(0xFFDDB68E)],
  ),
  LandscapeSpec(
    id: 'forest_hills',
    sky: [Color(0xFFE5F1EA), Color(0xFFF5FAF7)],
    hills: [Color(0xFFC6DFCF), Color(0xFFA3C9B0), Color(0xFF86B596)],
  ),
  LandscapeSpec(
    id: 'lavender_field',
    sky: [Color(0xFFEDE8F7), Color(0xFFFBF6F2)],
    sun: Color(0xFFFFE6C7),
    sunX: 0.6,
    hills: [Color(0xFFD8D0EC), Color(0xFFC3B7E2), Color(0xFFB2C99F)],
  ),
  LandscapeSpec(
    id: 'snow_peaks',
    sky: [Color(0xFFE8EFF7), Color(0xFFFAFCFE)],
    hills: [Color(0xFFDCE6F0), Color(0xFFC8D6E5), Color(0xFFE9EFF5)],
  ),
  LandscapeSpec(
    id: 'river_valley',
    sky: [Color(0xFFFFF0E0), Color(0xFFE7F3F6)],
    sun: Color(0xFFFFD6A0),
    sunX: 0.45,
    sunY: 0.28,
    hills: [Color(0xFFCFE0C4), Color(0xFFB4D2C2), Color(0xFFA6CFDD)],
  ),
];

/// Background of the day: the same for everyone, picked by date only.
LandscapeSpec landscapeForDay(DateTime now) {
  final dayIndex =
      DateTime.utc(now.year, now.month, now.day).millisecondsSinceEpoch ~/
          Duration.millisecondsPerDay;
  return kLandscapeBackgrounds[dayIndex % kLandscapeBackgrounds.length];
}

/// Subtle landscape behind [child] with a light overlay so dark text on top
/// keeps WCAG AA contrast (overlay alpha [overlayOpacity] over pale colors).
class LandscapeBackground extends StatelessWidget {
  static const double overlayOpacity = 0.72;

  final Widget child;
  final LandscapeSpec? spec;

  const LandscapeBackground({super.key, required this.child, this.spec});

  @override
  Widget build(BuildContext context) {
    final resolved = spec ?? landscapeForDay(DateTime.now());
    final asset = resolved.assetPath;
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          child: asset != null
              ? Image.asset(asset, fit: BoxFit.cover)
              : CustomPaint(
                  key: Key('landscape_${resolved.id}'),
                  painter: LandscapePainter(resolved),
                ),
        ),
        ColoredBox(
          color: Colors.white.withValues(alpha: overlayOpacity),
        ),
        child,
      ],
    );
  }
}

class LandscapePainter extends CustomPainter {
  final LandscapeSpec spec;

  LandscapePainter(this.spec);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: spec.sky,
        ).createShader(rect),
    );

    if (spec.sun != null) {
      final center = Offset(size.width * spec.sunX, size.height * spec.sunY);
      final radius = size.shortestSide * 0.12;
      canvas.drawCircle(
        center,
        radius * 1.8,
        Paint()..color = spec.sun!.withValues(alpha: 0.35),
      );
      canvas.drawCircle(center, radius, Paint()..color = spec.sun!);
    }

    // Layered hills, back to front, each a gentle sine wave.
    final count = spec.hills.length;
    for (var i = 0; i < count; i++) {
      final baseY = size.height * (0.55 + i * 0.12);
      final amplitude = size.height * (0.05 - i * 0.01);
      final phase = (i + 1) * 1.7 + spec.id.length;
      final path = Path()..moveTo(0, size.height);
      for (var x = 0.0; x <= size.width; x += 8) {
        final t = x / size.width;
        final y = baseY +
            math.sin(t * math.pi * (1.3 + i * 0.4) + phase) * amplitude;
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = spec.hills[i]);
    }
  }

  @override
  bool shouldRepaint(covariant LandscapePainter oldDelegate) =>
      oldDelegate.spec.id != spec.id;
}
