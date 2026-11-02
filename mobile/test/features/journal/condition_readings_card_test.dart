import 'package:dualis_mobile/core/theme/app_theme.dart';
import 'package:dualis_mobile/features/journal/domain/journal_keys.dart';
import 'package:dualis_mobile/features/journal/domain/journal_models.dart';
import 'package:dualis_mobile/features/journal/presentation/widgets/condition_readings_card.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:dualis_mobile/l10n/app_localizations_pt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final pt = AppLocalizationsPt();
  final clock = DateTime(2026, 11, 1, 8, 30);

  /// Pumps the card and returns the list of readings it last reported.
  Future<List<List<ConditionReading>>> pump(
    WidgetTester tester,
    List<String> tracking, {
    List<ConditionReading> initial = const [],
  }) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final reports = <List<ConditionReading>>[];
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      locale: const Locale('pt'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ConditionReadingsCard(
            keyPrefix: 'ct',
            tracking: tracking,
            initialReadings: initial,
            now: () => clock,
            onChanged: reports.add,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return reports;
  }

  Future<void> type(WidgetTester tester, String key, String text) async {
    await tester.enterText(find.byKey(Key(key)), text);
    await tester.pumpAndSettle();
  }

  testWidgets('blood pressure 120/80 is reported raw, with the row time', (tester) async {
    final reports = await pump(tester, [JournalKeys.trackingBloodPressure]);
    expect(find.text(pt.chronicTrackSystolic), findsOneWidget);
    expect(find.text(pt.chronicTrackDiastolic), findsOneWidget);
    expect(find.text(pt.chronicTrackPulse), findsOneWidget);
    expect(find.text('08:30'), findsOneWidget);

    await type(tester, 'ct_0_systolic', '120');
    expect(reports.last, isEmpty); // diastolic missing
    await type(tester, 'ct_0_diastolic', '80');

    final r = reports.last.single;
    expect(r.kind, JournalKeys.trackingBloodPressure);
    expect(r.systolic, 120);
    expect(r.diastolic, 80);
    expect(r.pulse, isNull);
    expect(r.measuredAt, clock);
    expect(find.text(pt.chronicTrackCheckValue), findsNothing);
  });

  testWidgets('a typo (400) shows "Confira o valor digitado" and is not reported',
      (tester) async {
    final reports = await pump(tester, [JournalKeys.trackingBloodPressure]);
    await type(tester, 'ct_0_systolic', '400');
    await type(tester, 'ct_0_diastolic', '80');

    expect(find.text(pt.chronicTrackCheckValue), findsOneWidget);
    expect(reports.last, isEmpty);

    // Fixed: the hint goes away and the reading is reported.
    await type(tester, 'ct_0_systolic', '140');
    expect(find.text(pt.chronicTrackCheckValue), findsNothing);
    expect(reports.last.single.systolic, 140);
  });

  testWidgets('a value below the limit shows the hint only after leaving the field',
      (tester) async {
    await pump(tester, [JournalKeys.trackingBloodPressure]);
    await type(tester, 'ct_0_systolic', '1');
    expect(find.text(pt.chronicTrackCheckValue), findsNothing);

    await tester.tap(find.byKey(const Key('ct_0_diastolic')));
    await tester.pumpAndSettle();
    expect(find.text(pt.chronicTrackCheckValue), findsOneWidget);
  });

  testWidgets('"+ Adicionar outra medição" adds a row; both readings are reported',
      (tester) async {
    final reports = await pump(tester, [JournalKeys.trackingBloodPressure]);
    await type(tester, 'ct_0_systolic', '130');
    await type(tester, 'ct_0_diastolic', '85');
    expect(find.text(pt.chronicTrackAddAnother), findsOneWidget);

    await tester.tap(find.byKey(const Key('ct_add')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ct_1_systolic')), findsOneWidget);
    await type(tester, 'ct_1_systolic', '118');
    await type(tester, 'ct_1_diastolic', '76');
    await type(tester, 'ct_1_pulse', '70');

    expect(reports.last, hasLength(2));
    expect(reports.last.map((r) => r.systolic), [130, 118]);
    expect(reports.last.last.pulse, 70);

    await tester.tap(find.byKey(const Key('ct_0_remove')));
    await tester.pumpAndSettle();
    expect(reports.last.map((r) => r.systolic), [118]);
  });

  testWidgets('weight accepts a comma; glucose needs a moment', (tester) async {
    final reports = await pump(tester, [
      JournalKeys.trackingGlucose,
      JournalKeys.trackingWeight,
    ]);
    await type(tester, 'ct_1_kg', '72,5');
    expect(reports.last.single.kg, 72.5);

    await type(tester, 'ct_0_mgdl', '98');
    expect(reports.last, hasLength(1)); // no moment yet
    expect(find.text(pt.chronicTrackMomentJejum), findsOneWidget);
    expect(find.text(pt.chronicTrackMomentDormir), findsOneWidget);
    await tester.tap(find.byKey(const Key('ct_0_moment_jejum')));
    await tester.pumpAndSettle();

    final glucose = reports.last.firstWhere((r) => r.kind == JournalKeys.trackingGlucose);
    expect(glucose.mgdl, 98);
    expect(glucose.moment, JournalKeys.momentJejum);
  });

  testWidgets('several kinds: adding asks which one', (tester) async {
    await pump(tester, [JournalKeys.trackingGlucose, JournalKeys.trackingWeight]);
    await tester.tap(find.byKey(const Key('ct_add')));
    await tester.pumpAndSettle();
    expect(find.text(pt.chronicTrackPickKind), findsOneWidget);
    await tester.tap(find.byKey(const Key('ct_pick_weight')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ct_2_kg')), findsOneWidget);
  });

  testWidgets('rows are rebuilt from readings already in the draft', (tester) async {
    await pump(
      tester,
      [JournalKeys.trackingWeight],
      initial: [ConditionReading.weight(measuredAt: DateTime(2026, 11, 1, 7, 5), kg: 70.25)],
    );
    expect(find.text('70,25'), findsOneWidget);
    expect(find.text('07:05'), findsOneWidget);
  });

  testWidgets('no value judgement: no range, label or trend words on the card',
      (tester) async {
    await pump(tester, JournalKeys.trackingKinds);
    await type(tester, 'ct_0_systolic', '190');
    await type(tester, 'ct_0_diastolic', '120');
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => (t.data ?? '').toLowerCase())
        .join(' | ');
    for (final word in ['normal', 'alto', 'alta', 'baixo', 'elevad', 'ideal', 'tendência', 'média']) {
      expect(texts.contains(word), isFalse, reason: word);
    }
  });
}
