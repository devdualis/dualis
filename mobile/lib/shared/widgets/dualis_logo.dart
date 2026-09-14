import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';

/// Presentation variants for [DualisLogo].
enum DualisLogoVariant {
  /// Horizontal layout: emblem on left, brand typography on right.
  horizontal,

  /// Vertical layout: emblem on top, brand typography centered below.
  vertical,

  /// Emblem only without brand text.
  emblemOnly,
}

/// Standalone medical shield emblem for DualisCheckUp.
class DualisEmblem extends StatelessWidget {
  /// Width and height of the emblem or its inner SVG.
  final double size;

  /// Whether to enclose the emblem inside a soft-glow branded badge container.
  final bool withContainer;

  /// Shape of the badge container if [withContainer] is true.
  final BoxShape shape;

  /// Border radius if [shape] is [BoxShape.rectangle].
  final BorderRadiusGeometry? borderRadius;

  /// Optional custom background color for the badge container.
  final Color? containerColor;

  const DualisEmblem({
    super.key,
    this.size = 40,
    this.withContainer = false,
    this.shape = BoxShape.circle,
    this.borderRadius,
    this.containerColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final svgWidget = SvgPicture.asset(
      AppAssets.emblem,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticsLabel: 'DualisCheckUp Emblem',
    );

    if (!withContainer) {
      return svgWidget;
    }

    final effectiveColor = containerColor ??
        (isDark
            ? AppColors.softIndigoDark.withAlpha(50)
            : AppColors.softIndigo.withAlpha(20));

    final effectiveBorderColor = isDark
        ? AppColors.clinicalTeal.withAlpha(60)
        : AppColors.softIndigo.withAlpha(35);

    return Container(
      width: size + 16,
      height: size + 16,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: effectiveColor,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle
            ? (borderRadius ?? BorderRadius.circular(16))
            : null,
        border: Border.all(
          color: effectiveBorderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.clinicalTeal : AppColors.softIndigo)
                .withAlpha(isDark ? 35 : 20),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(child: svgWidget),
    );
  }
}

/// The official DualisCheckUp brand logo component.
///
/// Combines the clinical shield emblem with brand typography.
class DualisLogo extends StatelessWidget {
  /// Logo presentation variant: [DualisLogoVariant.horizontal],
  /// [DualisLogoVariant.vertical], or [DualisLogoVariant.emblemOnly].
  final DualisLogoVariant variant;

  /// Size of the emblem inside the logo.
  final double emblemSize;

  /// Font size of the "DualisCheckUp" title text.
  final double? fontSize;

  /// Whether to display a subtitle tagline underneath the brand name.
  final bool showTagline;

  /// Custom tagline text (defaults to "Triagem Preventiva Unificada").
  final String? tagline;

  /// Whether to place the emblem inside a glowing branded container.
  final bool withEmblemContainer;

  /// Alignment of children across the layout axis.
  final MainAxisAlignment mainAxisAlignment;

  const DualisLogo({
    super.key,
    this.variant = DualisLogoVariant.horizontal,
    this.emblemSize = 38,
    this.fontSize,
    this.showTagline = false,
    this.tagline,
    this.withEmblemContainer = true,
    this.mainAxisAlignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveFontSize = fontSize ?? (variant == DualisLogoVariant.vertical ? 24 : 20);

    final emblem = DualisEmblem(
      size: emblemSize,
      withContainer: withEmblemContainer,
    );

    if (variant == DualisLogoVariant.emblemOnly) {
      return emblem;
    }

    final brandTitle = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Dualis',
            style: GoogleFonts.plusJakartaSans(
              fontSize: effectiveFontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: isDark ? AppColors.textPrimaryDark : AppColors.softIndigo,
            ),
          ),
          TextSpan(
            text: 'CheckUp',
            style: GoogleFonts.plusJakartaSans(
              fontSize: effectiveFontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppColors.clinicalTeal,
            ),
          ),
        ],
      ),
      textAlign: variant == DualisLogoVariant.vertical ? TextAlign.center : TextAlign.start,
    );

    final taglineWidget = showTagline
        ? Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              tagline ?? 'Triagem Preventiva Inteligente',
              style: GoogleFonts.plusJakartaSans(
                fontSize: (effectiveFontSize * 0.48).clamp(10.0, 13.0),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              textAlign: variant == DualisLogoVariant.vertical ? TextAlign.center : TextAlign.start,
            ),
          )
        : null;

    if (variant == DualisLogoVariant.vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          emblem,
          const SizedBox(height: 12),
          brandTitle,
          if (taglineWidget != null) taglineWidget,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        emblem,
        const SizedBox(width: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            brandTitle,
            if (taglineWidget != null) taglineWidget,
          ],
        ),
      ],
    );
  }
}
