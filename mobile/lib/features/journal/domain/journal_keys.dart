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

  // What the user feels in a physical item (journal v2.1).
  static const String sensationDor = 'dor';
  static const String sensationIncomodo = 'incomodo';
  static const List<String> sensations = [sensationDor, sensationIncomodo];

  // Item kinds.
  static const String kindEmotional = 'emotional';
  static const String kindPhysical = 'physical';
  static const String kindCondition = 'condition';

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
      'memoria': ['lembranca', 'magoa'],
    },
    'presente': {
      'energia': ['corpo', 'desligado'],
      'sobrecarga': ['paciencia', 'aperto'],
    },
    'futuro': {
      'mente': ['antecipar', 'cobranca'],
      'medo': ['julgamento', 'desanimo'],
    },
  };

  /// Physical tree: region -> branch -> options.
  static const Map<String, Map<String, List<String>>> physicalTree = {
    'cabeca': {
      'pressao': ['temporas', 'latejando'],
      'sentidos': ['garganta', 'olhos'],
      'nuca': ['rigida', 'pontada'],
    },
    'peito': {
      'respiracao': ['curta', 'tosse'],
      'incomodo': ['batedeira', 'costelas'],
    },
    'barriga': {
      'queimacao': ['subindo', 'enjoo'],
      'colica': ['gases', 'pontadas'],
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
  static Map<String, List<String>> branchesFor(String region, String? side) {
    final hidden = side == sideBack
        ? frontOnlyBranches[region] ?? const <String>{}
        : side == sideFront
            ? backOnlyBranches[region] ?? const <String>{}
            : const <String>{};
    return {
      for (final e in physicalTree[region]!.entries)
        if (!hidden.contains(e.key)) e.key: e.value,
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
  static const String triggerAlimentacao = 'alimentacao';
  static const String triggerEsforco = 'esforco';
  static const String triggerQueda = 'queda';
  static const String triggerMedicamento = 'medicamento';
  static const String triggerClima = 'clima';
  static const String triggerNaoSei = 'nao_sei';
  static const String triggerOutro = 'outro';

  static const List<String> triggers = [
    triggerTrabalho,
    triggerFamilia,
    triggerSono,
    triggerAlimentacao,
    triggerEsforco,
    triggerQueda,
    triggerMedicamento,
    triggerClima,
    triggerNaoSei,
    triggerOutro,
  ];

  /// Only offered when the entry has a physical item.
  static const Set<String> physicalOnlyTriggers = {
    triggerAlimentacao,
    triggerEsforco,
    triggerQueda,
    triggerMedicamento,
    triggerClima,
  };

  static List<String> triggersFor({required bool hasPhysicalItem}) => [
    for (final t in triggers)
      if (hasPhysicalItem || !physicalOnlyTriggers.contains(t)) t,
  ];

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

  /// Every valid option key, for validation and tests.
  static Set<String> get allOptionKeys => {
    for (final tree in [emotionalTree, physicalTree])
      for (final root in tree.entries) ...[
        customKey(root.key),
        for (final branch in root.value.entries)
          for (final option in branch.value)
            optionKey(root.key, branch.key, option),
      ],
  };
}
