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
import 'package:dualis_mobile/features/journal_insights/presentation/controllers/journal_insights_controller.dart';
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

Future<void> openPhysicalTab(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('history_tab_HistoryTab.physical')));
  await tester.pumpAndSettle();
}

void main() {
  group('HistoricalDashboardScreen (Psicoemocional | Físico)', () {
    testWidgets('loads 90 days once and starts on 30 dias, Psicoemocional',
        (tester) async {
      final ds = await pumpDashboard(tester, [entry('e1', 0, [head])]);
      expect(ds.requestedEntryDays, 90);
      expect(ds.requestedSummaryDays, isNull);
      expect(JournalInsightsState.fetchDays, 90);
      expect(find.text('Seus registros dos últimos 30 dias'), findsOneWidget);
      expect(find.text('Psicoemocional'), findsOneWidget);
      expect(find.text('Físico'), findsOneWidget);
      for (final days in [7, 30, 90]) {
        expect(find.byKey(Key('history_period_$days')), findsOneWidget);
      }
    });

    testWidgets('emotional tab: one line per branch, chips toggle each line',
        (tester) async {
      await pumpDashboard(tester, [
        entry('e1', 0, [
          mind,
          const JournalItemView(
              kind: 'emotional', optionKey: 'presente.sobrecarga.aperto', intensity: 2),
          const JournalItemView(
              kind: 'emotional', optionKey: 'passado.memoria.magoa', intensity: 1),
          const JournalItemView(
              kind: 'emotional', optionKey: 'futuro.medo.desanimo', intensity: 3),
        ]),
        entry('e2', 1, [
          const JournalItemView(
              kind: 'emotional', optionKey: 'futuro.mente.cobranca', intensity: 5),
        ]),
      ]);

      expect(find.text('Seus últimos 30 dias'), findsOneWidget);
      // Both "Mente acelerada" options share one line.
      expect(find.text('Futuro · Mente acelerada'), findsOneWidget);
      expect(find.byKey(const Key('emotional_chip_futuro.mente')), findsOneWidget);
      // First 3 lines start visible, the 4th starts hidden.
      expect(visibleLineCount(tester), 3);

      await tester.tap(find.byKey(const Key('emotional_chip_futuro.mente')));
      await tester.pumpAndSettle();
      expect(visibleLineCount(tester), 2);

      await tester.tap(find.byKey(const Key('emotional_chip_futuro.mente')));
      await tester.pumpAndSettle();
      expect(visibleLineCount(tester), 3);

      expect(find.byKey(const Key('time_distribution_bar')), findsOneWidget);
      expect(find.text('Passado · Presente · Futuro'), findsOneWidget);
      expect(find.text('Futuro: 2'), findsOneWidget);
      // Segments are drawn with height (they used to collapse to 0).
      final segment = find.descendant(
        of: find.byKey(const Key('time_distribution_bar')),
        matching: find.byType(ColoredBox),
      );
      expect(tester.getSize(segment.first).height, 18);
    });

    testWidgets('period chips filter entries on the device', (tester) async {
      await pumpDashboard(tester, [
        entry('recent', 1, [mind]),
        entry('older', 20, [
          const JournalItemView(
              kind: 'emotional', optionKey: 'passado.memoria.magoa', intensity: 2),
        ]),
        entry('oldest', 60, [
          const JournalItemView(
              kind: 'emotional', optionKey: 'presente.energia.corpo', intensity: 2),
        ]),
      ]);
      expect(find.byKey(const Key('emotional_chip_passado.memoria')), findsOneWidget);
      expect(find.byKey(const Key('emotional_chip_presente.energia')), findsNothing);

      await tester.tap(find.byKey(const Key('history_period_7')));
      await tester.pumpAndSettle();
      expect(find.text('Como foi sua semana'), findsOneWidget);
      expect(find.byKey(const Key('emotional_chip_passado.memoria')), findsNothing);
      expect(find.byKey(const Key('journal_entry_older')), findsNothing);

      await tester.tap(find.byKey(const Key('history_period_90')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('emotional_chip_presente.energia')), findsOneWidget);
      expect(find.byKey(const Key('journal_entry_oldest')), findsOneWidget);
    });

    testWidgets('physical tab: map counts include whole-body areas',
        (tester) async {
      await pumpDashboard(tester, [
        entry('e1', 0, [head]),
        entry('e2', 1, [head]),
        entry('e3', 2, const [
          JournalItemView(
            kind: 'physical',
            optionKey: 'pele.coceira.coceira',
            sensation: 'incomodo',
            intensity: 2,
          ),
        ]),
        entry('e4', 3, const [
          JournalItemView(
            kind: 'physical',
            optionKey: 'hormonios.temperatura.calorao',
            sensation: 'incomodo',
            intensity: 3,
          ),
        ]),
      ]);
      await openPhysicalTab(tester);

      expect(find.text('Este mês'), findsOneWidget);
      expect(find.byKey(const Key('journal_body_map')), findsOneWidget);
      expect(find.text('Cabeça e pescoço: 2 dias'), findsOneWidget);
      expect(find.text('Pele: 1 dia'), findsOneWidget);
      expect(find.text('Hormônios e metabolismo: 1 dia'), findsOneWidget);
      // Regions never marked are left out of the list.
      expect(find.byKey(const Key('body_map_count_peito')), findsNothing);
      expect(find.text('Cor = quantos dias você marcou'), findsOneWidget);
    });

    testWidgets('physical tab: Conexões counts same-day time and region',
        (tester) async {
      await pumpDashboard(tester, [
        entry('e1', 0, [head]),
        entry('e1b', 0, [mind]),
        entry('e2', 1, [head]),
        entry('e2b', 1, [mind]),
        entry('e3', 2, [mind]),
      ]);
      await openPhysicalTab(tester);
      await tester.tap(find.byKey(const Key('physical_view__PhysicalView.links')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('time_region_flow')), findsOneWidget);
      expect(
        find.text('Mesmo dia: Futuro e Cabeça e pescoço em 2 dias. Só contagem.'),
        findsOneWidget,
      );
    });

    testWidgets('physical tab: Conexões explains when nothing overlaps',
        (tester) async {
      await pumpDashboard(tester, [entry('e1', 0, [head])]);
      await openPhysicalTab(tester);
      await tester.tap(find.byKey(const Key('physical_view__PhysicalView.links')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('time_region_flow_empty')), findsOneWidget);
    });

    testWidgets('physical timeline splits by sensation and offers a dashed emotional line',
        (tester) async {
      await pumpDashboard(tester, [
        entry('e1', 0, const [
          JournalItemView(
            kind: 'physical',
            optionKey: 'cabeca.pressao.latejando',
            bodySide: 'front',
            sensation: 'dor',
            intensity: 4,
          ),
        ]),
        entry('e1b', 0, [mind]),
        entry('e2', 1, [head]),
      ]);
      await openPhysicalTab(tester);

      expect(find.text('Linha do tempo'), findsOneWidget);
      expect(find.text('Cabeça e pescoço · dor'), findsOneWidget);
      expect(find.byKey(const Key('physical_chip_cabeca:dor')), findsOneWidget);
      // Old item without sensation keeps a region-only line.
      expect(find.byKey(const Key('physical_chip_cabeca')), findsOneWidget);

      final overlayChip = find.byKey(const Key('physical_overlay_chip'));
      expect(overlayChip, findsOneWidget);
      expect(find.text('+ Futuro · Mente acelerada'), findsOneWidget);
      expect(visibleLineCount(tester), 2);
      await tester.tap(overlayChip);
      await tester.pumpAndSettle();
      expect(visibleLineCount(tester), 3);
      final chart = tester.widget<LineChart>(find.byType(LineChart).first);
      expect(chart.data.lineBarsData.last.dashArray, isNotNull);
    });

    testWidgets('co-occurrence sentence on Físico counts days, without cause',
        (tester) async {
      await pumpDashboard(tester, [
        entry('e1', 0, [head, mind]),
        entry('e2', 1, [head, mind]),
        entry('e3', 2, [mind]),
      ]);
      await openPhysicalTab(tester);
      expect(
        find.text(
            "Nos 3 dias em que você marcou 'Mente acelerada', também marcou 'Cabeça e pescoço' em 2."),
        findsOneWidget,
      );
    });

    testWidgets('history has no water line (it lives on the Água tab)',
        (tester) async {
      await pumpDashboard(
        tester,
        [entry('e1', 0, [head])],
        water: {DateTime(2026, 10, 26): 1800},
      );
      expect(find.byKey(const Key('water_line_chart')), findsNothing);
      await openPhysicalTab(tester);
      expect(find.byKey(const Key('water_line_chart')), findsNothing);
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
