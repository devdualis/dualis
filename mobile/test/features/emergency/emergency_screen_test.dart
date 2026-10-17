import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:dualis_mobile/features/emergency/presentation/screens/emergency_screen.dart';
import 'package:dualis_mobile/features/emergency/presentation/widgets/telephony_fallback_dialog.dart';
import 'package:dualis_mobile/features/emergency/services/emergency_audit_service.dart';
import 'emergency_test_helpers.dart';

/// Simulates no network: every report fails.
class OfflineAuditService extends RecordingAuditService {
  @override
  Future<bool> report(SafetyEventAction action, {String? channel}) async {
    throw Exception('offline');
  }
}

Future<void> openHelp(WidgetTester tester) async {
  await tester.tap(find.text('Home Screen'));
  await tester.pumpAndSettle();
  expect(find.byType(EmergencyScreen), findsOneWidget);
}

void main() {
  late FakeUrlLauncherPlatform platform;
  late RecordingAuditService audit;

  setUp(() {
    platform = FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = platform;
    audit = RecordingAuditService();
  });

  Future<void> pumpApp(WidgetTester tester, {String? region = 'BR', Locale locale = const Locale('pt', 'BR')}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(buildEmergencyTestApp(audit: audit, region: region, locale: locale));
    await tester.pumpAndSettle();
  }

  testWidgets('shows static resources for Brazil with official source', (tester) async {
    await pumpApp(tester);
    await openHelp(tester);

    expect(find.text('Precisa de ajuda agora?'), findsOneWidget);
    expect(find.text('Se você ou alguém perto de você estiver em perigo, ligue para a emergência. Não espere.'),
        findsOneWidget);
    expect(find.text('Ligar SAMU (192)'), findsOneWidget);
    expect(find.text('Ligar CVV – Apoio emocional (188)'), findsOneWidget);
    expect(find.text('Ligar Bombeiros (193)'), findsOneWidget);
    expect(find.text('Ligar Polícia (190)'), findsOneWidget);
    expect(find.text('Ligue 192 imediatamente se você ou alguém tiver:'), findsOneWidget);
    expect(find.text('dor ou pressão forte no peito'), findsOneWidget);
    expect(find.text('sangramento que não para'), findsOneWidget);
    expect(find.text('Fonte: Ministério da Saúde / SAMU'), findsOneWidget);
    expect(
      find.text('Se você está pensando em se machucar ou em tirar a própria vida, '
          'ligue 188 (CVV, 24h, gratuito) ou 192.'),
      findsOneWidget,
    );
  });

  testWidgets('never shows condition names, levels or "not recommended"', (tester) async {
    await pumpApp(tester);
    await openHelp(tester);

    for (final banned in ['AVC', 'Torácica', 'Nível', 'Manchester', 'ESI', 'Não recomendado',
        'Seus sintomas', 'Risco', 'Crítico']) {
      expect(find.textContaining(banned), findsNothing, reason: banned);
    }
  });

  testWidgets('opening is logged as opened_resources', (tester) async {
    await pumpApp(tester);
    await openHelp(tester);
    expect(audit.events, [(SafetyEventAction.openedResources, null)]);
  });

  testWidgets('close button dismisses without any confirmation', (tester) async {
    await pumpApp(tester);
    await openHelp(tester);

    await tester.tap(find.byKey(const Key('emergency_close_button')));
    await tester.pumpAndSettle();

    expect(find.byType(EmergencyScreen), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Home Screen'), findsOneWidget);
  });

  testWidgets('system back dismisses the screen (no PopScope lock)', (tester) async {
    await pumpApp(tester);
    await openHelp(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(EmergencyScreen), findsNothing);
    expect(find.text('Home Screen'), findsOneWidget);
  });

  testWidgets('"Fechar" text button also dismisses', (tester) async {
    await pumpApp(tester);
    await openHelp(tester);

    final close = find.byKey(const Key('emergency_close_text_button'));
    await tester.ensureVisible(close);
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(find.byType(EmergencyScreen), findsNothing);
  });

  testWidgets('call button dials and logs call_started with channel', (tester) async {
    await pumpApp(tester);
    await openHelp(tester);

    await tester.tap(find.text('Ligar SAMU (192)'));
    await tester.pumpAndSettle();

    expect(platform.launched, ['tel:192']);
    expect(audit.events.last, (SafetyEventAction.callStarted, 'ambulance_192'));
  });

  testWidgets('devices without a dialer get the copy-number dialog', (tester) async {
    platform.canLaunchReturnValue = false;
    await pumpApp(tester);
    await openHelp(tester);

    await tester.tap(find.text('Ligar CVV – Apoio emocional (188)'));
    await tester.pumpAndSettle();

    expect(find.byType(TelephonyFallbackDialog), findsOneWidget);
    expect(find.text('188'), findsOneWidget);
  });

  testWidgets('works offline: failed audit never blocks the screen', (tester) async {
    audit = OfflineAuditService();
    await pumpApp(tester);
    await openHelp(tester);

    await tester.tap(find.text('Ligar SAMU (192)'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(platform.launched, ['tel:192']);
    expect(find.text('Precisa de ajuda agora?'), findsOneWidget);
  });

  testWidgets('United States shows 911 and 988 in English', (tester) async {
    await pumpApp(tester, region: 'US', locale: const Locale('en'));
    await openHelp(tester);

    expect(find.text('Need help now?'), findsOneWidget);
    expect(find.text('Call Emergency services (911)'), findsOneWidget);
    expect(find.text('Call 988 Lifeline – Emotional support (988)'), findsOneWidget);
    expect(find.textContaining('192'), findsNothing);
  });

  testWidgets('unknown region falls back to 112 and the local number hint', (tester) async {
    await pumpApp(tester, region: null);
    await openHelp(tester);

    expect(find.text('Ligar Emergência (112)'), findsOneWidget);
    expect(find.text('Se o 112 não funcionar onde você está, ligue para o número local de emergência.'),
        findsOneWidget);
  });
}
