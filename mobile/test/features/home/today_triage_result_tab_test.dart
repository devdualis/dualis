import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/home/domain/trigger_checkin_state.dart';
import 'package:dualis_mobile/features/home/presentation/controllers/trigger_checkin_controller.dart';
import 'package:dualis_mobile/features/home/presentation/widgets/today_triage_result_tab.dart';
import 'package:dualis_mobile/features/triage_outcome/domain/triage_outcome_models.dart';
import 'package:dualis_mobile/features/triage_outcome/presentation/controllers/triage_outcome_controller.dart';
import 'package:dualis_mobile/features/triage_outcome/presentation/widgets/wellness_guidance_block.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

Widget createTestWrapper({
  required Widget child,
  TriageOutcome? outcome,
  TriggerCheckInState? triggerCheckInState,
}) {
  return ProviderScope(
    overrides: [
      if (outcome != null)
        triageOutcomeProvider.overrideWith(
          () => _TestTriageOutcomeNotifier(
            TriageOutcomeState(outcome: outcome),
          ),
        ),
      if (triggerCheckInState != null)
        triggerCheckInProvider.overrideWith(
          () => _TestTriggerCheckInNotifier(triggerCheckInState),
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
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: child,
      ),
    ),
  );
}

class _TestTriageOutcomeNotifier extends TriageOutcomeNotifier {
  final TriageOutcomeState _initial;
  _TestTriageOutcomeNotifier(this._initial);

  @override
  TriageOutcomeState build() => _initial;
}

class _TestTriggerCheckInNotifier extends TriggerCheckInNotifier {
  final TriggerCheckInState _initial;
  _TestTriggerCheckInNotifier(this._initial);

  @override
  TriggerCheckInState build() => _initial;
}

void main() {
  group('TodayTriageResultTab Widget Tests', () {
    testWidgets('Renders pending check-in view when no triage or check-in completed today',
        (WidgetTester tester) async {
      bool calledGoToCheckIn = false;

      await tester.pumpWidget(
        createTestWrapper(
          child: TodayTriageResultTab(
            onGoToCheckIn: () => calledGoToCheckIn = true,
          ),
          triggerCheckInState: const TriggerCheckInState(isCompletedToday: false),
        ),
      );
      await tester.pumpAndSettle();

      // The top "Estado Geral de Hoje" / "Pendente" header was removed: it
      // was redundant with "Nenhum registro hoje" below.
      expect(find.text('Estado Geral de Hoje'), findsNothing);
      expect(find.text('Pendente'), findsNothing);
      expect(find.text('Nenhum registro hoje'), findsOneWidget);
      expect(find.text('Realizar Check-in Agora'), findsOneWidget);
      expect(find.text('Leituras sobre bem-estar'), findsOneWidget);

      await tester.tap(find.byKey(const Key('today_start_checkin_cta_button')));
      await tester.pumpAndSettle();
      expect(calledGoToCheckIn, isTrue);
    });

    testWidgets('Renders full triage outcome with category, intensity, and general readings',
        (WidgetTester tester) async {
      final mockOutcome = TriageOutcome(
        id: 'out-123',
        vertical: 'physical',
        intensityScore: 3,
        primaryCategory: 'coluna_dorsal',
        categoryLabel: 'Coluna e Dor Dorsal',
        somaticMapping: 'Dor paravertebral postural leve',
        recommendedArticles: const [
          RecommendedArticle(
            id: 'art-coluna-1',
            title: 'Alongamento para Coluna Lombar',
            category: 'coluna',
            author: 'Sociedade Brasileira de Ortopedia e Traumatologia',
            authorRole: 'Fonte',
            readTimeMinutes: 4,
            summary: 'Exercícios práticos para alívio de sobrecarga postural.',
            url: 'https://sbot.org.br/dor-lombar-quais-os-motivos/',
          ),
        ],
        recordedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWrapper(
          child: TodayTriageResultTab(
            onGoToCheckIn: () {},
          ),
          outcome: mockOutcome,
          triggerCheckInState: const TriggerCheckInState(isCompletedToday: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Coluna e Dor Dorsal'), findsOneWidget);
      expect(find.text('Dor paravertebral postural leve'), findsOneWidget);
      expect(find.text('Leituras sobre bem-estar'), findsOneWidget);
      // General readings only: the article sent with the entry is not shown.
      expect(find.text('Alongamento para Coluna Lombar'), findsNothing);
      expect(find.text('Higiene do Sono e Repouso Restaurador'), findsOneWidget);
      expect(find.text('Atualizar registro de hoje'), findsOneWidget);
      // The top "Estado Geral de Hoje" header (with its "Registro concluído"
      // badge) and the standalone "Intensidade que você informou" meter were
      // removed: both were redundant with the axis cards' own tier badges.
      expect(find.text('Registro concluído'), findsNothing);
      expect(find.text('Intensidade que você informou'), findsNothing);
      expect(find.text('3 / 5'), findsNothing);
      expect(find.byType(WellnessGuidanceBlock), findsOneWidget);
      expect(find.text('Consulta de Rotina'), findsNothing);
    });

    testWidgets('Renders wellness check-in confirmation view with preventive articles',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWrapper(
          child: TodayTriageResultTab(
            onGoToCheckIn: () {},
          ),
          triggerCheckInState: const TriggerCheckInState(
            isCompletedToday: true,
            emotionalStatus: TriggerStatus.goodNormal,
            physicalStatus: TriggerStatus.goodNormal,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Check-in de Bem-Estar Confirmado'), findsOneWidget);
      expect(find.text('Leituras sobre bem-estar'), findsOneWidget);
      expect(find.text('Conteúdos educativos gerais. Não são orientação para o seu caso.'), findsOneWidget);
      expect(find.text('Higiene do Sono e Repouso Restaurador'), findsOneWidget);
      expect(find.text('Revisar Respostas do Check-in'), findsOneWidget);
    });

    testWidgets('Renders symptom check-in view when user reported badSick / soSo and text',
        (WidgetTester tester) async {
      bool calledGoToCheckIn = false;

      await tester.pumpWidget(
        createTestWrapper(
          child: TodayTriageResultTab(
            onGoToCheckIn: () => calledGoToCheckIn = true,
          ),
          triggerCheckInState: const TriggerCheckInState(
            isCompletedToday: true,
            emotionalStatus: TriggerStatus.badSick,
            physicalStatus: TriggerStatus.soSo,
            naturalLanguageText: 'coceira no braco',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sintomas Registrados no Check-in'), findsOneWidget);
      expect(find.text('1. Eixo Psico-Emocional'), findsOneWidget);
      expect(find.text('Mal / Ruim'), findsOneWidget);
      expect(find.text('2. Eixo Avaliação Física'), findsOneWidget);
      expect(find.text('Mais ou menos'), findsOneWidget);
      expect(find.text('Relato: "coceira no braco"'), findsOneWidget);
      expect(find.text('Leituras relacionadas ao tema que você registrou'), findsNothing);

      // General readings, never chosen from what was written
      expect(find.text('Prurido Cutâneo, Alergias e Cuidados com a Pele'), findsNothing);
      expect(find.text('Higiene do Sono e Repouso Restaurador'), findsOneWidget);

      // Verify CTA button
      expect(find.text('Fazer registro detalhado'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('today_start_full_triage_button')));
      await tester.tap(find.byKey(const Key('today_start_full_triage_button')));
      await tester.pumpAndSettle();
      expect(calledGoToCheckIn, isTrue);
    });

    testWidgets('Renders full triage outcome even when triggerCheckInState is goodNormal (Bug Regression)',
        (WidgetTester tester) async {
      final mockOutcome = TriageOutcome(
        id: 'out-regression-1',
        vertical: 'emotional',
        intensityScore: 3,
        primaryCategory: 'somatica',
        categoryLabel: 'Emoções sentidas no corpo',
        somaticMapping: 'Nó na garganta e aperto no peito',
        recommendedArticles: const [],
        recordedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWrapper(
          child: TodayTriageResultTab(onGoToCheckIn: () {}),
          outcome: mockOutcome,
          // Even if triggerCheckInState is goodNormal (wellness), outcome takes precedence!
          triggerCheckInState: const TriggerCheckInState(
            isCompletedToday: true,
            emotionalStatus: TriggerStatus.goodNormal,
            physicalStatus: TriggerStatus.goodNormal,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Must render full outcome, NOT wellness view
      expect(find.text('Emoções sentidas no corpo'), findsOneWidget);
      expect(find.byType(WellnessGuidanceBlock), findsOneWidget);
      expect(find.textContaining('Primazia Orgânica'), findsNothing);
      expect(find.text('Check-in de Bem-Estar Confirmado'), findsNothing);
    });
  });
}
