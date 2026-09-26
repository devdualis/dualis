import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/triage_history_models.dart';
import 'retrospective_list_view.dart';

class TriageHistoryDetailModal extends StatelessWidget {
  final TriageHistoryEntry entry;

  const TriageHistoryDetailModal({
    super.key,
    required this.entry,
  });

  static Future<void> show(BuildContext context, TriageHistoryEntry entry) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TriageHistoryDetailModal(entry: entry),
    );
  }

  static String formatDateTimeFull(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year às $hour:$minute';
  }

  static String getIntensityDescription(int intensity) {
    switch (intensity) {
      case 1:
        return 'Nível 1 - Mínimo';
      case 2:
        return 'Nível 2 - Leve';
      case 3:
        return 'Nível 3 - Moderado';
      case 4:
        return 'Nível 4 - Severo / Urgente';
      case 5:
        return 'Nível 5 - Crítico / Emergência';
      default:
        return 'Nível $intensity';
    }
  }

  static String getDispositionDescription(String? disposition) {
    switch (disposition) {
      case 'auto_cuidado':
        return 'Autocuidado orientado com repouso, hidratação e observação de novos sintomas.';
      case 'consulta_rotina':
        return 'Consulta médica ambulatorial recomendada nos próximos dias para avaliação com especialista.';
      case 'pronto_atendimento':
        return 'Avaliação presencial em pronto atendimento recomendada para investigação clínica prioritária.';
      case 'emergencia':
        return 'Atendimento médico imediato de emergência hospitalar recomendado.';
      default:
        return 'Acompanhamento clínico e observação da evolução dos sintomas.';
    }
  }

  static IconData getDispositionIcon(String? disposition) {
    switch (disposition) {
      case 'auto_cuidado':
        return Icons.spa_rounded;
      case 'consulta_rotina':
        return Icons.event_available_rounded;
      case 'pronto_atendimento':
        return Icons.medical_services_rounded;
      case 'emergencia':
        return Icons.emergency_rounded;
      default:
        return Icons.fact_check_rounded;
    }
  }

  static Color getDispositionColor(String? disposition) {
    switch (disposition) {
      case 'auto_cuidado':
        return AppColors.clinicalTeal;
      case 'consulta_rotina':
        return const Color(0xFF0288D1);
      case 'pronto_atendimento':
        return const Color(0xFFF57C00);
      case 'emergencia':
        return AppColors.emergencyCrimson;
      default:
        return Colors.grey.shade700;
    }
  }

  static String _formatAnswerValue(String key) {
    final map = {
      'comecou_agora': 'Começou agora',
      'comecou_hoje': 'Começou hoje',
      'ha_alguns_dias': 'Já faz alguns dias',
      'ja_faz_alguns_dias': 'Já faz alguns dias',
      'e_cronica': 'É crônica (semanas/meses)',
      'algo_constante_semanas': 'Constante há várias semanas',
      'leve_controlavel': 'Leve / Controlável',
      'moderada': 'Moderada',
      'muito_forte': 'Muito forte / Intensa',
      'sim_exercicio_intenso': 'Exercício físico intenso',
      'sim_sofri_queda': 'Queda ou trauma recente',
      'nao_comecou_do_nada': 'Início espontâneo (sem causa aparente)',
      'sim_postura_prolongada': 'Postura prolongada ou má postura',
      'sim_carregou_peso': 'Carregamento de peso excessivo',
      'sim_telas_esforco_visual': 'Uso prolongado de telas / esforço visual',
      'sim_estresse_sono': 'Privação de sono / estresse',
      'sim_estresse_ansiedade': 'Estresse emocional / ansiedade',
      'sim_esforco_fisico': 'Esforço físico ou atividade extenuante',
      'sim_cafeina_estimulante': 'Consumo de cafeína ou estimulantes',
      'sim_alimentacao_diferente': 'Alimentação diferente da rotina',
      'sim_jejum_estresse': 'Jejum prolongado ou estresse digestivo',
      'sim_movimento_repetitivo': 'Movimentos repetitivos de membros',
      'sim_caminhada_corrida': 'Caminhada ou corrida prolongada',
      'sim_cobranca_prazos': 'Pressão no trabalho / prazos',
      'sim_conflito_relacionamento': 'Conflitos interpessoais',
      'sim_sobrecarga_multitarefas': 'Sobrecarga de tarefas / cansaço mental',
      'sim_dificuldade_pegar_sono': 'Dificuldade para adormecer',
      'sim_acorda_madrugada': 'Despertares frequentes na madrugada',
      'sim_levantar_rapido': 'Ao levantar rápido / postural',
      'sim_baixa_ingestao_urina': 'Pouca ingestão de água / segurar urina',
      'sim_produto_novo': 'Uso de produto novo / cosmético',
      'sim_cansaco_esgotamento': 'Cansaço físico / esgotamento',
      'sim_jejum_alimentacao': 'Jejum prolongado / alimentação irregular',
      'trabalho_estudos': 'Trabalho / Estudos',
      'familia_relacionamentos': 'Família / Relacionamentos',
      'noite_ruim_sono': 'Noite ruim de sono',
      'nao_sei_dizer': 'Não sei dizer / Sem causa aparente',
      'sim_perda_luto': 'Perda significativa / luto',
      'sim_pressao_trabalho': 'Pressão profissional / sobrecarga',
      'sim_durante_trabalho': 'Sintomas durante o trabalho',
      'sim_comparacao_redes': 'Cobrança pessoal / redes sociais',
      'sim_alergia_ambiente': 'Exposição a poeira / alérgenos',
      'goodNormal': 'Bem / Normal',
      'soSo': 'Mais ou menos',
      'badSick': 'Mal / Ruim',
    };

    if (map.containsKey(key)) return map[key]!;
    final formatted = key.replaceAll('_', ' ');
    if (formatted.isEmpty) return '';
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isPhysical = entry.anatomicalSystem != null;
    final verticalThemeColor = isPhysical ? AppColors.clinicalTeal : AppColors.softIndigo;
    final intensityColor = RetrospectiveListView.getIntensityColor(entry.intensity);
    final dispositionColor = getDispositionColor(entry.disposition);

    final rawNarrative = entry.narrative ??
        entry.stepAnswers?['naturalLanguageText'] as String? ??
        entry.stepAnswers?['narrative'] as String?;
    final narrative = (rawNarrative != null &&
            rawNarrative.trim().isNotEmpty &&
            int.tryParse(rawNarrative.trim()) == null)
        ? rawNarrative.trim()
        : null;

    final causes = entry.stepAnswers?['causes'] ??
        entry.stepAnswers?['gatilhos'] ??
        entry.stepAnswers?['motivo'];

    final isDailyCheckIn = entry.stepAnswers?['type'] == 'daily_checkin' ||
        (entry.stepAnswers?.containsKey('emotionalStatus') == true ||
            entry.stepAnswers?.containsKey('physicalStatus') == true);

    return Container(
      key: const Key('triage_history_detail_modal'),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Top Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: verticalThemeColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPhysical ? Icons.healing_rounded : Icons.psychology_rounded,
                      color: verticalThemeColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detalhes da Triagem',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formatDateTimeFull(entry.recordedAt),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('modal_close_button'),
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.grey.shade600,
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Organic Primacy Alert Banner
                    if (entry.organicPrimacyApplied) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.emergencySurfaceRed,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.emergencyCrimson.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.emergencyCrimson,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Atenção Clínica (Primazia Orgânica): Sintomas físicos concorrentes foram identificados e receberam prioridade de avaliação médica.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.emergencyTextDark,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Category & Vertical Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: verticalThemeColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: verticalThemeColor.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isPhysical ? Icons.accessibility_new_rounded : Icons.psychology_outlined,
                            color: verticalThemeColor,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isPhysical ? 'AVALIAÇÃO FÍSICA' : 'AUTOAVALIAÇÃO EMOCIONAL',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: verticalThemeColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  RetrospectiveListView.formatCategory(entry),
                                  key: const Key('modal_category_badge'),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Level / Severity Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.outlineDark.withValues(alpha: 0.3) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Nível de Intensidade',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                key: const Key('modal_intensity_badge'),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: intensityColor.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: intensityColor.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  getIntensityDescription(entry.intensity),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: intensityColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // 5-bar visual intensity meter
                          Row(
                            children: List.generate(5, (index) {
                              final barIndex = index + 1;
                              final isActive = barIndex <= entry.intensity;
                              return Expanded(
                                child: Container(
                                  height: 6,
                                  margin: EdgeInsets.only(right: index < 4 ? 4 : 0),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? intensityColor
                                        : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Care Disposition Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: dispositionColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: dispositionColor.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                getDispositionIcon(entry.disposition),
                                color: dispositionColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Encaminhamento Sugerido',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                key: const Key('modal_disposition_badge'),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: dispositionColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: dispositionColor.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  RetrospectiveListView.formatDisposition(entry.disposition),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: dispositionColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            getDispositionDescription(entry.disposition),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textPrimaryLight,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Structured Answers / Symptoms Section
                    Text(
                      'Sintomas e Respostas Registradas',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.outlineDark.withValues(alpha: 0.2) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isDailyCheckIn) ...[
                            _buildAnswerRow(
                              icon: Icons.psychology_outlined,
                              label: 'Eixo Psico-Emocional',
                              value: _formatAnswerValue(
                                entry.stepAnswers?['emotionalStatus']?.toString() ?? 'goodNormal',
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildAnswerRow(
                              icon: Icons.accessibility_new_rounded,
                              label: 'Eixo Avaliação Física',
                              value: _formatAnswerValue(
                                entry.stepAnswers?['physicalStatus']?.toString() ?? 'goodNormal',
                              ),
                            ),
                          ] else ...[
                            _buildAnswerRow(
                              icon: Icons.place_outlined,
                              label: isPhysical ? 'Sistema / Região' : 'Dimensão Afetada',
                              value: RetrospectiveListView.formatCategory(entry),
                            ),
                            if (entry.stepAnswers != null) ...[
                              _buildWizardStepRows(entry.stepAnswers!),
                            ],
                          ],
                          if (causes != null && causes.toString().trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _buildAnswerRow(
                              icon: Icons.flag_outlined,
                              label: 'Motivo / Gatilho Informado',
                              value: causes.toString().trim(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Additional Description / Narrative
                    Text(
                      'Descrição Adicional',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.outlineDark.withValues(alpha: 0.25) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: (narrative != null && narrative.trim().isNotEmpty)
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.format_quote_rounded,
                                  color: verticalThemeColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    narrative.trim(),
                                    key: const Key('modal_narrative_text'),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontStyle: FontStyle.italic,
                                      color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Nenhuma descrição adicional relatada pelo paciente nesta triagem.',
                              key: const Key('modal_narrative_text'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Persistent Bottom Close Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: FilledButton(
                key: const Key('modal_dismiss_button'),
                style: FilledButton.styleFrom(
                  backgroundColor: verticalThemeColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Fechar',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWizardStepRows(Map<String, dynamic> stepAnswers) {
    final rows = <Widget>[];

    // Check step 1 (persistence / onset duration)
    final step1 = stepAnswers['1'] ?? stepAnswers['step_1'];
    if (step1 != null &&
        step1.toString().trim().isNotEmpty &&
        int.tryParse(step1.toString().trim()) == null) {
      rows.add(const SizedBox(height: 10));
      rows.add(
        _buildAnswerRow(
          icon: Icons.timer_outlined,
          label: 'Tempo / Início',
          value: _formatAnswerValue(step1.toString()),
        ),
      );
    }

    // Check step 2 (associated factor / trigger / symptom)
    // Note: Step 2 is the trigger / factor in TriageQuestionBank.
    // If not found at '2', check '3' only if non-numeric for backward compatibility.
    dynamic step2Raw = stepAnswers['2'] ?? stepAnswers['step_2'];
    if (step2Raw == null) {
      final candidate3 = stepAnswers['3'] ?? stepAnswers['step_3'];
      if (candidate3 != null && int.tryParse(candidate3.toString().trim()) == null) {
        step2Raw = candidate3;
      }
    }

    if (step2Raw != null &&
        step2Raw.toString().trim().isNotEmpty &&
        int.tryParse(step2Raw.toString().trim()) == null) {
      rows.add(const SizedBox(height: 10));
      rows.add(
        _buildAnswerRow(
          icon: Icons.bubble_chart_outlined,
          label: 'Fator Associado / Sintoma',
          value: _formatAnswerValue(step2Raw.toString()),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  Widget _buildAnswerRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
