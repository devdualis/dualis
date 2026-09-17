import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/triage_vertical.dart';

class TriagePreviewCard extends StatelessWidget {
  final TriageVertical vertical;
  final Map<int, String> answers;
  final Color activeColor;

  const TriagePreviewCard({
    super.key,
    required this.vertical,
    required this.answers,
    required this.activeColor,
  });

  static String resolveAnswerLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context);
    switch (key) {
      case 'ansiedade_agitacao':
        return l10n.triageOptAnsiedade;
      case 'ansiosa_agitacao':
        return l10n.triageOptAnsiosaAgitacao;
      case 'tristeza_desanimo':
        return l10n.triageOptTristeza;
      case 'depressiva_desanimo':
        return l10n.triageOptDepressivaDesanimo;
      case 'estresse_irritabilidade':
        return l10n.triageOptEstresse;
      case 'estresse_burnout':
        return l10n.triageOptEstresseBurnout;
      case 'cansaco_mental':
        return l10n.triageOptCansaco;
      case 'somatica':
        return l10n.triageOptSomatica;
      case 'sono':
        return l10n.triageOptSono;
      case 'cognitiva_foco':
        return l10n.triageOptCognitivaFoco;
      case 'autoestima':
        return l10n.triageOptAutoestima;

      case 'comecou_hoje':
        return l10n.triageOptComecouHoje;
      case 'ja_faz_alguns_dias':
        return l10n.triageOptJaFazDias;
      case 'algo_constante_semanas':
        return l10n.triageOptConstanteSemanas;

      case 'leve_controlavel':
        return l10n.triageOptLeveControlavel;
      case 'moderada':
        return l10n.triageOptModerada;
      case 'muito_forte':
        return l10n.triageOptMuitoForte;

      case 'trabalho_estudos':
        return l10n.triageOptTrabalho;
      case 'familia_relacionamentos':
        return l10n.triageOptFamilia;
      case 'noite_ruim_sono':
        return l10n.triageOptNoiteRuim;
      case 'nao_sei_dizer':
        return l10n.triageOptNaoSei;

      case 'cabeca':
        return l10n.triageOptCabeca;
      case 'cabeca_pescoco':
        return l10n.triageOptCabecaPescoco;
      case 'costas_coluna':
        return l10n.triageOptCostas;
      case 'coluna_dor_dorsal':
        return l10n.triageOptColunaDorDorsal;
      case 'articulacoes':
        return l10n.triageOptArticulacoes;
      case 'abdomen_estomago':
        return l10n.triageOptAbdomen;
      case 'gastrointestinal_abdomen':
        return l10n.triageOptGastrointestinalAbdomen;
      case 'cardiovascular_torax':
        return l10n.triageOptCardiovascularTorax;
      case 'respiratorio':
        return l10n.triageOptRespiratorio;
      case 'membros_superiores':
        return l10n.triageOptMembrosSuperiores;
      case 'membros_inferiores':
        return l10n.triageOptMembrosInferiores;
      case 'neurologico':
        return l10n.triageOptNeurologico;
      case 'geniturinario_pelvico':
        return l10n.triageOptGeniturinarioPelvico;
      case 'dermatologico':
        return l10n.triageOptDermatologico;
      case 'muscular_geral_sistemico':
        return l10n.triageOptMuscularGeralSistemico;
      case 'endocrino_metabolico':
        return l10n.triageOptEndocrinoMetabolico;

      case 'comecou_agora':
        return l10n.triageOptComecouAgora;
      case 'ha_alguns_dias':
        return l10n.triageOptHaAlgunsDias;
      case 'e_cronica':
        return l10n.triageOptCronica;

      case 'sim_exercicio_intenso':
        return l10n.triageOptSimExercicio;
      case 'sim_sofri_queda':
        return l10n.triageOptSimQueda;
      case 'nao_comecou_do_nada':
        return l10n.triageOptNaoComecouNada;

      case 'sim_produto_novo':
        return l10n.triageOptSimProdutoNovo;
      case 'sim_exposicao_sol_calor':
        return l10n.triageOptSimExposicaoSolCalor;
      case 'sim_picada_contato':
        return l10n.triageOptSimPicadaContato;

      case 'sim_estresse_sono':
        return l10n.triageOptSimEstresseSono;
      case 'sim_telas_esforco_visual':
        return l10n.triageOptSimTelasEsforcoVisual;
      case 'sim_postura_pescoco':
        return l10n.triageOptSimPosturaPescoco;
      case 'sim_resfriado_sinusite':
        return l10n.triageOptSimResfriadoSinusite;

      case 'sim_esforco_fisico':
        return l10n.triageOptSimEsforcoFisico;
      case 'sim_estresse_ansiedade':
        return l10n.triageOptSimEstresseAnsiedade;
      case 'sim_cafeina_estimulante':
        return l10n.triageOptSimCafeinaEstimulante;
      case 'nao_surgiu_em_repouso':
        return l10n.triageOptNaoSurgiuEmRepouso;

      case 'sim_alergia_ambiente':
        return l10n.triageOptSimAlergiaAmbiente;
      case 'sim_gripe_infeccao':
        return l10n.triageOptSimGripeInfeccao;
      case 'sim_mudanca_clima':
        return l10n.triageOptSimMudancaClima;

      case 'sim_alimentacao_diferente':
        return l10n.triageOptSimAlimentacaoDiferente;
      case 'sim_medicamento_recente':
        return l10n.triageOptSimMedicamentoRecente;
      case 'sim_jejum_estresse':
        return l10n.triageOptSimJejumEstresse;
      case 'nao_sem_relacao_alimento':
        return l10n.triageOptNaoSemRelacaoAlimento;

      case 'sim_carregou_peso':
        return l10n.triageOptSimCarregouPeso;
      case 'sim_postura_prolongada':
        return l10n.triageOptSimPosturaProlongada;
      case 'sim_mau_jeito_queda':
        return l10n.triageOptSimMauJeitoQueda;

      case 'sim_movimento_repetitivo':
        return l10n.triageOptSimMovimentoRepetitivo;
      case 'sim_treino_sobrecarga':
        return l10n.triageOptSimTreinoSobrecarga;
      case 'sim_trauma_pancada':
        return l10n.triageOptSimTraumaPancada;

      case 'sim_caminhada_corrida':
        return l10n.triageOptSimCaminhadaCorrida;
      case 'sim_tempo_em_pe_sentado':
        return l10n.triageOptSimTempoEmPeSentado;
      case 'sim_torcao_tropeco':
        return l10n.triageOptSimTorcaoTropeco;

      case 'sim_levantar_rapido':
        return l10n.triageOptSimLevantarRapido;
      case 'sim_jejum_desidratacao':
        return l10n.triageOptSimJejumDesidratacao;
      case 'sim_ansiedade_hiperventilacao':
        return l10n.triageOptSimAnsiedadeHiperventilacao;
      case 'sim_compressao_postural':
        return l10n.triageOptSimCompressaoPostural;

      case 'sim_baixa_ingestao_urina':
        return l10n.triageOptSimBaixaIngestaoUrina;
      case 'sim_ciclo_menstrual':
        return l10n.triageOptSimCicloMenstrual;
      case 'sim_pos_relacao_intima':
        return l10n.triageOptSimPosRelacaoIntima;
      case 'sim_roupas_umidas':
        return l10n.triageOptSimRoupasUmidas;

      case 'sim_cansaco_esgotamento':
        return l10n.triageOptSimCansacoEsgotamento;
      case 'sim_sintomas_gripe_virose':
        return l10n.triageOptSimSintomasGripeVirose;
      case 'sim_atividade_global':
        return l10n.triageOptSimAtividadeGlobal;
      case 'sim_desidratacao_calor':
        return l10n.triageOptSimDesidratacaoCalor;

      case 'sim_jejum_alimentacao':
        return l10n.triageOptSimJejumAlimentacao;
      case 'sim_ajuste_medicamento':
        return l10n.triageOptSimAjusteMedicamento;
      case 'sim_calor_desidratacao':
        return l10n.triageOptSimCalorDesidratacao;
      case 'sim_estresse_sobrecarga':
        return l10n.triageOptSimEstresseSobrecarga;

      // Emotional specialized triggers
      case 'sim_cobranca_prazos':
        return l10n.triageOptSimCobrancaPrazos;
      case 'sim_conflito_relacionamento':
        return l10n.triageOptSimConflitoRelacionamento;
      case 'sim_incerteza_futuro':
        return l10n.triageOptSimIncertezaFuturo;
      case 'sim_excesso_estimulantes':
        return l10n.triageOptSimExcessoEstimulantes;
      case 'nao_sei_dizer_emocional':
        return l10n.triageOptNaoSeiDizerEmocional;

      case 'sim_perda_luto':
        return l10n.triageOptSimPerdaLuto;
      case 'sim_solidao_isolamento':
        return l10n.triageOptSimSolidaoIsolamento;
      case 'sim_frustracao_desilusao':
        return l10n.triageOptSimFrustracaoDesilusao;
      case 'sim_cansaco_acumulado':
        return l10n.triageOptSimCansacoAcumulado;

      case 'sim_pressao_trabalho':
        return l10n.triageOptSimPressaoTrabalho;
      case 'sim_responsabilidades_casa':
        return l10n.triageOptSimResponsabilidadesCasa;
      case 'sim_falta_descanso':
        return l10n.triageOptSimFaltaDescanso;
      case 'sim_ambiente_toxico':
        return l10n.triageOptSimAmbienteToxico;

      case 'sim_durante_trabalho':
        return l10n.triageOptSimDuranteTrabalho;
      case 'sim_discussao_conflito':
        return l10n.triageOptSimDiscussaoConflito;
      case 'sim_final_do_dia':
        return l10n.triageOptSimFinalDoDia;
      case 'sim_preocupacao_constante':
        return l10n.triageOptSimPreocupacaoConstante;

      case 'sim_dificuldade_pegar_sono':
        return l10n.triageOptSimDificuldadePegarSono;
      case 'sim_acorda_madrugada':
        return l10n.triageOptSimAcordaMadrugada;
      case 'sim_sono_agitado_pesadelos':
        return l10n.triageOptSimSonoAgitadoPesadelos;
      case 'sim_horario_irregular_telas':
        return l10n.triageOptSimHorarioIrregularTelas;

      case 'sim_sobrecarga_multitarefas':
        return l10n.triageOptSimSobrecargaMultitarefas;
      case 'sim_preocupacao_intrusiva':
        return l10n.triageOptSimPreocupacaoIntrusiva;
      case 'sim_exaustao_mental':
        return l10n.triageOptSimExaustaoMental;
      case 'sim_falta_motivacao':
        return l10n.triageOptSimFaltaMotivacao;

      case 'sim_comparacao_redes':
        return l10n.triageOptSimComparacaoRedes;
      case 'sim_medo_falhar_julgamento':
        return l10n.triageOptSimMedoFalharJulgamento;
      case 'sim_critica_rejeicao':
        return l10n.triageOptSimCriticaRejeicao;
      case 'sim_desvalorizacao_propria':
        return l10n.triageOptSimDesvalorizacaoPropria;

      default:
        final intVal = int.tryParse(key);
        if (intVal != null) {
          return l10n.triageIntensityLabel(intVal);
        }
        return key;
    }
  }

  static String _emotionalTriggerLabel(String? systemOrDimension) {
    switch (systemOrDimension) {
      case 'ansiosa_agitacao':
      case 'ansiedade_agitacao':
      case 'anxious_agitation':
        return 'Fator Desencadeante / Gatilho';
      case 'depressiva_desanimo':
      case 'tristeza_desanimo':
      case 'depressive_hopelessness':
        return 'Contexto / Fator Associado';
      case 'estresse_burnout':
      case 'estresse_irritabilidade':
      case 'stress_burnout':
        return 'Fonte de Pressão / Sobrecarga';
      case 'somatica':
        return 'Momento / Fator Desencadeante';
      case 'sono':
        return 'Fator que Atrapalha o Sono';
      case 'cognitiva_foco':
      case 'cansaco_mental':
      case 'emotional_general':
        return 'Causa Principal / Sobrecarga';
      case 'autoestima':
        return 'Situação / Contexto Associado';
      default:
        return 'Motivo / Gatilho';
    }
  }

  static String _physicalTriggerLabel(String? systemOrDimension) {
    switch (systemOrDimension) {
      case 'dermatologico':
      case 'dermatological':
      case 'dermatologia':
        return 'Possível Gatilho / Exposição';
      case 'gastrointestinal_abdomen':
      case 'gastrointestinal':
      case 'abdomen':
      case 'abdomen_estomago':
        return 'Alimentação / Fator Desencadeante';
      case 'respiratorio':
      case 'respiratory':
        return 'Ambiente / Fator Desencadeante';
      case 'cardiovascular_torax':
      case 'cardiovascular':
      case 'cardiovascular_chest':
        return 'Contexto / Fator Desencadeante';
      case 'cabeca_pescoco':
      case 'cabeca':
      case 'head_neck':
        return 'Contexto / Fator Associado';
      case 'neurologico':
      case 'neurological':
        return 'Contexto / Fator Desencadeante';
      case 'geniturinario_pelvico':
      case 'geniturinario':
        return 'Fator Associado / Gatilho';
      case 'endocrino_metabolico':
      case 'endocrino':
        return 'Fator Associado / Rotina';
      case 'muscular_geral_sistemico':
      case 'muscular':
      case 'general_somatic':
        return 'Contexto / Causa Provável';
      case 'membros_superiores':
      case 'membros_inferiores':
      case 'coluna_dor_dorsal':
      case 'coluna_dorsal':
      case 'costas':
      case 'costas_coluna':
      default:
        return 'Histórico de Esforço / Queda';
    }
  }

  static String _physicalLocationLabel(String? systemOrDimension) {
    switch (systemOrDimension) {
      case 'dermatologico':
        return 'Localização da Coceira / Lesão';
      case 'gastrointestinal_abdomen':
      case 'respiratorio':
      case 'neurologico':
      case 'geniturinario_pelvico':
      case 'endocrino_metabolico':
        return 'Localização do Desconforto';
      default:
        return 'Localização da Dor';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isEmotional = vertical == TriageVertical.psicoEmocional;
    final stepLabels = isEmotional
        ? [
            'Natureza do Sintoma',
            'Tempo / Persistência',
            'Intensidade Relatada',
            _emotionalTriggerLabel(answers[0]),
          ]
        : [
            _physicalLocationLabel(answers[0]),
            'Tempo / Persistência',
            'Intensidade Relatada',
            _physicalTriggerLabel(answers[0]),
          ];

    return Card(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fact_check_outlined,
                  color: activeColor,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isEmotional
                        ? l10n.triagePreviewEmotional
                        : l10n.triagePreviewPhysical,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...List.generate(4, (index) {
              final stepTitle = stepLabels[index];
              final rawAnswer = answers[index];
              final displayValue = rawAnswer != null
                  ? resolveAnswerLabel(context, rawAnswer)
                  : '—';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: activeColor,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stepTitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            displayValue,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
