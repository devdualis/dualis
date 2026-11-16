import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Redesign "duotone" icon holder: a soft cyan-tinted rounded square behind a
/// navy glyph. Structural icons (card headers, list rows) sit in one of these.
/// The glyph itself is passed as [child], so it keeps its own size, colour and
/// any gradient wrapper.
class DuotoneIconTile extends StatelessWidget {
  final Widget child;
  final double size;
  final double radius;
  final Color? background;

  const DuotoneIconTile({
    super.key,
    required this.child,
    this.size = 40,
    this.radius = 12,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background ?? AppColors.iconTileTint,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}
