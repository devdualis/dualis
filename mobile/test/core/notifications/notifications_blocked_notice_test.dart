import 'package:dualis_mobile/core/notifications/notifications_blocked_notice.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app({required bool allowed, required void Function() onOpen, Locale locale = const Locale('pt')}) =>
      ProviderScope(
        overrides: [
          notificationsAllowedProvider.overrideWith((ref) async => allowed),
          openNotificationSettingsProvider.overrideWithValue(() async => onOpen()),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: NotificationsBlockedNotice()),
        ),
      );

  testWidgets('blocked: explains reminders will not appear and opens settings', (tester) async {
    var opened = 0;
    await tester.pumpWidget(app(allowed: false, onOpen: () => opened++));
    await tester.pumpAndSettle();

    expect(find.text('As notificações estão desligadas neste celular'), findsOneWidget);
    await tester.tap(find.byKey(const Key('notifications_open_settings')));
    expect(opened, 1);
  });

  testWidgets('allowed: shows nothing', (tester) async {
    await tester.pumpWidget(app(allowed: true, onOpen: () {}));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notifications_blocked_notice')), findsNothing);
  });

  testWidgets('coming back to the app reads the permission again', (tester) async {
    var reads = 0;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        notificationsAllowedProvider.overrideWith((ref) async {
          reads++;
          return reads > 1; // blocked first, allowed after the settings visit
        }),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: NotificationsBlockedNotice()),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Notifications are off on this phone'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notifications_blocked_notice')), findsNothing);
  });
}
