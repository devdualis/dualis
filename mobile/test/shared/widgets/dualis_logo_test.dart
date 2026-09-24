import 'package:dualis_mobile/core/constants/app_assets.dart';
import 'package:dualis_mobile/shared/widgets/dualis_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DualisLogo and DualisEmblem Tests', () {
    testWidgets('DualisEmblem loads official brand symbol asset', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DualisEmblem(size: 48),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(DualisEmblem), findsOneWidget);
    });

    testWidgets('DualisEmblem renders standalone and within container', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                DualisEmblem(key: Key('rawEmblem'), size: 32, withContainer: false),
                DualisEmblem(key: Key('badgeEmblem'), size: 48, withContainer: true),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('rawEmblem')), findsOneWidget);
      expect(find.byKey(const Key('badgeEmblem')), findsOneWidget);
      expect(find.byType(Image), findsNWidgets(2));
    });

    testWidgets('DualisLogo horizontal variant renders official horizontal asset', (tester) async {
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

      expect(find.byType(DualisLogo), findsOneWidget);
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final Image imageWidget = tester.widget(imageFinder);
      final AssetImage assetImage = imageWidget.image as AssetImage;
      expect(assetImage.assetName, AppAssets.logoHorizontal);
    });

    testWidgets('DualisLogo vertical variant renders official vertical asset', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DualisLogo(
              variant: DualisLogoVariant.vertical,
              width: 160,
              showTagline: true,
            ),
          ),
        ),
      );

      expect(find.byType(DualisLogo), findsOneWidget);
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final Image imageWidget = tester.widget(imageFinder);
      final AssetImage assetImage = imageWidget.image as AssetImage;
      expect(assetImage.assetName, AppAssets.logoVertical);
    });

    testWidgets('DualisLogo emblemOnly variant renders only symbol without text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DualisLogo(
              variant: DualisLogoVariant.emblemOnly,
              emblemSize: 44,
            ),
          ),
        ),
      );

      expect(find.byType(DualisEmblem), findsOneWidget);
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final Image imageWidget = tester.widget(imageFinder);
      final AssetImage assetImage = imageWidget.image as AssetImage;
      expect(assetImage.assetName, AppAssets.logoSymbol);
    });

    testWidgets('DualisLogo automatically falls back to no-tagline below minimum width 150px (Punto 4)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DualisLogo(
              variant: DualisLogoVariant.horizontal,
              width: 140, // Below 150px minimum
            ),
          ),
        ),
      );

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final Image imageWidget = tester.widget(imageFinder);
      final AssetImage assetImage = imageWidget.image as AssetImage;
      expect(assetImage.assetName, AppAssets.logoHorizontalNoTag);
    });
  });
}
