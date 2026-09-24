import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';

/// Presentation variants for [DualisLogo] according to the Dualis Brand Manual.
enum DualisLogoVariant {
  /// Horizontal layout: symbol on left, brand typography on right (Primary authorized version).
  horizontal,

  /// Vertical layout: symbol on top, brand typography centered below (Secondary authorized version).
  vertical,

  /// Continuous loop symbol only without brand text (for avatars, app icons, and minimal spaces).
  symbolOnly,

  /// Synonym for [symbolOnly] for backward compatibility.
  emblemOnly,
}

/// Color reproduction variants according to Manual Section 6.
enum DualisLogoColorScheme {
  /// Automatically matches system/theme brightness (color on light, white on dark).
  auto,

  /// Official polychromatic authorized brand version (color symbol, navy text, light blue tagline).
  fullColor,

  /// Monochrome Dualis Navy (#0E3E6C).
  monochromeNavy,

  /// Reverse white (#FFFFFF) for dark backgrounds.
  whiteReversed,
}

/// Official Dualis continuous loop brand symbol.
class DualisEmblem extends StatelessWidget {
  /// Width and height of the symbol.
  final double size;

  /// Whether to enclose the symbol inside a branded container.
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
    final assetPath = isDark ? AppAssets.logoSymbolWhite : AppAssets.logoSymbol;

    final imageWidget = Semantics(
      label: 'Dualis — continuous check up',
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        semanticLabel: 'Dualis Symbol',
      ),
    );

    if (!withContainer) {
      return imageWidget;
    }

    final effectiveColor = containerColor ??
        (isDark
            ? AppColors.dualisNavy.withAlpha(80)
            : AppColors.brandBgLightBlue);

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
      ),
      child: Center(child: imageWidget),
    );
  }
}

/// The official Dualis brand logo component.
///
/// Implements the guidelines from the **Manual de Uso da Marca Dualis** (Versão 1.0):
/// - Punto 1: Composição única (símbolo contínuo entrelaçado, logotipo Dualis, tagline continuous check up).
/// - Punto 2: Versões autorizadas (Horizontal principal e Vertical secundária).
/// - Punto 3: Área de proteção calculada proporcionalmente à altura da letra 'a'.
/// - Punto 4: Tamanho mínimo digital (150 px horizontal, 120 px vertical) com fallback sem tagline.
/// - Punto 5/6: Versões a cores, monocromática azul-marinho (#0E3E6C) e reversa branca (#FFFFFF).
/// - Punto 8: Ausência de distorções, sombras ou resplandores impróprios.
/// - Punto 9: Semantics label "Dualis — continuous check up" e suporte a clique institucional.
class DualisLogo extends StatelessWidget {
  /// Logo presentation variant: [DualisLogoVariant.horizontal],
  /// [DualisLogoVariant.vertical], or [DualisLogoVariant.symbolOnly].
  final DualisLogoVariant variant;

  /// Explicit width of the logo.
  /// Minimum recommended digital widths: 150 px (horizontal), 120 px (vertical).
  final double? width;

  /// Explicit height of the logo. If omitted, aspect ratio is preserved.
  final double? height;

  /// Emblem/symbol size when in [DualisLogoVariant.symbolOnly] or [DualisLogoVariant.emblemOnly].
  final double emblemSize;

  /// Font size compatibility parameter (kept for backward compatibility).
  final double? fontSize;

  /// Whether to display the tagline ("continuous check up").
  /// Note: If width is below the digital minimum (150px horizontal, 120px vertical),
  /// the tagline is automatically omitted for readability per Section 4.
  final bool showTagline;

  /// Custom tagline override (if needed).
  final String? tagline;

  /// Whether to enclose the standalone emblem in a container (for symbolOnly/emblemOnly).
  final bool withEmblemContainer;

  /// Alignment of children across the layout axis.
  final MainAxisAlignment mainAxisAlignment;

  /// Color reproduction mode. Defaults to [DualisLogoColorScheme.auto].
  final DualisLogoColorScheme colorScheme;

  /// Whether to apply the protective safe area padding around the logo per Section 3.
  final bool withProtectionArea;

  /// Whether this is a high-visibility hero presentation (applies 2x protection area).
  final bool isHighVisibility;

  /// Optional click callback (e.g. to navigate to home per Section 9.3).
  final VoidCallback? onTap;

  const DualisLogo({
    super.key,
    this.variant = DualisLogoVariant.horizontal,
    this.width,
    this.height,
    this.emblemSize = 38,
    this.fontSize,
    this.showTagline = true,
    this.tagline,
    this.withEmblemContainer = false,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.colorScheme = DualisLogoColorScheme.auto,
    this.withProtectionArea = false,
    this.isHighVisibility = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Resolve color mode
    final effectiveColorScheme = colorScheme == DualisLogoColorScheme.auto
        ? (isDark ? DualisLogoColorScheme.whiteReversed : DualisLogoColorScheme.fullColor)
        : colorScheme;

    final isWhiteReversed = effectiveColorScheme == DualisLogoColorScheme.whiteReversed;
    final isMonoNavy = effectiveColorScheme == DualisLogoColorScheme.monochromeNavy;

    // Handle symbol/emblem only
    if (variant == DualisLogoVariant.symbolOnly || variant == DualisLogoVariant.emblemOnly) {
      final symbolWidget = DualisEmblem(
        size: width ?? emblemSize,
        withContainer: withEmblemContainer,
      );

      return _wrapInteractivityAndPadding(
        context: context,
        child: symbolWidget,
        resolvedWidth: width ?? emblemSize,
      );
    }

    // Horizontal Layout (Primary Authorized Version)
    if (variant == DualisLogoVariant.horizontal) {
      final effectiveWidth = width ?? 180.0;
      // Section 4 minimum: 150px for horizontal with tagline
      final canShowTagline = showTagline && effectiveWidth >= 150.0;

      String assetPath;
      if (isWhiteReversed) {
        assetPath = AppAssets.logoReverseWhite;
      } else if (isMonoNavy) {
        assetPath = AppAssets.logoMonochromeNavy;
      } else if (canShowTagline) {
        assetPath = AppAssets.logoHorizontal;
      } else {
        assetPath = AppAssets.logoHorizontalNoTag;
      }

      final logoImage = Image.asset(
        assetPath,
        width: effectiveWidth,
        height: height,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      );

      return _wrapInteractivityAndPadding(
        context: context,
        child: logoImage,
        resolvedWidth: effectiveWidth,
      );
    }

    // Vertical Layout (Secondary Authorized Version)
    final effectiveWidth = width ?? 150.0;
    // Section 4 minimum: 120px for vertical with tagline
    final canShowTagline = showTagline && effectiveWidth >= 120.0;

    String assetPath;
    if (isWhiteReversed) {
      assetPath = AppAssets.logoVerticalReverseWhite;
    } else if (canShowTagline) {
      assetPath = AppAssets.logoVertical;
    } else {
      assetPath = AppAssets.logoVerticalNoTag;
    }

    final logoImage = Image.asset(
      assetPath,
      width: effectiveWidth,
      height: height,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );

    return _wrapInteractivityAndPadding(
      context: context,
      child: logoImage,
      resolvedWidth: effectiveWidth,
    );
  }

  Widget _wrapInteractivityAndPadding({
    required BuildContext context,
    required Widget child,
    required double resolvedWidth,
  }) {
    Widget content = Semantics(
      label: 'Dualis — continuous check up',
      button: onTap != null,
      child: child,
    );

    if (onTap != null) {
      content = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    if (withProtectionArea) {
      // Section 3: Protection area = height of lowercase 'a' (approx 6-8% of width)
      final baseProtection = (resolvedWidth * 0.06).clamp(8.0, 24.0);
      final protectionMargin = isHighVisibility ? baseProtection * 2.0 : baseProtection;

      content = Padding(
        padding: EdgeInsets.all(protectionMargin),
        child: content,
      );
    }

    return content;
  }
}
