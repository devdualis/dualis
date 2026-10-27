import '../../../l10n/app_localizations.dart';

/// Display text for the keys of the journal v2 contract
/// (docs/bienestar/CONTRATO-JOURNAL-V2.md). The app stores the key of what
/// the person chose and shows it back in their words; nothing is translated
/// into any other category.
class JournalLabels {
  JournalLabels._();

  static const List<String> times = ['passado', 'presente', 'futuro'];
  static const List<String> regions = [
    'cabeca',
    'peito',
    'barriga',
    'costas',
    'membros',
  ];
  static const List<String> triggers = [
    'trabalho',
    'familia',
    'sono',
    'alimentacao',
    'esforco',
    'queda',
    'medicamento',
    'clima',
    'nao_sei',
    'outro',
  ];

  /// Label for any marker used in counts: an option key, a region, a time
  /// or a trigger (bare or as `trigger:<key>`). Null when unknown.
  static String? marker(AppLocalizations l10n, String key) {
    if (key.startsWith('trigger:')) return trigger(l10n, key.substring(8));
    return option(l10n, key) ??
        region(l10n, key) ??
        time(l10n, key) ??
        trigger(l10n, key);
  }

  static String? option(AppLocalizations l10n, String key) => switch (key) {
        'passado.tristeza.culpa' => l10n.xv2OptPassadoTristezaCulpa,
        'passado.tristeza.saudade' => l10n.xv2OptPassadoTristezaSaudade,
        'passado.memoria.lembranca' => l10n.xv2OptPassadoMemoriaLembranca,
        'passado.memoria.magoa' => l10n.xv2OptPassadoMemoriaMagoa,
        'presente.energia.corpo' => l10n.xv2OptPresenteEnergiaCorpo,
        'presente.energia.desligado' => l10n.xv2OptPresenteEnergiaDesligado,
        'presente.sobrecarga.paciencia' => l10n.xv2OptPresenteSobrecargaPaciencia,
        'presente.sobrecarga.aperto' => l10n.xv2OptPresenteSobrecargaAperto,
        'futuro.mente.antecipar' => l10n.xv2OptFuturoMenteAntecipar,
        'futuro.mente.cobranca' => l10n.xv2OptFuturoMenteCobranca,
        'futuro.medo.julgamento' => l10n.xv2OptFuturoMedoJulgamento,
        'futuro.medo.desanimo' => l10n.xv2OptFuturoMedoDesanimo,
        'cabeca.pressao.temporas' => l10n.xv2OptCabecaPressaoTemporas,
        'cabeca.pressao.latejando' => l10n.xv2OptCabecaPressaoLatejando,
        'cabeca.sentidos.garganta' => l10n.xv2OptCabecaSentidosGarganta,
        'cabeca.sentidos.olhos' => l10n.xv2OptCabecaSentidosOlhos,
        'peito.respiracao.curta' => l10n.xv2OptPeitoRespiracaoCurta,
        'peito.respiracao.tosse' => l10n.xv2OptPeitoRespiracaoTosse,
        'peito.incomodo.batedeira' => l10n.xv2OptPeitoIncomodoBatedeira,
        'peito.incomodo.costelas' => l10n.xv2OptPeitoIncomodoCostelas,
        'barriga.queimacao.subindo' => l10n.xv2OptBarrigaQueimacaoSubindo,
        'barriga.queimacao.enjoo' => l10n.xv2OptBarrigaQueimacaoEnjoo,
        'barriga.colica.gases' => l10n.xv2OptBarrigaColicaGases,
        'barriga.colica.pontadas' => l10n.xv2OptBarrigaColicaPontadas,
        'costas.rigidez.ombros' => l10n.xv2OptCostasRigidezOmbros,
        'costas.rigidez.lombar' => l10n.xv2OptCostasRigidezLombar,
        'costas.fisgada.irradia' => l10n.xv2OptCostasFisgadaIrradia,
        'costas.fisgada.ao_mexer' => l10n.xv2OptCostasFisgadaAoMexer,
        'membros.cansaco.juntas' => l10n.xv2OptMembrosCansacoJuntas,
        'membros.cansaco.pesados' => l10n.xv2OptMembrosCansacoPesados,
        'membros.formigamento.dormentes' => l10n.xv2OptMembrosFormigamentoDormentes,
        'membros.formigamento.choque' => l10n.xv2OptMembrosFormigamentoChoque,
        _ => null,
      };

  static String? region(AppLocalizations l10n, String key) => switch (key) {
        'cabeca' => l10n.xv2RegionCabeca,
        'peito' => l10n.xv2RegionPeito,
        'barriga' => l10n.xv2RegionBarriga,
        'costas' => l10n.xv2RegionCostas,
        'membros' => l10n.xv2RegionMembros,
        _ => null,
      };

  static String? time(AppLocalizations l10n, String key) => switch (key) {
        'passado' => l10n.xv2TimePassado,
        'presente' => l10n.xv2TimePresente,
        'futuro' => l10n.xv2TimeFuturo,
        _ => null,
      };

  static String? timeShort(AppLocalizations l10n, String key) => switch (key) {
        'passado' => l10n.xv2TimeShortPassado,
        'presente' => l10n.xv2TimeShortPresente,
        'futuro' => l10n.xv2TimeShortFuturo,
        _ => null,
      };

  static String? trigger(AppLocalizations l10n, String key) => switch (key) {
        'trabalho' => l10n.xv2TriggerTrabalho,
        'familia' => l10n.xv2TriggerFamilia,
        'sono' => l10n.xv2TriggerSono,
        'alimentacao' => l10n.xv2TriggerAlimentacao,
        'esforco' => l10n.xv2TriggerEsforco,
        'queda' => l10n.xv2TriggerQueda,
        'medicamento' => l10n.xv2TriggerMedicamento,
        'clima' => l10n.xv2TriggerClima,
        'nao_sei' => l10n.xv2TriggerNaoSei,
        'outro' => l10n.xv2TriggerOutro,
        _ => null,
      };

  static String mood(AppLocalizations l10n, String key) => switch (key) {
        'bem' => l10n.xv2MoodBem,
        'normal' => l10n.xv2MoodNormal,
        _ => l10n.xv2MoodNaoTaoBem,
      };
}
