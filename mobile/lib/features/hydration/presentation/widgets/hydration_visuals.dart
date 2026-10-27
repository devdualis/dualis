import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Glass that fills with an animation as water is logged (strategy §11).
class AnimatedWaterGlass extends StatelessWidget {
  /// 0..1 share of the person's own goal.
  final double fill;
  final double width;
  final double height;

  const AnimatedWaterGlass({
    super.key,
    required this.fill,
    this.width = 96,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: fill.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => CustomPaint(
        key: const Key('hydration_glass'),
        size: Size(width, height),
        painter: _GlassPainter(value),
      ),
    );
  }
}

class _GlassPainter extends CustomPainter {
  final double fill;

  _GlassPainter(this.fill);

  @override
  void paint(Canvas canvas, Size size) {
    final inset = size.width * 0.12;
    final glass = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width - inset, size.height)
      ..lineTo(inset, size.height)
      ..close();

    canvas.save();
    canvas.clipPath(glass);
    canvas.drawPath(glass, Paint()..color = AppColors.clinicalTealLight);
    if (fill > 0) {
      final top = size.height * (1 - fill);
      final wave = Path()..moveTo(0, size.height);
      for (var x = 0.0; x <= size.width; x += 4) {
        wave.lineTo(
          x,
          top + math.sin(x / size.width * math.pi * 2) * size.height * 0.015,
        );
      }
      wave
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(
        wave,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5CC3EA), AppColors.clinicalTeal],
          ).createShader(Offset.zero & size),
      );
    }
    canvas.restore();
    canvas.drawPath(
      glass,
      Paint()
        ..color = AppColors.clinicalTealDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _GlassPainter oldDelegate) =>
      oldDelegate.fill != fill;
}

/// Daily goal ring with the amount in the middle.
class HydrationGoalRing extends StatelessWidget {
  final double progress;
  final Widget center;
  final double size;

  const HydrationGoalRing({
    super.key,
    required this.progress,
    required this.center,
    this.size = 132,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: progress.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              key: const Key('hydration_goal_ring'),
              value: value,
              strokeWidth: 10,
              backgroundColor: AppColors.outlineLight,
              valueColor: const AlwaysStoppedAnimation(AppColors.clinicalTeal),
              strokeCap: StrokeCap.round,
            ),
            Center(child: child),
          ],
        ),
        child: center,
      ),
    );
  }
}
