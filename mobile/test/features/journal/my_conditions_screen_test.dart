import 'package:dualis_mobile/features/journal/domain/journal_keys.dart';
import 'package:dualis_mobile/features/journal/domain/journal_models.dart';
import 'package:dualis_mobile/features/journal/presentation/screens/my_conditions_screen.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:dualis_mobile/l10n/app_localizations_pt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'journal_test_helpers.dart';

void main() {
  final pt = AppLocalizationsPt();

  Future<void> pump(WidgetTester tester, JournalHarness h) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
      overrides: h.overrides,
      child: const MaterialApp(
        locale: Locale('pt'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MyConditionsScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('adds a condition in the user\'s own words and lists it', (tester) async {
    final h = JournalHarness();
    await pump(tester, h);
    expect(find.text(pt.jv2ConditionsEmpty), findsOneWidget);

    await tester.enterText(find.byKey(const Key('jv2_conditions_field')), '  Enxaqueca  ');
    await tapKey(tester, 'jv2_conditions_add');

    expect(find.text('Enxaqueca'), findsOneWidget);
    expect(h.remote.conditions.single.label, 'Enxaqueca');
    // Cached for offline use in the daily entry.
    expect((await h.local.cachedConditions(null)).single.label, 'Enxaqueca');
  });

  testWidgets('field is limited to 40 characters', (tester) async {
    final h = JournalHarness();
    await pump(tester, h);
    final field = tester.widget<TextField>(find.byKey(const Key('jv2_conditions_field')));
    expect(field.maxLength, JournalKeys.conditionLabelMaxLength);
  });

  testWidgets('archives after confirmation', (tester) async {
    final h = JournalHarness(conditions: const [UserCondition(id: 'c1', label: 'Diabetes')]);
    await pump(tester, h);
    expect(find.text('Diabetes'), findsOneWidget);

    await tapKey(tester, 'jv2_condition_archive_c1');
    expect(find.text(pt.jv2ConditionsArchiveConfirm('Diabetes')), findsOneWidget);
    await tapKey(tester, 'jv2_conditions_archive_confirm');

    expect(h.remote.conditions, isEmpty);
    expect(find.text(pt.jv2ConditionsEmpty), findsOneWidget);
  });

  testWidgets('at 10 active conditions, adding is disabled', (tester) async {
    final h = JournalHarness(conditions: [
      for (var i = 0; i < JournalKeys.maxActiveConditions; i++)
        UserCondition(id: 'c$i', label: 'Item $i'),
    ]);
    await pump(tester, h);

    final button = find.byKey(const Key('jv2_conditions_add'));
    expect(tester.widget<ButtonStyleButton>(button).onPressed, isNull);
    expect(find.text(pt.jv2ConditionsLimit(10)), findsOneWidget);
  });

  testWidgets('offline: shows a message and keeps the cached list', (tester) async {
    final h = JournalHarness(online: false);
    await h.local.replaceConditions(null, const [UserCondition(id: 'c1', label: 'Asma')]);
    await pump(tester, h);
    expect(find.text('Asma'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('jv2_conditions_field')), 'Rinite');
    await tapKey(tester, 'jv2_conditions_add');

    expect(find.text(pt.jv2ConditionsOffline), findsOneWidget);
    expect(h.remote.conditions, isEmpty);
  });
}
