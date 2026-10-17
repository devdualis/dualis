import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/core/constants/app_colors.dart';
import 'package:dualis_mobile/features/home/presentation/widgets/dualis_bottom_nav_bar.dart';

void main() {
  group('DualisBottomNavBar Widget Tests', () {
    testWidgets('Renders all 5 navigation destinations correctly',
        (WidgetTester tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: DualisBottomNavBar(
              currentIndex: selectedIndex,
              hasCompletedToday: false,
              onTap: (index) => selectedIndex = index,
              onEmergencyTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('nav_destination_home')), findsOneWidget);
      expect(find.byKey(const Key('nav_destination_today_outcome')), findsOneWidget);
      expect(find.byKey(const Key('nav_destination_history')), findsOneWidget);
      expect(find.byKey(const Key('nav_destination_hydration')), findsOneWidget);
      expect(find.byKey(const Key('nav_destination_emergency')), findsOneWidget);

      // Verify text labels are hidden for clean icon-only bottom bar
      expect(find.text('Início'), findsNothing);
      expect(find.text('Meu Dia'), findsNothing);
      expect(find.text('Histórico & Mapa'), findsNothing);
      expect(find.text('Água'), findsNothing);
    });

    testWidgets('Tapping destination triggers onTap with proper index',
        (WidgetTester tester) async {
      int tappedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: DualisBottomNavBar(
              currentIndex: 0,
              hasCompletedToday: true,
              onTap: (index) => tappedIndex = index,
              onEmergencyTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Resultado do Dia'
      await tester.tap(find.byKey(const Key('nav_destination_today_outcome')));
      await tester.pumpAndSettle();
      expect(tappedIndex, equals(1));

      // Tap 'Histórico & Mapa'
      await tester.tap(find.byKey(const Key('nav_destination_history')));
      await tester.pumpAndSettle();
      expect(tappedIndex, equals(2));

      // Tap 'Água'
      await tester.tap(find.byKey(const Key('nav_destination_hydration')));
      await tester.pumpAndSettle();
      expect(tappedIndex, equals(3));

      // Tap 'Início'
      await tester.tap(find.byKey(const Key('nav_destination_home')));
      await tester.pumpAndSettle();
      expect(tappedIndex, equals(0));
    });

    testWidgets('Shows badge indicator when hasCompletedToday is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: DualisBottomNavBar(
              currentIndex: 0,
              hasCompletedToday: true,
              onTap: (_) {},
              onEmergencyTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final badgeFinder = find.descendant(
        of: find.byKey(const Key('nav_destination_today_outcome')),
        matching: find.byType(Badge),
      );
      expect(badgeFinder, findsOneWidget);
    });

    testWidgets('Emergency destination is crimson and does not change tab index',
        (WidgetTester tester) async {
      int tappedIndex = -1;
      var emergencyTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: DualisBottomNavBar(
              currentIndex: 0,
              onTap: (index) => tappedIndex = index,
              onEmergencyTap: () => emergencyTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final destination = find.byKey(const Key('nav_destination_emergency'));
      final icon = tester.widget<Icon>(find.descendant(
        of: destination,
        matching: find.byIcon(Icons.emergency_outlined),
      ));
      expect(icon.color, Colors.white);
      final circle = tester.widget<Container>(find.descendant(
        of: destination,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color ==
                  AppColors.emergencyCrimson,
        ),
      ));
      expect((circle.decoration as BoxDecoration).shape, BoxShape.circle);

      await tester.tap(find.byKey(const Key('nav_destination_emergency')));
      await tester.pumpAndSettle();
      expect(emergencyTapped, isTrue);
      expect(tappedIndex, equals(-1));
    });
  });
}
