import 'package:dualis_mobile/core/constants/app_assets.dart';
import 'package:dualis_mobile/shared/widgets/dualis_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DualisLogo and DualisEmblem Tests', () {
    testWidgets('SvgPicture.asset loads centered-minimalist-medical-emblem', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SvgPicture.asset(
              AppAssets.emblem,
              width: 48,
              height: 48,
            ),
          ),
        ),
      );

      expect(find.byType(SvgPicture), findsOneWidget);
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
      expect(find.byType(SvgPicture), findsNWidgets(2));
    });

    testWidgets('DualisLogo horizontal variant renders emblem and brand typography', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DualisLogo(
              variant: DualisLogoVariant.horizontal,
              emblemSize: 36,
            ),
          ),
        ),
      );

      expect(find.byType(DualisLogo), findsOneWidget);
      expect(find.byType(DualisEmblem), findsOneWidget);
      expect(find.textContaining('Dualis'), findsOneWidget);
      expect(find.textContaining('CheckUp'), findsOneWidget);
    });

    testWidgets('DualisLogo vertical variant renders emblem, typography and tagline', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DualisLogo(
              variant: DualisLogoVariant.vertical,
              emblemSize: 52,
              showTagline: true,
              tagline: 'Triagem Preventiva Inteligente',
            ),
          ),
        ),
      );

      expect(find.byType(DualisLogo), findsOneWidget);
      expect(find.textContaining('Dualis'), findsOneWidget);
      expect(find.textContaining('CheckUp'), findsOneWidget);
      expect(find.text('Triagem Preventiva Inteligente'), findsOneWidget);
    });

    testWidgets('DualisLogo emblemOnly variant renders only emblem without text', (tester) async {
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
      expect(find.textContaining('Dualis'), findsNothing);
      expect(find.textContaining('CheckUp'), findsNothing);
    });
  });
}
