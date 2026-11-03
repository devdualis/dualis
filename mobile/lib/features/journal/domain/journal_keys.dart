import 'package:flutter/widgets.dart';

/// Journal v2 keys, mirrored from `docs/bienestar/CONTRATO-JOURNAL-V2.md`.
///
/// A key describes the path of the user's own choice in everyday words. It is
/// stored as is and resolved to text on the device (pt/en/es `.arb`). Nothing
/// here sorts, scores or interprets what the user chose.
class JournalKeys {
  JournalKeys._();

  // Entry-level general mood.
  static const String moodBem = 'bem';
  static const String moodNormal = 'normal';
  static const String moodNaoTaoBem = 'nao_tao_bem';

  /// Valid when reading (old entries may say `normal`).
  static const List<String> moods = [moodBem, moodNormal, moodNaoTaoBem];

  /// Offered for new entries (journal v2.1).
  static const List<String> newEntryMoods = [moodBem, moodNaoTaoBem];

  // Entry axis (journal v2.1). Old entries have none.
  static const String areaEmotional = 'emotional';
  static const String areaPhysical = 'physical';

  // What the user felt in a physical item (journal v2.1 to v2.4). The flow
  // no longer asks it (v2.5); old entries keep it and still show it.
  static const String sensationDor = 'dor';
  static const String sensationIncomodo = 'incomodo';
  static const List<String> sensations = [sensationDor, sensationIncomodo];

  // Item kinds.
  static const String kindEmotional = 'emotional';
  static const String kindPhysical = 'physical';
  static const String kindCondition = 'condition';

  /// Good moments of a "Bem" entry (journal v2.2).
  static const String kindPositive = 'positive';

  // Body side for physical items.
  static const String sideFront = 'front';
  static const String sideBack = 'back';

  // Persistence.
  static const String persistenceHoje = 'hoje';
  static const String persistenceDiasSemanas = 'dias_semanas';
  static const String persistenceMesesAnos = 'meses_anos';
  static const List<String> persistences = [
    persistenceHoje,
    persistenceDiasSemanas,
    persistenceMesesAnos,
  ];

  /// Emotional tree: time -> branch -> options.
  static const Map<String, Map<String, List<String>>> emotionalTree = {
    'passado': {
      'tristeza': ['culpa', 'saudade'],
      'memoria': ['lembranca', 'magoa', 'vergonha'],
    },
    'presente': {
      'energia': ['corpo', 'desligado', 'concentracao'],
      'sobrecarga': ['paciencia', 'aperto', 'muita_coisa', 'inquieto'],
    },
    'futuro': {
      'mente': ['antecipar', 'cobranca', 'indecisao'],
      'medo': ['julgamento', 'desanimo', 'evitar'],
    },
  };

  /// Good moments tree (journal v2.2): time -> branch -> options. Branch
  /// names never repeat an emotional branch.
  static const Map<String, Map<String, List<String>>> positiveTree = {
    'passado': {
      'gratidao': ['alguem', 'algo'],
      'orgulho': ['conquista', 'resolvi'],
    },
    'presente': {
      'calma': ['paz', 'descansado'],
      'conexao': ['pessoas', 'foco'],
    },
    'futuro': {
      'animo': ['planos', 'esperanca'],
      'confianca': ['confiante', 'preparado'],
    },
  };

  /// Physical tree: region -> branch -> options. At most 2 branches per
  /// screen (v2.5): the old `cabeca.rosto`, `barriga.intestino`,
  /// `pelve.urina` and `pelve.intima` options moved into other branches.
  static const Map<String, Map<String, List<String>>> physicalTree = {
    'cabeca': {
      'pressao': ['temporas', 'latejando', 'tontura', 'mandibula'],
      'sentidos': ['garganta', 'olhos', 'nariz', 'ouvido'],
      'nuca': ['rigida', 'pontada'],
    },
    'peito': {
      'respiracao': ['curta', 'tosse'],
      'incomodo': ['batedeira', 'costelas'],
    },
    'barriga': {
      'queimacao': ['subindo', 'enjoo'],
      'colica': ['gases', 'pontadas', 'preso', 'solto', 'menstrual'],
    },
    // Pelvis and lower belly, front only (v2.3). Kept apart from barriga.
    'pelve': {
      'xixi_intima': ['ardencia', 'vontade', 'coceira', 'inchaco'],
      'baixo_ventre': ['colica', 'peso', 'menstrual'],
    },
    'costas': {
      'rigidez': ['ombros', 'lombar'],
      'fisgada': ['irradia', 'ao_mexer'],
    },
    'membros': {
      'cansaco': ['juntas', 'pesados'],
      'formigamento': ['dormentes', 'choque'],
    },
    // Whole body: no side.
    'pele': {
      'coceira': ['coceira', 'ardencia'],
      'aparencia': ['vermelhidao', 'manchas'],
    },
    'musculos': {
      'tensao': ['rigidez', 'caibra'],
      'cansaco': ['fraqueza', 'dolorido'],
    },
    'hormonios': {
      'temperatura': ['calorao', 'frio'],
      'apetite': ['sede', 'fome'],
    },
  };

  /// Areas of the whole body, recorded without a side.
  static const List<String> wholeBodyAreas = ['pele', 'musculos', 'hormonios'];

  /// Branches shown on one side only; every other branch shows on both.
  static const Map<String, Set<String>> frontOnlyBranches = {
    'cabeca': {'sentidos'},
  };
  static const Map<String, Set<String>> backOnlyBranches = {
    'cabeca': {'nuca'},
  };

  static bool isWholeBody(String region) => wholeBodyAreas.contains(region);

  /// Branches of [region] for the side it was marked on (`null` = whole body).
  static Map<String, List<String>> branchesFor(
    String region,
    String? side, {
    bool isMale = false,
  }) {
    final hidden = side == sideBack
        ? frontOnlyBranches[region] ?? const <String>{}
        : side == sideFront
            ? backOnlyBranches[region] ?? const <String>{}
            : const <String>{};
    return {
      for (final e in physicalTree[region]!.entries)
        if (!hidden.contains(e.key))
          e.key: [
            for (final opt in e.value)
              if (!isMale || opt != 'menstrual') opt,
          ],
    };
  }

  static List<String> get times => emotionalTree.keys.toList();
  static List<String> get regions => physicalTree.keys.toList();

  /// Regions marked on the body map (with a side).
  static List<String> get bodyRegions =>
      [for (final r in regions) if (!isWholeBody(r)) r];

  /// Custom item key segment: `<time>.custom` or `<region>.custom`.
  static const String customSegment = 'custom';

  static String optionKey(String root, String branch, String option) =>
      '$root.$branch.$option';
  static String customKey(String root) => '$root.$customSegment';

  /// First segment of an option key (time or region).
  static String rootOf(String optionKey) => optionKey.split('.').first;

  static bool isCustomKey(String optionKey) =>
      optionKey.endsWith('.$customSegment');

  // Triggers (entry level, multi-select, optional).
  static const String triggerTrabalho = 'trabalho';
  static const String triggerFamilia = 'familia';
  static const String triggerSono = 'sono';
  static const String triggerDinheiro = 'dinheiro';
  static const String triggerTelas = 'telas';
  static const String triggerCiclo = 'ciclo';
  static const String triggerAlimentacao = 'alimentacao';
  static const String triggerEsforco = 'esforco';
  static const String triggerQueda = 'queda';
  static const String triggerMedicamento = 'medicamento';
  static const String triggerClima = 'clima';
  static const String triggerNaoSei = 'nao_sei';
  static const String triggerOutro = 'outro';

  /// Display order (v2.2).
  static const List<String> triggers = [
    triggerTrabalho,
    triggerFamilia,
    triggerSono,
    triggerDinheiro,
    triggerTelas,
    triggerCiclo,
    triggerAlimentacao,
    triggerEsforco,
    triggerQueda,
    triggerMedicamento,
    triggerClima,
    triggerNaoSei,
    triggerOutro,
  ];

  /// Topics of the triggers screen (v2.3), in screen order. "Não sei" and
  /// "Outro" stay outside the topics. Order inside a topic follows [triggers].
  static const Map<String, List<String>> triggerTopics = {
    'dia': [triggerTrabalho, triggerSono, triggerTelas, triggerAlimentacao],
    'pessoas': [triggerFamilia, triggerDinheiro],
    'corpo': [triggerCiclo, triggerEsforco, triggerQueda, triggerMedicamento, triggerClima],
  };

  /// Only offered when the entry has a physical item.
  static const Set<String> physicalOnlyTriggers = {
    triggerAlimentacao,
    triggerEsforco,
    triggerQueda,
    triggerMedicamento,
    triggerClima,
  };

  static List<String> triggersFor({
    required bool hasPhysicalItem,
    bool isMale = false,
  }) => [
    for (final t in triggers)
      if ((hasPhysicalItem || !physicalOnlyTriggers.contains(t)) &&
          (!isMale || t != triggerCiclo))
        t,
  ];

  // Closing questions of a "não tão bem" entry (v2.2, both optional).
  static const List<String> copings = ['consegui', 'esperei', 'dificil'];
  static const String helperNadaAinda = 'nada_ainda';
  static const String helperBeberAgua = 'beber_agua';
  static const String helperRemedio = 'remedio';
  static const String helperRepouso = 'repouso';
  static const String helperCompressa = 'compressa';
  static const String helperAlimentacaoLeve = 'alimentacao_leve';
  static const String helperConsultaMedica = 'consulta_medica';

  static const List<String> emotionalHelpers = [
    'mexer_corpo',
    'conversar',
    'pausa',
    'lazer',
    'descansar',
    helperNadaAinda,
  ];
  static const List<String> physicalHelpers = [
    helperBeberAgua,
    helperRemedio,
    helperRepouso,
    helperCompressa,
    helperAlimentacaoLeve,
    helperConsultaMedica,
    helperNadaAinda,
  ];
  static const List<String> helpers = [
    'mexer_corpo',
    'conversar',
    'pausa',
    'lazer',
    'descansar',
    helperBeberAgua,
    helperRemedio,
    helperRepouso,
    helperCompressa,
    helperAlimentacaoLeve,
    helperConsultaMedica,
    helperNadaAinda,
  ];
  static List<String> helpersFor({required bool isPhysical}) =>
      isPhysical ? physicalHelpers : emotionalHelpers;
  static const int maxHelpers = 6;

  // Self-reported readings on a condition (v2.4, Premium). The person
  // chooses what a condition tracks; nothing is inferred from its name.
  static const String trackingBloodPressure = 'blood_pressure';
  static const String trackingGlucose = 'glucose';
  static const String trackingWeight = 'weight';

  /// Display and request order of reading kinds.
  static const List<String> trackingKinds = [
    trackingBloodPressure,
    trackingGlucose,
    trackingWeight,
  ];

  /// Moment of a glucose reading, chosen by the person.
  static const String momentJejum = 'jejum';
  static const String momentPreRefeicao = 'pre_refeicao';
  static const String momentPosRefeicao = 'pos_refeicao';
  static const String momentDormir = 'dormir';
  static const List<String> glucoseMoments = [
    momentJejum,
    momentPreRefeicao,
    momentPosRefeicao,
    momentDormir,
  ];

  /// Input limits of reading values. Wide on purpose: they only catch typos
  /// (1300 instead of 130) and are never shown as a range or used to judge a
  /// value.
  static const ReadingInputLimit systolicLimit = ReadingInputLimit(50, 300);
  static const ReadingInputLimit diastolicLimit = ReadingInputLimit(30, 200);
  static const ReadingInputLimit pulseLimit = ReadingInputLimit(30, 250);
  static const ReadingInputLimit mgdlLimit = ReadingInputLimit(20, 1000);
  static const ReadingInputLimit kgLimit = ReadingInputLimit(10, 500);

  /// Decimal places kept on a weight value.
  static const int kgDecimals = 2;

  /// A reading time may be at most this far after now (clock drift) ...
  static const Duration readingMaxAhead = Duration(minutes: 10);

  /// ... and at most this far before the entry time.
  static const Duration readingMaxBefore = Duration(days: 7);

  // Limits from the contract.
  static const int customLabelMaxLength = 80;
  static const int conditionLabelMaxLength = 40;
  static const int triggerNoteMaxLength = 60;

  /// Truncates by grapheme clusters so an emoji is never split.
  static String limitChars(String value, int max) {
    final chars = value.characters;
    return chars.length <= max ? value : chars.take(max).toString();
  }
  static const int maxItems = 12;
  static const int maxActiveConditions = 10;
  static const int intensityMin = 1;
  static const int intensityMax = 5;

  /// Every emotional and physical option key the flow offers today.
  static Set<String> get allOptionKeys => {
    for (final tree in [emotionalTree, physicalTree]) ..._keysOf(tree),
  };

  /// Keys of older app versions (v2.2 to v2.4) that the flow no longer
  /// offers, with the key the same option has now (`null`: removed in v2.5).
  /// Old entries and queued outbox items still carry them, so they stay
  /// valid and keep their label.
  static const Map<String, String?> legacyKeyMoves = {
    'presente.solidao.sozinho': null,
    'presente.solidao.menos': null,
    'cabeca.rosto.tontura': 'cabeca.pressao.tontura',
    'cabeca.rosto.mandibula': 'cabeca.pressao.mandibula',
    'cabeca.rosto.nariz': 'cabeca.sentidos.nariz',
    'cabeca.rosto.ouvido': 'cabeca.sentidos.ouvido',
    'barriga.intestino.preso': 'barriga.colica.preso',
    'barriga.intestino.solto': 'barriga.colica.solto',
    'pelve.urina.ardencia': 'pelve.xixi_intima.ardencia',
    'pelve.urina.vontade': 'pelve.xixi_intima.vontade',
    'pelve.urina.dificuldade': null,
    'pelve.urina.cor_odor': null,
    'pelve.intima.coceira': 'pelve.xixi_intima.coceira',
    'pelve.intima.inchaco': 'pelve.xixi_intima.inchaco',
  };

  static Set<String> get legacyOptionKeys => legacyKeyMoves.keys.toSet();

  /// The key [optionKey] has today, so old and new records of the same
  /// option count together. Removed and current keys come back unchanged.
  static String currentOptionKey(String optionKey) =>
      legacyKeyMoves[optionKey] ?? optionKey;

  /// Every key an entry may carry: the offered ones and the legacy ones.
  static Set<String> get acceptedOptionKeys =>
      {...allOptionKeys, ...legacyOptionKeys};

  /// Every valid key of a positive item (`<time>.custom` included).
  static Set<String> get positiveOptionKeys => _keysOf(positiveTree);

  static Set<String> _keysOf(Map<String, Map<String, List<String>>> tree) => {
    for (final root in tree.entries) ...[
      customKey(root.key),
      for (final branch in root.value.entries)
        for (final option in branch.value)
          optionKey(root.key, branch.key, option),
    ],
  };
}

/// Lowest and highest value a reading field accepts (typo guard only).
@immutable
class ReadingInputLimit {
  final num min;
  final num max;
  const ReadingInputLimit(this.min, this.max);

  bool accepts(num value) => value >= min && value <= max;
}
