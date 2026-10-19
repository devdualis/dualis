import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dualis_mobile/core/network/connectivity_service.dart';
import 'package:dualis_mobile/core/notifications/daily_checkin_notification_service.dart';
import 'package:dualis_mobile/core/router/route_paths.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/dashboard/presentation/screens/check_in_summary_screen.dart';
import 'package:dualis_mobile/features/emergency/presentation/widgets/safety_notice_banner.dart';
import 'package:dualis_mobile/features/triage/data/antiburla_remote_data_source.dart';
import 'package:dualis_mobile/features/triage/domain/triage_vertical.dart';
import 'package:dualis_mobile/features/triage/presentation/screens/triage_wizard_screen.dart';
import 'package:dualis_mobile/features/triage/presentation/widgets/triage_intensity_selector.dart';
import 'package:dualis_mobile/features/triage/presentation/widgets/triage_preview_card.dart';
import 'package:dualis_mobile/features/triage_outcome/data/triage_outcome_remote_data_source.dart';
import 'package:dualis_mobile/features/triage_outcome/domain/triage_outcome_models.dart';
import 'package:dualis_mobile/features/triage_outcome/presentation/controllers/triage_outcome_controller.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

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

class FakeSecureStorageService extends Fake implements SecureStorageService {
  final Map<String, dynamic> _data = {};

  @override
  Future<String?> getAccessToken() async => 'mock-token';

  @override
  Future<String?> getUserId() async => 'user-1';

  @override
  Future<Map<String, dynamic>?> getDailyCheckIn(String userId) async =>
      _data[userId] as Map<String, dynamic>?;

  @override
  Future<void> saveDailyCheckIn({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    _data[userId] = data;
  }

  @override
  Future<void> clearDailyCheckIn(String userId) async {
    _data.remove(userId);
  }
}

class FakeTriageOutcomeRemoteDataSource extends TriageOutcomeRemoteDataSource {
  @override
  Future<TriageOutcome> submitTriage({
    required String vertical,
    required Map<int, String> answers,
    String? narrative,
    String? token,
    String? clientSessionId,
    String? language,
  }) async {
    return generateOfflineFallback(vertical, answers, narrative, language: language);
  }
}

class FakeAntiburlaRemoteDataSource extends AntiburlaRemoteDataSource {
  final AntiburlaCheckResult result;

  FakeAntiburlaRemoteDataSource({
    this.result = const AntiburlaCheckResult(triggered: false),
  });

  @override
  Future<AntiburlaCheckResult> checkConsistency({
    required String vertical,
    required String category,
    required String selectedPersistence,
    String? narrative,
    String? token,
  }) async {
    return result;
  }
}

Widget createTriageTestWidget({
  TriageVertical vertical = TriageVertical.psicoEmocional,
  AntiburlaRemoteDataSource? antiburlaDataSource,
  String? naturalLanguageText,
  bool mentionsSelfHarm = false,
}) {
  return ProviderScope(
    overrides: [
      antiburlaDataSourceProvider.overrideWithValue(
        antiburlaDataSource ?? FakeAntiburlaRemoteDataSource(),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      home: TriageWizardScreen(
        vertical: vertical,
        naturalLanguageText: naturalLanguageText,
        mentionsSelfHarm: mentionsSelfHarm,
      ),
    ),
  );
}

/// Taps "Mais ou menos" on the intro question (Bem/Normal · Mais ou menos ·
/// Mal/Ruim) shown before the step-0 category grid, revealing it. Every test
/// below that interacts with step-0 content must call this first.
Future<void> dismissIntroQuestion(WidgetTester tester) async {
  await tester.tap(find.text('Mais ou menos'));
  await tester.pumpAndSettle();
}

void main() {
  group('TriageWizardScreen Widget Tests', () {
    testWidgets('1. Renders "Registro emocional de hoje" banner on psicoEmocional vertical',
        (tester) async {
      await tester.pumpWidget(createTriageTestWidget(
        vertical: TriageVertical.psicoEmocional,
      ));
      await tester.pumpAndSettle();
      await dismissIntroQuestion(tester);

      expect(find.text('Registro emocional de hoje'), findsOneWidget);
      expect(find.text('Passo 1 de 5'), findsOneWidget);
      // 'Normal' is no longer a grid tile — it's handled by the intro
      // question's own Bem/Normal option, which ends the entry immediately.
      expect(find.text('Normal / Me sinto bem'), findsNothing);
      // 7 mood categories (Normal excluded from the grid on purpose).
      expect(find.text('Inquieto(a) / Agitado(a)'), findsOneWidget);
      expect(find.text('Pra baixo / Desanimado(a)'), findsOneWidget);
      expect(find.text('Estressado(a) / Esgotado(a)'), findsOneWidget);
      expect(find.text('Tensão no corpo'), findsOneWidget);
      expect(find.text('Sono ruim ou sono demais'), findsOneWidget);
      expect(find.text('Dificuldade de foco'), findsOneWidget);
      expect(find.text('Autoestima / Autoimagem'), findsOneWidget);
    });

    testWidgets('2. Renders "Registro físico de hoje" banner on fisica vertical',
        (tester) async {
      await tester.pumpWidget(createTriageTestWidget(
        vertical: TriageVertical.fisica,
      ));
      await tester.pumpAndSettle();
      await dismissIntroQuestion(tester);

      expect(find.text('Registro físico de hoje'), findsOneWidget);
      expect(find.text('Passo 1 de 5'), findsOneWidget);
      expect(find.text('Normal / Me sinto bem'), findsNothing);
      expect(find.text('Cabeça e pescoço'), findsOneWidget);
      // 12 body-area categories (Normal excluded from the grid on purpose).
      expect(find.text('Peito'), findsOneWidget);
      expect(find.text('Respiração'), findsOneWidget);
      expect(find.text('Barriga'), findsOneWidget);
      expect(find.text('Costas'), findsOneWidget);
      expect(find.text('Braços'), findsOneWidget);
      expect(find.text('Pernas'), findsOneWidget);
      expect(find.text('Tontura / formigamento'), findsOneWidget);
      expect(find.text('Região íntima / urinária'), findsOneWidget);
      expect(find.text('Pele'), findsOneWidget);
      expect(find.text('Corpo todo / cansaço'), findsOneWidget);
      expect(find.text('Sede, fome ou energia'), findsOneWidget);
    });

    testWidgets('3. "Próximo" button starts disabled when no option is selected',
        (tester) async {
      await tester.pumpWidget(createTriageTestWidget(
        vertical: TriageVertical.psicoEmocional,
      ));
      await tester.pumpAndSettle();
      await dismissIntroQuestion(tester);

      final nextButton = find.widgetWithText(FilledButton, 'Próximo');
      expect(nextButton, findsOneWidget);

      final filledButton = tester.widget<FilledButton>(nextButton);
      expect(filledButton.onPressed, isNull);
    });

    testWidgets('4. Tapping an option chip enables the "Próximo" button',
        (tester) async {
      await tester.pumpWidget(createTriageTestWidget(
        vertical: TriageVertical.psicoEmocional,
      ));
      await tester.pumpAndSettle();
      await dismissIntroQuestion(tester);

      await tester.tap(find.text('Inquieto(a) / Agitado(a)'));
      await tester.pumpAndSettle();

      final nextButton = find.widgetWithText(FilledButton, 'Próximo');
      final filledButton = tester.widget<FilledButton>(nextButton);
      expect(filledButton.onPressed, isNotNull);
    });

    testWidgets('5. Tapping "Próximo" advances to Step 2', (tester) async {
      await tester.pumpWidget(createTriageTestWidget(
        vertical: TriageVertical.psicoEmocional,
      ));
      await tester.pumpAndSettle();
      await dismissIntroQuestion(tester);

      await tester.tap(find.text('Inquieto(a) / Agitado(a)'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();

      expect(find.text('Passo 2 de 5'), findsOneWidget);
      expect(find.text('Começou hoje'), findsOneWidget);
    });

    testWidgets('6. Tapping back arrow at Step 2 returns to Step 1', (tester) async {
      await tester.pumpWidget(createTriageTestWidget(
        vertical: TriageVertical.psicoEmocional,
      ));
      await tester.pumpAndSettle();
      await dismissIntroQuestion(tester);

      await tester.tap(find.text('Inquieto(a) / Agitado(a)'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();
      expect(find.text('Passo 2 de 5'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Passo 1 de 5'), findsOneWidget);
      expect(find.text('Inquieto(a) / Agitado(a)'), findsOneWidget);
    });

    testWidgets('7. Step 4 in Physical vertical renders TriageIntensitySelector',
        (tester) async {
      await tester.pumpWidget(createTriageTestWidget(
        vertical: TriageVertical.fisica,
      ));
      await tester.pumpAndSettle();
      await dismissIntroQuestion(tester);

      final colunaChip = find.text('Costas');
      await tester.ensureVisible(colunaChip);
      await tester.pumpAndSettle();
      await tester.tap(colunaChip);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Começou agora'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();

      // Step 2 is Trigger
      await tester.tap(find.text('Pegou peso ou fez esforço lombar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();

      expect(find.text('Passo 4 de 5'), findsOneWidget);
      expect(find.byType(TriageIntensitySelector), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('8. Reaching Step 5 displays TriagePreviewCard, narrative input, and "Confirmar e Finalizar" button',
        (tester) async {
      await tester.pumpWidget(createTriageTestWidget(
        vertical: TriageVertical.psicoEmocional,
      ));
      await tester.pumpAndSettle();
      await dismissIntroQuestion(tester);

      await tester.tap(find.text('Inquieto(a) / Agitado(a)'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Começou hoje'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();

      final anxietyTriggerChip = find.text('Sobrecarga de tarefas, prazos ou expectativas');
      await tester.ensureVisible(anxietyTriggerChip);
      await tester.tap(anxietyTriggerChip);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Leve e controlável'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();

      expect(find.text('Passo 5 de 5'), findsOneWidget);
      expect(find.byType(TriagePreviewCard), findsOneWidget);
      expect(find.byKey(const Key('triageOptionalNarrativeInput')), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Confirmar e Finalizar'), findsOneWidget);
    });

    testWidgets('9. Step 3 in Physical vertical renders gastrointestinal trigger question when gastrointestinal is selected',
        (tester) async {
      await tester.pumpWidget(createTriageTestWidget(
        vertical: TriageVertical.fisica,
      ));
      await tester.pumpAndSettle();
      await dismissIntroQuestion(tester);

      final gastroChip = find.text('Barriga');
      await tester.ensureVisible(gastroChip);
      await tester.tap(gastroChip);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Começou agora'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();

      // Step 3 of 5 (Trigger / Gatilho)
      expect(find.text('Passo 3 de 5'), findsOneWidget);
      expect(
        find.text('Você ingeriu algum alimento diferente ou pesado, tomou remédios recentes ou ficou muito tempo em jejum?'),
        findsOneWidget,
      );
      expect(find.text('Alimento diferente, pesado ou suspeito'), findsOneWidget);
      expect(find.text('Uso recente de medicamento ou anti-inflamatório'), findsOneWidget);
      expect(find.text('Longo período de jejum ou estresse intenso'), findsOneWidget);
      expect(find.text('Não, começou sem relação com alimentação'), findsOneWidget);

      // Verify the generic exercise / fall options are NOT present
      expect(find.text('Sim, exercício intenso'), findsNothing);
      expect(find.text('Sim, sofri uma queda'), findsNothing);
    });

    testWidgets('10. Step 3 in Emotional vertical renders specialized sleep trigger question when Sono is selected',
        (tester) async {
      await tester.pumpWidget(createTriageTestWidget(
        vertical: TriageVertical.psicoEmocional,
      ));
      await tester.pumpAndSettle();
      await dismissIntroQuestion(tester);

      final sonoChip = find.text('Sono ruim ou sono demais');
      await tester.ensureVisible(sonoChip);
      await tester.tap(sonoChip);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Começou hoje'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Próximo'));
      await tester.pumpAndSettle();

      // Step 3 of 5 (Trigger / Gatilho for Sleep)
      expect(find.text('Passo 3 de 5'), findsOneWidget);
      expect(
        find.text('Qual tem sido a principal dificuldade que atrapalha suas noites de sono?'),
        findsOneWidget,
      );
      expect(find.text('Cabeça acelerada / pensamentos na hora de dormir'), findsOneWidget);
      expect(find.text('Acordar no meio da noite e não conseguir voltar a dormir'), findsOneWidget);
      expect(find.text('Sono leve, agitado, com pesadelos ou despertares'), findsOneWidget);
      expect(find.text('Uso de celular/telas até tarde ou horários irregulares'), findsOneWidget);
      expect(find.text('Não sei identificar, surgiu de repente'), findsOneWidget);

      // Verify generic emotional options are NOT present
      expect(find.text('Trabalho / Estudos'), findsNothing);
      expect(find.text('Família / Relacionamentos'), findsNothing);
    });

    testWidgets('11. Intro question shows Bem/Normal, Mais ou menos and Mal/Ruim options',
        (tester) async {
      await tester.pumpWidget(createTriageTestWidget(
        vertical: TriageVertical.psicoEmocional,
      ));
      await tester.pumpAndSettle();

      // The entry question precedes the step-0 grid: no step counter yet.
      expect(find.text('Passo 1 de 5'), findsNothing);
      expect(find.text('Bem / Normal'), findsOneWidget);
      expect(find.text('Mais ou menos'), findsOneWidget);
      expect(find.text('Mal / Ruim'), findsOneWidget);
    });

    testWidgets('12. Psycho-emotional vertical: Selecting Normal skips onset step 2 and shows the emotional trend',
        (tester) async {
      final fakeOutcomeDataSource = FakeTriageOutcomeRemoteDataSource();
      final router = GoRouter(
        initialLocation: RoutePaths.triage,
        routes: [
          GoRoute(
            path: RoutePaths.home,
            builder: (context, state) => const Scaffold(body: Text('Home Screen Destination')),
          ),
          GoRoute(
            path: RoutePaths.checkInSummary,
            builder: (context, state) {
              final args = state.extra as CheckInSummaryArgs;
              return Scaffold(
                body: Text(
                  'Summary map=${args.showBodyMap} emotional=${args.showEmotionalTrend}',
                ),
              );
            },
          ),
          GoRoute(
            path: RoutePaths.triage,
            builder: (context, state) => const TriageWizardScreen(vertical: TriageVertical.psicoEmocional),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            antiburlaDataSourceProvider.overrideWithValue(FakeAntiburlaRemoteDataSource()),
            triageOutcomeDataSourceProvider.overrideWithValue(fakeOutcomeDataSource),
            connectivityServiceProvider.overrideWithValue(FakeConnectivityService()),
            dailyCheckinNotificationServiceProvider.overrideWithValue(FakeDailyCheckinNotificationService()),
            secureStorageServiceProvider.overrideWithValue(FakeSecureStorageService()),
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
            supportedLocales: const [Locale('pt', 'BR')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // "Bem / Normal" on the intro question ends today's entry directly —
      // there is no separate category chip + confirm button for it anymore.
      final goodOption = find.text('Bem / Normal');
      expect(goodOption, findsOneWidget);
      await tester.tap(goodOption);
      await tester.pump(); // Advance one frame to check intermediate state

      // CRITICAL: Ensure Step 2 / onset question is NOT rendered
      expect(find.text('Passo 2 de 5'), findsNothing);
      expect(find.text('Começou hoje'), findsNothing);

      await tester.pumpAndSettle();

      // Shows the emotional trend before returning Home
      expect(find.text('Summary map=false emotional=true'), findsOneWidget);
    });

    testWidgets('13. Physical vertical: Selecting Normal skips the onset question and shows the body map',
        (tester) async {
      final fakeOutcomeDataSource = FakeTriageOutcomeRemoteDataSource();
      final router = GoRouter(
        initialLocation: RoutePaths.triage,
        routes: [
          GoRoute(
            path: RoutePaths.home,
            builder: (context, state) => const Scaffold(body: Text('Home Screen Destination')),
          ),
          GoRoute(
            path: RoutePaths.checkInSummary,
            builder: (context, state) {
              final args = state.extra as CheckInSummaryArgs;
              return Scaffold(
                body: Text(
                  'Summary map=${args.showBodyMap} emotional=${args.showEmotionalTrend}',
                ),
              );
            },
          ),
          GoRoute(
            path: RoutePaths.triage,
            builder: (context, state) => const TriageWizardScreen(vertical: TriageVertical.fisica),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            antiburlaDataSourceProvider.overrideWithValue(FakeAntiburlaRemoteDataSource()),
            triageOutcomeDataSourceProvider.overrideWithValue(fakeOutcomeDataSource),
            connectivityServiceProvider.overrideWithValue(FakeConnectivityService()),
            dailyCheckinNotificationServiceProvider.overrideWithValue(FakeDailyCheckinNotificationService()),
            secureStorageServiceProvider.overrideWithValue(FakeSecureStorageService()),
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
            supportedLocales: const [Locale('pt', 'BR')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final goodOption = find.text('Bem / Normal');
      expect(goodOption, findsOneWidget);
      await tester.tap(goodOption);
      await tester.pump();

      // CRITICAL: Ensure Step 2 / onset question is NOT rendered
      expect(find.text('Passo 2 de 5'), findsNothing);
      expect(find.text('Começou agora'), findsNothing);

      await tester.pumpAndSettle();

      // Shows the body map before returning Home
      expect(find.text('Summary map=true emotional=false'), findsOneWidget);
    });
  });

  group('TriageWizardScreen safety notice wiring', () {
    const bannerKey = Key('safety_notice_banner');

    String bannerText(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(const Key('safety_notice_text'))).data!;

    testWidgets('self-harm phrase in the text typed on Home shows the crisis banner',
        (tester) async {
      addTearDown(SafetyNotice.hide);
      await tester.pumpWidget(createTriageTestWidget(
        naturalLanguageText: 'hoje eu quero morrer',
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(bannerKey), findsOneWidget);
      expect(find.byKey(const Key('safety_notice_open_resources')), findsOneWidget);
      // Non-blocking: the wizard stays usable under the banner, starting
      // with the intro question.
      expect(find.text('Bem / Normal'), findsOneWidget);

      await dismissIntroQuestion(tester);
      expect(find.text('Passo 1 de 5'), findsOneWidget);
      expect(find.text('Inquieto(a) / Agitado(a)'), findsOneWidget);
    });

    testWidgets('mentionsSelfHarm from the AI shows the same crisis banner, even for neutral text',
        (tester) async {
      addTearDown(SafetyNotice.hide);
      await tester.pumpWidget(createTriageTestWidget(
        naturalLanguageText: 'hoje eu quero morrer',
      ));
      await tester.pumpAndSettle();
      final fromPhrase = bannerText(tester);
      SafetyNotice.hide();
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(createTriageTestWidget(
        naturalLanguageText: 'dormi pouco esta semana',
        mentionsSelfHarm: true,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(bannerKey), findsOneWidget);
      expect(bannerText(tester), fromPhrase, reason: 'same card for everyone');
    });

    testWidgets('warning-sign text shows the generic notice, different from the crisis text',
        (tester) async {
      addTearDown(SafetyNotice.hide);
      await tester.pumpWidget(createTriageTestWidget(
        vertical: TriageVertical.fisica,
        naturalLanguageText: 'quero morrer',
      ));
      await tester.pumpAndSettle();
      final crisisText = bannerText(tester);
      SafetyNotice.hide();
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(createTriageTestWidget(
        vertical: TriageVertical.fisica,
        naturalLanguageText: 'dor forte no peito',
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(bannerKey), findsOneWidget);
      expect(bannerText(tester), isNot(crisisText));
    });

    testWidgets('neutral text shows no banner', (tester) async {
      addTearDown(SafetyNotice.hide);
      await tester.pumpWidget(createTriageTestWidget(
        naturalLanguageText: 'dormi pouco esta semana',
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(bannerKey), findsNothing);
    });

    testWidgets('no text shows no banner', (tester) async {
      addTearDown(SafetyNotice.hide);
      await tester.pumpWidget(createTriageTestWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(bannerKey), findsNothing);
    });
  });
}
