import 'package:dualis_mobile/core/constants/app_colors.dart';
import 'package:dualis_mobile/features/home/presentation/widgets/dualis_bottom_nav_bar.dart';
import 'package:dualis_mobile/shared/widgets/premium_gradient_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _dotKey = Key('premium_active_dot');

Widget _iconHarness(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

Widget _barHarness({required int currentIndex, bool? premiumIcons}) {
  return MaterialApp(
    home: Scaffold(
      bottomNavigationBar: premiumIcons == null
          ? DualisBottomNavBar(
              currentIndex: currentIndex,
              onTap: (_) {},
              onEmergencyTap: () {},
              showCare: true,
              habitsTab: true,
            )
          : DualisBottomNavBar(
              currentIndex: currentIndex,
              onTap: (_) {},
              onEmergencyTap: () {},
              showCare: true,
              habitsTab: true,
              premiumIcons: premiumIcons,
            ),
    ),
  );
}

Finder _under(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

void main() {
  group('PremiumAccents', () {
    test('gradient is the approved 3-stop teal and the dot is champagne', () {
      expect(PremiumAccents.iconGradient.colors, const [
        Color(0xFF3BA7E0),
        AppColors.clinicalTeal,
        Color(0xFF064A73),
      ]);
      expect(PremiumAccents.iconGradient.stops, const [0.0, 0.5, 1.0]);
      expect(PremiumAccents.iconGradient.begin, const Alignment(-0.4, -1.0));
      expect(PremiumAccents.iconGradient.end, const Alignment(0.4, 1.0));
      expect(PremiumAccents.champagne, const Color(0xFFC9A35B));
    });

    test('gradientFor keeps the icon accent in the middle stop', () {
      const green = AppColors.dualisSymbolGreen;
      final gradient = PremiumAccents.gradientFor(green);
      expect(gradient.colors, hasLength(3));
      expect(gradient.colors[1], green);
      expect(gradient.colors.first, Color.lerp(green, Colors.white, 0.3));
      expect(gradient.colors.last, Color.lerp(green, Colors.black, 0.3));
      expect(gradient.stops, PremiumAccents.iconGradient.stops);
    });
  });

  group('PremiumGradientIcon', () {
    testWidgets('masks the given Icon with srcIn and keeps its size', (tester) async {
      await tester.pumpWidget(_iconHarness(const PremiumGradientIcon(
        icon: Icon(Icons.home_rounded, size: 24, color: AppColors.clinicalTealDark),
      )));

      final masks = find.byType(ShaderMask);
      expect(masks, findsOneWidget);
      expect(tester.widget<ShaderMask>(masks).blendMode, BlendMode.srcIn);

      final icon = tester.widget<Icon>(
        find.descendant(of: masks, matching: find.byType(Icon)),
      );
      expect(icon.icon, Icons.home_rounded);
      expect(icon.size, 24);
      expect(tester.getSize(find.byType(PremiumGradientIcon)), const Size(24, 24));
      expect(find.byKey(_dotKey), findsNothing);
    });

    testWidgets('same rendered size as a bare Icon', (tester) async {
      await tester.pumpWidget(_iconHarness(
        const Icon(Icons.home_rounded, size: 24, color: AppColors.clinicalTealDark),
      ));
      final bare = tester.getSize(find.byIcon(Icons.home_rounded));

      await tester.pumpWidget(_iconHarness(const PremiumGradientIcon(
        icon: Icon(Icons.home_rounded, size: 24, color: AppColors.clinicalTealDark),
      )));
      expect(tester.getSize(find.byType(PremiumGradientIcon)), bare);
    });

    testWidgets('active dot: 10 px champagne circle with a 2 px white ring, size unchanged',
        (tester) async {
      await tester.pumpWidget(_iconHarness(const PremiumGradientIcon(
        icon: Icon(Icons.home_rounded, size: 24),
        showActiveDot: true,
      )));

      final dot = find.byKey(_dotKey);
      expect(dot, findsOneWidget);
      expect(tester.getSize(dot), const Size(10, 10));
      final decoration = tester.widget<Container>(dot).decoration! as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color, const Color(0xFFC9A35B));
      final border = decoration.border! as Border;
      expect(border.top.color, Colors.white);
      expect(border.top.width, 2);
      // The dot sits outside the mask so it keeps its own color.
      expect(find.descendant(of: find.byType(ShaderMask), matching: dot), findsNothing);
      expect(tester.getSize(find.byType(PremiumGradientIcon)), const Size(24, 24));
    });
  });

  group('DualisBottomNavBar premium icons', () {
    testWidgets('Premium: only the selected destination gets the mask and the dot',
        (tester) async {
      await tester.pumpWidget(_barHarness(currentIndex: 0, premiumIcons: true));
      await tester.pumpAndSettle();

      expect(find.byType(ShaderMask), findsOneWidget);
      expect(_under(const Key('nav_destination_home'), find.byType(ShaderMask)), findsOneWidget);
      expect(find.byKey(_dotKey), findsOneWidget);
      expect(_under(const Key('nav_destination_home'), find.byKey(_dotKey)), findsOneWidget);

      // The selected glyph is still the Free one.
      expect(
        _under(const Key('nav_destination_home'), find.byIcon(Icons.home_rounded)),
        findsOneWidget,
      );

      // Help destination untouched.
      expect(_under(const Key('nav_destination_emergency'), find.byType(ShaderMask)), findsNothing);
      expect(_under(const Key('nav_destination_emergency'), find.byKey(_dotKey)), findsNothing);

      // Unselected icons stay gray with no mask.
      final insights = find.byIcon(Icons.insights_outlined);
      expect(tester.widget<Icon>(insights).color, AppColors.textSecondaryLight);
      expect(find.ancestor(of: insights, matching: find.byType(ShaderMask)), findsNothing);
    });

    testWidgets('Premium: selecting history moves the mask and the dot', (tester) async {
      await tester.pumpWidget(_barHarness(currentIndex: 0, premiumIcons: true));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_barHarness(currentIndex: 1, premiumIcons: true));
      await tester.pumpAndSettle();

      expect(find.byType(ShaderMask), findsOneWidget);
      expect(_under(const Key('nav_destination_history'), find.byType(ShaderMask)), findsOneWidget);
      expect(find.byKey(_dotKey), findsOneWidget);
      expect(_under(const Key('nav_destination_history'), find.byKey(_dotKey)), findsOneWidget);
      expect(_under(const Key('nav_destination_home'), find.byType(ShaderMask)), findsNothing);
    });

    testWidgets('Free (flag omitted): no mask and no dot', (tester) async {
      await tester.pumpWidget(_barHarness(currentIndex: 0));
      await tester.pumpAndSettle();

      expect(find.byType(ShaderMask), findsNothing);
      expect(find.byKey(_dotKey), findsNothing);
    });

    testWidgets('selected icon keeps the same rect in Free and Premium', (tester) async {
      await tester.pumpWidget(_barHarness(currentIndex: 0));
      await tester.pumpAndSettle();
      final freeRect = tester.getRect(find.byIcon(Icons.home_rounded));

      await tester.pumpWidget(_barHarness(currentIndex: 0, premiumIcons: true));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byIcon(Icons.home_rounded)), freeRect);
    });

    testWidgets('Premium: help destination is still the crimson circle with a white glyph',
        (tester) async {
      await tester.pumpWidget(_barHarness(currentIndex: 0, premiumIcons: true));
      await tester.pumpAndSettle();

      final destination = find.byKey(const Key('nav_destination_emergency'));
      final icon = tester.widget<Icon>(
        find.descendant(of: destination, matching: find.byIcon(Icons.emergency_outlined)),
      );
      expect(icon.color, Colors.white);
      expect(icon.size, 18);
      final circle = tester.widget<Container>(find.descendant(
        of: destination,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color == AppColors.emergencyCrimson,
        ),
      ));
      expect((circle.decoration as BoxDecoration).shape, BoxShape.circle);
    });
  });
}
