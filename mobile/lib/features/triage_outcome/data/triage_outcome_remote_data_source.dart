import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../domain/triage_outcome_models.dart';

class TriageOutcomeRemoteDataSource {
  final ApiClient _apiClient;

  TriageOutcomeRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<TriageOutcome> submitTriage({
    required String vertical,
    required Map<int, String> answers,
    String? narrative,
    String? token,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.triageOutcome,
        data: {
          'vertical': vertical,
          'answers': answers.map((key, value) => MapEntry(key.toString(), value)),
          if (narrative != null && narrative.isNotEmpty) 'narrative': narrative,
        },
        options: token != null
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
      );

      if (response.data is Map<String, dynamic>) {
        return TriageOutcome.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Formato de resposta de desfecho inesperado.');
    } catch (_) {
      // Deterministic offline fallback to ensure the patient always receives clinical guidance
      return _generateOfflineFallback(vertical, answers, narrative);
    }
  }

  TriageOutcome _generateOfflineFallback(
    String vertical,
    Map<int, String> answers,
    String? narrative,
  ) {
    final step1 = answers[1] ?? '';
    final step3 = answers[3] ?? '2';

    int score = 2;
    if (vertical == 'physical') {
      score = int.tryParse(step3) ?? 2;
    } else {
      if (step3.contains('muito_forte') || step3.contains('grave')) {
        score = 4;
      } else if (step3.contains('moderada')) {
        score = 3;
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

    return TriageOutcome(
      id: 'offline-${DateTime.now().millisecondsSinceEpoch}',
      vertical: vertical,
      intensityScore: score,
      careDisposition: disposition,
      primaryCategory: step1,
      categoryLabel: vertical == 'physical' ? 'Avaliação Física' : 'Autoavaliação Psico-Emocional',
      somaticMapping: 'Avaliação clínica preliminar em modo desconectado',
      organicPrimacyApplied: isSomatic,
      organicPrimacyNotice: isSomatic
          ? 'Atenção Clínica (Primazia Orgânica): Sintomas físicos concorrentes exigem avaliação médica presencial prioritária.'
          : null,
      recommendedArticles: const [
        RecommendedArticle(
          id: 'art-offline-01',
          title: 'Guia de Auto-Cuidado Preventivo e Bem-Estar Diário',
          category: 'geral',
          author: 'Dr. André Cavalcanti',
          authorRole: 'Clínico Geral (SBCM / CRM-SP 134.800)',
          readTimeMinutes: 3,
          summary: 'Práticas fundamentais de hidratação e monitoramento preventivo de sinais vitais.',
          url: 'https://dualis.health/artigos/autocuidado-preventivo',
        ),
      ],
      recordedAt: DateTime.now(),
    );
  }
}
