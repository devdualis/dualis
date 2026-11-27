import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/core/constants/app_colors.dart';
import 'package:dualis_mobile/core/utils/error_message_resolver.dart';
import 'package:dualis_mobile/features/auth/presentation/widgets/biological_sex_selector.dart';
import 'package:dualis_mobile/features/journal_insights/presentation/widgets/history_widgets.dart';
import 'package:dualis_mobile/features/onboarding/presentation/widgets/animated_page_indicator.dart';
import 'package:dualis_mobile/shared/widgets/dualis_text_field.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

Widget _app(Widget child, {String locale = 'en', double textScale = 1}) {
  return MaterialApp(
    locale: Locale(locale),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  testWidgets('page dots read in the app language', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(const AnimatedPageIndicator(count: 3, currentIndex: 0)),
    );
    expect(find.bySemanticsLabel('Page 1 of 3'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('e-mail field is not autocorrected', (tester) async {
    await tester.pumpWidget(
      _app(
        DualisTextField(
          labelText: 'E-mail',
          controller: TextEditingController(),
          keyboardType: TextInputType.emailAddress,
        ),
      ),
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.autocorrect, isFalse);
    expect(field.enableSuggestions, isFalse);
  });

  testWidgets('sex selector starts with nothing chosen', (tester) async {
    await tester.pumpWidget(
      _app(BiologicalSexSelector(onGenderChanged: (_) {})),
    );
    for (final icon in [
      Icons.male_rounded,
      Icons.female_rounded,
      Icons.person_outline_rounded,
    ]) {
      expect(
        tester.widget<Icon>(find.byIcon(icon)).color,
        isNot(AppColors.dualisNavy),
      );
    }
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('history tabs never cut a label (text x$scale)',
        (tester) async {
      tester.view.physicalSize = const Size(375, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      const labels = ['Emociones', 'Cuerpo', 'Agua', 'Hábitos', 'Juntos'];
      await tester.pumpWidget(
        _app(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: HistorySegmented<int>(
              keyPrefix: 'tab',
              options: [for (var i = 0; i < labels.length; i++) (i, labels[i])],
              selected: 0,
              onChanged: (_) {},
            ),
          ),
          locale: 'es',
          textScale: scale,
        ),
      );
      for (final label in labels) {
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(label),
        );
        expect(paragraph.didExceedMaxLines, isFalse, reason: label);
      }
    });
  }

  test('privacy session error resolves to the selected language', () {
    final es = lookupAppLocalizations(const Locale('es'));
    expect(
      ErrorMessageResolver.resolve(Exception('session expired'), es),
      es.errorSessionExpired,
    );
  });
}
