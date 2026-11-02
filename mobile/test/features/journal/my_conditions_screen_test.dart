import 'package:dualis_mobile/features/journal/domain/journal_keys.dart';
import 'package:dualis_mobile/core/theme/app_theme.dart';
import 'package:dualis_mobile/features/journal/domain/journal_models.dart';
import 'package:dualis_mobile/features/journal/presentation/screens/my_conditions_screen.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:dualis_mobile/l10n/app_localizations_pt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('pt'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MyConditionsScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  /// Same screen inside a router with stub promo and readings routes.
  Future<void> pumpRouted(WidgetTester tester, JournalHarness h) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: '/my-conditions',
      routes: [
        GoRoute(path: '/my-conditions', builder: (_, __) => const MyConditionsScreen()),
        GoRoute(
          path: '/premium-promo',
          builder: (_, __) => const Scaffold(body: Text('PROMO')),
        ),
        GoRoute(
          path: '/conditions/:id/readings',
          builder: (_, state) => Scaffold(
            body: Text('READINGS ${state.pathParameters['id']} ${state.extra}'),
          ),
        ),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: h.overrides,
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
        locale: const Locale('pt'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
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

  group('tracking (Premium)', () {
    testWidgets('Premium: switch on, pick glucose, add; sent with PATCH, never from the name',
        (tester) async {
      final h = JournalHarness()..premium = true;
      await pumpRouted(tester, h);
      expect(find.text(pt.chronicTrackToggle), findsOneWidget);
      expect(find.byKey(const Key('chronicTrack_premium_badge')), findsNothing);

      await tester.enterText(find.byKey(const Key('jv2_conditions_field')), 'Diabetes');
      await tapKey(tester, 'chronicTrack_toggle');
      // Switch on with no kind: adding waits for a kind.
      final add = find.byKey(const Key('jv2_conditions_add'));
      expect(tester.widget<ButtonStyleButton>(add).onPressed, isNull);
      expect(find.text(pt.chronicTrackKindBloodPressureLong), findsOneWidget);
      await tapKey(tester, 'chronicTrack_kind_glucose');
      await tapKey(tester, 'jv2_conditions_add');

      expect(h.remote.conditions.single.tracking, [JournalKeys.trackingGlucose]);
      expect(h.remote.patchRequests.single['tracking'], [JournalKeys.trackingGlucose]);
      expect(find.byKey(const Key('chronicTrack_kinds_c1')), findsOneWidget);
      expect(find.text(pt.chronicTrackKindGlucose), findsOneWidget);
      // The switch resets for the next condition.
      expect(find.byKey(const Key('chronicTrack_kind_glucose')), findsNothing);
    });

    testWidgets('Premium: a name alone never turns tracking on', (tester) async {
      final h = JournalHarness()..premium = true;
      await pumpRouted(tester, h);
      await tester.enterText(find.byKey(const Key('jv2_conditions_field')), 'Hipertensão');
      await tapKey(tester, 'jv2_conditions_add');
      expect(h.remote.conditions.single.tracking, isEmpty);
      expect(h.remote.patchRequests, isEmpty);
    });

    testWidgets('Premium: edit sheet switches tracking on for an existing condition',
        (tester) async {
      final h = JournalHarness(conditions: const [UserCondition(id: 'c1', label: 'Pressão')])
        ..premium = true;
      await pumpRouted(tester, h);
      expect(find.byKey(const Key('chronicTrack_view_readings_c1')), findsNothing);

      await tapKey(tester, 'chronicTrack_edit_c1');
      expect(find.text(pt.chronicTrackEdit), findsWidgets);
      final sheetToggle = find.byKey(const Key('chronicTrack_toggle')).last;
      await tester.tap(sheetToggle);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chronicTrack_kind_blood_pressure')).last);
      await tester.pumpAndSettle();
      await tapKey(tester, 'chronicTrack_edit_save');

      final patch = h.remote.patchRequests.single;
      expect(patch['id'], 'c1');
      expect(patch['tracking'], [JournalKeys.trackingBloodPressure]);
      expect(patch.containsKey('label'), isFalse);
      expect(find.byKey(const Key('chronicTrack_view_readings_c1')), findsOneWidget);
    });

    testWidgets('Premium: "Ver medições" opens the condition readings route', (tester) async {
      final h = JournalHarness(conditions: const [
        UserCondition(id: 'c1', label: 'Diabetes', tracking: [JournalKeys.trackingGlucose]),
      ])..premium = true;
      await pumpRouted(tester, h);
      expect(find.text(pt.chronicTrackConditionsSubtitle), findsOneWidget);
      expect(find.byKey(const Key('chronicTrack_kinds_c1')), findsOneWidget);
      await tapKey(tester, 'chronicTrack_view_readings_c1');
      expect(find.text('READINGS c1 Diabetes'), findsOneWidget);
    });

    testWidgets('Free: the switch shows PREMIUM and opens the promo; no readings link',
        (tester) async {
      final h = JournalHarness(conditions: const [
        UserCondition(id: 'c1', label: 'Diabetes', tracking: [JournalKeys.trackingGlucose]),
      ]);
      await pumpRouted(tester, h);
      expect(find.byKey(const Key('chronicTrack_premium_badge')), findsOneWidget);
      expect(find.text(pt.chronicTrackPremiumBadge), findsOneWidget);
      expect(find.byKey(const Key('chronicTrack_view_readings_c1')), findsNothing);
      // A condition tracked earlier on Premium shows no reading kinds here,
      // and the subtitle keeps the 1 to 5 wording.
      expect(find.byKey(const Key('chronicTrack_kinds_c1')), findsNothing);
      expect(find.text(pt.jv2ConditionsSubtitle), findsOneWidget);

      await tapKey(tester, 'chronicTrack_toggle');
      expect(find.text('PROMO'), findsOneWidget);
      expect(h.remote.patchRequests, isEmpty);
    });

    testWidgets('Free: adding still works and sends no tracking', (tester) async {
      final h = JournalHarness();
      await pumpRouted(tester, h);
      await tester.enterText(find.byKey(const Key('jv2_conditions_field')), 'Asma');
      await tapKey(tester, 'jv2_conditions_add');
      expect(h.remote.conditions.single.label, 'Asma');
      expect(h.remote.patchRequests, isEmpty);
    });
  });
}
