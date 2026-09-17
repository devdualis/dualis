import 'triage_question.dart';
import 'triage_vertical.dart';

class TriageQuestionBank {
  const TriageQuestionBank._();

  static const List<TriageQuestion> psicoEmocional = [
    TriageQuestion(
      stepIndex: 0,
      questionKey: 'triageQ1Emotional',
      options: [
        TriageOption(
          key: 'ansiosa_agitacao',
          labelKey: 'triageOptAnsiosaAgitacao',
          systemKey: 'ansiosa_agitacao',
        ),
        TriageOption(
          key: 'depressiva_desanimo',
          labelKey: 'triageOptDepressivaDesanimo',
          systemKey: 'depressiva_desanimo',
        ),
        TriageOption(
          key: 'estresse_burnout',
          labelKey: 'triageOptEstresseBurnout',
          systemKey: 'estresse_burnout',
        ),
        TriageOption(
          key: 'somatica',
          labelKey: 'triageOptSomatica',
          systemKey: 'somatica',
        ),
        TriageOption(
          key: 'sono',
          labelKey: 'triageOptSono',
          systemKey: 'sono',
        ),
        TriageOption(
          key: 'cognitiva_foco',
          labelKey: 'triageOptCognitivaFoco',
          systemKey: 'cognitiva_foco',
        ),
        TriageOption(
          key: 'autoestima',
          labelKey: 'triageOptAutoestima',
          systemKey: 'autoestima',
        ),
      ],
    ),
    TriageQuestion(
      stepIndex: 1,
      questionKey: 'triageQ2Emotional',
      options: [
        TriageOption(key: 'comecou_hoje', labelKey: 'triageOptComecouHoje'),
        TriageOption(key: 'ja_faz_alguns_dias', labelKey: 'triageOptJaFazDias'),
        TriageOption(
          key: 'algo_constante_semanas',
          labelKey: 'triageOptConstanteSemanas',
        ),
      ],
    ),
    TriageQuestion(
      stepIndex: 2,
      questionKey: 'triageQ3Emotional',
      options: [
        TriageOption(
          key: 'leve_controlavel',
          labelKey: 'triageOptLeveControlavel',
          intensityValue: 2,
        ),
        TriageOption(
          key: 'moderada',
          labelKey: 'triageOptModerada',
          intensityValue: 3,
        ),
        TriageOption(
          key: 'muito_forte',
          labelKey: 'triageOptMuitoForte',
          intensityValue: 4,
        ),
      ],
    ),
    TriageQuestion(
      stepIndex: 3,
      questionKey: 'triageQ4Emotional',
      options: [
        TriageOption(key: 'trabalho_estudos', labelKey: 'triageOptTrabalho'),
        TriageOption(
          key: 'familia_relacionamentos',
          labelKey: 'triageOptFamilia',
        ),
        TriageOption(key: 'noite_ruim_sono', labelKey: 'triageOptNoiteRuim'),
        TriageOption(key: 'nao_sei_dizer', labelKey: 'triageOptNaoSei'),
      ],
    ),
    TriageQuestion(
      stepIndex: 4,
      questionKey: 'triagePreviewEmotional',
      options: [],
      isPreview: true,
    ),
  ];

  static const List<TriageQuestion> fisica = [
    TriageQuestion(
      stepIndex: 0,
      questionKey: 'triageQ1Physical',
      options: [
        TriageOption(
          key: 'cabeca_pescoco',
          labelKey: 'triageOptCabecaPescoco',
          systemKey: 'cabeca_pescoco',
        ),
        TriageOption(
          key: 'cardiovascular_torax',
          labelKey: 'triageOptCardiovascularTorax',
          systemKey: 'cardiovascular_torax',
        ),
        TriageOption(
          key: 'respiratorio',
          labelKey: 'triageOptRespiratorio',
          systemKey: 'respiratorio',
        ),
        TriageOption(
          key: 'gastrointestinal_abdomen',
          labelKey: 'triageOptGastrointestinalAbdomen',
          systemKey: 'gastrointestinal_abdomen',
        ),
        TriageOption(
          key: 'coluna_dor_dorsal',
          labelKey: 'triageOptColunaDorDorsal',
          systemKey: 'coluna_dor_dorsal',
        ),
        TriageOption(
          key: 'membros_superiores',
          labelKey: 'triageOptMembrosSuperiores',
          systemKey: 'membros_superiores',
        ),
        TriageOption(
          key: 'membros_inferiores',
          labelKey: 'triageOptMembrosInferiores',
          systemKey: 'membros_inferiores',
        ),
        TriageOption(
          key: 'neurologico',
          labelKey: 'triageOptNeurologico',
          systemKey: 'neurologico',
        ),
        TriageOption(
          key: 'geniturinario_pelvico',
          labelKey: 'triageOptGeniturinarioPelvico',
          systemKey: 'geniturinario_pelvico',
        ),
        TriageOption(
          key: 'dermatologico',
          labelKey: 'triageOptDermatologico',
          systemKey: 'dermatologico',
        ),
        TriageOption(
          key: 'muscular_geral_sistemico',
          labelKey: 'triageOptMuscularGeralSistemico',
          systemKey: 'muscular_geral_sistemico',
        ),
        TriageOption(
          key: 'endocrino_metabolico',
          labelKey: 'triageOptEndocrinoMetabolico',
          systemKey: 'endocrino_metabolico',
        ),
      ],
    ),
    TriageQuestion(
      stepIndex: 1,
      questionKey: 'triageQ2Physical',
      options: [
        TriageOption(key: 'comecou_agora', labelKey: 'triageOptComecouAgora'),
        TriageOption(
          key: 'ha_alguns_dias',
          labelKey: 'triageOptHaAlgunsDias',
        ),
        TriageOption(key: 'e_cronica', labelKey: 'triageOptCronica'),
      ],
    ),
    TriageQuestion(
      stepIndex: 2,
      questionKey: 'triageQ3Physical',
      options: [],
      isNumericScale: true,
    ),
    TriageQuestion(
      stepIndex: 3,
      questionKey: 'triageQ4Physical',
      options: [
        TriageOption(
          key: 'sim_exercicio_intenso',
          labelKey: 'triageOptSimExercicio',
        ),
        TriageOption(key: 'sim_sofri_queda', labelKey: 'triageOptSimQueda'),
        TriageOption(
          key: 'nao_comecou_do_nada',
          labelKey: 'triageOptNaoComecouNada',
        ),
      ],
    ),
    TriageQuestion(
      stepIndex: 4,
      questionKey: 'triagePreviewPhysical',
      options: [],
      isPreview: true,
    ),
  ];

  static const TriageQuestion _fisicaStep3CabecaPescoco = TriageQuestion(
    stepIndex: 3,
    questionKey: 'triageQ4CabecaPescoco',
    options: [
      TriageOption(
        key: 'sim_estresse_sono',
        labelKey: 'triageOptSimEstresseSono',
      ),
      TriageOption(
        key: 'sim_telas_esforco_visual',
        labelKey: 'triageOptSimTelasEsforcoVisual',
      ),
      TriageOption(
        key: 'sim_postura_pescoco',
        labelKey: 'triageOptSimPosturaPescoco',
      ),
      TriageOption(
        key: 'sim_resfriado_sinusite',
        labelKey: 'triageOptSimResfriadoSinusite',
      ),
      TriageOption(
        key: 'nao_comecou_do_nada',
        labelKey: 'triageOptNaoComecouNada',
      ),
    ],
  );

  static const TriageQuestion _fisicaStep3CardiovascularTorax = TriageQuestion(
    stepIndex: 3,
    questionKey: 'triageQ4CardiovascularTorax',
    options: [
      TriageOption(
        key: 'sim_esforco_fisico',
        labelKey: 'triageOptSimEsforcoFisico',
      ),
      TriageOption(
        key: 'sim_estresse_ansiedade',
        labelKey: 'triageOptSimEstresseAnsiedade',
      ),
      TriageOption(
        key: 'sim_cafeina_estimulante',
        labelKey: 'triageOptSimCafeinaEstimulante',
      ),
      TriageOption(
        key: 'nao_surgiu_em_repouso',
        labelKey: 'triageOptNaoSurgiuEmRepouso',
      ),
    ],
  );

  static const TriageQuestion _fisicaStep3Respiratorio = TriageQuestion(
    stepIndex: 3,
    questionKey: 'triageQ4Respiratorio',
    options: [
      TriageOption(
        key: 'sim_alergia_ambiente',
        labelKey: 'triageOptSimAlergiaAmbiente',
      ),
      TriageOption(
        key: 'sim_gripe_infeccao',
        labelKey: 'triageOptSimGripeInfeccao',
      ),
      TriageOption(
        key: 'sim_mudanca_clima',
        labelKey: 'triageOptSimMudancaClima',
      ),
      TriageOption(
        key: 'nao_comecou_do_nada',
        labelKey: 'triageOptNaoComecouNada',
      ),
    ],
  );

  static const TriageQuestion _fisicaStep3Gastrointestinal = TriageQuestion(
    stepIndex: 3,
    questionKey: 'triageQ4Gastrointestinal',
    options: [
      TriageOption(
        key: 'sim_alimentacao_diferente',
        labelKey: 'triageOptSimAlimentacaoDiferente',
      ),
      TriageOption(
        key: 'sim_medicamento_recente',
        labelKey: 'triageOptSimMedicamentoRecente',
      ),
      TriageOption(
        key: 'sim_jejum_estresse',
        labelKey: 'triageOptSimJejumEstresse',
      ),
      TriageOption(
        key: 'nao_sem_relacao_alimento',
        labelKey: 'triageOptNaoSemRelacaoAlimento',
      ),
    ],
  );

  static const TriageQuestion _fisicaStep3ColunaDorDorsal = TriageQuestion(
    stepIndex: 3,
    questionKey: 'triageQ4ColunaDorDorsal',
    options: [
      TriageOption(
        key: 'sim_carregou_peso',
        labelKey: 'triageOptSimCarregouPeso',
      ),
      TriageOption(
        key: 'sim_postura_prolongada',
        labelKey: 'triageOptSimPosturaProlongada',
      ),
      TriageOption(
        key: 'sim_mau_jeito_queda',
        labelKey: 'triageOptSimMauJeitoQueda',
      ),
      TriageOption(
        key: 'nao_comecou_do_nada',
        labelKey: 'triageOptNaoComecouNada',
      ),
    ],
  );

  static const TriageQuestion _fisicaStep3MembrosSuperiores = TriageQuestion(
    stepIndex: 3,
    questionKey: 'triageQ4MembrosSuperiores',
    options: [
      TriageOption(
        key: 'sim_movimento_repetitivo',
        labelKey: 'triageOptSimMovimentoRepetitivo',
      ),
      TriageOption(
        key: 'sim_treino_sobrecarga',
        labelKey: 'triageOptSimTreinoSobrecarga',
      ),
      TriageOption(
        key: 'sim_trauma_pancada',
        labelKey: 'triageOptSimTraumaPancada',
      ),
      TriageOption(
        key: 'nao_comecou_do_nada',
        labelKey: 'triageOptNaoComecouNada',
      ),
    ],
  );

  static const TriageQuestion _fisicaStep3MembrosInferiores = TriageQuestion(
    stepIndex: 3,
    questionKey: 'triageQ4MembrosInferiores',
    options: [
      TriageOption(
        key: 'sim_caminhada_corrida',
        labelKey: 'triageOptSimCaminhadaCorrida',
      ),
      TriageOption(
        key: 'sim_tempo_em_pe_sentado',
        labelKey: 'triageOptSimTempoEmPeSentado',
      ),
      TriageOption(
        key: 'sim_torcao_tropeco',
        labelKey: 'triageOptSimTorcaoTropeco',
      ),
      TriageOption(
        key: 'nao_comecou_do_nada',
        labelKey: 'triageOptNaoComecouNada',
      ),
    ],
  );

  static const TriageQuestion _fisicaStep3Neurologico = TriageQuestion(
    stepIndex: 3,
    questionKey: 'triageQ4Neurologico',
    options: [
      TriageOption(
        key: 'sim_levantar_rapido',
        labelKey: 'triageOptSimLevantarRapido',
      ),
      TriageOption(
        key: 'sim_jejum_desidratacao',
        labelKey: 'triageOptSimJejumDesidratacao',
      ),
      TriageOption(
        key: 'sim_ansiedade_hiperventilacao',
        labelKey: 'triageOptSimAnsiedadeHiperventilacao',
      ),
      TriageOption(
        key: 'sim_compressao_postural',
        labelKey: 'triageOptSimCompressaoPostural',
      ),
      TriageOption(
        key: 'nao_comecou_do_nada',
        labelKey: 'triageOptNaoComecouNada',
      ),
    ],
  );

  static const TriageQuestion _fisicaStep3Geniturinario = TriageQuestion(
    stepIndex: 3,
    questionKey: 'triageQ4Geniturinario',
    options: [
      TriageOption(
        key: 'sim_baixa_ingestao_urina',
        labelKey: 'triageOptSimBaixaIngestaoUrina',
      ),
      TriageOption(
        key: 'sim_ciclo_menstrual',
        labelKey: 'triageOptSimCicloMenstrual',
      ),
      TriageOption(
        key: 'sim_pos_relacao_intima',
        labelKey: 'triageOptSimPosRelacaoIntima',
      ),
      TriageOption(
        key: 'sim_roupas_umidas',
        labelKey: 'triageOptSimRoupasUmidas',
      ),
      TriageOption(
        key: 'nao_comecou_do_nada',
        labelKey: 'triageOptNaoComecouNada',
      ),
    ],
  );

  static const TriageQuestion _fisicaStep3Dermatologica = TriageQuestion(
    stepIndex: 3,
    questionKey: 'triageQ4Dermatological',
    options: [
      TriageOption(
        key: 'sim_produto_novo',
        labelKey: 'triageOptSimProdutoNovo',
      ),
      TriageOption(
        key: 'sim_exposicao_sol_calor',
        labelKey: 'triageOptSimExposicaoSolCalor',
      ),
      TriageOption(
        key: 'sim_picada_contato',
        labelKey: 'triageOptSimPicadaContato',
      ),
      TriageOption(
        key: 'nao_comecou_do_nada',
        labelKey: 'triageOptNaoComecouNada',
      ),
    ],
  );

  static const TriageQuestion _fisicaStep3MuscularGeral = TriageQuestion(
    stepIndex: 3,
    questionKey: 'triageQ4MuscularGeral',
    options: [
      TriageOption(
        key: 'sim_cansaco_esgotamento',
        labelKey: 'triageOptSimCansacoEsgotamento',
      ),
      TriageOption(
        key: 'sim_sintomas_gripe_virose',
        labelKey: 'triageOptSimSintomasGripeVirose',
      ),
      TriageOption(
        key: 'sim_atividade_global',
        labelKey: 'triageOptSimAtividadeGlobal',
      ),
      TriageOption(
        key: 'sim_desidratacao_calor',
        labelKey: 'triageOptSimDesidratacaoCalor',
      ),
      TriageOption(
        key: 'nao_comecou_do_nada',
        labelKey: 'triageOptNaoComecouNada',
      ),
    ],
  );

  static const TriageQuestion _fisicaStep3EndocrinoMetabolico = TriageQuestion(
    stepIndex: 3,
    questionKey: 'triageQ4EndocrinoMetabolico',
    options: [
      TriageOption(
        key: 'sim_jejum_alimentacao',
        labelKey: 'triageOptSimJejumAlimentacao',
      ),
      TriageOption(
        key: 'sim_ajuste_medicamento',
        labelKey: 'triageOptSimAjusteMedicamento',
      ),
      TriageOption(
        key: 'sim_calor_desidratacao',
        labelKey: 'triageOptSimCalorDesidratacao',
      ),
      TriageOption(
        key: 'sim_estresse_sobrecarga',
        labelKey: 'triageOptSimEstresseSobrecarga',
      ),
      TriageOption(
        key: 'nao_comecou_do_nada',
        labelKey: 'triageOptNaoComecouNada',
      ),
    ],
  );

  static const TriageQuestion _emocionalStep3Ansiedade = TriageQuestion(
    stepIndex: 3,
    questionKey: 'triageQ4Ansiedade',
    options: [
      TriageOption(
        key: 'sim_cobranca_prazos',
        labelKey: 'triageOptSimCobrancaPrazos',
      ),
      TriageOption(
        key: 'sim_conflito_relacionamento',
        labelKey: 'triageOptSimConflitoRelacionamento',
      ),
      TriageOption(
        key: 'sim_incerteza_futuro',
        labelKey: 'triageOptSimIncertezaFuturo',
      ),
      TriageOption(
        key: 'sim_excesso_estimulantes',
        labelKey: 'triageOptSimExcessoEstimulantes',
      ),
      TriageOption(
        key: 'nao_sei_dizer_emocional',
        labelKey: 'triageOptNaoSeiDizerEmocional',
      ),
    ],
  );

  static const TriageQuestion _emocionalStep3Depressao = TriageQuestion(
    stepIndex: 3,
    questionKey: 'triageQ4Depressao',
    options: [
      TriageOption(
        key: 'sim_perda_luto',
        labelKey: 'triageOptSimPerdaLuto',
      ),
      TriageOption(
        key: 'sim_solidao_isolamento',
        labelKey: 'triageOptSimSolidaoIsolamento',
      ),
      TriageOption(
        key: 'sim_frustracao_desilusao',
        labelKey: 'triageOptSimFrustracaoDesilusao',
      ),
      TriageOption(
        key: 'sim_cansaco_acumulado',
        labelKey: 'triageOptSimCansacoAcumulado',
      ),
      TriageOption(
        key: 'nao_sei_dizer_emocional',
        labelKey: 'triageOptNaoSeiDizerEmocional',
      ),
    ],
  );

  static const TriageQuestion _emocionalStep3EstresseBurnout = TriageQuestion(
    stepIndex: 3,
    questionKey: 'triageQ4EstresseBurnout',
    options: [
      TriageOption(
        key: 'sim_pressao_trabalho',
        labelKey: 'triageOptSimPressaoTrabalho',
      ),
      TriageOption(
        key: 'sim_responsabilidades_casa',
        labelKey: 'triageOptSimResponsabilidadesCasa',
      ),
      TriageOption(
        key: 'sim_falta_descanso',
        labelKey: 'triageOptSimFaltaDescanso',
      ),
      TriageOption(
        key: 'sim_ambiente_toxico',
        labelKey: 'triageOptSimAmbienteToxico',
      ),
      TriageOption(
        key: 'nao_sei_dizer_emocional',
        labelKey: 'triageOptNaoSeiDizerEmocional',
      ),
    ],
  );

  static const TriageQuestion _emocionalStep3Somatica = TriageQuestion(
    stepIndex: 3,
    questionKey: 'triageQ4Somatica',
    options: [
      TriageOption(
        key: 'sim_durante_trabalho',
        labelKey: 'triageOptSimDuranteTrabalho',
      ),
      TriageOption(
        key: 'sim_discussao_conflito',
        labelKey: 'triageOptSimDiscussaoConflito',
      ),
      TriageOption(
        key: 'sim_final_do_dia',
        labelKey: 'triageOptSimFinalDoDia',
      ),
      TriageOption(
        key: 'sim_preocupacao_constante',
        labelKey: 'triageOptSimPreocupacaoConstante',
      ),
      TriageOption(
        key: 'nao_sei_dizer_emocional',
        labelKey: 'triageOptNaoSeiDizerEmocional',
      ),
    ],
  );

  static const TriageQuestion _emocionalStep3Sono = TriageQuestion(
    stepIndex: 3,
    questionKey: 'triageQ4Sono',
    options: [
      TriageOption(
        key: 'sim_dificuldade_pegar_sono',
        labelKey: 'triageOptSimDificuldadePegarSono',
      ),
      TriageOption(
        key: 'sim_acorda_madrugada',
        labelKey: 'triageOptSimAcordaMadrugada',
      ),
      TriageOption(
        key: 'sim_sono_agitado_pesadelos',
        labelKey: 'triageOptSimSonoAgitadoPesadelos',
      ),
      TriageOption(
        key: 'sim_horario_irregular_telas',
        labelKey: 'triageOptSimHorarioIrregularTelas',
      ),
      TriageOption(
        key: 'nao_sei_dizer_emocional',
        labelKey: 'triageOptNaoSeiDizerEmocional',
      ),
    ],
  );

  static const TriageQuestion _emocionalStep3CognitivaFoco = TriageQuestion(
    stepIndex: 3,
    questionKey: 'triageQ4CognitivaFoco',
    options: [
      TriageOption(
        key: 'sim_sobrecarga_multitarefas',
        labelKey: 'triageOptSimSobrecargaMultitarefas',
      ),
      TriageOption(
        key: 'sim_preocupacao_intrusiva',
        labelKey: 'triageOptSimPreocupacaoIntrusiva',
      ),
      TriageOption(
        key: 'sim_exaustao_mental',
        labelKey: 'triageOptSimExaustaoMental',
      ),
      TriageOption(
        key: 'sim_falta_motivacao',
        labelKey: 'triageOptSimFaltaMotivacao',
      ),
      TriageOption(
        key: 'nao_sei_dizer_emocional',
        labelKey: 'triageOptNaoSeiDizerEmocional',
      ),
    ],
  );

  static const TriageQuestion _emocionalStep3Autoestima = TriageQuestion(
    stepIndex: 3,
    questionKey: 'triageQ4Autoestima',
    options: [
      TriageOption(
        key: 'sim_comparacao_redes',
        labelKey: 'triageOptSimComparacaoRedes',
      ),
      TriageOption(
        key: 'sim_medo_falhar_julgamento',
        labelKey: 'triageOptSimMedoFalharJulgamento',
      ),
      TriageOption(
        key: 'sim_critica_rejeicao',
        labelKey: 'triageOptSimCriticaRejeicao',
      ),
      TriageOption(
        key: 'sim_desvalorizacao_propria',
        labelKey: 'triageOptSimDesvalorizacaoPropria',
      ),
      TriageOption(
        key: 'nao_sei_dizer_emocional',
        labelKey: 'triageOptNaoSeiDizerEmocional',
      ),
    ],
  );

  static TriageQuestion _emotionalStep3ForDimension(String? systemKey) {
    switch (systemKey) {
      case 'ansiosa_agitacao':
      case 'ansiedade_agitacao':
      case 'ansiedade':
      case 'anxious_agitation':
      case 'anxiety':
        return _emocionalStep3Ansiedade;

      case 'depressiva_desanimo':
      case 'tristeza_desanimo':
      case 'depressao':
      case 'tristeza':
      case 'depressive_hopelessness':
      case 'depression':
        return _emocionalStep3Depressao;

      case 'estresse_burnout':
      case 'estresse_irritabilidade':
      case 'estresse':
      case 'burnout':
      case 'stress_burnout':
      case 'stress':
        return _emocionalStep3EstresseBurnout;

      case 'somatica':
      case 'somatico':
      case 'psychosomatic':
      case 'somatic':
        return _emocionalStep3Somatica;

      case 'sono':
      case 'sono_repouso':
      case 'sleep':
      case 'insonia':
        return _emocionalStep3Sono;

      case 'cognitiva_foco':
      case 'cognitivo':
      case 'foco':
      case 'cansaco_mental':
      case 'emotional_general':
      case 'cognitive':
        return _emocionalStep3CognitivaFoco;

      case 'autoestima':
      case 'autoimagem':
      case 'self_esteem':
        return _emocionalStep3Autoestima;

      default:
        return psicoEmocional[3];
    }
  }

  static TriageQuestion _physicalStep3ForSystem(String? systemKey) {
    switch (systemKey) {
      case 'cabeca_pescoco':
      case 'cabeca':
      case 'head_neck':
        return _fisicaStep3CabecaPescoco;

      case 'cardiovascular_torax':
      case 'cardiovascular':
      case 'cardiovascular_chest':
        return _fisicaStep3CardiovascularTorax;

      case 'respiratorio':
      case 'respiratory':
        return _fisicaStep3Respiratorio;

      case 'gastrointestinal_abdomen':
      case 'gastrointestinal':
      case 'abdomen':
      case 'abdomen_estomago':
        return _fisicaStep3Gastrointestinal;

      case 'coluna_dor_dorsal':
      case 'coluna_dorsal':
      case 'costas':
      case 'costas_coluna':
      case 'musculoskeletal_back':
        return _fisicaStep3ColunaDorDorsal;

      case 'membros_superiores':
      case 'musculoskeletal_joints':
        return _fisicaStep3MembrosSuperiores;

      case 'membros_inferiores':
        return _fisicaStep3MembrosInferiores;

      case 'neurologico':
      case 'neurological':
        return _fisicaStep3Neurologico;

      case 'geniturinario_pelvico':
      case 'geniturinario':
        return _fisicaStep3Geniturinario;

      case 'dermatologico':
      case 'dermatological':
      case 'dermatologia':
        return _fisicaStep3Dermatologica;

      case 'muscular_geral_sistemico':
      case 'muscular':
      case 'general_somatic':
        return _fisicaStep3MuscularGeral;

      case 'endocrino_metabolico':
      case 'endocrino':
        return _fisicaStep3EndocrinoMetabolico;

      default:
        return fisica[3];
    }
  }

  /// Returns the question set for [v]. For both verticals, [systemKey]
  /// (the step-0 answer) swaps in a domain-appropriate step-3 question tailored
  /// to each of the 7 emotional dimensions or 12 physical systems.
  static List<TriageQuestion> forVertical(TriageVertical v, {String? systemKey}) {
    if (v == TriageVertical.psicoEmocional) {
      if (systemKey == null || systemKey.isEmpty) return psicoEmocional;
      final step3 = _emotionalStep3ForDimension(systemKey);
      return [
        psicoEmocional[0],
        psicoEmocional[1],
        psicoEmocional[2],
        step3,
        psicoEmocional[4],
      ];
    }
    if (systemKey == null || systemKey.isEmpty) return fisica;
    final step3 = _physicalStep3ForSystem(systemKey);
    return [
      fisica[0],
      fisica[1],
      fisica[2],
      step3,
      fisica[4],
    ];
  }
}
