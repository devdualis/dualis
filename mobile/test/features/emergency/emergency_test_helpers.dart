import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/core/safety/emergency_numbers.dart';
import 'package:dualis_mobile/features/emergency/presentation/screens/emergency_screen.dart';
import 'package:dualis_mobile/features/emergency/services/emergency_audit_service.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

class FakeUrlLauncherPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  final List<String> launched = [];
  bool canLaunchReturnValue = true;

  @override
  Future<bool> canLaunch(String url) async => canLaunchReturnValue;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return true;
  }
}

/// Records safety events instead of calling the API.
class RecordingAuditService extends EmergencyAuditService {
  final List<(SafetyEventAction, String?)> events = [];

  RecordingAuditService() : super(apiClient: null);

  @override
  Future<bool> report(SafetyEventAction action, {String? channel}) async {
    events.add((action, channel));
    return true;
  }
}

const testLocalizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// Minimal app: a home page with a button that pushes the help screen.
Widget buildEmergencyTestApp({
  required RecordingAuditService audit,
  String? region = 'BR',
  Locale locale = const Locale('pt', 'BR'),
  String initialLocation = RoutePaths.home,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => EmergencyScreen.open(context),
              child: const Text('Home Screen'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: RoutePaths.emergency,
        builder: (context, state) => const EmergencyScreen(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      deviceRegionProvider.overrideWithValue(region),
      emergencyAuditServiceProvider.overrideWithValue(audit),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: locale,
      localizationsDelegates: testLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}
