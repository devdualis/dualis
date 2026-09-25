import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/triage_outcome/domain/triage_outcome_models.dart';
import 'package:dualis_mobile/features/triage_outcome/presentation/widgets/article_card.dart';

void main() {
  const articleSono = RecommendedArticle(
    id: 'art-sono-01',
    title: 'Higiene do Sono e Repouso Restaurador',
    category: 'sono',
    author: 'Dr. Lucas Mendes',
    authorRole: 'Neurologista e Especialista em Sono',
    readTimeMinutes: 4,
    summary: 'Entenda como ciclos regulares de sono consolidam a imunidade celular.',
    url: 'https://example.com/sono',
  );

  const articleRespiracao = RecommendedArticle(
    id: 'art-respiracao-01',
    title: 'Técnica de Respiração Diafragmática 4–7–8',
    category: 'respiracao',
    author: 'Dra. Beatriz Santos',
    authorRole: 'Psicóloga Especialista em Regulação Emocional',
    readTimeMinutes: 5,
    summary: 'Três minutos de respiração compassada ativam o tônus vagal.',
    url: 'https://example.com/respiracao',
  );

  testWidgets('ArticleCard renders without overflow on 360dp phone width (constraints <= 287.4)',
      (tester) async {
    // 287.4 width available to row + 32 padding of ArticleCard = 319.4
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 319.4,
              child: ArticleCard(article: articleSono),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ArticleCard), findsOneWidget);
    expect(find.text('Saúde Emocional'), findsOneWidget);
    expect(find.text('4 min de leitura'), findsOneWidget);
    expect(find.text('Revisado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ArticleCard renders without overflow for 5 min reading article',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 319.4,
              child: ArticleCard(article: articleRespiracao),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ArticleCard), findsOneWidget);
    expect(find.text('Saúde Emocional'), findsOneWidget);
    expect(find.text('5 min de leitura'), findsOneWidget);
    expect(find.text('Revisado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ArticleCard renders without overflow on very narrow screen (e.g., width 260)',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 260.0,
              child: ArticleCard(article: articleSono),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ArticleCard), findsOneWidget);
    expect(find.text('Saúde Emocional'), findsOneWidget);
    expect(find.text('4 min de leitura'), findsOneWidget);
    expect(find.text('Revisado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
