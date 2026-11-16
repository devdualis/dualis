import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/duotone_icon_tile.dart';

/// Glass card with a title (and an optional duotone icon tile), shared by the
/// dashboard sections.
class InsightsCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;

  const InsightsCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CustomPaint(
        // The fill is translucent, so a regular BoxShadow would show through
        // as a second panel inside the card. Paint it outside the card only.
        painter: const OuterGlassShadowPainter(radius: 24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.glassFill,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.glassEdge),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (icon == null)
                titleBlock
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DuotoneIconTile(
                      size: 32,
                      radius: 10,
                      child: Icon(icon, size: 18, color: AppColors.dualisNavy),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: titleBlock),
                  ],
                ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
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
