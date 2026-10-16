import 'triage_outcome_models.dart';

class CuratedArticlesCatalog {
  static const RecommendedArticle sleepHygiene = RecommendedArticle(
    id: 'art-wellness-1',
    title: 'Higiene do Sono e Repouso Restaurador',
    category: 'sono',
    author: 'Portal Drauzio Varella',
    authorRole: 'Fonte',
    readTimeMinutes: 4,
    summary:
        'Hábitos simples para manter horários regulares de sono e favorecer noites mais tranquilas.',
    url: 'https://drauziovarella.uol.com.br/neurologia/higiene-do-sono-conheca-11-dicas-para-dormir-melhor/',
  );

  static const RecommendedArticle hydrationAndFocus = RecommendedArticle(
    id: 'art-wellness-2',
    title: 'Equilíbrio Hidroeletrolítico e Foco Diário',
    category: 'nutricao',
    author: 'Organização Pan-Americana da Saúde (OPAS)',
    authorRole: 'Fonte',
    readTimeMinutes: 3,
    summary:
        'Beber água ao longo do dia faz parte dos hábitos que ajudam a manter disposição e concentração.',
    url: 'https://www.paho.org/pt/topicos/curso-vida-saudavel',
  );

  static const RecommendedArticle breathingTechnique = RecommendedArticle(
    id: 'art-wellness-3',
    title: 'Técnica de Respiração Diafragmática 4-7-8',
    category: 'respiracao',
    author: 'Portal Drauzio Varella',
    authorRole: 'Fonte',
    readTimeMinutes: 5,
    summary:
        'Alguns minutos de respiração compassada podem ajudar a desacelerar e relaxar em dias exigentes.',
    url: 'https://drauziovarella.uol.com.br/saude-mental/transtornos-de-ansiedade-nao-sao-todos-iguais-entenda-as-caracteristicas-de-cada-tipo/',
  );

  static const RecommendedArticle skinPruritus = RecommendedArticle(
    id: 'art-dermato-01',
    title: 'Prurido Cutâneo, Alergias e Cuidados com a Pele',
    category: 'dermatologico',
    author: 'Sociedade Brasileira de Dermatologia',
    authorRole: 'Fonte',
    readTimeMinutes: 4,
    summary:
        'Cuidados gerais com a pele, hidratação da barreira cutânea e sinais de atenção.',
    url: 'https://www.sbd.org.br/doencas/urticaria/',
  );

  static const RecommendedArticle upperLimbsOverload = RecommendedArticle(
    id: 'art-membros-sup-01',
    title: 'Sobrecarga Musculoesquelética em Braços e Ombros',
    category: 'membros_superiores',
    author: 'Portal Drauzio Varella',
    authorRole: 'Fonte',
    readTimeMinutes: 4,
    summary:
        'Informações gerais sobre sobrecarga nos braços e ombros e orientações posturais para o dia a dia.',
    url: 'https://drauziovarella.uol.com.br/podcasts/tendinite/',
  );

  static const RecommendedArticle moodDepression = RecommendedArticle(
    id: 'art-humor-01',
    title: 'Manejo do Desânimo Persistente e Baixa Energia',
    category: 'depressiva_desanimo',
    author: 'Organização Pan-Americana da Saúde (OPAS)',
    authorRole: 'Fonte',
    readTimeMinutes: 5,
    summary:
        'Pequenas rotinas para lidar com dias de desânimo e informações sobre quando buscar apoio.',
    url: 'https://www.paho.org/pt/topicos/depressao',
  );

  static const RecommendedArticle acuteAnxiety = RecommendedArticle(
    id: 'art-ansiedade-01',
    title: 'Manejo da Ansiedade Aguda e Agitação Psicomotora',
    category: 'ansiosa_agitacao',
    author: 'Portal Drauzio Varella',
    authorRole: 'Fonte',
    readTimeMinutes: 4,
    summary:
        'Exercício guiado de respiração para momentos de nervosismo e pensamentos acelerados.',
    url: 'https://drauziovarella.uol.com.br/saude-mental/transtornos-de-ansiedade-nao-sao-todos-iguais-entenda-as-caracteristicas-de-cada-tipo/',
  );

  static const RecommendedArticle tensionHeadache = RecommendedArticle(
    id: 'art-cefaleia-01',
    title: 'Cefaleia Tensional e Alívio Crânio-Cervical',
    category: 'cabeca_pescoco',
    author: 'Sociedade Brasileira de Cefaleia',
    authorRole: 'Fonte',
    readTimeMinutes: 4,
    summary:
        'Gatilhos posturais e de estresse para dores de cabeça tensionais e técnicas ergonômicas de descompressão.',
    url: 'https://sbcefaleia.com.br/noticias.php?id=350',
  );

  static const RecommendedArticle lumbarSpine = RecommendedArticle(
    id: 'art-coluna-01',
    title: 'Cuidados Posturais e Descompressão Lombar',
    category: 'coluna_dor_lombar',
    author: 'Sociedade Brasileira de Ortopedia e Traumatologia',
    authorRole: 'Fonte',
    readTimeMinutes: 4,
    summary:
        'Exercícios de mobilidade diária para alívio de dor lombar e prevenção de contraturas musculares.',
    url: 'https://sbot.org.br/dor-lombar-quais-os-motivos/',
  );

  static const RecommendedArticle burnoutStress = RecommendedArticle(
    id: 'art-burnout-01',
    title: 'Esgotamento e Estresse Crônico (Burnout)',
    category: 'estresse_burnout',
    author: 'Portal Drauzio Varella',
    authorRole: 'Fonte',
    readTimeMinutes: 5,
    summary:
        'Informações gerais sobre cansaço emocional no trabalho e limites saudáveis na rotina.',
    url: 'https://drauziovarella.uol.com.br/psiquiatria/sindrome-de-burnout-esgotamento-profissional/',
  );

  static List<RecommendedArticle> get wellnessArticles => const [
        sleepHygiene,
        hydrationAndFocus,
        breathingTechnique,
      ];

  static List<RecommendedArticle> getArticlesForSymptoms({
    String? queryText,
    String? anatomicalSystem,
    String? emotionalDimension,
    bool isEmotionalDistressed = false,
    bool isPhysicalDistressed = false,
  }) {
    final lower = (queryText ?? '').toLowerCase();
    final result = <RecommendedArticle>[];

    // Check textual keywords first
    if (lower.contains('coceira') ||
        lower.contains('pele') ||
        lower.contains('alergia') ||
        lower.contains('mancha') ||
        lower.contains('prurido')) {
      result.add(skinPruritus);
    }

    if (lower.contains('braco') ||
        lower.contains('braço') ||
        lower.contains('ombro') ||
        lower.contains('punho') ||
        lower.contains('mao') ||
        lower.contains('mão')) {
      result.add(upperLimbsOverload);
    }

    if (lower.contains('cabeca') ||
        lower.contains('cabeça') ||
        lower.contains('enxaqueca') ||
        lower.contains('pescoco') ||
        lower.contains('pescoço')) {
      result.add(tensionHeadache);
    }

    if (lower.contains('coluna') ||
        lower.contains('lombar') ||
        lower.contains('costas')) {
      result.add(lumbarSpine);
    }

    if (lower.contains('ansiedade') ||
        lower.contains('panico') ||
        lower.contains('pânico') ||
        lower.contains('nervoso') ||
        lower.contains('agitado')) {
      result.add(acuteAnxiety);
    }

    if (lower.contains('desanimo') ||
        lower.contains('desânimo') ||
        lower.contains('triste') ||
        lower.contains('vazio') ||
        lower.contains('depress')) {
      result.add(moodDepression);
    }

    if (lower.contains('burnout') ||
        lower.contains('esgotamento') ||
        lower.contains('estresse') ||
        lower.contains('cansaco') ||
        lower.contains('cansaço')) {
      result.add(burnoutStress);
    }

    // Check anatomical system tag
    if (anatomicalSystem != null) {
      if (anatomicalSystem.contains('dermato') && !result.contains(skinPruritus)) {
        result.add(skinPruritus);
      } else if (anatomicalSystem.contains('membros_superiores') &&
          !result.contains(upperLimbsOverload)) {
        result.add(upperLimbsOverload);
      } else if (anatomicalSystem.contains('cabeca') &&
          !result.contains(tensionHeadache)) {
        result.add(tensionHeadache);
      } else if (anatomicalSystem.contains('coluna') &&
          !result.contains(lumbarSpine)) {
        result.add(lumbarSpine);
      }
    }

    // Check emotional dimension tag
    if (emotionalDimension != null) {
      if (emotionalDimension.contains('depress') &&
          !result.contains(moodDepression)) {
        result.add(moodDepression);
      } else if (emotionalDimension.contains('ansio') &&
          !result.contains(acuteAnxiety)) {
        result.add(acuteAnxiety);
      } else if (emotionalDimension.contains('estresse') &&
          !result.contains(burnoutStress)) {
        result.add(burnoutStress);
      }
    }

    // If still empty or partially filled, check distress flags
    if (isPhysicalDistressed &&
        !result.any((a) =>
            a.category == 'dermatologico' ||
            a.category == 'membros_superiores' ||
            a.category == 'cabeca_pescoco' ||
            a.category == 'coluna_dor_lombar')) {
      if (lower.contains('coceira')) {
        if (!result.contains(skinPruritus)) result.add(skinPruritus);
      } else {
        if (!result.contains(upperLimbsOverload)) result.add(upperLimbsOverload);
      }
    }

    if (isEmotionalDistressed &&
        !result.any((a) =>
            a.category == 'depressiva_desanimo' ||
            a.category == 'ansiosa_agitacao' ||
            a.category == 'estresse_burnout')) {
      result.add(moodDepression);
    }

    // Fill remaining spots up to 3 with appropriate articles
    if (result.length < 3) {
      if (isEmotionalDistressed && !result.contains(acuteAnxiety)) {
        result.add(acuteAnxiety);
      } else if (!result.contains(hydrationAndFocus)) {
        result.add(hydrationAndFocus);
      }
    }

    if (result.length < 3 && !result.contains(breathingTechnique)) {
      result.add(breathingTechnique);
    }

    return result.take(3).toList();
  }
}
