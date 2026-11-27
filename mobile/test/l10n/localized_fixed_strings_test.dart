import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/auth/domain/form_validators.dart';
import 'package:dualis_mobile/features/auth/domain/user_profile.dart';
import 'package:dualis_mobile/features/auth/presentation/widgets/biological_sex_selector.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

void main() {
  group('FormValidators messages follow the selected language', () {
    for (final code in ['en', 'es']) {
      test('returns the $code arb values', () {
        final l10n = lookupAppLocalizations(Locale(code));
        final year = DateTime.now().year;

        expect(FormValidators.validateName('Ana', l10n), l10n.formErrorName);
        expect(FormValidators.validateEmail('ana@', l10n), l10n.formErrorEmail);
        expect(
          FormValidators.validatePassword('abc', l10n),
          l10n.formErrorPassword,
        );
        expect(
          FormValidators.validateDateOfBirth('31/02/1985', l10n),
          l10n.addDependentDobInvalid,
        );
        expect(
          FormValidators.validateDateOfBirth('01/01/${year + 2}', l10n),
          l10n.addDependentDobFuture,
        );
        expect(
          FormValidators.validateDateOfBirth('01/01/${year - 5}', l10n),
          l10n.formErrorMinAge,
        );
        expect(
          FormValidators.validateDateOfBirth('01/01/${year - 130}', l10n),
          l10n.addDependentDobInvalid,
        );
      });
    }

    test('en and es messages differ from the Portuguese ones', () {
      final pt = lookupAppLocalizations(const Locale('pt'));
      for (final code in ['en', 'es']) {
        final other = lookupAppLocalizations(Locale(code));
        expect(other.formErrorMinAge, isNot(pt.formErrorMinAge));
        expect(other.formErrorEmail, isNot(pt.formErrorEmail));
      }
    });
  });

  testWidgets(
    'BiologicalSexSelector shows English labels and keeps Gender values',
    (tester) async {
      Gender? picked;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BiologicalSexSelector(
              selectedGender: Gender.masculino,
              onGenderChanged: (value) => picked = value,
            ),
          ),
        ),
      );

      expect(find.text('Biological Sex'), findsOneWidget);
      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics && w.properties.label == 'Biological sex: Female',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Female'));
      expect(picked, Gender.feminino);
    },
  );
}
