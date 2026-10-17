import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/core/safety/emergency_numbers.dart';
import 'package:dualis_mobile/features/emergency/presentation/screens/emergency_screen.dart';
import 'package:dualis_mobile/features/emergency/services/emergency_audit_service.dart';
import 'package:dualis_mobile/features/triage/domain/triage_vertical.dart';
import 'package:dualis_mobile/features/triage/presentation/controllers/triage_wizard_notifier.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'emergency_test_helpers.dart';

typedef Trigger = void Function(BuildContext context, TriageWizardNotifier notifier);

/// A wizard-like page that runs [trigger] when 'Trigger' is tapped.
Widget buildWizardHarness(Trigger trigger, {String? region = 'BR'}) {
  final router = GoRouter(
    initialLocation: RoutePaths.triage,
    routes: [
      GoRoute(
        path: RoutePaths.triage,
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Wizard')),
          body: Consumer(
            builder: (context, ref, _) {
              ref.watch(triageWizardNotifierProvider);
              return Column(
                children: [
                  TextButton(
                    onPressed: () => trigger(context, ref.read(triageWizardNotifierProvider.notifier)),
                    child: const Text('Trigger'),
                  ),
                  const Text('Wizard content'),
                ],
              );
            },
          ),
        ),
      ),
      GoRoute(path: RoutePaths.emergency, builder: (context, state) => const EmergencyScreen()),
    ],
  );
  return ProviderScope(
    overrides: [
      deviceRegionProvider.overrideWithValue(region),
      emergencyAuditServiceProvider.overrideWithValue(RecordingAuditService()),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: testLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void physical(BuildContext c, TriageWizardNotifier n, String area, String intensity) {
  n.setVertical(TriageVertical.fisica);
  n.selectOption(c, 0, area);
  n.selectOption(c, 1, 'ha_alguns_dias');
  n.selectOption(c, 2, intensity);
}

Future<String?> noticeTextFor(WidgetTester tester, Trigger trigger) async {
  await tester.pumpWidget(buildWizardHarness(trigger));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Trigger'));
  await tester.pumpAndSettle();
  final finder = find.byKey(const Key('safety_notice_text'));
  if (finder.evaluate().isEmpty) return null;
  return tester.widget<Text>(finder).data;
}

const generalNotice = 'Se isso for uma emergência, não use o app: ligue 192 agora.';

void main() {
  final generalTriggers = <String, Trigger>{
    'chest intensity 4': (c, n) => physical(c, n, 'cardiovascular_torax', '4'),
    'breathing intensity 4': (c, n) => physical(c, n, 'respiratorio', '4'),
    'head intensity 4': (c, n) => physical(c, n, 'cabeca', '4'),
    'back intensity 5': (c, n) => physical(c, n, 'costas_coluna', '5'),
    'emotional intensity 5': (c, n) {
      n.setVertical(TriageVertical.psicoEmocional);
      n.selectOption(c, 0, 'tristeza_desanimo');
      n.selectOption(c, 2, '5');
    },
    'chest pain text': (c, n) => n.checkFreeText(c, 'estou com dor no peito'),
    'stroke-like text': (c, n) => n.checkFreeText(c, 'acordei com o rosto torto'),
  };

  for (final entry in generalTriggers.entries) {
    testWidgets('${entry.key} shows the identical generic notice', (tester) async {
      expect(await noticeTextFor(tester, entry.value), generalNotice);
      // Non-blocking: the wizard is still there and usable.
      expect(find.text('Wizard content'), findsOneWidget);
      expect(find.text('Trigger'), findsOneWidget);
      // Never names a condition or a level.
      for (final banned in ['AVC', 'infarto', 'Nível', 'risco', 'peito', 'Torácica']) {
        expect(find.textContaining(banned), findsNothing, reason: banned);
      }
    });
  }

  testWidgets('back intensity 4 shows nothing', (tester) async {
    expect(await noticeTextFor(tester, (c, n) => physical(c, n, 'costas_coluna', '4')), isNull);
  });

  testWidgets('self-harm text shows crisis resources without blocking', (tester) async {
    final text = await noticeTextFor(tester, (c, n) => n.checkFreeText(c, 'eu quero morrer'));
    expect(text,
        'Se você está pensando em se machucar ou em tirar a própria vida, ligue 188 (CVV, 24h, gratuito) ou 192.');
    expect(find.text('Wizard content'), findsOneWidget);
  });

  testWidgets('notice uses the regional number', (tester) async {
    await tester.pumpWidget(buildWizardHarness((c, n) => physical(c, n, 'costas_coluna', '5'), region: 'US'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trigger'));
    await tester.pumpAndSettle();
    expect(find.text('Se isso for uma emergência, não use o app: ligue 911 agora.'), findsOneWidget);
  });

  testWidgets('notice opens the resources screen and can be closed', (tester) async {
    await noticeTextFor(tester, (c, n) => physical(c, n, 'costas_coluna', '5'));

    await tester.tap(find.byKey(const Key('safety_notice_open_resources')));
    await tester.pumpAndSettle();
    expect(find.byType(EmergencyScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('emergency_close_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('safety_notice_close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('safety_notice_text')), findsNothing);
    expect(find.text('Wizard content'), findsOneWidget);
  });
}
