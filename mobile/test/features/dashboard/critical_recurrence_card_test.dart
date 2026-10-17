import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/dashboard/domain/models/triage_history_models.dart';
import 'package:dualis_mobile/features/dashboard/presentation/widgets/journal_pattern_card.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

void main() {
  group('JournalPatternCard', () {
    testWidgets('shows descriptive pattern copy without clinical alarm', (tester) async {
      const item = JournalPatternItem(
        category: 'cabeca_pescoco',
        vertical: 'physical',
        count: 2,
        windowDays: 10,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt'),
          home: Scaffold(
            body: JournalPatternCard(item: item),
          ),
        ),
      );

      expect(find.text('Padrões nos seus registros'), findsOneWidget);
      expect(find.textContaining('Cabeça e pescoço'), findsOneWidget);
      expect(find.text('2x'), findsOneWidget);
    });
  });
}
