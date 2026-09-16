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

      default:
        final intVal = int.tryParse(key);
        if (intVal != null) {
          return l10n.triageIntensityLabel(intVal);
        }
        return key;
    }
  }

  static String _physicalTriggerLabel(String? systemOrDimension) {
    switch (systemOrDimension) {
      case 'dermatologico':
        return 'Possível Gatilho / Exposição';
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
            'Motivo / Gatilho',
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
