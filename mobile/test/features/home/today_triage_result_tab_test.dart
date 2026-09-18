import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/home/domain/trigger_checkin_state.dart';
import 'package:dualis_mobile/features/home/presentation/controllers/trigger_checkin_controller.dart';
import 'package:dualis_mobile/features/home/presentation/widgets/today_triage_result_tab.dart';
import 'package:dualis_mobile/features/triage_outcome/domain/triage_outcome_models.dart';
import 'package:dualis_mobile/features/triage_outcome/presentation/controllers/triage_outcome_controller.dart';
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

      expect(find.text('Estado Geral de Hoje'), findsOneWidget);
      expect(find.text('Pendente'), findsOneWidget);
      expect(find.text('Nenhuma avaliação realizada hoje'), findsOneWidget);
      expect(find.text('Realizar Check-in Agora'), findsOneWidget);
      expect(find.text('Artigos Sugeridos para Você'), findsOneWidget);

      await tester.tap(find.byKey(const Key('today_start_checkin_cta_button')));
      await tester.pumpAndSettle();
      expect(calledGoToCheckIn, isTrue);
    });

    testWidgets('Renders full triage outcome with category, intensity, and suggested articles',
        (WidgetTester tester) async {
      final mockOutcome = TriageOutcome(
        id: 'out-123',
        vertical: 'physical',
        intensityScore: 3,
        careDisposition: CareDisposition.routineConsultation,
        primaryCategory: 'coluna_dorsal',
        categoryLabel: 'Coluna e Dor Dorsal',
        somaticMapping: 'Dor paravertebral postural leve',
        organicPrimacyApplied: false,
        recommendedArticles: const [
          RecommendedArticle(
            id: 'art-coluna-1',
            title: 'Alongamento para Coluna Lombar',
            category: 'coluna',
            author: 'Dr. Marcos Lima',
            authorRole: 'Fisioterapeuta Especialista em Coluna',
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
      expect(find.text('Artigos Sugeridos para Você'), findsOneWidget);
      expect(find.text('Alongamento para Coluna Lombar'), findsOneWidget);
      expect(find.text('Atualizar Triagem de Hoje'), findsOneWidget);
      expect(find.text('Triagem Concluída'), findsOneWidget);
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

      expect(find.text('Bem-Estar Confirmado'), findsOneWidget);
      expect(find.text('Check-in de Bem-Estar Confirmado'), findsOneWidget);
      expect(find.text('Artigos Preventivos do Dia'), findsOneWidget);
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

      expect(find.text('Sintomas Registrados'), findsOneWidget);
      expect(find.text('Sintomas Registrados no Check-in'), findsOneWidget);
      expect(find.text('1. Eixo Psico-Emocional'), findsOneWidget);
      expect(find.text('Mal / Ruim'), findsOneWidget);
      expect(find.text('2. Eixo Avaliação Física'), findsOneWidget);
      expect(find.text('Mais ou menos'), findsOneWidget);
      expect(find.text('Relato: "coceira no braco"'), findsOneWidget);
      expect(find.text('Artigos Sugeridos para Seus Sintomas'), findsOneWidget);

      // Verify tailored articles for skin / pruritus / upper limbs are suggested
      expect(find.text('Prurido Cutâneo, Alergias e Cuidados com a Pele'), findsOneWidget);
      expect(find.text('Sobrecarga Musculoesquelética em Braços e Ombros'), findsOneWidget);

      // Verify CTA button
      expect(find.text('Completar Triagem Clínica Detalhada'), findsOneWidget);
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
        careDisposition: CareDisposition.routineConsultation,
        primaryCategory: 'somatica',
        categoryLabel: 'Dimensão Somática (Psicossomática)',
        somaticMapping: 'Manifestação somatizada de sobrecarga emocional (nó na garganta / aperto torácico)',
        organicPrimacyApplied: true,
        organicPrimacyNotice: 'Atenção Clínica (Primazia Orgânica): Sintomas físicos concorrentes exigem que causas orgânicas sejam avaliadas presencialmente por um médico antes de atribuí-los unicamente ao estresse psicológico.',
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
      expect(find.text('Dimensão Somática (Psicossomática)'), findsOneWidget);
      expect(find.text('Triagem Concluída'), findsOneWidget);
      expect(find.textContaining('Primazia Orgânica'), findsWidgets);
      expect(find.text('Check-in de Bem-Estar Confirmado'), findsNothing);
    });
  });
}
