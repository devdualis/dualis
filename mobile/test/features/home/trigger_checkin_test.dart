import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:dualis_mobile/features/home/presentation/widgets/admob_banner_container.dart';
import 'package:dualis_mobile/features/home/domain/trigger_checkin_state.dart';
import 'package:dualis_mobile/features/home/presentation/controllers/trigger_checkin_controller.dart';
import 'package:dualis_mobile/features/dashboard/data/triage_history_remote_data_source.dart';
import 'package:dualis_mobile/features/dashboard/domain/models/triage_history_models.dart';
import 'package:dualis_mobile/features/home/presentation/widgets/dual_axis_trigger_card.dart';
import 'package:dualis_mobile/features/triage/domain/triage_vertical.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

Widget createTriggerCheckInTestApp({
  void Function(TriageVertical vertical)? onTriageNavigated,
  ProviderContainer? container,
}) {
  final router = GoRouter(
    initialLocation: RoutePaths.home,
    routes: [
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.triage,
        builder: (context, state) {
          final TriageVertical vertical;
          if (state.extra is TriageNavigationArgs) {
            vertical = (state.extra as TriageNavigationArgs).initialVertical;
          } else if (state.extra is TriageVertical) {
            vertical = state.extra as TriageVertical;
          } else {
            vertical = TriageVertical.psicoEmocional;
          }
          if (onTriageNavigated != null) {
            onTriageNavigated(vertical);
          }
          return Scaffold(
            body: Center(child: Text('Triage Screen: ${vertical.name}')),
          );
        },
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
      : ProviderScope(child: app);
}

void main() {
  group('Two-Stage Trigger Check-in Widget & Controller Tests', () {
    testWidgets('1. Displays two stages (Psicoemocional and Avaliação Física) with direct triage start buttons',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTriggerCheckInTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Check-in Diário em 2 Etapas'), findsOneWidget);
      expect(find.text('Psicoemocional'), findsOneWidget);
      expect(find.text('Avaliação Física'), findsOneWidget);

      expect(find.byKey(const Key('start_psicoemocional_triage_button')), findsOneWidget);
      expect(find.byKey(const Key('start_fisica_triage_button')), findsOneWidget);
      expect(find.text('Iniciar Psicoemocional'), findsOneWidget);
      expect(find.text('Iniciar Avaliação Física'), findsOneWidget);
    });

    testWidgets('2. Tapping Iniciar Psicoemocional navigates to Triage Screen with psicoEmocional vertical',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      TriageVertical? navigatedVertical;

      await tester.pumpWidget(createTriggerCheckInTestApp(
        onTriageNavigated: (v) => navigatedVertical = v,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('start_psicoemocional_triage_button')));
      await tester.pumpAndSettle();

      expect(find.text('Triage Screen: psicoEmocional'), findsOneWidget);
      expect(navigatedVertical, equals(TriageVertical.psicoEmocional));
    });

    testWidgets('3. Tapping Iniciar Avaliação Física navigates to Triage Screen with fisica vertical',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      TriageVertical? navigatedVertical;

      await tester.pumpWidget(createTriggerCheckInTestApp(
        onTriageNavigated: (v) => navigatedVertical = v,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('start_fisica_triage_button')));
      await tester.pumpAndSettle();

      expect(find.text('Triage Screen: fisica'), findsOneWidget);
      expect(navigatedVertical, equals(TriageVertical.fisica));
    });

    testWidgets('4. Completing emotional stage displays completed summary badge and keeps physical stage available',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(triggerCheckInProvider.notifier);
      notifier.completeStage(
        vertical: TriageVertical.psicoEmocional,
        summary: 'Bem / Ótimo',
        narrative: 'Hoje foi um dia tranquilo e produtivo',
      );

      await tester.pumpWidget(createTriggerCheckInTestApp(container: container));
      await tester.pumpAndSettle();

      // Emotional stage is marked completed
      expect(find.byKey(const Key('psicoemocional_completed_card')), findsOneWidget);
      expect(find.text('Bem / Ótimo'), findsWidgets);
      expect(find.byKey(const Key('retake_psicoemocional_button')), findsOneWidget);

      // Physical stage is still pending
      expect(find.text('Avaliação Física'), findsOneWidget);
      expect(find.byKey(const Key('start_fisica_triage_button')), findsOneWidget);
    });

    testWidgets('5. Completing physical stage displays completed summary badge',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(triggerCheckInProvider.notifier);
      notifier.completeStage(
        vertical: TriageVertical.fisica,
        summary: 'Mais ou menos',
        narrative: 'Leve desconforto lombar',
      );

      await tester.pumpWidget(createTriggerCheckInTestApp(container: container));
      await tester.pumpAndSettle();

      // Physical stage is marked completed
      expect(find.byKey(const Key('fisica_completed_card')), findsOneWidget);
      expect(find.text('Mais ou menos'), findsWidgets);
      expect(find.byKey(const Key('retake_fisica_button')), findsOneWidget);

      // Emotional stage is still pending
      expect(find.byKey(const Key('start_psicoemocional_triage_button')), findsOneWidget);
    });

    testWidgets('6. Stage with narrative displays quote block',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(triggerCheckInProvider.notifier);
      notifier.completeStage(
        vertical: TriageVertical.psicoEmocional,
        summary: 'Bem / Ótimo',
        narrative: 'Sensação de paz e clareza mental',
      );

      await tester.pumpWidget(createTriggerCheckInTestApp(container: container));
      await tester.pumpAndSettle();

      expect(find.text('“Sensação de paz e clareza mental”'), findsOneWidget);
    });

    testWidgets('7. Renders privacy-safe local AdMob banner container (AD-01)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTriggerCheckInTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(AdMobBannerContainer), findsOneWidget);
      expect(find.text('Parceiro Local • Zero rastreamento clínico'), findsOneWidget);
      expect(find.text('AD'), findsOneWidget);
    });

    testWidgets('8. Both stages completed shows dailyCheckInCompletedBanner',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(triggerCheckInProvider.notifier);
      notifier.completeStage(
        vertical: TriageVertical.psicoEmocional,
        summary: 'Bem / Ótimo',
      );
      notifier.completeStage(
        vertical: TriageVertical.fisica,
        summary: 'Normal / Bom',
      );

      await tester.pumpWidget(createTriggerCheckInTestApp(container: container));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dailyCheckInCompletedBanner')), findsOneWidget);
      expect(find.text('Bem / Ótimo'), findsWidgets);
      expect(find.text('Normal / Bom'), findsWidgets);
    });

    testWidgets('9. Tapping Refazer resets that stage and navigates to triage',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(triggerCheckInProvider.notifier);
      notifier.completeStage(
        vertical: TriageVertical.psicoEmocional,
        summary: 'Bem / Ótimo',
      );

      await tester.pumpWidget(createTriggerCheckInTestApp(container: container));
      await tester.pumpAndSettle();

      expect(find.text('Bem / Ótimo'), findsWidgets);
      final retakeBtn = find.byKey(const Key('retake_psicoemocional_button'));
      await tester.ensureVisible(retakeBtn);
      await tester.tap(retakeBtn);
      await tester.pumpAndSettle();

      // Upon tapping retake, prepareForUpdate is called and it navigates to triage
      expect(find.text('Triage Screen: psicoEmocional'), findsOneWidget);
      // Verify that the previous stage state was NOT prematurely wiped out
      final state = container.read(triggerCheckInProvider);
      expect(state.isEmotionalCompleted, isTrue);
      expect(state.emotionalSummary, 'Bem / Ótimo');
    });

    testWidgets('10. Resets values to blank when calendar date advances past 24:00h',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(triggerCheckInProvider.notifier);
      notifier.setEmotionalStatus(TriggerStatus.goodNormal);
      notifier.setPhysicalStatus(TriggerStatus.goodNormal);
      notifier.markCompletedToday();

      expect(container.read(triggerCheckInProvider).isCompletedToday, isTrue);

      final nextDay = DateTime.now().add(const Duration(days: 1));
      notifier.checkAndResetIfNewDay(nextDay);

      expect(container.read(triggerCheckInProvider).emotionalStatus, isNull);
      expect(container.read(triggerCheckInProvider).physicalStatus, isNull);
      expect(container.read(triggerCheckInProvider).isCompletedToday, isFalse);
      expect(container.read(triggerCheckInProvider).isEmotionalCompleted, isFalse);
      expect(container.read(triggerCheckInProvider).isPhysicalCompleted, isFalse);
    });

    test('11. Restores daily check-in status from remote history on rebuild/load', () async {
      final now = DateTime.now();
      final mockHistory = TriageHistoryResponse(
        logs: [
          TriageHistoryEntry(
            id: 'log-1',
            intensity: 3,
            emotionalDimension: 'depressiva_desanimo',
            disposition: 'consulta_rotina',
            recordedAt: now,
          ),
        ],
        physicalSummary: {},
        emotionalSummary: [],
        criticalRecurrences: [],
      );

      final container = ProviderContainer(
        overrides: [
          triageHistoryDataSourceProvider.overrideWithValue(
            _FakeHistoryDataSource(mockHistory),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(triggerCheckInProvider.notifier);
      await notifier.loadTodayCheckIn();

      final state = container.read(triggerCheckInProvider);
      expect(state.isCompletedToday, isTrue);
      expect(state.emotionalStatus, TriggerStatus.soSo);
      expect(state.physicalStatus, TriggerStatus.goodNormal);
      expect(state.completedAt, isNotNull);
    });

    test('12. Remote history with older daily_checkin and newer triage prioritizes the triage (Bug Regression)', () async {
      final earlier = DateTime.now().subtract(const Duration(hours: 2));
      final later = DateTime.now();

      final mockHistory = TriageHistoryResponse(
        logs: [
          // Newer triage entry
          TriageHistoryEntry(
            id: 'triage-log-newer',
            intensity: 3,
            emotionalDimension: 'somatica',
            disposition: 'consulta_rotina',
            organicPrimacyApplied: true,
            narrative: 'aperto no peito e garganta',
            stepAnswers: {'type': 'triage_checkin'},
            recordedAt: later,
          ),
          // Older checkin entry
          TriageHistoryEntry(
            id: 'checkin-log-older',
            intensity: 1,
            disposition: 'autocuidado',
            stepAnswers: {
              'type': 'daily_checkin',
              'emotionalStatus': 'goodNormal',
              'physicalStatus': 'goodNormal',
            },
            recordedAt: earlier,
          ),
        ],
        physicalSummary: {},
        emotionalSummary: [],
        criticalRecurrences: [],
      );

      final container = ProviderContainer(
        overrides: [
          triageHistoryDataSourceProvider.overrideWithValue(
            _FakeHistoryDataSource(mockHistory),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(triggerCheckInProvider.notifier);
      await notifier.loadTodayCheckIn();

      final state = container.read(triggerCheckInProvider);
      expect(state.isCompletedToday, isTrue);
      expect(state.emotionalStatus, TriggerStatus.soSo);
      expect(state.naturalLanguageText, 'aperto no peito e garganta');
    });

    testWidgets('13. Bug Regression: Narrative box does not render when narrative is "5" or empty', (tester) async {
      // 1. Verify TriggerCheckInState.fromJson sanitizes "5"
      final jsonWithDirty5 = {
        'isCompletedToday': true,
        'isPhysicalCompleted': true,
        'physicalStatus': 'soSo',
        'physicalSummary': 'Avaliação Física Registrada',
        'physicalNarrative': '5',
        'naturalLanguageText': '5',
      };
      final sanitizedState = TriggerCheckInState.fromJson(jsonWithDirty5);
      expect(sanitizedState.physicalNarrative, isNull);
      expect(sanitizedState.naturalLanguageText, isEmpty);

      // 2. Verify DualAxisTriggerCard does not render narrative container if physicalNarrative is '5'
      final containerDirty = ProviderContainer(
        overrides: [
          triggerCheckInProvider.overrideWith(
            () => _FakeTriggerCheckInNotifier(
              const TriggerCheckInState(
                isCompletedToday: true,
                isPhysicalCompleted: true,
                physicalStatus: TriggerStatus.soSo,
                physicalSummary: 'Avaliação Física Registrada',
                physicalNarrative: '5',
              ),
            ),
          ),
        ],
      );
      addTearDown(containerDirty.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: containerDirty,
          child: const MaterialApp(
            locale: Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: DualAxisTriggerCard(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('“5”'), findsNothing);
      expect(find.text('5'), findsNothing);

      // 3. Verify that if valid narrative exists, it DOES render
      final containerValid = ProviderContainer(
        overrides: [
          triggerCheckInProvider.overrideWith(
            () => _FakeTriggerCheckInNotifier(
              const TriggerCheckInState(
                isCompletedToday: true,
                isPhysicalCompleted: true,
                physicalStatus: TriggerStatus.soSo,
                physicalSummary: 'Avaliação Física Registrada',
                physicalNarrative: 'Dor de cabeça ao acordar',
              ),
            ),
          ),
        ],
      );
      addTearDown(containerValid.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: containerValid,
          child: const MaterialApp(
            locale: Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: DualAxisTriggerCard(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('“Dor de cabeça ao acordar”'), findsOneWidget);
    });

    testWidgets('14. Retaking psychoemotional stage preserves previous stage data when triage is not completed',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(triggerCheckInProvider.notifier);
      notifier.completeStage(
        vertical: TriageVertical.psicoEmocional,
        summary: 'Dimensão Somática (Psicossomática)',
        intensity: 3,
        status: TriggerStatus.soSo,
      );
      notifier.completeStage(
        vertical: TriageVertical.fisica,
        summary: 'Membros Inferiores (Pé / Dedos Direito)',
        intensity: 3,
        status: TriggerStatus.soSo,
      );

      await tester.pumpWidget(createTriggerCheckInTestApp(container: container));
      await tester.pumpAndSettle();

      // Both stages are completed initially
      expect(find.byKey(const Key('psicoemocional_completed_card')), findsOneWidget);
      expect(find.byKey(const Key('fisica_completed_card')), findsOneWidget);
      expect(find.text('Dimensão Somática (Psicossomática)'), findsOneWidget);

      // User taps "Atualizar" on Psicoemocional
      final retakeBtn = find.byKey(const Key('retake_psicoemocional_button'));
      await tester.ensureVisible(retakeBtn);
      await tester.tap(retakeBtn);
      await tester.pumpAndSettle();

      // Navigated to triage wizard
      expect(find.text('Triage Screen: psicoEmocional'), findsOneWidget);

      // Verify the state did NOT wipe out emotional completion or summary
      final state = container.read(triggerCheckInProvider);
      expect(state.isEmotionalCompleted, isTrue);
      expect(state.emotionalSummary, 'Dimensão Somática (Psicossomática)');
      expect(state.emotionalStatus, TriggerStatus.soSo);
      expect(state.emotionalIntensity, 3);
    });
  });
}

class _FakeTriggerCheckInNotifier extends TriggerCheckInNotifier {
  final TriggerCheckInState _initial;
  _FakeTriggerCheckInNotifier(this._initial);

  @override
  TriggerCheckInState build() => _initial;
}

class _FakeHistoryDataSource extends TriageHistoryRemoteDataSource {
  final TriageHistoryResponse response;
  _FakeHistoryDataSource(this.response);

  @override
  Future<TriageHistoryResponse> fetchHistory({int days = 14}) async => response;
}
