import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/dashboard/domain/models/triage_history_models.dart';
import 'package:dualis_mobile/features/dashboard/presentation/widgets/delete_history_item_dialog.dart';

void main() {
  group('DeleteHistoryItemDialog Widget Tests', () {
    final testEntry = TriageHistoryEntry(
      id: 'entry-test-123',
      intensity: 3,
      disposition: 'consulta_rotina',
      anatomicalSystem: 'cardiovascular_torax',
      recordedAt: DateTime(2026, 9, 27, 14, 30),
      narrative: 'Sensação de aperto no peito após estresse intenso no trabalho.',
      stepAnswers: {
        'causes': 'Pressão e sobrecarga de trabalho',
      },
    );

    testWidgets('1. Renders title, danger icon, record snapshot, and action buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeleteHistoryItemDialog(
              entry: testEntry,
              onDelete: (_) async => true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_forever_rounded), findsOneWidget);
      expect(find.text('Descartar Registro'), findsOneWidget);
      expect(
        find.textContaining('Tem certeza de que deseja descartar este registro'),
        findsOneWidget,
      );
      expect(find.textContaining('27/09/2026 às 14:30'), findsOneWidget);
      expect(find.text('CARDIOVASCULAR / TÓRAX'), findsOneWidget);
      expect(find.text('Nível 3'), findsOneWidget);
      expect(
        find.text('"Sensação de aperto no peito após estresse intenso no trabalho."'),
        findsOneWidget,
      );
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.byKey(const Key('confirm_delete_history_item_button')), findsOneWidget);
    });

    testWidgets('2. Tapping Cancelar dismisses dialog without calling onDelete', (tester) async {
      bool onDeleteCalled = false;
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await DeleteHistoryItemDialog.show(
                    context,
                    entry: testEntry,
                    onDelete: (id) async {
                      onDeleteCalled = true;
                      return true;
                    },
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(DeleteHistoryItemDialog), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.byType(DeleteHistoryItemDialog), findsNothing);
      expect(onDeleteCalled, isFalse);
      expect(result, isNull);
    });

    testWidgets('3. Tapping Descartar triggers onDelete, displays loading state, and pops true', (tester) async {
      String? deletedId;
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await DeleteHistoryItemDialog.show(
                    context,
                    entry: testEntry,
                    onDelete: (id) async {
                      deletedId = id;
                      await Future.delayed(const Duration(milliseconds: 50));
                      return true;
                    },
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final confirmButton = find.byKey(const Key('confirm_delete_history_item_button'));
      expect(confirmButton, findsOneWidget);

      await tester.tap(confirmButton);
      await tester.pump(); // Advance to start async deletion

      // Spinner should appear while deleting
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle(); // Complete async deletion

      expect(find.byType(DeleteHistoryItemDialog), findsNothing);
      expect(deletedId, equals('entry-test-123'));
      expect(result, isTrue);
    });
  });
}
