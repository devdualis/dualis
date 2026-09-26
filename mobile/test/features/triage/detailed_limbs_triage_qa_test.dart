import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dualis_mobile/features/triage/domain/triage_question_bank.dart';
import 'package:dualis_mobile/features/triage/domain/triage_vertical.dart';
import 'package:dualis_mobile/features/triage/presentation/widgets/triage_preview_card.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

Widget createPreviewCardTestApp({
  required Map<int, String> answers,
}) {
  return MaterialApp(
    locale: const Locale('pt', 'BR'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TriagePreviewCard(
            vertical: TriageVertical.fisica,
            answers: answers,
            activeColor: Colors.teal,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('QA Feature 5: Detalhe de membros inferiores e superiores com lateralidade', () {
    test('QA 5.1: Membros Superiores question contains all detailed regions with lateralidade', () {
      final questions = TriageQuestionBank.forVertical(
        TriageVertical.fisica,
        systemKey: 'membros_superiores',
      );
      final step2 = questions[2];
      expect(step2.questionKey, equals('triageQ4MembrosSuperiores'));

      final optionKeys = step2.options.map((o) => o.key).toList();

      // Right side
      expect(optionKeys, contains('ombro_direito'));
      expect(optionKeys, contains('braco_direito'));
      expect(optionKeys, contains('cotovelo_direito'));
      expect(optionKeys, contains('antebraco_direito'));
      expect(optionKeys, contains('punho_direito'));
      expect(optionKeys, contains('mao_dedos_direito'));

      // Left side
      expect(optionKeys, contains('ombro_esquerdo'));
      expect(optionKeys, contains('braco_esquerdo'));
      expect(optionKeys, contains('cotovelo_esquerdo'));
      expect(optionKeys, contains('antebraco_esquerdo'));
      expect(optionKeys, contains('punho_esquerdo'));
      expect(optionKeys, contains('mao_dedos_esquerdo'));

      // Bilateral
      expect(optionKeys, contains('membros_superiores_bilateral'));
    });

    test('QA 5.2: Membros Inferiores question contains all detailed regions with lateralidade', () {
      final questions = TriageQuestionBank.forVertical(
        TriageVertical.fisica,
        systemKey: 'membros_inferiores',
      );
      final step2 = questions[2];
      expect(step2.questionKey, equals('triageQ4MembrosInferiores'));

      final optionKeys = step2.options.map((o) => o.key).toList();

      // Right side
      expect(optionKeys, contains('coxa_quadril_direito'));
      expect(optionKeys, contains('joelho_direito'));
      expect(optionKeys, contains('canela_panturrilha_direito'));
      expect(optionKeys, contains('tornozelo_direito'));
      expect(optionKeys, contains('pe_dedos_direito'));

      // Left side
      expect(optionKeys, contains('coxa_quadril_esquerdo'));
      expect(optionKeys, contains('joelho_esquerdo'));
      expect(optionKeys, contains('canela_panturrilha_esquerdo'));
      expect(optionKeys, contains('tornozelo_esquerdo'));
      expect(optionKeys, contains('pe_dedos_esquerdo'));

      // Bilateral
      expect(optionKeys, contains('membros_inferiores_bilateral'));
    });

    testWidgets('QA 5.3: TriagePreviewCard renders human-readable Ombro Direito on step 2 answer',
        (WidgetTester tester) async {
      final answers = {
        0: 'membros_superiores',
        1: 'comecou_agora',
        2: 'ombro_direito',
        3: '3',
      };

      await tester.pumpWidget(createPreviewCardTestApp(answers: answers));
      await tester.pumpAndSettle();

      expect(find.text('Ombro Direito'), findsOneWidget);
      expect(find.text('Membros Superiores D/E'), findsOneWidget);
      expect(find.text('Começou agora'), findsOneWidget);
    });

    testWidgets('QA 5.4: TriagePreviewCard renders human-readable Joelho Esquerdo on step 2 answer',
        (WidgetTester tester) async {
      final answers = {
        0: 'membros_inferiores',
        1: 'ha_alguns_dias',
        2: 'joelho_esquerdo',
        3: '4',
      };

      await tester.pumpWidget(createPreviewCardTestApp(answers: answers));
      await tester.pumpAndSettle();

      expect(find.text('Joelho Esquerdo'), findsOneWidget);
      expect(find.text('Membros Inferiores D/E'), findsOneWidget);
      expect(find.text('Há alguns dias'), findsOneWidget);
    });

    testWidgets('QA 5.5: TriagePreviewCard renders bilateral limb options correctly',
        (WidgetTester tester) async {
      final answers = {
        0: 'membros_superiores',
        1: 'e_cronica',
        2: 'membros_superiores_bilateral',
        3: '2',
      };

      await tester.pumpWidget(createPreviewCardTestApp(answers: answers));
      await tester.pumpAndSettle();

      expect(find.text('Ambos os Membros Superiores (Bilateral)'), findsOneWidget);
    });
  });
}
