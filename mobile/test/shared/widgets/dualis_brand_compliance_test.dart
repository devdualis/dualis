import 'package:dualis_mobile/core/constants/app_assets.dart';
import 'package:dualis_mobile/core/constants/app_colors.dart';
import 'package:dualis_mobile/core/theme/app_theme.dart';
import 'package:dualis_mobile/shared/widgets/dualis_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Dualis Brand Compliance Suite (Manual de Uso da Marca Dualis - v1.0)', () {
    // Punto 1: Objetivo e composição da marca
    test('Punto 1 & 5: Brand Colors exact HEX specification', () {
      expect(AppColors.dualisNavy, const Color(0xFF0E3E6C));
      expect(AppColors.dualisSymbolBlue, const Color(0xFF0B83C9));
      expect(AppColors.dualisSymbolCyan, const Color(0xFF26B7D7));
      expect(AppColors.dualisSymbolGreen, const Color(0xFF66BE71));
      expect(AppColors.dualisTagline, const Color(0xFF2B9ED0));

      expect(AppColors.brandBgWhite, const Color(0xFFFFFFFF));
      expect(AppColors.brandBgLightGray, const Color(0xFFF8FAFC));
      expect(AppColors.brandBgLightBlue, const Color(0xFFF0F7FB));
      expect(AppColors.brandBgDarkNavy, const Color(0xFF0E3E6C));
    });

    // Punto 2: Versões autorizadas (Horizontal principal e Vertical secundária)
    testWidgets('Punto 2.1: Horizontal principal renders with tagline above 150px', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DualisLogo(
              variant: DualisLogoVariant.horizontal,
              width: 180,
            ),
          ),
        ),
      );

      final Image image = tester.widget(find.byType(Image));
      final AssetImage asset = image.image as AssetImage;
      expect(asset.assetName, AppAssets.logoHorizontal);
    });

    testWidgets('Punto 2.2: Vertical secundária renders centered composition with tagline above 120px', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DualisLogo(
              variant: DualisLogoVariant.vertical,
              width: 140,
            ),
          ),
        ),
      );

      final Image image = tester.widget(find.byType(Image));
      final AssetImage asset = image.image as AssetImage;
      expect(asset.assetName, AppAssets.logoVertical);
    });

    // Punto 3: Área de proteção
    testWidgets('Punto 3: Protective area applies minimum padding proportional to letter "a"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DualisLogo(
              variant: DualisLogoVariant.horizontal,
              width: 200,
              withProtectionArea: true,
              isHighVisibility: false,
            ),
          ),
        ),
      );

      final paddingFinder = find.byType(Padding);
      expect(paddingFinder, findsWidgets);

      // Verify padding is applied (200 * 0.06 = 12px)
      final Padding padding = tester.widget(paddingFinder.first);
      expect(padding.padding, const EdgeInsets.all(12.0));
    });

    testWidgets('Punto 3: Protective area applies 2x measure in high-visibility mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DualisLogo(
              variant: DualisLogoVariant.horizontal,
              width: 200,
              withProtectionArea: true,
              isHighVisibility: true,
            ),
          ),
        ),
      );

      final paddingFinder = find.byType(Padding);
      expect(paddingFinder, findsWidgets);

      final Padding padding = tester.widget(paddingFinder.first);
      expect(padding.padding, const EdgeInsets.all(24.0)); // 2 * 12.0
    });

    // Punto 4: Tamanho mínimo e degradação sem tagline
    testWidgets('Punto 4: Horizontal below 150px switches automatically to no-tagline asset', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DualisLogo(
              variant: DualisLogoVariant.horizontal,
              width: 130, // Below 150px
            ),
          ),
        ),
      );

      final Image image = tester.widget(find.byType(Image));
      final AssetImage asset = image.image as AssetImage;
      expect(asset.assetName, AppAssets.logoHorizontalNoTag);
    });

    testWidgets('Punto 4: Vertical below 120px switches automatically to no-tagline asset', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DualisLogo(
              variant: DualisLogoVariant.vertical,
              width: 110, // Below 120px
            ),
          ),
        ),
      );

      final Image image = tester.widget(find.byType(Image));
      final AssetImage asset = image.image as AssetImage;
      expect(asset.assetName, AppAssets.logoVerticalNoTag);
    });

    // Punto 6: Versões monocromáticas e reversas
    testWidgets('Punto 6: Monochrome Navy version renders AppAssets.logoMonochromeNavy', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DualisLogo(
              variant: DualisLogoVariant.horizontal,
              width: 180,
              colorScheme: DualisLogoColorScheme.monochromeNavy,
            ),
          ),
        ),
      );

      final Image image = tester.widget(find.byType(Image));
      final AssetImage asset = image.image as AssetImage;
      expect(asset.assetName, AppAssets.logoMonochromeNavy);
    });

    testWidgets('Punto 6: Dark mode renders white reversed logo automatically', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: DualisLogo(
              variant: DualisLogoVariant.horizontal,
              width: 180,
              colorScheme: DualisLogoColorScheme.auto,
            ),
          ),
        ),
      );

      final Image image = tester.widget(find.byType(Image));
      final AssetImage asset = image.image as AssetImage;
      expect(asset.assetName, AppAssets.logoReverseWhite);
    });

    // Punto 7: Tipografia de apoio (Inter)
    test('Punto 7: AppTheme uses Inter typography as recommended by Brand Manual', () {
      final lightTheme = AppTheme.lightTheme;
      final darkTheme = AppTheme.darkTheme;

      expect(lightTheme.textTheme.displayLarge?.fontFamily, contains('Inter'));
      expect(lightTheme.textTheme.headlineMedium?.fontFamily, contains('Inter'));
      expect(lightTheme.textTheme.bodyLarge?.fontFamily, contains('Inter'));

      expect(darkTheme.textTheme.displayLarge?.fontFamily, contains('Inter'));
      expect(darkTheme.textTheme.headlineMedium?.fontFamily, contains('Inter'));
      expect(darkTheme.textTheme.bodyLarge?.fontFamily, contains('Inter'));

      // Headings use dualisNavy
      expect(lightTheme.textTheme.displayLarge?.color, AppColors.dualisNavy);
      expect(lightTheme.textTheme.headlineMedium?.color, AppColors.dualisNavy);
    });

    test('AppTheme.darkTheme retains identical colors and light brightness to maintain consistent appearance across dark/light mode', () {
      final lightTheme = AppTheme.lightTheme;
      final darkTheme = AppTheme.darkTheme;

      expect(darkTheme.brightness, equals(lightTheme.brightness));
      expect(darkTheme.scaffoldBackgroundColor, equals(lightTheme.scaffoldBackgroundColor));
      expect(darkTheme.colorScheme.primary, equals(lightTheme.colorScheme.primary));
      expect(darkTheme.colorScheme.surface, equals(lightTheme.colorScheme.surface));
      expect(darkTheme.textTheme.displayLarge?.color, equals(lightTheme.textTheme.displayLarge?.color));
    });

    // Punto 8: Proibição de distorção
    testWidgets('Punto 8: Logo maintains contain BoxFit to prevent distortion', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DualisLogo(
              variant: DualisLogoVariant.horizontal,
              width: 180,
            ),
          ),
        ),
      );

      final Image image = tester.widget(find.byType(Image));
      expect(image.fit, BoxFit.contain);
    });

    // Punto 9: Website e Canais Digitais
    testWidgets('Punto 9.3: Provides official Semantics accessibility label and handles onTap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DualisLogo(
              variant: DualisLogoVariant.horizontal,
              width: 180,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Dualis — continuous check up'), findsOneWidget);

      await tester.tap(find.byType(DualisLogo));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}
