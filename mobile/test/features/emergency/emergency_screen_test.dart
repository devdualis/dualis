import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:dualis_mobile/core/constants/app_colors.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/features/emergency/domain/emergency_context.dart';
import 'package:dualis_mobile/features/emergency/domain/emergency_trigger_category.dart';
import 'package:dualis_mobile/features/emergency/presentation/screens/emergency_screen.dart';
import 'package:dualis_mobile/features/emergency/presentation/widgets/emergency_badge.dart';
import 'package:dualis_mobile/features/emergency/presentation/widgets/emergency_exit_confirmation_dialog.dart';
import 'package:dualis_mobile/features/emergency/presentation/widgets/emergency_instructions_card.dart';
import 'package:dualis_mobile/features/emergency/presentation/widgets/telephony_fallback_dialog.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

class FakeUrlLauncherPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  String? lastLaunchedUrl;
  LaunchOptions? lastLaunchOptions;
  bool canLaunchReturnValue = true;
  bool launchUrlReturnValue = true;

  @override
  Future<bool> canLaunch(String url) async => canLaunchReturnValue;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchedUrl = url;
    lastLaunchOptions = options;
    return launchUrlReturnValue;
  }
}

Widget createEmergencyTestApp({
  required EmergencyContext emergencyContext,
  Locale locale = const Locale('pt', 'BR'),
}) {
  final router = GoRouter(
    initialLocation: RoutePaths.emergency,
    routes: [
      GoRoute(
        path: RoutePaths.emergency,
        builder: (context, state) =>
            EmergencyScreen(emergencyContext: emergencyContext),
      ),
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Home Screen')),
        ),
      ),
    ],
  );

  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: router,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeUrlLauncherPlatform fakePlatform;
  String? mockClipboardText;

  setUp(() {
    fakePlatform = FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = fakePlatform;
    mockClipboardText = null;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
      if (methodCall.method == 'Clipboard.setData') {
        mockClipboardText = (methodCall.arguments as Map)['text'] as String?;
        return null;
      } else if (methodCall.method == 'Clipboard.getData') {
        return <String, dynamic>{'text': mockClipboardText};
      }
      return null;
    });
  });

  final physicalEmergency = EmergencyContext(
    category: EmergencyTriggerCategory.chestPain,
    severityLevel: 5,
    isEmotional: false,
    detectedAt: DateTime.now(),
  );

  final emotionalEmergency = EmergencyContext(
    category: EmergencyTriggerCategory.suicidalCrisis,
    severityLevel: 5,
    isEmotional: true,
    detectedAt: DateTime.now(),
  );

  group('Screen 8: Emergency Risk Alert Screen (RF-006) Tests', () {
    testWidgets('renders full-bleed #D32F2F canvas, badge, title and subtitle', (tester) async {
      await tester.pumpWidget(
        createEmergencyTestApp(emergencyContext: physicalEmergency),
      );
      await tester.pumpAndSettle();

      // Verify Scaffold background color
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(AppColors.emergencyCrimson));

      // Verify EmergencyBadge renders
      expect(find.byType(EmergencyBadge), findsOneWidget);
      expect(find.text('Dor Torácica Crítica'), findsOneWidget);

      // Verify title & subtitle
      expect(find.text('Alerta de Risco Imediato'), findsOneWidget);
      expect(
        find.text('Sintomas de gravidade identificados. Procure atendimento médico urgente.'),
        findsOneWidget,
      );
    });

    testWidgets('physical emergency renders physical instructions and SAMU 192 primary button', (tester) async {
      await tester.pumpWidget(
        createEmergencyTestApp(emergencyContext: physicalEmergency),
      );
      await tester.pumpAndSettle();

      // Verify instructions card
      expect(find.byType(EmergencyInstructionsCard), findsOneWidget);
      expect(find.text('Interrompa qualquer esforço físico e permaneça em repouso.'), findsOneWidget);
      expect(find.text('Não dirija até o hospital. Acione o 192 ou peça ajuda a terceiros.'), findsOneWidget);

      // Verify action buttons
      expect(find.text('Ligar SAMU (192)'), findsOneWidget);
      expect(find.text('Ligar Bombeiros (193)'), findsOneWidget);
      expect(find.text('Buscar Pronto-Socorro Mais Próximo'), findsOneWidget);
    });

    testWidgets('emotional emergency renders emotional instructions and CVV 188 primary button', (tester) async {
      await tester.pumpWidget(
        createEmergencyTestApp(emergencyContext: emotionalEmergency),
      );
      await tester.pumpAndSettle();

      // Verify emotional instructions card
      expect(find.byType(EmergencyInstructionsCard), findsOneWidget);
      expect(find.text('Você não está sozinho(a). Ajuda qualificada e sigilosa está disponível agora.'), findsOneWidget);
      expect(find.text('O CVV oferece apoio emocional gratuito 24 horas por dia pelo telefone 188.'), findsOneWidget);

      // Verify buttons
      expect(find.text('Ligar CVV - Apoio Emocional (188)'), findsOneWidget);
      expect(find.text('Ligar SAMU (192)'), findsOneWidget);
    });

    testWidgets('PopScope and exit button trigger non-dismissible confirmation dialog; stay keeps screen', (tester) async {
      await tester.pumpWidget(
        createEmergencyTestApp(emergencyContext: physicalEmergency),
      );
      await tester.pumpAndSettle();

      // Ensure exit button is visible in scrollable viewport and tap
      final exitBtn = find.text('Voltar ao Início (Não recomendado)');
      expect(exitBtn, findsOneWidget);
      await tester.ensureVisible(exitBtn);
      await tester.pumpAndSettle();

      await tester.tap(exitBtn);
      await tester.pumpAndSettle();

      // Verify confirmation dialog is visible
      expect(find.byType(EmergencyExitConfirmationDialog), findsOneWidget);
      expect(find.text('Atenção Médica Urgente'), findsOneWidget);

      // Tap stay
      final stayBtn = find.text('Permanecer na Emergência');
      await tester.tap(stayBtn);
      await tester.pumpAndSettle();

      // Dialog dismissed, EmergencyScreen remains
      expect(find.byType(EmergencyExitConfirmationDialog), findsNothing);
      expect(find.byType(EmergencyScreen), findsOneWidget);
    });

    testWidgets('Confirming exit in dialog transitions router to /home', (tester) async {
      await tester.pumpWidget(
        createEmergencyTestApp(emergencyContext: physicalEmergency),
      );
      await tester.pumpAndSettle();

      // Tap exit button
      final exitBtn = find.text('Voltar ao Início (Não recomendado)');
      await tester.ensureVisible(exitBtn);
      await tester.pumpAndSettle();

      await tester.tap(exitBtn);
      await tester.pumpAndSettle();

      // Tap confirm leave
      final leaveBtn = find.text('Entendi os Riscos / Sair');
      await tester.tap(leaveBtn);
      await tester.pumpAndSettle();

      // Verify navigated to home
      expect(find.text('Home Screen'), findsOneWidget);
      expect(find.byType(EmergencyScreen), findsNothing);
    });

    testWidgets('System pop gesture triggers confirmation dialog without popping', (tester) async {
      await tester.pumpWidget(
        createEmergencyTestApp(emergencyContext: physicalEmergency),
      );
      await tester.pumpAndSettle();

      // Simulate system pop via navigator
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      await navigator.maybePop();
      await tester.pumpAndSettle();

      // Verify dialog is triggered and screen is still present
      expect(find.byType(EmergencyExitConfirmationDialog), findsOneWidget);
      expect(find.text('Atenção Médica Urgente'), findsOneWidget);
      expect(find.byType(EmergencyScreen), findsOneWidget);
    });

    testWidgets('Tapping SAMU 192 dispatches tel intent', (tester) async {
      await tester.pumpWidget(
        createEmergencyTestApp(emergencyContext: physicalEmergency),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ligar SAMU (192)'));
      await tester.pumpAndSettle();

      expect(fakePlatform.lastLaunchedUrl, equals('tel:192'));
    });

    testWidgets('Telephony fallback dialog opens when launchUrl fails and can copy number', (tester) async {
      fakePlatform.launchUrlReturnValue = false;

      await tester.pumpWidget(
        createEmergencyTestApp(emergencyContext: physicalEmergency),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ligar SAMU (192)'));
      await tester.pumpAndSettle();

      // Verify fallback dialog appears
      expect(find.byType(TelephonyFallbackDialog), findsOneWidget);
      expect(find.text('192'), findsOneWidget);
      expect(find.text('Copiar Número'), findsOneWidget);

      // Tap copy number
      await tester.tap(find.text('Copiar Número'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify clipboard was set
      expect(mockClipboardText, equals('192'));

      // Verify fallback dialog was popped
      await tester.pumpAndSettle();
      expect(find.byType(TelephonyFallbackDialog), findsNothing);
    });

    testWidgets('Trilingual localization: renders correctly in Spanish', (tester) async {
      await tester.pumpWidget(
        createEmergencyTestApp(
          emergencyContext: physicalEmergency,
          locale: const Locale('es'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alerta de Riesgo Inmediato'), findsOneWidget);
      expect(find.text('Dolor Torácico Crítico'), findsOneWidget);
      expect(find.text('Llamar SAMU (192)'), findsOneWidget);
      expect(find.text('Qué hacer ahora'), findsOneWidget);
    });

    testWidgets('Trilingual localization: renders correctly in English', (tester) async {
      await tester.pumpWidget(
        createEmergencyTestApp(
          emergencyContext: physicalEmergency,
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Immediate Risk Alert'), findsOneWidget);
      expect(find.text('Critical Chest Pain'), findsOneWidget);
      expect(find.text('Call SAMU (192)'), findsOneWidget);
      expect(find.text('What to do now'), findsOneWidget);
    });
  });
}
