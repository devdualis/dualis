import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/core/network/api_client.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/home/domain/home_greeting.dart';
import 'package:dualis_mobile/features/house_ads/data/house_ads_repository.dart';
import 'package:dualis_mobile/features/house_ads/domain/house_ad.dart';
import 'package:dualis_mobile/features/house_ads/presentation/house_ad_card.dart';
import 'package:dualis_mobile/features/hydration/domain/models/hydration_settings.dart';
import 'package:dualis_mobile/features/hydration/domain/models/water_intake_log.dart';
import 'package:dualis_mobile/features/hydration/presentation/controllers/hydration_controller.dart';
import 'package:dualis_mobile/features/hydration/presentation/screens/hydration_dashboard_screen.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

final DateTime now = DateTime(2026, 10, 27, 10);

class FakeHydration extends HydrationController {
  final HydrationState initial;
  FakeHydration(this.initial);

  @override
  HydrationState build() => initial;

  @override
  Future<void> loadData() async {}

  @override
  Future<bool> logWater({
    required int amountMl,
    String source = 'manual',
    DateTime? timestamp,
  }) async {
    state = state.copyWith(
      todayTotalMl: state.todayTotalMl + amountMl,
      todayLogs: [
        ...state.todayLogs,
        WaterIntakeEntry(
          id: state.todayLogs.length + 1,
          userId: 'u',
          amountMl: amountMl,
          timestamp: now,
          source: source,
        ),
      ],
    );
    return true;
  }

  @override
  Future<void> setDailyTarget(int targetMl) async {
    state = state.copyWith(
      settings: state.settings.copyWith(dailyTargetMl: targetMl),
    );
  }
}

/// Simulates the once-per-day rule with an in-memory day.
class FakeAdsRepository extends HouseAdsRepository {
  String? lastDay;
  FakeAdsRepository()
      : super(apiClient: ApiClient(), storage: SecureStorageService());

  @override
  Future<List<HouseAd>?> fetchAds() async => null;

  @override
  Future<bool> takeWaterAdSlot(DateTime now) async {
    final day = '${now.year}-${now.month}-${now.day}';
    if (lastDay == day) return false;
    lastDay = day;
    return true;
  }
}

Future<FakeHydration> pumpHydration(
  WidgetTester tester, {
  HydrationState? state,
  FakeAdsRepository? ads,
}) async {
  tester.view.physicalSize = const Size(900, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final controller = FakeHydration(state ??
      const HydrationState(
        settings: HydrationSettings(dailyTargetMl: 2000, reminderEnabled: false),
      ));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hydrationControllerProvider.overrideWith(() => controller),
        houseAdsRepositoryProvider.overrideWithValue(ads ?? FakeAdsRepository()),
        homeClockProvider.overrideWithValue(() => now),
      ],
      child: const MaterialApp(
        locale: Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HydrationDashboardScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  testWidgets('shows glass, goal ring, streak and the three quick buttons',
      (tester) async {
    await pumpHydration(tester);
    expect(find.byKey(const Key('hydration_glass')), findsOneWidget);
    expect(find.byKey(const Key('hydration_goal_ring')), findsOneWidget);
    expect(find.text('Sequência: 0 dias'), findsOneWidget);
    expect(find.text('200 ml'), findsOneWidget);
    expect(find.text('500 ml'), findsOneWidget);
    expect(find.text('Outro'), findsOneWidget);
    expect(find.text('Últimos 30 dias'), findsOneWidget);
  });

  testWidgets('quick buttons add water and move the ring', (tester) async {
    await pumpHydration(tester);
    await tester.tap(find.byKey(const Key('hydration_quick_add_200')));
    await tester.pumpAndSettle();
    expect(find.text('200 / 2000 ml'), findsOneWidget);
    await tester.tap(find.byKey(const Key('hydration_quick_add_500')));
    await tester.pumpAndSettle();
    expect(find.text('700 / 2000 ml'), findsOneWidget);
    final ring = tester.widget<CircularProgressIndicator>(
      find.byKey(const Key('hydration_goal_ring')),
    );
    expect(ring.value, closeTo(0.35, 0.001));
  });

  testWidgets('"Outro" opens the custom amount sheet', (tester) async {
    await pumpHydration(tester);
    await tester.tap(find.byKey(const Key('dashboard_add_water_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('confirm_water_intake_button')), findsOneWidget);
  });

  testWidgets('the person sets their own goal', (tester) async {
    await pumpHydration(tester);
    await tester.tap(find.byKey(const Key('hydration_goal_edit')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('hydration_goal_field')), '1750');
    await tester.tap(find.byKey(const Key('hydration_goal_save')));
    await tester.pumpAndSettle();
    expect(find.text('Sua meta: 1750 ml'), findsOneWidget);
    expect(find.text('0 / 1750 ml'), findsOneWidget);
  });

  testWidgets('house ad appears after logging water, at most once a day',
      (tester) async {
    final ads = FakeAdsRepository();
    await pumpHydration(tester, ads: ads);
    expect(find.byType(HouseAdCard), findsNothing);

    await tester.tap(find.byKey(const Key('hydration_quick_add_200')));
    await tester.pumpAndSettle();
    expect(find.byType(HouseAdCard), findsOneWidget);
    expect(find.text('Anúncio'), findsOneWidget);

    // Same day, screen opened again: no second ad.
    await tester.pumpWidget(const SizedBox());
    await pumpHydration(tester, ads: ads);
    await tester.tap(find.byKey(const Key('hydration_quick_add_200')));
    await tester.pumpAndSettle();
    expect(find.byType(HouseAdCard), findsNothing);
  });

  test('streak counts consecutive days that reached the goal', () {
    final state = HydrationState(
      todayTotalMl: 500,
      settings: const HydrationSettings(dailyTargetMl: 2000),
      last30DaysTotals: {
        DateTime(2026, 10, 26): 2100,
        DateTime(2026, 10, 25): 2000,
        DateTime(2026, 10, 24): 1200,
        DateTime(2026, 10, 23): 2500,
      },
    );
    // Today still open: counts the two days before.
    expect(state.streakDays(now), 2);
    expect(state.copyWith(todayTotalMl: 2000).streakDays(now), 3);
  });
}
