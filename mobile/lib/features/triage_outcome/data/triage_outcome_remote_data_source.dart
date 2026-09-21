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
    String? language,
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
          if (language != null && language.isNotEmpty) 'language': language,
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
      return generateOfflineFallback(vertical, answers, narrative, language: language);
    }
  }

  TriageOutcome generateOfflineFallback(
    String vertical,
    Map<int, String> answers,
    String? narrative, {
    String? language,
  }) {
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

    final somaticKeywords = [
      'peito',
      'coraç',
      'ar',
      'respir',
      'garganta',
      'estômago',
      'nó',
      'aperto',
      'cabeça',
      'cabeca',
      'costas',
      'dor',
    ];
    final isSomatic = vertical == 'emotional' &&
        (step1 == 'somatico' ||
            (narrative != null &&
                somaticKeywords.any((kw) => narrative.toLowerCase().contains(kw))));

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

    final lang = (language ?? 'pt').toLowerCase();
    String categoryLabel;
    String somaticDesc;

    if (lang == 'es') {
      categoryLabel = vertical == 'physical' ? 'Evaluación Física' : 'Autoevaluación Psicoemocional';
      somaticDesc = 'Evaluación clínica preliminar en modo fuera de línea';
    } else if (lang == 'en') {
      categoryLabel = vertical == 'physical' ? 'Physical Assessment' : 'Psycho-Emotional Assessment';
      somaticDesc = 'Preliminary clinical assessment in offline mode';
    } else {
      categoryLabel = vertical == 'physical' ? 'Avaliação Física' : 'Autoavaliação Psico-Emocional';
      somaticDesc = 'Avaliação clínica preliminar em modo desconectado';
    }

    List<RecommendedArticle> articles;
    final lowerStep1 = step1.toLowerCase();
    final lowerNarrative = (narrative ?? '').toLowerCase();
    final matchTarget = '$lowerStep1 $lowerNarrative';

    if (matchTarget.contains('costas') || matchTarget.contains('coluna') || matchTarget.contains('lombar') || matchTarget.contains('espalda') || matchTarget.contains('back')) {
      if (lang == 'es') {
        categoryLabel = 'Columna y Dolor Dorsal';
        somaticDesc = 'Dolor lumbar / Tensión paravertebral postural';
        articles = const [
          RecommendedArticle(
            id: 'art-coluna-01-es',
            title: 'Dolor Lumbar y Ergonomía Postural',
            category: 'coluna_dor_dorsal',
            author: 'Dr. Marcelo Mendes',
            authorRole: 'Ortopedista y Traumatólogo',
            readTimeMinutes: 5,
            summary: 'Higiene postural, pausas activas y desmitificación del reposo prolongado en cama.',
            url: 'https://medlineplus.gov/spanish/backpain.html',
          ),
        ];
      } else if (lang == 'en') {
        categoryLabel = 'Spine & Back Pain';
        somaticDesc = 'Low back pain / Postural paravertebral strain';
        articles = const [
          RecommendedArticle(
            id: 'art-coluna-01-en',
            title: 'Back Pain and Lumbar Strain: Posture and Ergonomics',
            category: 'coluna_dor_dorsal',
            author: 'Dr. Marcelo Mendes',
            authorRole: 'Orthopedic Spine Surgeon',
            readTimeMinutes: 5,
            summary: 'Postural ergonomics, active breaks for desk workers, and avoiding prolonged bed rest.',
            url: 'https://medlineplus.gov/backpain.html',
          ),
        ];
      } else {
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
            url: 'https://sbot.org.br/dor-lombar-quais-os-motivos/',
          ),
        ];
      }
    } else if (matchTarget.contains('cabeca') || matchTarget.contains('cabeza') || matchTarget.contains('head') || matchTarget.contains('migraine') || matchTarget.contains('enxaqueca') || matchTarget.contains('cefaleia')) {
      if (lang == 'es') {
        categoryLabel = 'Cabeza y Cuello';
        somaticDesc = 'Cefalea / Tensión craneocervical';
        articles = const [
          RecommendedArticle(
            id: 'art-cabeca-01-es',
            title: 'Dolor de Cabeza y Migraña: Cuidados Iniciales',
            category: 'cabeca_pescoco',
            author: 'Dr. Fernando Siqueira',
            authorRole: 'Neurólogo Clínico',
            readTimeMinutes: 4,
            summary: 'Identificación de cefalea tensional y migraña pulsátil con pautas de descanso.',
            url: 'https://medlineplus.gov/spanish/headache.html',
          ),
        ];
      } else if (lang == 'en') {
        categoryLabel = 'Head & Neck';
        somaticDesc = 'Headache / Cranio-cervical discomfort';
        articles = const [
          RecommendedArticle(
            id: 'art-cabeca-01-en',
            title: 'Headaches and Migraines: Initial Care Guide',
            category: 'cabeca_pescoco',
            author: 'Dr. Fernando Siqueira',
            authorRole: 'Consultant Clinical Neurologist',
            readTimeMinutes: 4,
            summary: 'Distinguishing tension headaches from pulsating migraines with hydration and rest.',
            url: 'https://medlineplus.gov/headache.html',
          ),
        ];
      } else {
        categoryLabel = 'Cabeça e Pescoço';
        somaticDesc = 'Cefaleia / Desconforto crânio-cervical (modo desconectado)';
        articles = const [
          RecommendedArticle(
            id: 'art-cabeca-01',
            title: 'Cefaleia Tensional vs. Enxaqueca: Como Identificar os Primeiros Sinais',
            category: 'cabeca_pescoco',
            author: 'Dr. Thiago Albuquerque',
            authorRole: 'Neurologista Clínico (UNIFESP / CRM-SP 156.702)',
            readTimeMinutes: 4,
            summary: 'Diferenciação prática entre dores de cabeça causadas por tensão muscular e crises de enxaqueca pulsátil.',
            url: 'https://sbcefaleia.com.br/noticias.php?id=350',
          ),
        ];
      }
    } else if (matchTarget.contains('peito') || matchTarget.contains('pecho') || matchTarget.contains('chest') || matchTarget.contains('coracao') || matchTarget.contains('heart') || matchTarget.contains('palpitac')) {
      if (lang == 'es') {
        categoryLabel = 'Cardiovascular y Tórax';
        somaticDesc = 'Palpitaciones / Tensión torácica funcional';
        articles = const [
          RecommendedArticle(
            id: 'art-cardio-01-es',
            title: 'Palpitaciones y Taquicardia: Comprendiendo los Latidos Rápidos',
            category: 'cardiovascular_torax',
            author: 'Dra. Beatriz Silva',
            authorRole: 'Cardióloga Clínica',
            readTimeMinutes: 4,
            summary: 'Pautas sobre palpitaciones por estrés y cuándo acudir a valoración cardiológica.',
            url: 'https://medlineplus.gov/spanish/heartpalpitations.html',
          ),
        ];
      } else if (lang == 'en') {
        categoryLabel = 'Cardiovascular & Thorax';
        somaticDesc = 'Palpitations / Functional chest tightness';
        articles = const [
          RecommendedArticle(
            id: 'art-cardio-01-en',
            title: 'Heart Racing and Palpitations: Understanding Rapid Heartbeats',
            category: 'cardiovascular_torax',
            author: 'Dr. Beatriz Silva',
            authorRole: 'Consultant Cardiologist',
            readTimeMinutes: 4,
            summary: 'Clinical guide on stress palpitations versus arrhythmias needing prompt assessment.',
            url: 'https://medlineplus.gov/heartpalpitations.html',
          ),
        ];
      } else {
        categoryLabel = 'Cardiovascular e Tórax';
        somaticDesc = 'Sensação de palpitação / Tensão torácica (modo desconectado)';
        articles = const [
          RecommendedArticle(
            id: 'art-cardio-01',
            title: 'Compreendendo as Palpitações e Quando Procurar um Cardiologista',
            category: 'cardiovascular_torax',
            author: 'Dra. Beatriz Silva',
            authorRole: 'Cardiologista (InCor / CRM-SP 142.890)',
            readTimeMinutes: 4,
            summary: 'Guia clínico sobre diferenciação de palpitações benignas por estresse e arritmias que requerem eletrocardiograma imediato.',
            url: 'https://drauziovarella.uol.com.br/entrevistas-2/arritmia-cardiaca-entrevista/',
          ),
        ];
      }
    } else if (matchTarget.contains('estomago') || matchTarget.contains('abdomen') || matchTarget.contains('digest')) {
      categoryLabel = 'Gastrointestinal e Abdômen';
      somaticDesc = 'Desconforto digestivo funcional (modo desconectado)';
      articles = const [
        RecommendedArticle(
          id: 'art-gastro-01',
          title: 'O Eixo Intestino-Cérebro: Como o Estresse Afeta Sua Digestão',
          category: 'gastrointestinal_abdomen',
          author: 'Dra. Fernanda Toledo',
          authorRole: 'Gastroenterologista (FBG / CRM-SP 139.112)',
          readTimeMinutes: 5,
          summary: 'Mecanismos neuroquímicos da dispepsia funcional, gastrite nervosa e estratégias de modulação alimentar.',
          url: 'https://drauziovarella.uol.com.br/gastroenterologia/refluxo-saiba-o-que-e-os-sintomas-e-as-formas-de-tratamento/',
        ),
      ];
    } else if (matchTarget.contains('ansiedade') || matchTarget.contains('agitacao') || matchTarget.contains('nervos')) {
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
          url: 'https://drauziovarella.uol.com.br/saude-mental/transtornos-de-ansiedade-nao-sao-todos-iguais-entenda-as-caracteristicas-de-cada-tipo/',
        ),
      ];
    } else if (matchTarget.contains('tristeza') || matchTarget.contains('desanimo') || matchTarget.contains('depress')) {
      categoryLabel = 'Dimensão Depressiva / Desânimo';
      somaticDesc = 'Sensação de desânimo / Queda de energia psicomotora (modo desconectado)';
      articles = const [
        RecommendedArticle(
          id: 'art-desanimo-01',
          title: 'Ativação Comportamental: Passos para Romper o Ciclo do Desânimo',
          category: 'depressiva_desanimo',
          author: 'Dr. Rafael Nogueira',
          authorRole: 'Psiquiatra e Psicoterapeuta (CRM-SP 148.910)',
          readTimeMinutes: 5,
          summary: 'Estratégias práticas para reengajar em pequenas atividades diárias e restaurar gradualmente a motivação.',
          url: 'https://www.paho.org/pt/topicos/depressao',
        ),
      ];
    } else if (matchTarget.contains('burnout') || matchTarget.contains('estresse') || matchTarget.contains('sobrecarga')) {
      categoryLabel = 'Dimensão Estresse / Sobrecarga';
      somaticDesc = 'Sobrecarga psíquica e mental (modo desconectado)';
      articles = const [
        RecommendedArticle(
          id: 'art-burnout-01',
          title: 'Prevenção da Exaustão Mental e Sobrecarga Emocional',
          category: 'estresse_burnout',
          author: 'Dr. Lucas Rossi',
          authorRole: 'Psicólogo Clínico (CRP-06/123456)',
          readTimeMinutes: 5,
          summary: 'Sinais precoces de esgotamento pelo trabalho e métodos de reestruturação de rotina para restauração cognitiva.',
          url: 'https://www.gov.br/saude/pt-br/assuntos/saude-de-a-a-z/s/sindrome-de-burnout',
        ),
      ];
    } else if (matchTarget.contains('sono') || matchTarget.contains('insonia')) {
      categoryLabel = 'Dimensão do Sono';
      somaticDesc = 'Irregularidade do ciclo sono-vigília (modo desconectado)';
      articles = const [
        RecommendedArticle(
          id: 'art-sono-01',
          title: 'Higiene do Sono: 7 Hábitos Essenciais para uma Noite Reparadora',
          category: 'sono',
          author: 'Dra. Helena Vasconcelos',
          authorRole: 'Especialista em Medicina do Sono (ABMS / CRM-SP 153.220)',
          readTimeMinutes: 4,
          summary: 'Protocolo de descompressão antes de deitar, controle da exposição à luz azul e ambiente ideal para repouso.',
          url: 'https://drauziovarella.uol.com.br/neurologia/higiene-do-sono-conheca-11-dicas-para-dormir-melhor/',
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
          url: 'https://www.paho.org/pt/topicos/curso-vida-saudavel',
        ),
      ];
    }

    String? secondaryCategoryLabel;
    String? secondarySomaticMapping;
    String? aiClinicalConcept;
    String? aiMappedLayTerm;
    bool isCrossVerticalSomatic = false;
    String? crossVerticalContextNote;

    if (vertical == 'emotional') {
      if (matchTarget.contains('cabeca') ||
          matchTarget.contains('cabeza') ||
          matchTarget.contains('head') ||
          matchTarget.contains('migraine') ||
          matchTarget.contains('enxaqueca') ||
          matchTarget.contains('cefaleia')) {
        secondaryCategoryLabel = 'Cabeça e Pescoço';
        secondarySomaticMapping = 'Cefaleia / Desconforto crânio-cervical';
        aiClinicalConcept = 'cefaleia tensional / migrânea';
        aiMappedLayTerm = 'dor de cabeça';
        isCrossVerticalSomatic = true;
        crossVerticalContextNote =
            'Manifestação física concorrente identificada no relato. Em quadros de ansiedade e tensão psicomotora, cefaleias e dores musculares são frequentes como somatização, mas exigem avaliação clínica para descartar causas orgânicas primárias.';
      } else if (matchTarget.contains('costas') ||
          matchTarget.contains('coluna') ||
          matchTarget.contains('lombar')) {
        secondaryCategoryLabel = 'Coluna e Dor Dorsal';
        secondarySomaticMapping = 'Dor lombar / Tensão paravertebral postural';
        aiClinicalConcept = 'lombalgia mecânica / postural';
        aiMappedLayTerm = 'dor nas costas';
        isCrossVerticalSomatic = true;
        crossVerticalContextNote =
            'Manifestação física concorrente identificada no relato. Exige avaliação clínica para descartar causas orgânicas primárias.';
      }
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
      secondaryCategoryLabel: secondaryCategoryLabel,
      secondarySomaticMapping: secondarySomaticMapping,
      aiClinicalConcept: aiClinicalConcept,
      aiMappedLayTerm: aiMappedLayTerm,
      isCrossVerticalSomatic: isCrossVerticalSomatic,
      crossVerticalContextNote: crossVerticalContextNote,
    );
  }
}
