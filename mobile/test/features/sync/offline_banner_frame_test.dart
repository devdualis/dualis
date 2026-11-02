import 'package:dualis_mobile/core/network/connectivity_service.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/features/sync/presentation/widgets/offline_indicator_banner.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:dualis_mobile/shared/widgets/urgent_help_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _statusBar = 24.0;

/// Same wiring as main.dart: the frame wraps the urgent-help overlay.
Widget _app({required bool online}) {
  final router = GoRouter(
    initialLocation: '/page',
    routes: [
      GoRoute(
        path: '/page',
        builder: (_, __) => Scaffold(
          appBar: AppBar(key: const Key('page_app_bar'), title: const Text('Page')),
          body: const SizedBox.expand(),
        ),
      ),
      GoRoute(
        path: RoutePaths.emergency,
        builder: (_, __) => const Scaffold(body: Text('Emergency Screen')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      isOnlineProvider.overrideWith((ref) => Stream.value(online)),
      pendingOutboxCountProvider.overrideWith((ref) => Stream.value(0)),
      rejectedOutboxCountProvider.overrideWith((ref) => Stream.value(0)),
    ],
    child: MediaQuery(
      data: const MediaQueryData(
        size: Size(400, 800),
        padding: EdgeInsets.only(top: _statusBar),
      ),
      child: MaterialApp.router(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) => OfflineBannerFrame(
          child: UrgentHelpOverlay(router: router, child: child!),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('offline: banner fills the status bar on any screen; app bar and help sit below it',
      (tester) async {
    await tester.pumpWidget(_app(online: false));
    await tester.pumpAndSettle();

    final banner = find.byKey(const Key('offline_indicator_banner'));
    expect(banner, findsOneWidget);
    expect(tester.getTopLeft(banner).dy, 0);

    final bannerBottom = tester.getBottomLeft(banner).dy;
    expect(bannerBottom, greaterThan(_statusBar));
    // No double status-bar gap: the app bar starts right under the banner.
    expect(tester.getTopLeft(find.byKey(const Key('page_app_bar'))).dy, bannerBottom);
    expect(tester.getSize(find.byKey(const Key('page_app_bar'))).height, kToolbarHeight);
    // The banner takes the status-bar area on top of its own content.
    final content = find.descendant(of: banner, matching: find.byType(Row));
    expect(tester.getTopLeft(content).dy, greaterThanOrEqualTo(_statusBar));

    final help = find.byType(UrgentHelpButton);
    expect(help, findsOneWidget);
    expect(tester.getTopLeft(help).dy, greaterThanOrEqualTo(bannerBottom));

    await tester.tap(help);
    await tester.pumpAndSettle();
    expect(find.text('Emergency Screen'), findsOneWidget);
  });

  testWidgets('online with nothing to sync: no banner, layout unchanged', (tester) async {
    await tester.pumpWidget(_app(online: true));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('offline_indicator_banner')), findsNothing);
    expect(tester.getTopLeft(find.byKey(const Key('page_app_bar'))).dy, 0);
    // The app bar keeps its own status-bar inset.
    expect(tester.getSize(find.byKey(const Key('page_app_bar'))).height,
        kToolbarHeight + _statusBar);
  });
}
