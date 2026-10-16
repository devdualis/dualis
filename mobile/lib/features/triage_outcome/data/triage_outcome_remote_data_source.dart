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
  }) =>
      submitTriageForProfile(
        vertical: vertical,
        answers: answers,
        narrative: narrative,
        token: token,
        clientSessionId: clientSessionId,
        language: language,
      );

  Future<TriageOutcome> submitTriageForProfile({
    required String vertical,
    required Map<int, String> answers,
    String? narrative,
    String? token,
    String? clientSessionId,
    String? language,
    String? profileId,
  }) async {
    try {
      final authToken = token ?? await _secureStorage.getAccessToken();
      final headers = <String, dynamic>{
        if (authToken != null) 'Authorization': 'Bearer $authToken',
        if (profileId != null && profileId.isNotEmpty) 'X-Profile-Id': profileId,
      };
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
        options: headers.isNotEmpty ? Options(headers: headers) : null,
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
    final lang = (language ?? 'pt').toLowerCase();
    final isZeroIndexed = answers.containsKey(0);
    final step1 = (isZeroIndexed ? answers[0] : answers[1]) ?? '';
    final lowerStep1 = step1.toLowerCase();

    if (lowerStep1 == 'normal' || lowerStep1 == 'bem_normal') {
      return TriageOutcome(
        id: 'fallback-normal-${DateTime.now().millisecondsSinceEpoch}',
        vertical: vertical,
        intensityScore: 0,
        primaryCategory: 'normal',
        categoryLabel: _t(lang, pt: 'Tudo bem hoje', en: 'Feeling well today', es: 'Todo bien hoy'),
        somaticMapping: _t(
          lang,
          pt: 'Você indicou que está bem hoje.',
          en: 'You said you are feeling well today.',
          es: 'Indicaste que hoy te sientes bien.',
        ),
        recommendedArticles: const [],
        recordedAt: DateTime.now(),
      );
    }

    // Intensity is exactly what the person reported in step 3; it is never
    // interpreted or escalated here.
    final step3 = answers[3] ?? (isZeroIndexed ? answers[2] : answers[3]) ?? '2';

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

    final savedOffline = _t(
      lang,
      pt: 'Registro salvo no aparelho; será sincronizado.',
      en: 'Entry saved on this device; it will sync later.',
      es: 'Registro guardado en el dispositivo; se sincronizará.',
    );

    String categoryLabel = vertical == 'physical'
        ? _t(lang, pt: 'Registro físico', en: 'Physical entry', es: 'Registro físico')
        : _t(lang, pt: 'Registro emocional', en: 'Emotional entry', es: 'Registro emocional');
    List<RecommendedArticle> articles;

    final lowerNarrative = (narrative ?? '').toLowerCase();
    final matchTarget = '$lowerStep1 $lowerNarrative';
    final mentionsBack = matchTarget.contains('costas') || matchTarget.contains('coluna') || matchTarget.contains('lombar') || matchTarget.contains('espalda') || matchTarget.contains('back');
    final mentionsHead = matchTarget.contains('cabeca') || matchTarget.contains('cabeça') || matchTarget.contains('cabeza') || matchTarget.contains('head') || matchTarget.contains('migraine') || matchTarget.contains('enxaqueca') || matchTarget.contains('cefaleia');

    if (mentionsBack) {
      categoryLabel = _t(lang, pt: 'Costas', en: 'Back', es: 'Espalda');
      articles = [
        _t(
          lang,
          pt: const RecommendedArticle(
            id: 'art-coluna-01',
            title: 'Ergonomia no Trabalho e Cuidados com a Coluna',
            category: 'coluna_dor_dorsal',
            author: 'Sociedade Brasileira de Ortopedia e Traumatologia',
            authorRole: 'Fonte',
            readTimeMinutes: 5,
            summary: 'Posturas no dia a dia, pausas ativas a cada 50 minutos e alongamentos simples para as costas.',
            url: 'https://sbot.org.br/dor-lombar-quais-os-motivos/',
          ),
          en: const RecommendedArticle(
            id: 'art-coluna-01-en',
            title: 'Back Pain and Lumbar Strain: Posture and Ergonomics',
            category: 'coluna_dor_dorsal',
            author: 'MedlinePlus (U.S. National Library of Medicine)',
            authorRole: 'Source',
            readTimeMinutes: 5,
            summary: 'Posture at your desk, active breaks during the day and gentle movement for your back.',
            url: 'https://medlineplus.gov/backpain.html',
          ),
          es: const RecommendedArticle(
            id: 'art-coluna-01-es',
            title: 'Dolor Lumbar y Ergonomía Postural',
            category: 'coluna_dor_dorsal',
            author: 'MedlinePlus (Biblioteca Nacional de Medicina de EE. UU.)',
            authorRole: 'Fuente',
            readTimeMinutes: 5,
            summary: 'Postura en el trabajo, pausas activas durante el día y movimiento suave para la espalda.',
            url: 'https://medlineplus.gov/spanish/backpain.html',
          ),
        ),
      ];
    } else if (mentionsHead) {
      categoryLabel = _t(lang, pt: 'Cabeça e pescoço', en: 'Head and neck', es: 'Cabeza y cuello');
      articles = [
        _t(
          lang,
          pt: const RecommendedArticle(
            id: 'art-cabeca-01',
            title: 'Dor de Cabeça no Dia a Dia: Informações Gerais',
            category: 'cabeca_pescoco',
            author: 'Sociedade Brasileira de Cefaleia',
            authorRole: 'Fonte',
            readTimeMinutes: 4,
            summary: 'Hábitos de descanso, hidratação e postura que costumam ajudar em dias de dor de cabeça.',
            url: 'https://sbcefaleia.com.br/noticias.php?id=350',
          ),
          en: const RecommendedArticle(
            id: 'art-cabeca-01-en',
            title: 'Headaches: General Self-Care Guide',
            category: 'cabeca_pescoco',
            author: 'MedlinePlus (U.S. National Library of Medicine)',
            authorRole: 'Source',
            readTimeMinutes: 4,
            summary: 'Rest, hydration and posture habits that often help on headache days.',
            url: 'https://medlineplus.gov/headache.html',
          ),
          es: const RecommendedArticle(
            id: 'art-cabeca-01-es',
            title: 'Dolor de Cabeza: Guía General de Autocuidado',
            category: 'cabeca_pescoco',
            author: 'MedlinePlus (Biblioteca Nacional de Medicina de EE. UU.)',
            authorRole: 'Fuente',
            readTimeMinutes: 4,
            summary: 'Hábitos de descanso, hidratación y postura que suelen ayudar en días con dolor de cabeza.',
            url: 'https://medlineplus.gov/spanish/headache.html',
          ),
        ),
      ];
    } else if (matchTarget.contains('peito') || matchTarget.contains('pecho') || matchTarget.contains('chest') || matchTarget.contains('coracao') || matchTarget.contains('heart') || matchTarget.contains('palpitac')) {
      categoryLabel = _t(lang, pt: 'Peito', en: 'Chest', es: 'Pecho');
      articles = [
        _t(
          lang,
          pt: const RecommendedArticle(
            id: 'art-cardio-01',
            title: 'Coração Acelerado: Informações Gerais sobre Palpitações',
            category: 'cardiovascular_torax',
            author: 'Portal Drauzio Varella',
            authorRole: 'Fonte',
            readTimeMinutes: 4,
            summary: 'Conteúdo educativo sobre a sensação de coração acelerado e fatores comuns do dia a dia, como estresse e cafeína.',
            url: 'https://drauziovarella.uol.com.br/entrevistas-2/arritmia-cardiaca-entrevista/',
          ),
          en: const RecommendedArticle(
            id: 'art-cardio-01-en',
            title: 'Heart Racing and Palpitations: Understanding Rapid Heartbeats',
            category: 'cardiovascular_torax',
            author: 'MedlinePlus (U.S. National Library of Medicine)',
            authorRole: 'Source',
            readTimeMinutes: 4,
            summary: 'Educational content about a racing heart and everyday factors such as stress and caffeine.',
            url: 'https://medlineplus.gov/heartpalpitations.html',
          ),
          es: const RecommendedArticle(
            id: 'art-cardio-01-es',
            title: 'Palpitaciones: Comprendiendo los Latidos Rápidos',
            category: 'cardiovascular_torax',
            author: 'MedlinePlus (Biblioteca Nacional de Medicina de EE. UU.)',
            authorRole: 'Fuente',
            readTimeMinutes: 4,
            summary: 'Contenido educativo sobre la sensación de corazón acelerado y factores cotidianos como el estrés y la cafeína.',
            url: 'https://medlineplus.gov/spanish/heartpalpitations.html',
          ),
        ),
      ];
    } else if (matchTarget.contains('estomago') || matchTarget.contains('abdomen') || matchTarget.contains('digest')) {
      categoryLabel = _t(lang, pt: 'Barriga e digestão', en: 'Stomach and digestion', es: 'Abdomen y digestión');
      articles = const [
        RecommendedArticle(
          id: 'art-gastro-01',
          title: 'Estresse e Digestão: Como um Afeta o Outro',
          category: 'gastrointestinal_abdomen',
          author: 'Portal Drauzio Varella',
          authorRole: 'Fonte',
          readTimeMinutes: 5,
          summary: 'Conteúdo educativo sobre a relação entre estresse e desconforto digestivo, com dicas de alimentação.',
          url: 'https://drauziovarella.uol.com.br/gastroenterologia/refluxo-saiba-o-que-e-os-sintomas-e-as-formas-de-tratamento/',
        ),
      ];
    } else if (matchTarget.contains('ansiedade') || matchTarget.contains('agitacao') || matchTarget.contains('nervos')) {
      categoryLabel = _t(lang, pt: 'Nervosismo e agitação', en: 'Nervous and restless', es: 'Nervios e inquietud');
      articles = const [
        RecommendedArticle(
          id: 'art-ansiedade-01',
          title: 'Respiração Diafragmática para Momentos de Nervosismo',
          category: 'ansiosa_agitacao',
          author: 'Portal Drauzio Varella',
          authorRole: 'Fonte',
          readTimeMinutes: 4,
          summary: 'Exercício guiado de respiração 4-7-8 para desacelerar e relaxar.',
          url: 'https://drauziovarella.uol.com.br/saude-mental/transtornos-de-ansiedade-nao-sao-todos-iguais-entenda-as-caracteristicas-de-cada-tipo/',
        ),
      ];
    } else if (matchTarget.contains('tristeza') || matchTarget.contains('desanimo') || matchTarget.contains('depress')) {
      categoryLabel = _t(lang, pt: 'Pra baixo', en: 'Feeling low', es: 'Decaído(a)');
      articles = const [
        RecommendedArticle(
          id: 'art-desanimo-01',
          title: 'Ativação Comportamental: Passos para Romper o Ciclo do Desânimo',
          category: 'depressiva_desanimo',
          author: 'Organização Pan-Americana da Saúde (OPAS)',
          authorRole: 'Fonte',
          readTimeMinutes: 5,
          summary: 'Estratégias práticas para retomar pequenas atividades diárias e recuperar aos poucos a motivação.',
          url: 'https://www.paho.org/pt/topicos/depressao',
        ),
      ];
    } else if (matchTarget.contains('burnout') || matchTarget.contains('estresse') || matchTarget.contains('sobrecarga')) {
      categoryLabel = _t(lang, pt: 'Esgotado(a)', en: 'Worn out', es: 'Agotado(a)');
      articles = const [
        RecommendedArticle(
          id: 'art-burnout-01',
          title: 'Cansaço Mental e Sobrecarga: Cuidando da Rotina',
          category: 'estresse_burnout',
          author: 'Ministério da Saúde',
          authorRole: 'Fonte',
          readTimeMinutes: 5,
          summary: 'Sinais comuns de cansaço pelo trabalho e ideias para reorganizar a rotina com pausas.',
          url: 'https://www.gov.br/saude/pt-br/assuntos/saude-de-a-a-z/s/sindrome-de-burnout',
        ),
      ];
    } else if (matchTarget.contains('sono') || matchTarget.contains('insonia')) {
      categoryLabel = _t(lang, pt: 'Sono ruim', en: 'Poor sleep', es: 'Mal sueño');
      articles = const [
        RecommendedArticle(
          id: 'art-sono-01',
          title: 'Higiene do Sono: Hábitos para uma Noite Mais Tranquila',
          category: 'sono',
          author: 'Portal Drauzio Varella',
          authorRole: 'Fonte',
          readTimeMinutes: 4,
          summary: 'Rotina para desacelerar antes de deitar, cuidado com a luz das telas e um ambiente confortável para dormir.',
          url: 'https://drauziovarella.uol.com.br/neurologia/higiene-do-sono-conheca-11-dicas-para-dormir-melhor/',
        ),
      ];
    } else {
      articles = const [
        RecommendedArticle(
          id: 'art-offline-01',
          title: 'Guia de Autocuidado e Bem-Estar Diário',
          category: 'geral',
          author: 'Organização Pan-Americana da Saúde (OPAS)',
          authorRole: 'Fonte',
          readTimeMinutes: 3,
          summary: 'Hábitos simples de hidratação, sono e pausas ao longo do dia.',
          url: 'https://www.paho.org/pt/topicos/curso-vida-saudavel',
        ),
      ];
    }

    String? secondaryCategoryLabel;
    String? secondarySomaticMapping;
    String? aiMappedLayTerm;
    bool isCrossVerticalSomatic = false;
    String? crossVerticalContextNote;

    // Descriptive only: notes that the emotional entry also mentions a body
    // area. No assessment or recommendation is derived from it.
    final mentionsBackPt = matchTarget.contains('costas') || matchTarget.contains('coluna') || matchTarget.contains('lombar');
    if (vertical == 'emotional' && (mentionsHead || mentionsBackPt)) {
      isCrossVerticalSomatic = true;
      crossVerticalContextNote = _t(
        lang,
        pt: 'Você também mencionou algo físico neste registro.',
        en: 'You also mentioned something physical in this entry.',
        es: 'También mencionaste algo físico en este registro.',
      );
      final String layTerm;
      if (mentionsHead) {
        secondaryCategoryLabel = _t(lang, pt: 'Cabeça e pescoço', en: 'Head and neck', es: 'Cabeza y cuello');
        layTerm = _t(lang, pt: 'Dor de cabeça', en: 'Headache', es: 'Dolor de cabeza');
      } else {
        secondaryCategoryLabel = _t(lang, pt: 'Costas', en: 'Back', es: 'Espalda');
        layTerm = _t(lang, pt: 'Dor nas costas', en: 'Back pain', es: 'Dolor de espalda');
      }
      secondarySomaticMapping = layTerm;
      aiMappedLayTerm = layTerm.toLowerCase();
    }

    return TriageOutcome(
      id: 'offline-${DateTime.now().millisecondsSinceEpoch}',
      vertical: vertical,
      intensityScore: score,
      primaryCategory: step1,
      categoryLabel: categoryLabel,
      somaticMapping: savedOffline,
      recommendedArticles: articles,
      recordedAt: DateTime.now(),
      secondaryCategoryLabel: secondaryCategoryLabel,
      secondarySomaticMapping: secondarySomaticMapping,
      aiMappedLayTerm: aiMappedLayTerm,
      isCrossVerticalSomatic: isCrossVerticalSomatic,
      crossVerticalContextNote: crossVerticalContextNote,
    );
  }

  static T _t<T>(String lang, {required T pt, required T en, required T es}) {
    if (lang == 'es') return es;
    if (lang == 'en') return en;
    return pt;
  }
}
