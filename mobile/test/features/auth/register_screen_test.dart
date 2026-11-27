import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

Widget createRegisterTestApp() {
  final router = GoRouter(
    initialLocation: RoutePaths.register,
    routes: [
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Home Screen')),
        ),
      ),
    ],
  );

  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  group('Screen 2: Simplified Registration (AUTH-01 / RF-007) Widget Tests', () {
    testWidgets('Submission button is strictly disabled when fields are empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(createRegisterTestApp());
      await tester.pumpAndSettle();

      final buttonFinder = find.byKey(const Key('submitRegisterButton'));
      expect(buttonFinder, findsOneWidget);

      final filledButton = tester.widget<FilledButton>(
        find.descendant(of: buttonFinder, matching: find.byType(FilledButton)),
      );
      expect(filledButton.onPressed, isNull);
    });

    testWidgets(
        'Submission button remains disabled when all fields are valid but LGPD checkbox is unchecked',
        (WidgetTester tester) async {
      await tester.pumpWidget(createRegisterTestApp());
      await tester.pumpAndSettle();

      // Enter valid name
      await tester.enterText(
        find.byKey(const Key('fullNameField')),
        'Carlos Alberto Silva',
      );
      // Enter valid DOB
      await tester.enterText(
        find.byKey(const Key('birthDateField')),
        '15/05/1990',
      );
      // Enter valid email
      await tester.enterText(
        find.byKey(const Key('emailField')),
        'carlos.silva@example.com',
      );
      // Enter valid password
      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'P@ssword123!',
      );

      await tester.pumpAndSettle();

      // LGPD Checkbox is still unchecked
      final buttonFinder = find.byKey(const Key('submitRegisterButton'));
      final filledButton = tester.widget<FilledButton>(
        find.descendant(of: buttonFinder, matching: find.byType(FilledButton)),
      );
      expect(filledButton.onPressed, isNull);
    });

    testWidgets(
        'Checking LGPD checkbox enables the submission button when form is valid, unchecking disables it',
        (WidgetTester tester) async {
      await tester.pumpWidget(createRegisterTestApp());
      await tester.pumpAndSettle();

      // Enter all valid fields
      await tester.enterText(
        find.byKey(const Key('fullNameField')),
        'Carlos Alberto Silva',
      );
      await tester.enterText(
        find.byKey(const Key('birthDateField')),
        '15/05/1990',
      );
      await tester.enterText(
        find.byKey(const Key('emailField')),
        'carlos.silva@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'P@ssword123!',
      );

      await tester.pumpAndSettle();

      // Sex starts empty: the button waits for a choice too.
      final checkbox = find.byKey(const Key('lgpdConsentCheckbox'));
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.descendant(
              of: find.byKey(const Key('submitRegisterButton')),
              matching: find.byType(FilledButton),
            ))
            .onPressed,
        isNull,
      );
      await tester.tap(checkbox);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byIcon(Icons.female_rounded));
      await tester.tap(find.byIcon(Icons.female_rounded));
      await tester.pumpAndSettle();

      // Toggle LGPD Checkbox ON
      final checkboxFinder = find.byKey(const Key('lgpdConsentCheckbox'));
      await tester.ensureVisible(checkboxFinder);
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Button should now be enabled
      final buttonFinder = find.byKey(const Key('submitRegisterButton'));
      final enabledButton = tester.widget<FilledButton>(
        find.descendant(of: buttonFinder, matching: find.byType(FilledButton)),
      );
      expect(enabledButton.onPressed, isNotNull);

      // Toggle LGPD Checkbox OFF
      await tester.ensureVisible(checkboxFinder);
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Button should be disabled again
      final disabledButton = tester.widget<FilledButton>(
        find.descendant(of: buttonFinder, matching: find.byType(FilledButton)),
      );
      expect(disabledButton.onPressed, isNull);
    });

    testWidgets('Entering invalid email shows localized error message',
        (WidgetTester tester) async {
      await tester.pumpWidget(createRegisterTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('emailField')),
        'carlos@',
      );
      await tester.pumpAndSettle();

      expect(find.text('Informe um endereço de e-mail válido.'), findsOneWidget);
    });

    testWidgets('Entering weak password displays complexity error message',
        (WidgetTester tester) async {
      await tester.pumpWidget(createRegisterTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'weak',
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'A senha deve ter pelo menos 8 caracteres, incluindo letra maiúscula, minúscula, número e símbolo especial.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('typing in the name field does not turn other fields red',
        (WidgetTester tester) async {
      await tester.pumpWidget(createRegisterTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('fullNameField')), 'C');
      await tester.pumpAndSettle();

      expect(_fieldHasError(tester, 'fullNameField'), isTrue);
      expect(_fieldHasError(tester, 'birthDateField'), isFalse);
      expect(_fieldHasError(tester, 'emailField'), isFalse);
      expect(_fieldHasError(tester, 'passwordField'), isFalse);
    });

    testWidgets('date of birth set from the calendar picker is still validated',
        (WidgetTester tester) async {
      await tester.pumpWidget(createRegisterTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_calendar_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      // A date picked from the calendar is a valid DOB: no error shown.
      expect(_fieldHasError(tester, 'birthDateField'), isFalse);

      // Clearing the picked value must surface the field error again.
      await tester.enterText(find.byKey(const Key('birthDateField')), '');
      await tester.pumpAndSettle();
      expect(_fieldHasError(tester, 'birthDateField'), isTrue);
    });
  });
}

bool _fieldHasError(WidgetTester tester, String key) {
  final state = tester.state<FormFieldState<String>>(
    find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byType(TextFormField),
    ),
  );
  return state.hasError;
}
