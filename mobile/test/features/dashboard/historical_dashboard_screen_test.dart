import 'package:drift/native.dart';
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

void main() {
  group('HistoricalDashboardScreen (30-day journal dashboard)', () {
    testWidgets('requests a 30-day window for entries and summary',
        (tester) async {
      final ds = await pumpDashboard(tester, [entry('e1', 0, [head])]);
      expect(ds.requestedEntryDays, 30);
      expect(ds.requestedSummaryDays, 30);
      expect(JournalInsightsState.windowDays, 30);
      expect(find.text('Seus registros dos últimos 30 dias'), findsOneWidget);
    });

    testWidgets('shows time bar, body map counts and item lines from local counts',
        (tester) async {
      await pumpDashboard(tester, [
        entry('e1', 0, [head, mind]),
        entry('e2', 1, [head]),
        entry('e3', 29, [mind]),
      ]);

      expect(find.byKey(const Key('time_distribution_bar')), findsOneWidget);
      expect(find.text('Futuro: 2'), findsOneWidget);
      expect(find.text('Cabeça e pescoço: 2 dias'), findsOneWidget);
      expect(find.text('Peito: nenhum dia'), findsOneWidget);
      expect(find.byKey(const Key('item_intensity_lines')), findsOneWidget);
      expect(
        find.byKey(const Key('item_series_cabeca.pressao.temporas')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Fico antecipando problemas · Intensidade que você informou: 4/5'),
        findsNWidgets(2),
      );
    });

    testWidgets('entries older than 30 days are left out of the lines',
        (tester) async {
      await pumpDashboard(tester, [
        entry('old', 30, [mind]),
        entry('e1', 0, [head]),
      ]);
      expect(
        find.byKey(const Key('item_series_futuro.mente.antecipar')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('item_series_cabeca.pressao.temporas')),
        findsOneWidget,
      );
    });

    testWidgets('shows at most 5 item lines, the rest behind "Ver mais"',
        (tester) async {
      final keys = [
        'cabeca.pressao.temporas',
        'peito.respiracao.curta',
        'barriga.queimacao.enjoo',
        'costas.rigidez.lombar',
        'membros.cansaco.juntas',
        'cabeca.sentidos.olhos',
      ];
      await pumpDashboard(tester, [
        for (var i = 0; i < keys.length; i++)
          entry('e$i', i, [
            JournalItemView(kind: 'physical', optionKey: keys[i], intensity: 2),
          ]),
      ]);
      final seriesRows = find.byWidgetPredicate((w) =>
          w.key is ValueKey<String> &&
          (w.key as ValueKey<String>).value.startsWith('item_series_'));
      expect(find.byKey(const Key('item_lines_see_more')), findsOneWidget);
      expect(seriesRows, findsNWidgets(5));
      await tester.tap(find.byKey(const Key('item_lines_see_more')));
      await tester.pumpAndSettle();
      expect(seriesRows, findsNWidgets(6));
    });

    testWidgets('co-occurrence sentence counts days, without cause',
        (tester) async {
      await pumpDashboard(tester, [
        entry('e1', 0, [head, mind]),
        entry('e2', 1, [head, mind]),
        entry('e3', 2, [mind]),
      ]);
      expect(
        find.text(
            "Nos 3 dias em que você marcou 'Mente acelerada', também marcou 'Cabeça e pescoço' em 2."),
        findsOneWidget,
      );
    });

    testWidgets('uses the summary endpoint when available', (tester) async {
      await pumpDashboard(
        tester,
        [entry('e1', 0, [head])],
        summary: const JournalSummary(
          byTime: {'passado': 7},
          byRegion: {'cabeca': 9},
        ),
      );
      expect(find.text('Passado: 7'), findsOneWidget);
      expect(find.text('Cabeça e pescoço: 9 dias'), findsOneWidget);
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

    testWidgets('water line uses the 30-day hydration totals', (tester) async {
      await pumpDashboard(
        tester,
        const [],
        water: {
          DateTime(2026, 10, 26): 1800,
          DateTime(2026, 10, 1): 900,
        },
      );
      expect(find.byKey(const Key('water_line_chart')), findsOneWidget);
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
