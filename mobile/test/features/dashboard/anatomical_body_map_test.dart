import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/dashboard/domain/models/triage_history_models.dart';
import 'package:dualis_mobile/features/dashboard/presentation/widgets/anatomical_body_map.dart';
import 'package:dualis_mobile/features/dashboard/presentation/widgets/retrospective_list_view.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

void main() {
  group('AnatomicalBodyMap & RetrospectiveListView Widget Tests (DASH-02, DASH-04)', () {
    testWidgets('1. AnatomicalBodyMap renders silhouette canvas and legend bar', (tester) async {
      final summary = {
        'cabeca_pescoco': 4,
        'coluna_dorsal': 2,
        'cardiovascular_torax': 0,
      };

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AnatomicalBodyMap(physicalSummary: summary),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('Sem registro'), findsOneWidget);
      expect(find.text('Leve (1-2)'), findsOneWidget);
      expect(find.text('Moderada (3)'), findsOneWidget);
      expect(find.text('Intensa (4-5)'), findsOneWidget);
    });

    testWidgets('2. Tapping on body map displays region details card', (tester) async {
      final summary = {
        'cabeca_pescoco': 4,
        'coluna_dorsal': 3,
      };

      String? tappedKey;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AnatomicalBodyMap(
              physicalSummary: summary,
              onRegionSelected: (key) => tappedKey = key,
            ),
          ),
        ),
      );

      final gestureDetector = find.byKey(const Key('body_map_gesture_detector'));
      expect(gestureDetector, findsOneWidget);

      await tester.tap(gestureDetector);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('body_map_detail_card')), findsOneWidget);
      expect(tappedKey, isNotNull);
    });

    testWidgets('2b. Supports coluna_dor_dorsal key in physicalSummary and displays detail card', (tester) async {
      final summary = {
        'coluna_dor_dorsal': 3,
      };

      String? tappedKey;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AnatomicalBodyMap(
              physicalSummary: summary,
              onRegionSelected: (key) => tappedKey = key,
            ),
          ),
        ),
      );

      final gestureDetector = find.byKey(const Key('body_map_gesture_detector'));
      final center = tester.getCenter(gestureDetector);
      final size = tester.getSize(gestureDetector);
      await tester.tapAt(Offset(center.dx, center.dy - size.height * 0.20));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('body_map_detail_card')), findsOneWidget);
      expect(tappedKey, equals('coluna_dorsal'));
      expect(find.text('Costas'), findsOneWidget);
      expect(find.textContaining('Maior intensidade informada nos últimos 14 dias: 3/5'), findsOneWidget);
    });

    testWidgets('2c. Supports general membros_superiores key in physicalSummary as fallback', (tester) async {
      final summary = {
        'membros_superiores': 3,
      };

      String? tappedKey;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AnatomicalBodyMap(
              physicalSummary: summary,
              onRegionSelected: (key) => tappedKey = key,
            ),
          ),
        ),
      );

      final gestureDetector = find.byKey(const Key('body_map_gesture_detector'));
      final topLeft = tester.getTopLeft(gestureDetector);
      final size = tester.getSize(gestureDetector);
      // Tap on left arm (relativeBounds LTWH(0.18, 0.18, 0.16, 0.32))
      await tester.tapAt(Offset(topLeft.dx + size.width * 0.25, topLeft.dy + size.height * 0.25));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('body_map_detail_card')), findsOneWidget);
      expect(tappedKey, equals('membros_superiores_d'));
      expect(find.text('Braço direito'), findsOneWidget);
      expect(find.textContaining('Maior intensidade informada nos últimos 14 dias: 3/5'), findsOneWidget);
    });

    testWidgets('2d. Tapping left arm (E) when right arm (D) has level 3 displays cross-limb notice and switch action', (tester) async {
      final summary = {
        'membros_superiores_d': 3,
        'membros_superiores_e': 0,
      };

      String? tappedKey;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AnatomicalBodyMap(
              physicalSummary: summary,
              onRegionSelected: (key) => tappedKey = key,
            ),
          ),
        ),
      );

      final gestureDetector = find.byKey(const Key('body_map_gesture_detector'));
      final topLeft = tester.getTopLeft(gestureDetector);
      final size = tester.getSize(gestureDetector);
      // Tap on right arm from viewer perspective / left arm of body: relativeBounds LTWH(0.66, 0.18, 0.16, 0.32)
      await tester.tapAt(Offset(topLeft.dx + size.width * 0.72, topLeft.dy + size.height * 0.25));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('body_map_detail_card')), findsOneWidget);
      expect(tappedKey, equals('membros_superiores_e'));
      expect(find.text('Braço esquerdo'), findsOneWidget);
      expect(find.textContaining('(Braço direito: intensidade informada 3/5)'), findsOneWidget);

      // Tap on switch action to select right arm
      await tester.tap(find.text('Ver Braço direito'));
      await tester.pumpAndSettle();

      expect(find.text('Braço direito'), findsOneWidget);
      expect(find.textContaining('Maior intensidade informada nos últimos 14 dias: 3/5'), findsOneWidget);
      expect(find.text('3/5'), findsOneWidget);
    });

    testWidgets('2e. Tapping systemic chip (Endócrino / Pele / Muscular) updates detail card with correct level', (tester) async {
      final summary = {
        'endocrino_metabolico': 2,
        'muscular_geral_sistemico': 3,
        'dermatologico': 1,
      };

      String? tappedKey;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: AnatomicalBodyMap(
                physicalSummary: summary,
                onRegionSelected: (key) => tappedKey = key,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Energia'), findsOneWidget);
      await tester.tap(find.text('Energia'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('body_map_detail_card')), findsOneWidget);
      expect(tappedKey, equals('endocrino_metabolico'));
      expect(find.text('Sede, fome ou energia'), findsOneWidget);
      expect(find.textContaining('Maior intensidade informada nos últimos 14 dias: 2/5'), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('body_map_detail_card')), matching: find.text('2/5')), findsOneWidget);
    });

    testWidgets('2f. Switching to Todos os 12 Sistemas displays full matrix and selects any system', (tester) async {
      final summary = {
        'respiratorio': 2,
        'neurologico': 3,
        'endocrino_metabolico': 2,
      };

      String? tappedKey;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: AnatomicalBodyMap(
                physicalSummary: summary,
                onRegionSelected: (key) => tappedKey = key,
              ),
            ),
          ),
        ),
      );

      // Switch to Todos os 12 Sistemas view
      await tester.tap(find.text('Todas as áreas'));
      await tester.pumpAndSettle();

      expect(find.text('Cabeça'), findsOneWidget);
      expect(find.text('Tronco'), findsOneWidget);
      expect(find.text('Braços e pernas'), findsOneWidget);
      expect(find.text('Corpo todo e pele'), findsOneWidget);
      expect(find.text('Respiração'), findsOneWidget);
      expect(find.text('Tontura / formigamento'), findsOneWidget);

      // Tap on Respiratório
      await tester.tap(find.text('Respiração'));
      await tester.pumpAndSettle();

      expect(tappedKey, equals('respiratorio'));
      expect(find.byKey(const Key('body_map_detail_card')), findsOneWidget);
      expect(find.textContaining('Maior intensidade informada nos últimos 14 dias: 2/5'), findsOneWidget);
    });

    testWidgets('3. RetrospectiveListView renders entries with formatted date and category', (tester) async {
      final entries = [
        TriageHistoryEntry(
          id: 'log-1',
          intensity: 4,
          anatomicalSystem: 'coluna_dorsal',
          emotionalDimension: null,
          stepAnswers: {'causes': 'postura incorreta no trabalho'},
          recordedAt: DateTime.parse('2026-09-14T10:30:00.000Z'),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: RetrospectiveListView(
                entries: entries,
                verticalFilter: 'physical',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Intensidade informada: 4/5'), findsOneWidget);
      expect(find.text('COSTAS'), findsOneWidget);
      expect(find.textContaining('postura incorreta'), findsOneWidget);
      // No levels and no care recommendation in the journal history.
      expect(find.text('Nível 4'), findsNothing);
      expect(find.text('Consulta de Rotina'), findsNothing);
    });

    testWidgets('4. RetrospectiveListView displays empty state when no records exist', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RetrospectiveListView(
              entries: [],
              verticalFilter: 'physical',
            ),
          ),
        ),
      );

      expect(find.text('Nenhum registro anterior'), findsOneWidget);
      expect(find.text('Os seus check-ins diários concluídos aparecerão aqui.'), findsOneWidget);
    });

    testWidgets('5. RetrospectiveListView renders delete icon when onDeleteEntry is provided', (tester) async {
      String? deletedId;
      final entries = [
        TriageHistoryEntry(
          id: 'log-delete-target',
          intensity: 3,
          anatomicalSystem: 'coluna_dorsal',
          emotionalDimension: null,
          stepAnswers: {'causes': 'dor nas costas'},
          recordedAt: DateTime.parse('2026-09-14T10:30:00.000Z'),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: RetrospectiveListView(
                entries: entries,
                verticalFilter: 'physical',
                onDeleteEntry: (id) async {
                  deletedId = id;
                  return true;
                },
              ),
            ),
          ),
        ),
      );

      final deleteButton = find.byKey(const Key('delete_history_item_log-delete-target'));
      expect(deleteButton, findsOneWidget);

      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      final confirmButton = find.byKey(const Key('confirm_delete_history_item_button'));
      expect(confirmButton, findsOneWidget);

      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      expect(deletedId, equals('log-delete-target'));
    });
  });
}
