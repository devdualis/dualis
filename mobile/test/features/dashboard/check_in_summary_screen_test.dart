import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:dualis_mobile/core/network/api_client.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/dashboard/presentation/screens/check_in_summary_screen.dart';
import 'package:dualis_mobile/features/home/domain/home_greeting.dart';
import 'package:dualis_mobile/features/house_ads/data/house_ads_repository.dart';
import 'package:dualis_mobile/features/house_ads/domain/house_ad.dart';
import 'package:dualis_mobile/features/house_ads/presentation/house_ad_card.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

class FakeHouseAdsRepository extends HouseAdsRepository {
  final List<HouseAd>? remote;
  int fetchCount = 0;

  FakeHouseAdsRepository({this.remote})
      : super(apiClient: ApiClient(), storage: SecureStorageService());

  @override
  Future<List<HouseAd>?> fetchAds() async {
    fetchCount++;
    return remote;
  }
}

final DateTime fixedNow = DateTime(2026, 10, 27, 9);

void main() {
  late GoRouter router;

  Future<FakeHouseAdsRepository> pumpSummary(
    WidgetTester tester,
    CheckInSummaryArgs args, {
    List<HouseAd>? remoteAds,
  }) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final ads = FakeHouseAdsRepository(remote: remoteAds);
    router = GoRouter(
      initialLocation: RoutePaths.checkInSummary,
      routes: [
        GoRoute(
          path: RoutePaths.home,
          builder: (_, __) => const Scaffold(body: Text('Home Screen Destination')),
        ),
        GoRoute(
          path: RoutePaths.emergency,
          builder: (_, __) => const Scaffold(body: Text('Emergency Screen')),
        ),
        GoRoute(
          path: RoutePaths.library,
          builder: (_, __) => const Scaffold(body: Text('Library Screen')),
        ),
        GoRoute(
          path: RoutePaths.checkInSummary,
          builder: (_, __) => CheckInSummaryScreen(args: args),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          houseAdsRepositoryProvider.overrideWithValue(ads),
          homeClockProvider.overrideWithValue(() => fixedNow),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return ads;
  }

  const items = CheckInSummaryArgs(items: [
    CheckInSummaryItem(label: 'Cabeça e pescoço · Enjoo', intensity: 3),
    CheckInSummaryItem(label: 'Fico antecipando problemas', intensity: 5),
  ]);

  testWidgets('lists the items in the person\'s words with reported intensity',
      (tester) async {
    await pumpSummary(tester, items);

    expect(find.text('Seu registro de hoje'), findsOneWidget);
    expect(find.text('Cabeça e pescoço · Enjoo'), findsOneWidget);
    expect(find.text('Intensidade que você informou: 3/5'), findsOneWidget);
    expect(find.text('Fico antecipando problemas'), findsOneWidget);
    expect(find.text('Intensidade que você informou: 5/5'), findsOneWidget);
    expect(
      find.textContaining('Obrigado por registrar seu dia! 🌿'),
      findsOneWidget,
    );
  });

  testWidgets('shows the bundled house ad labelled "Anúncio" when offline',
      (tester) async {
    await pumpSummary(tester, items);

    expect(find.byType(HouseAdCard), findsOneWidget);
    expect(find.text('Anúncio'), findsOneWidget);
  });

  testWidgets('the ad is the same whatever was recorded', (tester) async {
    String adBrand() {
      final view = tester.widget<HouseAdView>(find.byType(HouseAdView));
      return view.ad.id;
    }

    await pumpSummary(tester, items);
    final first = adBrand();

    await pumpSummary(
      tester,
      const CheckInSummaryArgs(items: [
        CheckInSummaryItem(label: 'Aperto no peito e momentos de desespero', intensity: 5),
      ]),
    );
    expect(adBrand(), first);

    await pumpSummary(tester, const CheckInSummaryArgs(moodLabel: 'Bem'));
    expect(adBrand(), first);
  });

  testWidgets('remote house ads are used when the API answers', (tester) async {
    final ads = await pumpSummary(tester, items, remoteAds: const [
      HouseAd(id: 'r1', brand: 'Dualis Premium', title: 'Remote title', body: 'Remote body'),
    ]);
    await tester.pumpAndSettle();
    expect(ads.fetchCount, 1);
    expect(find.text('Remote title'), findsOneWidget);
    expect(find.text('Anúncio'), findsOneWidget);
  });

  testWidgets('library link opens the general library', (tester) async {
    await pumpSummary(tester, items);
    await tester.tap(find.byKey(const Key('check_in_summary_library')));
    await tester.pumpAndSettle();
    expect(find.text('Library Screen'), findsOneWidget);
  });

  testWidgets('no items shows the mood the person chose', (tester) async {
    await pumpSummary(tester, const CheckInSummaryArgs(moodLabel: 'Bem'));
    expect(find.text('Bem'), findsOneWidget);
  });

  testWidgets('returns Home by itself after the countdown', (tester) async {
    await pumpSummary(tester, items);
    const total = CheckInSummaryScreen.autoReturnSeconds;
    expect(find.text('Voltar ao início ($total)'), findsOneWidget);
    await tester.pump(const Duration(seconds: total - 1));
    expect(find.text('Voltar ao início (1)'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Home Screen Destination'), findsOneWidget);
  });

  testWidgets('touching the screen stops the automatic return', (tester) async {
    await pumpSummary(tester, items);
    await tester.tap(find.text('Seu registro de hoje'));
    await tester.pump(const Duration(seconds: 20));
    expect(find.text('Home Screen Destination'), findsNothing);
    expect(find.text('Voltar ao início'), findsOneWidget);
    await tester.tap(find.byKey(const Key('check_in_summary_home_button')));
    await tester.pumpAndSettle();
    expect(find.text('Home Screen Destination'), findsOneWidget);
  });

  testWidgets('system back goes Home instead of leaving the app', (tester) async {
    await pumpSummary(tester, items);
    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(handled, isTrue);
    expect(find.text('Home Screen Destination'), findsOneWidget);
  });

  testWidgets('help opened on top is never closed by the countdown',
      (tester) async {
    await pumpSummary(tester, items);
    router.push(RoutePaths.emergency);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 20));
    await tester.pumpAndSettle();
    expect(find.text('Emergency Screen'), findsOneWidget);
    expect(find.text('Home Screen Destination'), findsNothing);
  });

  test('pickHouseAd depends only on the date', () {
    final ads = [
      for (final id in ['a', 'b', 'c', 'd'])
        HouseAd(id: id, brand: id, title: id, body: id),
    ];
    final morning = pickHouseAd(ads, DateTime(2026, 10, 27, 8));
    final night = pickHouseAd(ads, DateTime(2026, 10, 27, 23));
    expect(morning!.id, night!.id);
    expect(pickHouseAd(ads, DateTime(2026, 10, 28))!.id, isNot(morning.id));
  });

  test('bundled ads are our own three apps with their official sites', () {
    final ads = bundledHouseAds(lookupAppLocalizations(const Locale('pt')));
    expect(ads.map((a) => a.brand), ['Dualis Premium', 'ZOC', 'e-BEF']);
    expect(ads.map((a) => a.url), [
      'https://dualischeckup.com/#pricing',
      'https://www.zoctec.com',
      'https://e-bef.com.br',
    ]);
  });

  test('remote and bundled brand keys share the same card', () {
    const remote = HouseAd(id: 'ebef', brand: 'e-BEF', title: 't', body: 'b', assetKey: 'house_ad_ebef');
    expect(houseAdBrandKey(remote), 'ebef');
  });
}
