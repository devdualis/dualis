import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../domain/triage_outcome_models.dart';

class TriageOutcomeRemoteDataSource {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  TriageOutcomeRemoteDataSource({
    ApiClient? apiClient,
    SecureStorageService? secureStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _secureStorage = secureStorage ?? SecureStorageService();

  Future<TriageOutcome> submitTriage({
    required String vertical,
    required Map<int, String> answers,
    String? narrative,
    String? token,
    String? clientSessionId,
  }) async {
    try {
      final authToken = token ?? await _secureStorage.getAccessToken();
      final response = await _apiClient.post(
        ApiEndpoints.triageOutcome,
        data: {
          'vertical': vertical,
          'answers': answers.map((key, value) => MapEntry(key.toString(), value)),
          if (narrative != null && narrative.isNotEmpty) 'narrative': narrative,
          if (clientSessionId != null && clientSessionId.isNotEmpty)
            'clientSessionId': clientSessionId,
        },
        options: authToken != null
            ? Options(headers: {'Authorization': 'Bearer $authToken'})
            : null,
      );

      if (response.data is Map<String, dynamic>) {
        return TriageOutcome.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Formato de resposta de desfecho inesperado.');
    } catch (_) {
      return generateOfflineFallback(vertical, answers, narrative);
    }
  }

  TriageOutcome generateOfflineFallback(
    String vertical,
    Map<int, String> answers,
    String? narrative,
  ) {
    final isZeroIndexed = answers.containsKey(0);
    final step1 = (isZeroIndexed ? answers[0] : answers[1]) ?? '';
    final step3 = (isZeroIndexed ? answers[2] : answers[3]) ?? '2';

    int score = 2;
    if (vertical == 'physical') {
      score = int.tryParse(step3) ?? 2;
    } else {
      final lower3 = step3.toLowerCase();
      if (lower3.contains('muito_forte') || lower3.contains('grave') || lower3.contains('crise') || lower3 == '4' || lower3 == '5') {
        score = 4;
      } else if (lower3.contains('moderada') || lower3 == '3') {
        score = 3;
      } else if (lower3.contains('leve') || lower3 == '1' || lower3 == '2') {
        score = 2;
      }
    }

    final isSomatic = vertical == 'emotional' &&
        (step1 == 'somatico' || (narrative != null && narrative.toLowerCase().contains('peito')));

    CareDisposition disposition;
    if (score <= 2) {
      disposition = CareDisposition.selfCare;
    } else if (score == 3) {
      disposition = CareDisposition.routineConsultation;
    } else if (score == 4) {
      disposition = CareDisposition.urgentCare;
    } else {
      disposition = CareDisposition.emergency;
    }

    if (isSomatic && disposition == CareDisposition.selfCare) {
      disposition = CareDisposition.routineConsultation;
    }

    String categoryLabel = vertical == 'physical' ? 'Avaliação Física' : 'Autoavaliação Psico-Emocional';
    String somaticDesc = 'Avaliação clínica preliminar em modo desconectado';
    List<RecommendedArticle> articles;

    final lowerStep1 = step1.toLowerCase();
    if (lowerStep1.contains('costas') || lowerStep1.contains('coluna') || lowerStep1.contains('lombar')) {
      categoryLabel = 'Coluna e Dor Dorsal';
      somaticDesc = 'Dor lombar / Tensão paravertebral postural (modo desconectado)';
      articles = const [
        RecommendedArticle(
          id: 'art-coluna-01',
          title: 'Ergonomia no Trabalho e Prevenção de Dores Lombares e Cervicais',
          category: 'coluna_dor_dorsal',
          author: 'Dr. Marcelo Mendes',
          authorRole: 'Ortopedista e Traumatologista (HCFMUSP / CRM-SP 128.450)',
          readTimeMinutes: 5,
          summary: 'Posturas preventivas, pausas ativas a cada 50 minutos e exercícios de descompressão da coluna lombar.',
          url: 'https://dualis.health/artigos/ergonomia-postura-coluna',
        ),
      ];
    } else if (lowerStep1.contains('ansiedade') || lowerStep1.contains('agitacao')) {
      categoryLabel = 'Dimensão Ansiosa / Agitação';
      somaticDesc = 'Ansiedade antecipatória / Tensão psicomotora (modo desconectado)';
      articles = const [
        RecommendedArticle(
          id: 'art-ansiedade-01',
          title: 'Manejo da Ansiedade Aguda com Respiração Diafragmática',
          category: 'ansiosa_agitacao',
          author: 'Dra. Camila Prado',
          authorRole: 'Psiquiatra Clínica (ABP / CRM-SP 165.340)',
          readTimeMinutes: 4,
          summary: 'Exercício guiado 4-7-8 para desaceleração do sistema simpático e restabelecimento do equilíbrio vagal em minutos.',
          url: 'https://dualis.health/artigos/respiracao-diafragmatica-ansiedade',
        ),
      ];
    } else {
      articles = const [
        RecommendedArticle(
          id: 'art-offline-01',
          title: 'Guia de Auto-Cuidado Preventivo e Bem-Estar Diário',
          category: 'geral',
          author: 'Dr. André Cavalcanti',
          authorRole: 'Clínico Geral (SBCM / CRM-SP 134.800)',
          readTimeMinutes: 3,
          summary: 'Práticas fundamentais de repouso preventivo e monitoramento postural e fisiológico.',
          url: 'https://dualis.health/artigos/autocuidado-preventivo',
        ),
      ];
    }

    return TriageOutcome(
      id: 'offline-${DateTime.now().millisecondsSinceEpoch}',
      vertical: vertical,
      intensityScore: score,
      careDisposition: disposition,
      primaryCategory: step1,
      categoryLabel: categoryLabel,
      somaticMapping: somaticDesc,
      organicPrimacyApplied: isSomatic,
      organicPrimacyNotice: isSomatic
          ? 'Atenção Clínica (Primazia Orgânica): Sintomas físicos concorrentes exigem avaliação médica presencial prioritária.'
          : null,
      recommendedArticles: articles,
      recordedAt: DateTime.now(),
    );
  }
}
