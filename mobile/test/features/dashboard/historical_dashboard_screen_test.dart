import 'package:drift/native.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/core/database/app_database.dart';
import 'package:dualis_mobile/core/network/api_client.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/dashboard/presentation/screens/historical_dashboard_screen.dart';
import 'package:dualis_mobile/features/home/domain/home_greeting.dart';
import 'package:dualis_mobile/features/hydration/domain/models/hydration_settings.dart';
import 'package:dualis_mobile/features/hydration/presentation/controllers/hydration_controller.dart';
import 'package:dualis_mobile/features/journal/data/journal_local_store.dart';
import 'package:dualis_mobile/features/journal/domain/journal_models.dart';
import 'package:dualis_mobile/features/journal_insights/data/journal_insights_remote_data_source.dart';
import 'package:dualis_mobile/features/journal_insights/domain/journal_insights_models.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

final DateTime today = DateTime(2026, 10, 27, 15);

class FakeJournalDataSource extends JournalInsightsRemoteDataSource {
  final List<JournalEntryView> entries;
  final JournalSummary? summary;
  int? requestedEntryDays;
  int? requestedSummaryDays;
  final List<String> deleted = [];

  FakeJournalDataSource(this.entries, {this.summary})
      : super(apiClient: ApiClient(), secureStorage: SecureStorageService());

  @override
  Future<List<JournalEntryView>> fetchEntries({int days = 30}) async {
    requestedEntryDays = days;
    return entries;
  }

  @override
  Future<JournalSummary?> fetchSummary({int days = 30}) async {
    requestedSummaryDays = days;
    return summary;
  }

  @override
  Future<bool> deleteEntry(String id) async {
    deleted.add(id);
    return true;
  }
}

class FixedHydration extends HydrationController {
  final HydrationState initial;
  FixedHydration(this.initial);

  @override
  HydrationState build() => initial;

  @override
  Future<void> loadData() async {}
}

JournalEntryView entry(
  String id,
  int daysAgo,
  List<JournalItemView> items, {
  List<String> triggers = const [],
  bool legacy = false,
}) {
  return JournalEntryView(
    id: id,
    recordedAt: today.subtract(Duration(days: daysAgo)),
    mood: 'nao_tao_bem',
    triggers: triggers,
    legacy: legacy,
    items: items,
  );
}

const head = JournalItemView(
  kind: 'physical',
  optionKey: 'cabeca.pressao.temporas',
  bodySide: 'front',
  persistence: 'hoje',
  intensity: 3,
);
const mind = JournalItemView(
  kind: 'emotional',
  optionKey: 'futuro.mente.antecipar',
  persistence: 'dias_semanas',
  intensity: 4,
);

Future<FakeJournalDataSource> pumpDashboard(
  WidgetTester tester,
  List<JournalEntryView> entries, {
  JournalSummary? summary,
  Map<DateTime, int> water = const {},
  AppDatabase? database,
}) async {
  tester.view.physicalSize = const Size(900, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final db = database ?? AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);

  final dataSource = FakeJournalDataSource(entries, summary: summary);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        homeClockProvider.overrideWithValue(() => today),
        journalInsightsDataSourceProvider.overrideWithValue(dataSource),
        waterLogsForDayProvider.overrideWith((ref, day) async => const []),
        hydrationControllerProvider.overrideWith(
          () => FixedHydration(
            HydrationState(
              settings: const HydrationSettings(dailyTargetMl: 2000),
              last30DaysTotals: water,
            ),
          ),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HistoricalDashboardScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return dataSource;
}

int visibleLineCount(WidgetTester tester) {
  final chart = tester.widget<LineChart>(find.byType(LineChart).first);
  return chart.data.lineBarsData.length;
}

void main() {
  group('HistoricalDashboardScreen (Emoções | Corpo | Água | Juntos)', () {
    testWidgets('loads 30 days once and starts on 30 dias, Emoções',
        (tester) async {
      final ds = await pumpDashboard(tester, [entry('e1', 0, [head])]);
      expect(ds.requestedEntryDays, 30);
      expect(ds.requestedSummaryDays, isNull);
      expect(find.text('Seus registros dos últimos 30 dias'), findsOneWidget);
      for (final tab in ['Emoções', 'Corpo', 'Água', 'Juntos']) {
        expect(find.text(tab), findsWidgets);
      }
      expect(find.byKey(const Key('history_period_7')), findsOneWidget);
      expect(find.byKey(const Key('history_period_30')), findsOneWidget);
      // Free shows up to 30 days (handoff v2.0).
      expect(find.byKey(const Key('history_period_90')), findsNothing);
    });

    testWidgets('Emoções: pie counts records per time, lines one per time',
        (tester) async {
      await pumpDashboard(tester, [
        entry('e1', 0, [
          mind,
          const JournalItemView(
              kind: 'emotional', optionKey: 'passado.memoria.magoa', intensity: 1),
        ]),
        entry('e2', 1, [
          const JournalItemView(
              kind: 'emotional', optionKey: 'futuro.mente.cobranca', intensity: 5),
        ]),
        JournalEntryView(id: 'bem', recordedAt: today, mood: 'bem'),
      ]);

      expect(find.byKey(const Key('temporal_pie')), findsOneWidget);
      expect(find.byKey(const Key('temporal_pie_row_futuro')), findsOneWidget);
      expect(find.byKey(const Key('temporal_pie_row_presente')), findsNothing);
      expect(find.textContaining('2 registros · 67%'), findsOneWidget);
      expect(find.byKey(const Key('temporal_pie_without_axis')), findsOneWidget);

      // E2: one series per time; hiding Futuro removes its line.
      expect(find.byKey(const Key('emotional_chip_futuro')), findsOneWidget);
      final before = visibleLineCount(tester);
      await tester.tap(find.byKey(const Key('emotional_chip_futuro')));
      await tester.pumpAndSettle();
      expect(visibleLineCount(tester), lessThan(before));

      // E3: filter by time, legend names each fork.
      expect(find.byKey(const Key('emotional_answers')), findsOneWidget);
      expect(find.byKey(const Key('emotional_filter_passado')), findsOneWidget);
    });

    testWidgets('period chips filter entries on the device', (tester) async {
      await pumpDashboard(tester, [
        entry('recent', 1, [mind]),
        entry('older', 20, [
          const JournalItemView(
              kind: 'emotional', optionKey: 'passado.memoria.magoa', intensity: 2),
        ]),
      ]);
      expect(find.byKey(const Key('emotional_chip_passado')), findsOneWidget);

      await tester.tap(find.byKey(const Key('history_period_7')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('emotional_chip_passado')), findsNothing);
      expect(find.byKey(const Key('journal_entry_older')), findsNothing);
    });

    testWidgets('Corpo: markers count days, sheet lists marks and opens F3',
        (tester) async {
      await pumpDashboard(tester, [
        entry('e1', 0, [head, head]),
        entry('e2', 2, [
          head,
          const JournalItemView(
              kind: 'physical', optionKey: 'pele.coceira.ardencia', intensity: 2),
        ]),
        entry('e3', 3, [
          const JournalItemView(
              kind: 'physical',
              optionKey: 'costas.fisgada.ao_mexer',
              bodySide: 'back',
              intensity: 2),
        ]),
      ]);
      await tester.tap(find.byKey(const Key('history_tab_HistoryTab.body')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('body_marker_map')), findsOneWidget);
      expect(find.byKey(const Key('body_marker_cabeca')), findsOneWidget);
      expect(find.byKey(const Key('body_marker_costas')), findsOneWidget);
      // Whole-body areas are listed, never placed on the map.
      expect(find.byKey(const Key('body_marker_pele')), findsNothing);
      expect(find.byKey(const Key('body_region_row_pele')), findsOneWidget);
      expect(find.text('Cabeça e pescoço · 2 dias com marcação'), findsOneWidget);

      await tester.tap(find.byKey(const Key('body_marker_cabeca')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('region_marks_cabeca')), findsOneWidget);
      expect(find.text('2 dias com marcação · 3 marcações'), findsOneWidget);

      await tester.tap(find.byKey(const Key('region_marks_see_evolution')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('region_marks_cabeca')), findsNothing);
      final chip = tester.widget<ChoiceChip>(
          find.byKey(const Key('physical_filter_cabeca')));
      expect(chip.selected, isTrue);
    });

    testWidgets('Água: H1–H4 share one base and a tapped day drives H1',
        (tester) async {
      await pumpDashboard(tester, [], water: {
        DateTime(2026, 10, 20): 1600,
        DateTime(2026, 10, 21): 2400,
      });
      await tester.tap(find.byKey(const Key('history_tab_HistoryTab.water')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('water_period_bars')), findsOneWidget);
      expect(find.byKey(const Key('water_calendar')), findsOneWidget);
      expect(find.text('Nenhum registro de água'), findsWidgets);

      await tester.tap(find.byKey(const Key('water_day_20261021')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('water_day_ring_percent')), findsOneWidget);
      expect(find.text('120%'), findsWidgets);
      expect(find.text('2,4 L'), findsOneWidget);
      // Entries list is not part of the water tab.
      expect(find.text('Seus registros'), findsNothing);
    });

    testWidgets('Juntos: calendar keeps head and body apart and opens the day',
        (tester) async {
      await pumpDashboard(tester, [
        entry('e1', 0, [mind, head]),
      ], water: {
        DateTime(2026, 10, 27): 1600,
      });
      await tester.tap(find.byKey(const Key('history_tab_HistoryTab.together')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('combined_calendar')), findsOneWidget);
      await tester.tap(find.byKey(const Key('combined_day_20261027')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('calendar_day_20261027')), findsOneWidget);
      expect(find.textContaining('Intensidade 4/5'), findsOneWidget);
      expect(find.textContaining('Intensidade 3/5'), findsOneWidget);
      expect(find.textContaining('1.600 ml'), findsOneWidget);
    });

    testWidgets('entries list shows the reported intensity', (tester) async {
      await pumpDashboard(tester, [entry('e1', 0, [head, mind])]);
      expect(
        find.text('Fico antecipando problemas · Intensidade que você informou: 4/5'),
        findsOneWidget,
      );
    });

    testWidgets('legacy entries render with their saved text and are not deletable',
        (tester) async {
      await pumpDashboard(tester, [
        entry('legacy-1', 3, const [
          JournalItemView(kind: 'physical', legacyLabel: 'Dor nas costas', intensity: 2),
        ], legacy: true),
      ]);
      expect(
        find.text('Dor nas costas · Intensidade que você informou: 2/5'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('journal_entry_delete_legacy-1')), findsNothing);
    });

    testWidgets('custom items keep the words the person wrote', (tester) async {
      await pumpDashboard(tester, [
        entry('e1', 0, const [
          JournalItemView(
            kind: 'emotional',
            optionKey: 'presente.custom',
            customLabel: 'Saudade da praia',
            intensity: 2,
          ),
        ]),
      ]);
      expect(
        find.text('Saudade da praia · Intensidade que você informou: 2/5'),
        findsOneWidget,
      );
    });

    testWidgets('deleting an entry asks first and calls the API', (tester) async {
      final ds = await pumpDashboard(tester, [entry('e1', 0, [head])]);
      await tester.tap(find.byKey(const Key('journal_entry_delete_e1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dashboard_delete_confirm')));
      await tester.pumpAndSettle();
      expect(ds.deleted, ['e1']);
      expect(find.byKey(const Key('journal_entry_e1')), findsNothing);
    });

    testWidgets('shows pending offline entries marked as aguardando sincronizar',
        (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final store = JournalLocalStore(db);
      await store.enqueue(
        JournalEntry(
          clientId: 'offline-entry-1',
          recordedAt: today,
          mood: 'bem',
        ),
      );

      await pumpDashboard(
        tester,
        const [],
        database: db,
      );

      expect(find.text('Aguardando sincronizar'), findsOneWidget);
      expect(
        find.byKey(const Key('journal_entry_pending_offline-entry-1')),
        findsOneWidget,
      );
      // Pending entries cannot be deleted via remote API button
      expect(
        find.byKey(const Key('journal_entry_delete_offline-entry-1')),
        findsNothing,
      );
    });
  });
}
