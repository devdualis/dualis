import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

enum CareMarkKind {
  vaccines,
  allergies,
  conditions,
  medications,
  prescriptions,
  appointments,
  exams,
  summary,
}

/// Compact, hand-drawn care marks used by the care hub tiles.
class CareMark extends StatelessWidget {
  const CareMark(this.kind, {super.key, this.size = 27});

  final CareMarkKind kind;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _CareMarkPainter(kind)),
  );
}

class _CareMarkPainter extends CustomPainter {
  const _CareMarkPainter(this.kind);

  final CareMarkKind kind;
  static const _navy = AppColors.dualisNavy;
  static const _cyan = AppColors.clinicalTeal;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48, size.height / 48);
    final outline =
        Paint()
          ..color = _navy
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    final accent =
        Paint()
          ..color = _cyan
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = _cyan;

    switch (kind) {
      case CareMarkKind.vaccines:
        // Angled syringe with a cyan plunger and dose window.
        canvas.drawLine(const Offset(15, 34), const Offset(33, 16), outline);
        canvas.drawLine(const Offset(12, 37), const Offset(17, 32), outline);
        canvas.drawLine(const Offset(31, 13), const Offset(36, 18), outline);
        canvas.drawLine(const Offset(27, 14), const Offset(34, 21), outline);
        canvas.drawLine(const Offset(19, 30), const Offset(23, 34), accent);
        canvas.drawLine(const Offset(18, 26), const Offset(22, 30), outline);
        canvas.drawLine(const Offset(24, 20), const Offset(28, 24), outline);
        canvas.drawLine(const Offset(10, 39), const Offset(7, 42), outline);
        break;
      case CareMarkKind.allergies:
        final shield =
            Path()
              ..moveTo(24, 7)
              ..lineTo(38, 12)
              ..lineTo(37, 25)
              ..quadraticBezierTo(35, 35, 24, 41)
              ..quadraticBezierTo(13, 35, 11, 25)
              ..lineTo(10, 12)
              ..close();
        canvas.drawPath(shield, outline);
        canvas.drawCircle(const Offset(24, 24), 3.4, fill);
        for (final p in const [
          Offset(24, 16),
          Offset(17, 22),
          Offset(31, 22),
          Offset(19, 31),
          Offset(29, 31),
        ]) {
          canvas.drawCircle(p, 1.2, outline);
        }
        break;
      case CareMarkKind.conditions:
        final heart =
            Path()
              ..moveTo(24, 38)
              ..cubicTo(20, 34, 9, 26, 9, 18)
              ..cubicTo(9, 8, 22, 7, 24, 17)
              ..cubicTo(27, 7, 39, 8, 39, 18)
              ..cubicTo(39, 26, 28, 34, 24, 38);
        canvas.drawPath(heart, outline);
        canvas.drawLine(const Offset(15, 24), const Offset(20, 24), accent);
        canvas.drawLine(const Offset(28, 24), const Offset(33, 24), accent);
        canvas.drawLine(const Offset(20, 24), const Offset(23, 28), accent);
        canvas.drawLine(const Offset(23, 28), const Offset(27, 19), accent);
        canvas.drawLine(const Offset(27, 19), const Offset(30, 24), accent);
        break;
      case CareMarkKind.medications:
        canvas.save();
        canvas.translate(24, 24);
        canvas.rotate(-math.pi / 4);
        final capsule = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-8, -18, 16, 36),
          const Radius.circular(8),
        );
        canvas.drawRRect(capsule, outline);
        canvas.drawLine(const Offset(-8, 0), const Offset(8, 0), accent);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-7, -17, 14, 16),
            const Radius.circular(7),
          ),
          fill,
        );
        canvas.restore();
        break;
      case CareMarkKind.prescriptions:
        final page = RRect.fromRectAndRadius(
          const Rect.fromLTWH(11, 6, 26, 36),
          const Radius.circular(4),
        );
        canvas.drawRRect(page, outline);
        canvas.drawLine(const Offset(17, 16), const Offset(31, 16), outline);
        canvas.drawLine(const Offset(17, 23), const Offset(25, 23), outline);
        canvas.drawLine(const Offset(17, 31), const Offset(22, 31), accent);
        canvas.drawLine(const Offset(30, 28), const Offset(30, 36), accent);
        canvas.drawLine(const Offset(26, 32), const Offset(34, 32), accent);
        break;
      case CareMarkKind.appointments:
        final calendar = RRect.fromRectAndRadius(
          const Rect.fromLTWH(8, 11, 32, 29),
          const Radius.circular(5),
        );
        canvas.drawRRect(calendar, outline);
        canvas.drawLine(const Offset(8, 19), const Offset(40, 19), outline);
        canvas.drawLine(const Offset(16, 7), const Offset(16, 15), outline);
        canvas.drawLine(const Offset(32, 7), const Offset(32, 15), outline);
        canvas.drawLine(const Offset(16, 29), const Offset(21, 34), accent);
        canvas.drawLine(const Offset(21, 34), const Offset(32, 24), accent);
        break;
      case CareMarkKind.exams:
        final tube =
            Path()
              ..moveTo(17, 8)
              ..lineTo(31, 8)
              ..moveTo(20, 8)
              ..lineTo(20, 29)
              ..quadraticBezierTo(20, 37, 27, 39)
              ..quadraticBezierTo(34, 37, 34, 29)
              ..lineTo(34, 8);
        canvas.drawPath(tube, outline);
        canvas.drawLine(const Offset(20, 27), const Offset(34, 27), accent);
        canvas.drawCircle(const Offset(24, 32), 1.4, fill);
        canvas.drawCircle(const Offset(30, 34), 1.2, fill);
        break;
      case CareMarkKind.summary:
        final page = RRect.fromRectAndRadius(
          const Rect.fromLTWH(9, 6, 30, 36),
          const Radius.circular(4),
        );
        canvas.drawRRect(page, outline);
        canvas.drawLine(const Offset(16, 14), const Offset(30, 14), outline);
        canvas.drawLine(const Offset(16, 20), const Offset(32, 20), outline);
        final pulse =
            Path()
              ..moveTo(15, 29)
              ..lineTo(20, 29)
              ..lineTo(23, 24)
              ..lineTo(27, 34)
              ..lineTo(30, 29)
              ..lineTo(34, 29);
        canvas.drawPath(pulse, accent);
        break;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CareMarkPainter oldDelegate) =>
      kind != oldDelegate.kind;
}
