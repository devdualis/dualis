import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Redesign glass surface: translucent white fill, soft white edge and a navy
/// drop shadow painted only outside the card (see [OuterGlassShadowPainter]).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      // The fill is translucent, so a regular BoxShadow would show through
      // as a second panel inside the card. Paint it outside the card only.
      painter: OuterGlassShadowPainter(radius: radius),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.glassFill,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColors.glassEdge),
        ),
        child: child,
      ),
    );
  }
}

/// Glass-card drop shadow painted only outside the rounded card, so it never
/// shows through a translucent fill. Matches [AppColors.glassShadow].
class OuterGlassShadowPainter extends CustomPainter {
  final double radius;
  final double blur;
  final double alpha;

  const OuterGlassShadowPainter({
    required this.radius,
    this.blur = 24,
    this.alpha = 0.2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final card = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect((Offset.zero & size).inflate(blur * 3)),
      Path()..addRRect(card),
    );
    canvas
      ..save()
      ..clipPath(outside)
      ..drawRRect(
        card.shift(const Offset(0, 10)).deflate(10),
        Paint()
          ..color = AppColors.dualisNavy.withValues(alpha: alpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur / 2),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(OuterGlassShadowPainter old) =>
      old.radius != radius || old.blur != blur || old.alpha != alpha;
}
