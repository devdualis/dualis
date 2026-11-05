import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Premium-only icon accents (approved design "D+E"): a teal gradient on the
/// Free glyphs and a small champagne dot on the active navigation item.
abstract final class PremiumAccents {
  static const Color gradientTop = Color(0xFF3BA7E0);
  static const Color gradientMid = AppColors.clinicalTeal;
  static const Color gradientBottom = Color(0xFF064A73);
  static const Color champagne = Color(0xFFC9A35B);

  static const LinearGradient iconGradient = LinearGradient(
    begin: Alignment(-0.4, -1.0),
    end: Alignment(0.4, 1.0),
    colors: [gradientTop, gradientMid, gradientBottom],
    stops: [0.0, 0.5, 1.0],
  );

  /// Same gradient shape built around [accent], so each icon keeps the
  /// colour the original design gives it (green, indigo, teal...) and only
  /// gains depth: lighter at the top, the accent itself in the middle,
  /// darker at the bottom.
  static LinearGradient gradientFor(Color accent) => LinearGradient(
    begin: iconGradient.begin,
    end: iconGradient.end,
    colors: [
      Color.lerp(accent, Colors.white, 0.3)!,
      accent,
      Color.lerp(accent, Colors.black, 0.3)!,
    ],
    stops: iconGradient.stops,
  );
}

/// Paints [icon] with a gradient built from its own colour (see
/// [PremiumAccents.gradientFor]). The glyph, size and
/// semantics come from [icon] untouched, so the layout matches the Free build.
class PremiumGradientIcon extends StatelessWidget {
  final Icon icon;

  /// Adds the champagne dot at the top-right corner (selected nav item only).
  final bool showActiveDot;

  const PremiumGradientIcon({
    super.key,
    required this.icon,
    this.showActiveDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final mask = ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        final accent = icon.color;
        final gradient = accent == null
            ? PremiumAccents.iconGradient
            : PremiumAccents.gradientFor(accent);
        return gradient.createShader(bounds);
      },
      child: icon,
    );
    if (!showActiveDot) return mask;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        mask,
        Positioned(
          top: -2,
          right: -2,
          child: Container(
            key: const Key('premium_active_dot'),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: PremiumAccents.champagne,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
