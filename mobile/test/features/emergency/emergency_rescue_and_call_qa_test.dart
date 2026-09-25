import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:dualis_mobile/core/network/connectivity_service.dart';
import 'package:dualis_mobile/core/notifications/daily_checkin_notification_service.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/features/emergency/domain/emergency_context.dart';
import 'package:dualis_mobile/features/emergency/domain/emergency_trigger_category.dart';
import 'package:dualis_mobile/features/emergency/presentation/screens/emergency_screen.dart';
import 'package:dualis_mobile/features/emergency/presentation/widgets/emergency_exit_confirmation_dialog.dart';
import 'package:dualis_mobile/features/emergency/services/emergency_audit_service.dart';
import 'package:dualis_mobile/features/home/presentation/controllers/trigger_checkin_controller.dart';
import 'package:dualis_mobile/features/triage/domain/triage_question_bank.dart';
import 'package:dualis_mobile/features/triage/domain/triage_vertical.dart';
import 'package:dualis_mobile/features/triage_outcome/data/triage_outcome_remote_data_source.dart';
import 'package:dualis_mobile/features/triage_outcome/domain/triage_outcome_models.dart';
import 'package:dualis_mobile/features/triage_outcome/presentation/controllers/triage_outcome_controller.dart';
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

class FakeConnectivityService extends Fake implements ConnectivityService {
  @override
  Future<bool> checkOnline() async => true;

  @override
  Stream<bool> get isOnlineStream => Stream.value(true);
}

class FakeDailyCheckinNotificationService extends Fake
    implements DailyCheckinNotificationService {
  @override
  Future<void> scheduleDailyCheckInReminders({required bool isCompletedToday}) async {}

  @override
  Future<void> cancelAllCheckInReminders() async {}
}

class FakeEmergencyAuditService extends Fake implements EmergencyAuditService {
  @override
  void reportEventFireAndForget(
    EmergencyContext context, {
    String? actionTaken,
  }) {}

  @override
  Future<bool> reportEvent(
    EmergencyContext context, {
    String? actionTaken,
  }) async => true;
}

class _FakeTriageOutcomeRemoteDataSource extends Fake
    implements TriageOutcomeRemoteDataSource {
  @override
  Future<TriageOutcome> submitTriage({
    required String vertical,
    required Map<int, String> answers,
    String? narrative,
    String? token,
    String? clientSessionId,
    String? language,
  }) async {
    return TriageOutcome(
      id: 'fake-emergency-id',
      vertical: vertical,
      intensityScore: 5,
      careDisposition: CareDisposition.emergency,
      primaryCategory: 'respiratory',
      categoryLabel: 'Emergência',
      somaticMapping: 'Emergência',
      organicPrimacyApplied: false,
      recommendedArticles: const [],
      recordedAt: DateTime.now(),
    );
  }
}

Widget createEmergencyRescueTestApp({
  required Widget child,
  ProviderContainer? container,
}) {
  final router = GoRouter(
    initialLocation: '/test',
    routes: [
      GoRoute(
        path: '/test',
        builder: (context, state) => child,
      ),
      GoRoute(
        path: RoutePaths.emergency,
        builder: (context, state) {
          final ctx = state.extra as EmergencyContext? ??
              EmergencyContext(
                category: EmergencyTriggerCategory.chestPain,
                severityLevel: 5,
                isEmotional: false,
                detectedAt: DateTime.now(),
                rawTriggerPhrase: 'dor forte peito',
              );
          return EmergencyScreen(emergencyContext: ctx);
        },
      ),
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Home Screen')),
        ),
      ),
    ],
  );

  final app = MaterialApp.router(
    routerConfig: router,
    locale: const Locale('pt', 'BR'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
  );

  return container != null
      ? UncontrolledProviderScope(container: container, child: app)
      : ProviderScope(
          overrides: [
            triageOutcomeDataSourceProvider.overrideWithValue(_FakeTriageOutcomeRemoteDataSource()),
            connectivityServiceProvider.overrideWithValue(FakeConnectivityService()),
            dailyCheckinNotificationServiceProvider.overrideWithValue(FakeDailyCheckinNotificationService()),
            emergencyAuditServiceProvider.overrideWithValue(FakeEmergencyAuditService()),
          ],
          child: app,
        );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeUrlLauncherPlatform fakeUrlLauncher;

  setUp(() {
    fakeUrlLauncher = FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = fakeUrlLauncher;
  });

  group('QA Feature 4: Resgate de triagem em emergência, nível de dor na etapa 3 e persistência 5', () {
    test('QA 4.1: Pain/Intensity is the last question before preview (Step 3)', () {
      // Physical vertical: Step 0 is Natureza, Step 1 is Tempo, Step 2 is Região/Membros, Step 3 is Intensidade/Dor, Step 4 is Preview
      final physicalQuestions = TriageQuestionBank.forVertical(TriageVertical.fisica);
      expect(physicalQuestions.length, equals(5));
      expect(physicalQuestions[3].stepIndex, equals(3));
      expect(physicalQuestions[3].questionKey, equals('triageQ3Physical'));
      expect(physicalQuestions[3].isNumericScale, isTrue);
      expect(physicalQuestions[4].isPreview, isTrue);

      // Emotional vertical: Step 3 is Emotional Intensity, Step 4 is Preview
      final emotionalQuestions = TriageQuestionBank.forVertical(TriageVertical.psicoEmocional);
      expect(emotionalQuestions.length, equals(5));
      expect(emotionalQuestions[3].stepIndex, equals(3));
      expect(emotionalQuestions[3].questionKey, equals('triageQ3Emotional'));
      expect(emotionalQuestions[3].options.any((o) => o.intensityValue != null), isTrue);
      expect(emotionalQuestions[4].isPreview, isTrue);
    });

    testWidgets('QA 4.2: Exit from EmergencyScreen pops back without discarding triage session',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Launcher widget simulating triage wizard pushing emergency
      final testWidget = Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                context.push(
                  RoutePaths.emergency,
                  extra: EmergencyContext(
                    category: EmergencyTriggerCategory.chestPain,
                    severityLevel: 5,
                    isEmotional: false,
                    detectedAt: DateTime.now(),
                    rawTriggerPhrase: 'dor_forte_peito',
                  ),
                );
              },
              child: const Text('Simular Gatilho de Emergência'),
            ),
          ),
        ),
      );

      await tester.pumpWidget(createEmergencyRescueTestApp(child: testWidget));
      await tester.pumpAndSettle();

      // Launch emergency screen via push
      await tester.tap(find.text('Simular Gatilho de Emergência'));
      await tester.pumpAndSettle();

      // Verify on Emergency Screen
      expect(find.byType(EmergencyScreen), findsOneWidget);
      expect(find.text('Alerta de Risco Imediato'), findsOneWidget);

      // Tap exit button on AppBar or bottom
      final closeButton = find.byKey(const Key('emergency_close_button'));
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Confirmation dialog appears
      expect(find.byType(EmergencyExitConfirmationDialog), findsOneWidget);
      expect(find.text('Atenção Médica Urgente'), findsOneWidget);

      // Confirm leave ("Entendi os Riscos / Sair")
      final leaveBtn = find.text('Entendi os Riscos / Sair');
      await tester.tap(leaveBtn);
      await tester.pumpAndSettle();

      // Successfully popped back to caller (triage caller still active on top of stack!)
      expect(find.text('Simular Gatilho de Emergência'), findsOneWidget);
      expect(find.byType(EmergencyScreen), findsNothing);
    });

    testWidgets('QA 4.3: Dialing emergency immediately calls persistEmergencyTriage with level 5 and completes check-in',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          triageOutcomeDataSourceProvider.overrideWithValue(_FakeTriageOutcomeRemoteDataSource()),
          connectivityServiceProvider.overrideWithValue(FakeConnectivityService()),
          dailyCheckinNotificationServiceProvider.overrideWithValue(FakeDailyCheckinNotificationService()),
          emergencyAuditServiceProvider.overrideWithValue(FakeEmergencyAuditService()),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(triggerCheckInProvider).isCompletedToday, isFalse);

      final emergencyContext = EmergencyContext(
        category: EmergencyTriggerCategory.respiratoryDistress,
        severityLevel: 5,
        isEmotional: false,
        detectedAt: DateTime.now(),
        rawTriggerPhrase: 'falta_ar_grave',
      );

      final testWidget = Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                context.push(RoutePaths.emergency, extra: emergencyContext);
              },
              child: const Text('Abrir Emergência'),
            ),
          ),
        ),
      );

      await tester.pumpWidget(createEmergencyRescueTestApp(
        child: testWidget,
        container: container,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Emergência'));
      await tester.pumpAndSettle();

      // Find SAMU 192 button and tap
      final samuButton = find.text('Ligar SAMU (192)');
      expect(samuButton, findsOneWidget);
      await tester.ensureVisible(samuButton);
      await tester.tap(samuButton);
      await tester.pumpAndSettle();

      // Telephony dispatch was called
      expect(fakeUrlLauncher.lastLaunchedUrl, equals('tel:192'));

      // Daily check-in is immediately completed
      expect(container.read(triggerCheckInProvider).isCompletedToday, isTrue);
    });
  });
}
