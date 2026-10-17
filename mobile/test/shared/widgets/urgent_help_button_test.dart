import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:dualis_mobile/core/database/app_database.dart';
import 'package:dualis_mobile/core/network/connectivity_service.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/core/safety/emergency_numbers.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:dualis_mobile/features/dashboard/data/triage_history_remote_data_source.dart';
import 'package:dualis_mobile/features/dashboard/presentation/screens/historical_dashboard_screen.dart';
import 'package:dualis_mobile/features/emergency/presentation/screens/emergency_screen.dart';
import 'package:dualis_mobile/features/emergency/services/emergency_audit_service.dart';
import 'package:dualis_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:dualis_mobile/features/hydration/presentation/screens/hydration_dashboard_screen.dart';
import 'package:dualis_mobile/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:dualis_mobile/features/settings/presentation/screens/settings_screen.dart';
import 'package:dualis_mobile/features/sync/presentation/widgets/offline_indicator_banner.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:dualis_mobile/main.dart';
import 'package:dualis_mobile/shared/widgets/urgent_help_button.dart';

class _Storage extends SecureStorageService {
  @override
  Future<String?> getAccessToken() async => null;
  @override
  Future<String?> getRefreshToken() async => null;
  @override
  Future<String?> getUserId() async => null;
  @override
  Future<void> clearAll() async {}
}

/// History is irrelevant here: calls never complete, screens stay loading.
class _NoHistory implements TriageHistoryRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => Completer<Never>().future;
}

class _NoAudit extends EmergencyAuditService {
  _NoAudit() : super(apiClient: null);
  @override
  Future<bool> report(SafetyEventAction action, {String? channel}) async => true;
}

/// Real screens under the same global builder used by `main.dart`.
Widget buildApp(AppDatabase db, String initialLocation) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: RoutePaths.onboarding, builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: RoutePaths.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: RoutePaths.home, builder: (_, __) => const HomeScreen()),
      GoRoute(path: RoutePaths.history, builder: (_, __) => const HistoricalDashboardScreen()),
      GoRoute(path: RoutePaths.hydration, builder: (_, __) => const HydrationDashboardScreen()),
      GoRoute(path: RoutePaths.settings, builder: (_, __) => const SettingsScreen()),
      GoRoute(path: RoutePaths.emergency, builder: (_, __) => const EmergencyScreen()),
    ],
  );

  return ProviderScope(
    overrides: [
      isOnlineProvider.overrideWith((ref) => Stream.value(true)),
      pendingOutboxCountProvider.overrideWith((ref) => Stream.value(0)),
      appDatabaseProvider.overrideWithValue(db),
      secureStorageServiceProvider.overrideWithValue(_Storage()),
      triageHistoryDataSourceProvider.overrideWithValue(_NoHistory()),
      deviceRegionProvider.overrideWithValue('BR'),
      emergencyAuditServiceProvider.overrideWithValue(_NoAudit()),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => UrgentHelpOverlay(router: router, child: child!),
    ),
  );
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  Future<void> pump(WidgetTester tester, String location) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(buildApp(db, location));
    await tester.pump(const Duration(milliseconds: 500));
  }

  final screens = <String, Type>{
    RoutePaths.home: HomeScreen,
    RoutePaths.history: HistoricalDashboardScreen,
    RoutePaths.hydration: HydrationDashboardScreen,
    RoutePaths.settings: SettingsScreen,
    RoutePaths.login: LoginScreen,
    RoutePaths.onboarding: OnboardingScreen,
  };

  for (final entry in screens.entries) {
    testWidgets('help is 1 tap away from ${entry.key}', (tester) async {
      await pump(tester, entry.key);
      expect(find.byType(entry.value), findsOneWidget);

      final button = find.byKey(const Key('urgent_help_button'));
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(EmergencyScreen), findsOneWidget);
      expect(find.text('Precisa de ajuda agora?'), findsOneWidget);
      // Not shown on the help screen itself.
      expect(find.byKey(const Key('urgent_help_button')), findsNothing);

      // Dismissable: back to the same screen, button visible again.
      await tester.tap(find.byKey(const Key('emergency_close_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(EmergencyScreen), findsNothing);
      expect(find.byType(entry.value), findsOneWidget);
      expect(find.byKey(const Key('urgent_help_button')), findsOneWidget);
    });
  }

  testWidgets('button floats in the top-right corner, away from the bottom nav', (tester) async {
    await pump(tester, RoutePaths.login);
    final buttonTopLeft = tester.getTopLeft(find.byKey(const Key('urgent_help_button')));
    final screenSize = tester.view.physicalSize / tester.view.devicePixelRatio;
    // Near the top (well above the midpoint) and near the right edge.
    expect(buttonTopLeft.dy, lessThan(screenSize.height / 4));
    expect(buttonTopLeft.dx, greaterThan(screenSize.width / 2));
  });

  testWidgets('real app root (main.dart) shows the button on first launch', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DualisApp()));
    await tester.pumpAndSettle();
    expect(find.byType(UrgentHelpOverlay), findsOneWidget);
    expect(find.byKey(const Key('urgent_help_button')), findsOneWidget);
  });
}
