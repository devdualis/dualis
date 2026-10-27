import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/core/network/api_client.dart';
import 'package:dualis_mobile/core/security/secure_storage_service.dart';
import 'package:dualis_mobile/features/triage_outcome/data/triage_outcome_remote_data_source.dart';
import 'package:dualis_mobile/features/triage_outcome/domain/curated_articles_catalog.dart';
import 'package:dualis_mobile/features/triage_outcome/domain/triage_outcome_models.dart';

final _personOrRegistration = RegExp(r'\bDra?\.\s|\bCRM\b|\bCRP\b|CRM-|CRP-');
const _sourceRoles = {'Fonte', 'Source', 'Fuente'};

void _expectSourceAttribution(RecommendedArticle article) {
  expect(article.authorRole, isIn(_sourceRoles), reason: article.id);
  expect(article.author, isNot(matches(_personOrRegistration)), reason: article.id);
  expect(article.summary, isNot(matches(_personOrRegistration)), reason: article.id);
  expect(article.summary, isNot(contains('eletrocardiograma imediato')), reason: article.id);
  expect(article.summary, isNot(contains('diagnosticar')), reason: article.id);
  expect(article.url.startsWith('https://'), isTrue, reason: article.id);
}

void main() {
  final dataSource = TriageOutcomeRemoteDataSource(
    apiClient: ApiClient(),
    secureStorage: SecureStorageService(),
  );

  const narratives = [
    'dor nas costas',
    'dor de cabeça forte',
    'aperto no peito',
    'desconforto no estomago',
    'muita ansiedade',
    'tristeza',
    'burnout no trabalho',
    'sono ruim, insonia',
    'nada específico',
  ];

  group('Offline fallback', () {
    for (final lang in ['pt', 'en', 'es']) {
      for (final vertical in ['physical', 'emotional']) {
        test('articles credit only the real source ($lang, $vertical)', () {
          for (final narrative in narratives) {
            final outcome = dataSource.generateOfflineFallback(
              vertical,
              {1: 'outro', 3: '3'},
              narrative,
              language: lang,
            );
            expect(outcome.recommendedArticles, isNotEmpty);
            outcome.recommendedArticles.forEach(_expectSourceAttribution);
          }
        });
      }
    }

    test('uses the C-37 offline copy and keeps the self-reported intensity', () {
      final outcome = dataSource.generateOfflineFallback('physical', {1: 'outro', 3: '4'}, 'dor nas costas');
      expect(outcome.somaticMapping, 'Registro salvo no aparelho; será sincronizado.');
      expect(outcome.intensityScore, 4);
      expect(outcome.categoryLabel, 'Costas');
      expect(outcome.somaticMapping.toLowerCase(), isNot(contains('clínic')));
    });

    test('"feeling well" entry uses the C-37 copy in every language', () {
      expect(
        dataSource.generateOfflineFallback('physical', {1: 'normal'}, null).somaticMapping,
        'Você indicou que está bem hoje.',
      );
      expect(
        dataSource.generateOfflineFallback('physical', {1: 'normal'}, null, language: 'en').somaticMapping,
        'You said you are feeling well today.',
      );
      expect(
        dataSource.generateOfflineFallback('physical', {1: 'normal'}, null, language: 'es').somaticMapping,
        'Indicaste que hoy te sientes bien.',
      );
    });

    test('cross-vertical note is descriptive, with no assessment wording', () {
      final outcome = dataSource.generateOfflineFallback('emotional', {1: 'ansiosa', 3: 'moderada'}, 'dor de cabeça');
      expect(outcome.isCrossVerticalSomatic, isTrue);
      expect(outcome.crossVerticalContextNote, 'Você também mencionou algo físico neste registro.');
      expect(outcome.secondaryCategoryLabel, 'Cabeça e pescoço');
    });
  });

  group('CuratedArticlesCatalog', () {
    test('every curated article credits only the real source', () {
      final all = {
        ...CuratedArticlesCatalog.wellnessArticles,
        CuratedArticlesCatalog.skinPruritus,
        CuratedArticlesCatalog.upperLimbsOverload,
        CuratedArticlesCatalog.moodDepression,
        CuratedArticlesCatalog.acuteAnxiety,
        CuratedArticlesCatalog.tensionHeadache,
        CuratedArticlesCatalog.lumbarSpine,
        CuratedArticlesCatalog.burnoutStress,
      };
      all.forEach(_expectSourceAttribution);
    });
  });
}
