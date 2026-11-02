// GENERATED from the jv2 strings list. Maps journal v2 keys to the user's
// language. Keys are resolved on the device; nothing is translated into
// another vocabulary.
import '../../../l10n/app_localizations.dart';

class JournalLabels {
  JournalLabels._();

  static const List<String> times = ['passado', 'presente', 'futuro'];
  static const List<String> regions = [
    'cabeca',
    'peito',
    'barriga',
    'pelve',
    'costas',
    'membros',
    'pele',
    'musculos',
    'hormonios',
  ];

  /// Any summary marker: option, branch, bare region/time, or `trigger:<key>`.
  static String? marker(AppLocalizations l10n, String key) {
    if (key.startsWith('trigger:')) return _triggerOrNull(l10n, key.substring(8));
    return _optionOrNull(l10n, key) ??
        _branchOrNull(l10n, key) ??
        region(l10n, key) ??
        time(l10n, key) ??
        _triggerOrNull(l10n, key);
  }

  /// Text of a final option key (`<root>.<branch>.<option>`).
  static String option(AppLocalizations l10n, String key) {
    switch (key) {
      case 'passado.tristeza.culpa':
        return l10n.jv2OptPassadoTristezaCulpa;
      case 'passado.tristeza.saudade':
        return l10n.jv2OptPassadoTristezaSaudade;
      case 'passado.memoria.lembranca':
        return l10n.jv2OptPassadoMemoriaLembranca;
      case 'passado.memoria.magoa':
        return l10n.jv2OptPassadoMemoriaMagoa;
      case 'presente.energia.corpo':
        return l10n.jv2OptPresenteEnergiaCorpo;
      case 'presente.energia.desligado':
        return l10n.jv2OptPresenteEnergiaDesligado;
      case 'presente.sobrecarga.paciencia':
        return l10n.jv2OptPresenteSobrecargaPaciencia;
      case 'presente.sobrecarga.aperto':
        return l10n.jv2OptPresenteSobrecargaAperto;
      case 'futuro.mente.antecipar':
        return l10n.jv2OptFuturoMenteAntecipar;
      case 'futuro.mente.cobranca':
        return l10n.jv2OptFuturoMenteCobranca;
      case 'futuro.medo.julgamento':
        return l10n.jv2OptFuturoMedoJulgamento;
      case 'futuro.medo.desanimo':
        return l10n.jv2OptFuturoMedoDesanimo;
      case 'cabeca.pressao.temporas':
        return l10n.jv2OptCabecaPressaoTemporas;
      case 'cabeca.pressao.latejando':
        return l10n.jv2OptCabecaPressaoLatejando;
      case 'cabeca.sentidos.garganta':
        return l10n.jv2OptCabecaSentidosGarganta;
      case 'cabeca.sentidos.olhos':
        return l10n.jv2OptCabecaSentidosOlhos;
      case 'peito.respiracao.curta':
        return l10n.jv2OptPeitoRespiracaoCurta;
      case 'peito.respiracao.tosse':
        return l10n.jv2OptPeitoRespiracaoTosse;
      case 'peito.incomodo.batedeira':
        return l10n.jv2OptPeitoIncomodoBatedeira;
      case 'peito.incomodo.costelas':
        return l10n.jv2OptPeitoIncomodoCostelas;
      case 'barriga.queimacao.subindo':
        return l10n.jv2OptBarrigaQueimacaoSubindo;
      case 'barriga.queimacao.enjoo':
        return l10n.jv2OptBarrigaQueimacaoEnjoo;
      case 'barriga.colica.gases':
        return l10n.jv2OptBarrigaColicaGases;
      case 'barriga.colica.pontadas':
        return l10n.jv2OptBarrigaColicaPontadas;
      case 'costas.rigidez.ombros':
        return l10n.jv2OptCostasRigidezOmbros;
      case 'costas.rigidez.lombar':
        return l10n.jv2OptCostasRigidezLombar;
      case 'costas.fisgada.irradia':
        return l10n.jv2OptCostasFisgadaIrradia;
      case 'costas.fisgada.ao_mexer':
        return l10n.jv2OptCostasFisgadaAoMexer;
      case 'membros.cansaco.juntas':
        return l10n.jv2OptMembrosCansacoJuntas;
      case 'membros.cansaco.pesados':
        return l10n.jv2OptMembrosCansacoPesados;
      case 'membros.formigamento.dormentes':
        return l10n.jv2OptMembrosFormigamentoDormentes;
      case 'membros.formigamento.choque':
        return l10n.jv2OptMembrosFormigamentoChoque;
      case 'cabeca.nuca.rigida':
        return l10n.jv2OptCabecaNucaRigida;
      case 'cabeca.nuca.pontada':
        return l10n.jv2OptCabecaNucaPontada;
      case 'pele.coceira.coceira':
        return l10n.jv2OptPeleCoceiraCoceira;
      case 'pele.coceira.ardencia':
        return l10n.jv2OptPeleCoceiraArdencia;
      case 'pele.aparencia.vermelhidao':
        return l10n.jv2OptPeleAparenciaVermelhidao;
      case 'pele.aparencia.manchas':
        return l10n.jv2OptPeleAparenciaManchas;
      case 'musculos.tensao.rigidez':
        return l10n.jv2OptMusculosTensaoRigidez;
      case 'musculos.tensao.caibra':
        return l10n.jv2OptMusculosTensaoCaibra;
      case 'musculos.cansaco.fraqueza':
        return l10n.jv2OptMusculosCansacoFraqueza;
      case 'musculos.cansaco.dolorido':
        return l10n.jv2OptMusculosCansacoDolorido;
      case 'hormonios.temperatura.calorao':
        return l10n.jv2OptHormoniosTemperaturaCalorao;
      case 'hormonios.temperatura.frio':
        return l10n.jv2OptHormoniosTemperaturaFrio;
      case 'hormonios.apetite.sede':
        return l10n.jv2OptHormoniosApetiteSede;
      case 'hormonios.apetite.fome':
        return l10n.jv2OptHormoniosApetiteFome;
      // v2.2: new emotional and physical options.
      case 'passado.memoria.vergonha':
        return l10n.jv22OptPassadoMemoriaVergonha;
      case 'presente.energia.concentracao':
        return l10n.jv22OptPresenteEnergiaConcentracao;
      case 'presente.sobrecarga.muita_coisa':
        return l10n.jv22OptPresenteSobrecargaMuitaCoisa;
      case 'presente.sobrecarga.inquieto':
        return l10n.jv22OptPresenteSobrecargaInquieto;
      case 'presente.solidao.sozinho':
        return l10n.jv22OptPresenteSolidaoSozinho;
      case 'presente.solidao.menos':
        return l10n.jv22OptPresenteSolidaoMenos;
      case 'futuro.mente.indecisao':
        return l10n.jv22OptFuturoMenteIndecisao;
      case 'futuro.medo.evitar':
        return l10n.jv22OptFuturoMedoEvitar;
      case 'cabeca.rosto.tontura':
        return l10n.jv22OptCabecaRostoTontura;
      case 'cabeca.rosto.nariz':
        return l10n.jv22OptCabecaRostoNariz;
      case 'cabeca.rosto.ouvido':
        return l10n.jv22OptCabecaRostoOuvido;
      case 'cabeca.rosto.mandibula':
        return l10n.jv22OptCabecaRostoMandibula;
      case 'barriga.colica.menstrual':
        return l10n.jv22OptBarrigaColicaMenstrual;
      case 'barriga.intestino.preso':
        return l10n.jv22OptBarrigaIntestinoPreso;
      case 'barriga.intestino.solto':
        return l10n.jv22OptBarrigaIntestinoSolto;
      // v2.3: pelvis and lower belly.
      case 'pelve.urina.ardencia':
        return l10n.jv23OptPelveUrinaArdencia;
      case 'pelve.urina.vontade':
        return l10n.jv23OptPelveUrinaVontade;
      case 'pelve.urina.dificuldade':
        return l10n.jv23OptPelveUrinaDificuldade;
      case 'pelve.urina.cor_odor':
        return l10n.jv23OptPelveUrinaCorOdor;
      case 'pelve.baixo_ventre.colica':
        return l10n.jv23OptPelveBaixoVentreColica;
      case 'pelve.baixo_ventre.peso':
        return l10n.jv23OptPelveBaixoVentrePeso;
      case 'pelve.baixo_ventre.menstrual':
        return l10n.jv23OptPelveBaixoVentreMenstrual;
      case 'pelve.intima.coceira':
        return l10n.jv23OptPelveIntimaCoceira;
      case 'pelve.intima.inchaco':
        return l10n.jv23OptPelveIntimaInchaco;
      // v2.2: good moments.
      case 'passado.gratidao.alguem':
        return l10n.jv22OptPassadoGratidaoAlguem;
      case 'passado.gratidao.algo':
        return l10n.jv22OptPassadoGratidaoAlgo;
      case 'passado.orgulho.conquista':
        return l10n.jv22OptPassadoOrgulhoConquista;
      case 'passado.orgulho.resolvi':
        return l10n.jv22OptPassadoOrgulhoResolvi;
      case 'presente.calma.paz':
        return l10n.jv22OptPresenteCalmaPaz;
      case 'presente.calma.descansado':
        return l10n.jv22OptPresenteCalmaDescansado;
      case 'presente.conexao.pessoas':
        return l10n.jv22OptPresenteConexaoPessoas;
      case 'presente.conexao.foco':
        return l10n.jv22OptPresenteConexaoFoco;
      case 'futuro.animo.planos':
        return l10n.jv22OptFuturoAnimoPlanos;
      case 'futuro.animo.esperanca':
        return l10n.jv22OptFuturoAnimoEsperanca;
      case 'futuro.confianca.confiante':
        return l10n.jv22OptFuturoConfiancaConfiante;
      case 'futuro.confianca.preparado':
        return l10n.jv22OptFuturoConfiancaPreparado;
      default:
        return key;
    }
  }

  static String? _optionOrNull(AppLocalizations l10n, String key) {
    final text = option(l10n, key);
    return text == key ? null : text;
  }

  /// Text of a branch key (`<root>.<branch>`).
  static String branch(AppLocalizations l10n, String key) {
    switch (key) {
      case 'passado.tristeza':
        return l10n.jv2BranchPassadoTristeza;
      case 'passado.memoria':
        return l10n.jv2BranchPassadoMemoria;
      case 'presente.energia':
        return l10n.jv2BranchPresenteEnergia;
      case 'presente.sobrecarga':
        return l10n.jv2BranchPresenteSobrecarga;
      case 'futuro.mente':
        return l10n.jv2BranchFuturoMente;
      case 'futuro.medo':
        return l10n.jv2BranchFuturoMedo;
      case 'cabeca.pressao':
        return l10n.jv2BranchCabecaPressao;
      case 'cabeca.sentidos':
        return l10n.jv2BranchCabecaSentidos;
      case 'peito.respiracao':
        return l10n.jv2BranchPeitoRespiracao;
      case 'peito.incomodo':
        return l10n.jv2BranchPeitoIncomodo;
      case 'barriga.queimacao':
        return l10n.jv2BranchBarrigaQueimacao;
      case 'barriga.colica':
        return l10n.jv2BranchBarrigaColica;
      case 'costas.rigidez':
        return l10n.jv2BranchCostasRigidez;
      case 'costas.fisgada':
        return l10n.jv2BranchCostasFisgada;
      case 'membros.cansaco':
        return l10n.jv2BranchMembrosCansaco;
      case 'membros.formigamento':
        return l10n.jv2BranchMembrosFormigamento;
      case 'cabeca.nuca':
        return l10n.jv2BranchCabecaNuca;
      case 'pele.coceira':
        return l10n.jv2BranchPeleCoceira;
      case 'pele.aparencia':
        return l10n.jv2BranchPeleAparencia;
      case 'musculos.tensao':
        return l10n.jv2BranchMusculosTensao;
      case 'musculos.cansaco':
        return l10n.jv2BranchMusculosCansaco;
      case 'hormonios.temperatura':
        return l10n.jv2BranchHormoniosTemperatura;
      case 'hormonios.apetite':
        return l10n.jv2BranchHormoniosApetite;
      case 'presente.solidao':
        return l10n.jv22BranchPresenteSolidao;
      case 'cabeca.rosto':
        return l10n.jv22BranchCabecaRosto;
      case 'barriga.intestino':
        return l10n.jv22BranchBarrigaIntestino;
      case 'pelve.urina':
        return l10n.jv23BranchPelveUrina;
      case 'pelve.baixo_ventre':
        return l10n.jv23BranchPelveBaixoVentre;
      case 'pelve.intima':
        return l10n.jv23BranchPelveIntima;
      case 'passado.gratidao':
        return l10n.jv22BranchPassadoGratidao;
      case 'passado.orgulho':
        return l10n.jv22BranchPassadoOrgulho;
      case 'presente.calma':
        return l10n.jv22BranchPresenteCalma;
      case 'presente.conexao':
        return l10n.jv22BranchPresenteConexao;
      case 'futuro.animo':
        return l10n.jv22BranchFuturoAnimo;
      case 'futuro.confianca':
        return l10n.jv22BranchFuturoConfianca;
      default:
        return key;
    }
  }

  static String? _branchOrNull(AppLocalizations l10n, String key) {
    final text = branch(l10n, key);
    return text == key ? null : text;
  }

  /// Text of a time (emotional) or body region (physical).
  static String root(AppLocalizations l10n, String key) =>
      time(l10n, key) ?? region(l10n, key) ?? key;

  static String? region(AppLocalizations l10n, String key) => switch (key) {
        'cabeca' => l10n.jv2RegionCabeca,
        'peito' => l10n.jv2RegionPeito,
        'barriga' => l10n.jv2RegionBarriga,
        'pelve' => l10n.jv23RegionPelve,
        'costas' => l10n.jv2RegionCostas,
        'membros' => l10n.jv2RegionMembros,
        'pele' => l10n.jv2RegionPele,
        'musculos' => l10n.jv2RegionMusculos,
        'hormonios' => l10n.jv2RegionHormonios,
        _ => null,
      };

  static String? time(AppLocalizations l10n, String key) => switch (key) {
        'passado' => l10n.jv2TimePassado,
        'presente' => l10n.jv2TimePresente,
        'futuro' => l10n.jv2TimeFuturo,
        _ => null,
      };

  static String? timeShort(AppLocalizations l10n, String key) => switch (key) {
        'passado' => l10n.jv2TimeShortPassado,
        'presente' => l10n.jv2TimeShortPresente,
        'futuro' => l10n.jv2TimeShortFuturo,
        _ => null,
      };

  /// Text of a trigger key.
  static String trigger(AppLocalizations l10n, String key) {
    switch (key) {
      case 'trabalho':
        return l10n.jv2TriggerTrabalho;
      case 'familia':
        return l10n.jv2TriggerFamilia;
      case 'sono':
        return l10n.jv2TriggerSono;
      case 'dinheiro':
        return l10n.jv22TriggerDinheiro;
      case 'telas':
        return l10n.jv22TriggerTelas;
      case 'ciclo':
        return l10n.jv22TriggerCiclo;
      case 'alimentacao':
        return l10n.jv2TriggerAlimentacao;
      case 'esforco':
        return l10n.jv2TriggerEsforco;
      case 'queda':
        return l10n.jv2TriggerQueda;
      case 'medicamento':
        return l10n.jv2TriggerMedicamento;
      case 'clima':
        return l10n.jv2TriggerClima;
      case 'nao_sei':
        return l10n.jv2TriggerNaoSei;
      case 'outro':
        return l10n.jv2TriggerOutro;
      default:
        return key;
    }
  }

  static String? _triggerOrNull(AppLocalizations l10n, String key) {
    final text = trigger(l10n, key);
    return text == key ? null : text;
  }

  /// Text of a persistence key.
  static String persistence(AppLocalizations l10n, String key) {
    switch (key) {
      case 'hoje':
        return l10n.jv2PersistenceHoje;
      case 'dias_semanas':
        return l10n.jv2PersistenceDiasSemanas;
      case 'meses_anos':
        return l10n.jv2PersistenceMesesAnos;
      default:
        return key;
    }
  }

  /// Text of a physical item's sensation (`dor` / `incomodo`).
  static String sensation(AppLocalizations l10n, String key) {
    switch (key) {
      case 'dor':
        return l10n.jv2SensationDor;
      case 'incomodo':
        return l10n.jv2SensationIncomodo;
      default:
        return key;
    }
  }

  /// Text of a coping key ("Como foi lidar com isso?").
  static String coping(AppLocalizations l10n, String key) => switch (key) {
        'consegui' => l10n.jv22CopingConsegui,
        'esperei' => l10n.jv22CopingEsperei,
        'dificil' => l10n.jv22CopingDificil,
        _ => key,
      };

  /// Text of a helper key ("O que te ajudou hoje?").
  static String helper(AppLocalizations l10n, String key) => switch (key) {
        'mexer_corpo' => l10n.jv22HelperMexerCorpo,
        'conversar' => l10n.jv22HelperConversar,
        'pausa' => l10n.jv22HelperPausa,
        'lazer' => l10n.jv22HelperLazer,
        'descansar' => l10n.jv22HelperDescansar,
        'beber_agua' => l10n.jv22HelperBeberAgua,
        'remedio' => l10n.jv22HelperRemedio,
        'repouso' => l10n.jv22HelperRepouso,
        'compressa' => l10n.jv22HelperCompressa,
        'alimentacao_leve' => l10n.jv22HelperAlimentacaoLeve,
        'consulta_medica' => l10n.jv22HelperConsultaMedica,
        'nada_ainda' => l10n.jv22HelperNadaAinda,
        _ => key,
      };

  /// Name of an entry axis (`emotional` / `physical`).
  static String axis(AppLocalizations l10n, String key) {
    switch (key) {
      case 'emotional':
        return l10n.jv2AxisEmotional;
      case 'physical':
        return l10n.jv2AxisPhysical;
      default:
        return key;
    }
  }

  /// Text of a general mood key.
  static String mood(AppLocalizations l10n, String key) {
    switch (key) {
      case 'bem':
        return l10n.jv2MoodBem;
      case 'normal':
        return l10n.jv2MoodNormal;
      case 'nao_tao_bem':
        return l10n.jv2MoodNaoTaoBem;
      default:
        return key;
    }
  }

  /// Text of a transition phrase variant id (`<screen>.<n>`).
  static String phrase(AppLocalizations l10n, String key) {
    switch (key) {
      case 'time.1':
        return l10n.jv2PhraseTime1;
      case 'time.2':
        return l10n.jv2PhraseTime2;
      case 'time.3':
        return l10n.jv2PhraseTime3;
      case 'time.4':
        return l10n.jv2PhraseTime4;
      case 'passado.1':
        return l10n.jv2PhrasePassado1;
      case 'passado.2':
        return l10n.jv2PhrasePassado2;
      case 'passado.3':
        return l10n.jv2PhrasePassado3;
      case 'passado.4':
        return l10n.jv2PhrasePassado4;
      case 'passado.5':
        return l10n.jv2PhrasePassado5;
      case 'passado.6':
        return l10n.jv2PhrasePassado6;
      case 'passado.7':
        return l10n.jv2PhrasePassado7;
      case 'presente.1':
        return l10n.jv2PhrasePresente1;
      case 'presente.2':
        return l10n.jv2PhrasePresente2;
      case 'presente.3':
        return l10n.jv2PhrasePresente3;
      case 'presente.4':
        return l10n.jv2PhrasePresente4;
      case 'presente.5':
        return l10n.jv2PhrasePresente5;
      case 'presente.6':
        return l10n.jv2PhrasePresente6;
      case 'presente.7':
        return l10n.jv2PhrasePresente7;
      case 'futuro.1':
        return l10n.jv2PhraseFuturo1;
      case 'futuro.2':
        return l10n.jv2PhraseFuturo2;
      case 'futuro.3':
        return l10n.jv2PhraseFuturo3;
      case 'futuro.4':
        return l10n.jv2PhraseFuturo4;
      case 'futuro.5':
        return l10n.jv2PhraseFuturo5;
      case 'futuro.6':
        return l10n.jv2PhraseFuturo6;
      case 'futuro.7':
        return l10n.jv2PhraseFuturo7;
      case 'passado.tristeza.1':
        return l10n.jv2PhrasePassadoTristeza1;
      case 'passado.tristeza.2':
        return l10n.jv2PhrasePassadoTristeza2;
      case 'passado.tristeza.3':
        return l10n.jv2PhrasePassadoTristeza3;
      case 'passado.tristeza.4':
        return l10n.jv2PhrasePassadoTristeza4;
      case 'passado.tristeza.5':
        return l10n.jv2PhrasePassadoTristeza5;
      case 'passado.tristeza.6':
        return l10n.jv2PhrasePassadoTristeza6;
      case 'passado.tristeza.7':
        return l10n.jv2PhrasePassadoTristeza7;
      case 'passado.memoria.1':
        return l10n.jv2PhrasePassadoMemoria1;
      case 'passado.memoria.2':
        return l10n.jv2PhrasePassadoMemoria2;
      case 'passado.memoria.3':
        return l10n.jv2PhrasePassadoMemoria3;
      case 'passado.memoria.4':
        return l10n.jv2PhrasePassadoMemoria4;
      case 'passado.memoria.5':
        return l10n.jv2PhrasePassadoMemoria5;
      case 'passado.memoria.6':
        return l10n.jv2PhrasePassadoMemoria6;
      case 'passado.memoria.7':
        return l10n.jv2PhrasePassadoMemoria7;
      case 'presente.energia.1':
        return l10n.jv2PhrasePresenteEnergia1;
      case 'presente.energia.2':
        return l10n.jv2PhrasePresenteEnergia2;
      case 'presente.energia.3':
        return l10n.jv2PhrasePresenteEnergia3;
      case 'presente.energia.4':
        return l10n.jv2PhrasePresenteEnergia4;
      case 'presente.energia.5':
        return l10n.jv2PhrasePresenteEnergia5;
      case 'presente.energia.6':
        return l10n.jv2PhrasePresenteEnergia6;
      case 'presente.energia.7':
        return l10n.jv2PhrasePresenteEnergia7;
      case 'presente.sobrecarga.1':
        return l10n.jv2PhrasePresenteSobrecarga1;
      case 'presente.sobrecarga.2':
        return l10n.jv2PhrasePresenteSobrecarga2;
      case 'presente.sobrecarga.3':
        return l10n.jv2PhrasePresenteSobrecarga3;
      case 'presente.sobrecarga.4':
        return l10n.jv2PhrasePresenteSobrecarga4;
      case 'presente.sobrecarga.5':
        return l10n.jv2PhrasePresenteSobrecarga5;
      case 'presente.sobrecarga.6':
        return l10n.jv2PhrasePresenteSobrecarga6;
      case 'presente.sobrecarga.7':
        return l10n.jv2PhrasePresenteSobrecarga7;
      case 'presente.solidao.1':
        return l10n.jv2PhrasePresenteSolidao1;
      case 'presente.solidao.2':
        return l10n.jv2PhrasePresenteSolidao2;
      case 'presente.solidao.3':
        return l10n.jv2PhrasePresenteSolidao3;
      case 'presente.solidao.4':
        return l10n.jv2PhrasePresenteSolidao4;
      case 'presente.solidao.5':
        return l10n.jv2PhrasePresenteSolidao5;
      case 'presente.solidao.6':
        return l10n.jv2PhrasePresenteSolidao6;
      case 'presente.solidao.7':
        return l10n.jv2PhrasePresenteSolidao7;
      case 'futuro.mente.1':
        return l10n.jv2PhraseFuturoMente1;
      case 'futuro.mente.2':
        return l10n.jv2PhraseFuturoMente2;
      case 'futuro.mente.3':
        return l10n.jv2PhraseFuturoMente3;
      case 'futuro.mente.4':
        return l10n.jv2PhraseFuturoMente4;
      case 'futuro.mente.5':
        return l10n.jv2PhraseFuturoMente5;
      case 'futuro.mente.6':
        return l10n.jv2PhraseFuturoMente6;
      case 'futuro.mente.7':
        return l10n.jv2PhraseFuturoMente7;
      case 'futuro.medo.1':
        return l10n.jv2PhraseFuturoMedo1;
      case 'futuro.medo.2':
        return l10n.jv2PhraseFuturoMedo2;
      case 'futuro.medo.3':
        return l10n.jv2PhraseFuturoMedo3;
      case 'futuro.medo.4':
        return l10n.jv2PhraseFuturoMedo4;
      case 'futuro.medo.5':
        return l10n.jv2PhraseFuturoMedo5;
      case 'futuro.medo.6':
        return l10n.jv2PhraseFuturoMedo6;
      case 'futuro.medo.7':
        return l10n.jv2PhraseFuturoMedo7;
      case 'region.cabeca.1':
        return l10n.jv2PhraseRegionCabeca1;
      case 'region.cabeca.2':
        return l10n.jv2PhraseRegionCabeca2;
      case 'region.cabeca.3':
        return l10n.jv2PhraseRegionCabeca3;
      case 'region.cabeca.4':
        return l10n.jv2PhraseRegionCabeca4;
      case 'region.cabeca.5':
        return l10n.jv2PhraseRegionCabeca5;
      case 'region.cabeca.6':
        return l10n.jv2PhraseRegionCabeca6;
      case 'region.cabeca.7':
        return l10n.jv2PhraseRegionCabeca7;
      case 'region.peito.1':
        return l10n.jv2PhraseRegionPeito1;
      case 'region.peito.2':
        return l10n.jv2PhraseRegionPeito2;
      case 'region.peito.3':
        return l10n.jv2PhraseRegionPeito3;
      case 'region.peito.4':
        return l10n.jv2PhraseRegionPeito4;
      case 'region.peito.5':
        return l10n.jv2PhraseRegionPeito5;
      case 'region.peito.6':
        return l10n.jv2PhraseRegionPeito6;
      case 'region.peito.7':
        return l10n.jv2PhraseRegionPeito7;
      case 'region.barriga.1':
        return l10n.jv2PhraseRegionBarriga1;
      case 'region.barriga.2':
        return l10n.jv2PhraseRegionBarriga2;
      case 'region.barriga.3':
        return l10n.jv2PhraseRegionBarriga3;
      case 'region.barriga.4':
        return l10n.jv2PhraseRegionBarriga4;
      case 'region.barriga.5':
        return l10n.jv2PhraseRegionBarriga5;
      case 'region.barriga.6':
        return l10n.jv2PhraseRegionBarriga6;
      case 'region.barriga.7':
        return l10n.jv2PhraseRegionBarriga7;
      case 'region.costas.1':
        return l10n.jv2PhraseRegionCostas1;
      case 'region.costas.2':
        return l10n.jv2PhraseRegionCostas2;
      case 'region.costas.3':
        return l10n.jv2PhraseRegionCostas3;
      case 'region.costas.4':
        return l10n.jv2PhraseRegionCostas4;
      case 'region.costas.5':
        return l10n.jv2PhraseRegionCostas5;
      case 'region.costas.6':
        return l10n.jv2PhraseRegionCostas6;
      case 'region.costas.7':
        return l10n.jv2PhraseRegionCostas7;
      case 'region.membros.1':
        return l10n.jv2PhraseRegionMembros1;
      case 'region.membros.2':
        return l10n.jv2PhraseRegionMembros2;
      case 'region.membros.3':
        return l10n.jv2PhraseRegionMembros3;
      case 'region.membros.4':
        return l10n.jv2PhraseRegionMembros4;
      case 'region.membros.5':
        return l10n.jv2PhraseRegionMembros5;
      case 'region.membros.6':
        return l10n.jv2PhraseRegionMembros6;
      case 'region.membros.7':
        return l10n.jv2PhraseRegionMembros7;
      case 'thanks.1':
        return l10n.jv2PhraseThanks1;
      case 'body.1':
        return l10n.jv2PhraseBody1;
      case 'body.2':
        return l10n.jv2PhraseBody2;
      case 'body.3':
        return l10n.jv2PhraseBody3;
      case 'region.1':
        return l10n.jv2PhraseRegion1;
      case 'region.2':
        return l10n.jv2PhraseRegion2;
      case 'region.3':
        return l10n.jv2PhraseRegion3;
      case 'region.4':
        return l10n.jv2PhraseRegion4;
      case 'triggers.1':
        return l10n.jv2PhraseTriggers1;
      case 'triggers.2':
        return l10n.jv2PhraseTriggers2;
      case 'triggers.3':
        return l10n.jv2PhraseTriggers3;
      case 'positive.1':
        return l10n.jv22PhrasePositive1;
      case 'positive.2':
        return l10n.jv22PhrasePositive2;
      case 'positive.3':
        return l10n.jv22PhrasePositive3;
      case 'closing.1':
        return l10n.jv22PhraseClosing1;
      case 'closing.2':
        return l10n.jv22PhraseClosing2;
      case 'closing.3':
        return l10n.jv22PhraseClosing3;
      default:
        return key;
    }
  }

  /// Approved transition phrase variants per pool (strategy section 7).
  static const Map<String, int> phrasePools = {
    'time': 4,
    // Screen 2 of the emotional flow, by time (client spec, 7 each).
    'passado': 7,
    'presente': 7,
    'futuro': 7,
    // Screen 3 of the emotional flow, by branch (7 each).
    'passado.tristeza': 7,
    'passado.memoria': 7,
    'presente.energia': 7,
    'presente.sobrecarga': 7,
    'presente.solidao': 7,
    'futuro.mente': 7,
    'futuro.medo': 7,
    'body': 3,
    // "É dor ou incômodo?" of the client's five regions (7 each); the
    // other areas use the shared `region` pool.
    'region.cabeca': 7,
    'region.peito': 7,
    'region.barriga': 7,
    'region.costas': 7,
    'region.membros': 7,
    'region': 4,
    // Fixed thank-you before persistence and intensity.
    'thanks': 1,
    'triggers': 3,
    'positive': 3,
    'closing': 3,
  };
}
