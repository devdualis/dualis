import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/triage_outcome_models.dart';

class DispositionCard extends StatelessWidget {
  final CareDisposition disposition;
  final String? category;

  const DispositionCard({
    super.key,
    required this.disposition,
    this.category,
  });

  // Self-care advice generic enough to fit any category ("rest and hydrate")
  // reads as wrong for e.g. a skin rash or joint pain, so this tailors it
  // to the detected system/dimension instead of one-size-fits-all copy.
  static const Map<String, String> _selfCareByCategory = {
    'cabeca_pescoco':
        'Hidrate-se, evite telas por algumas horas e descanse em ambiente com pouca luz e ruído.',
    'cardiovascular_torax':
        'Evite esforço físico intenso e observe se a sensação persiste ou piora nas próximas horas.',
    'respiratorio':
        'Mantenha-se hidratado, evite ambientes com fumaça ou poeira e observe a evolução da respiração.',
    'gastrointestinal_abdomen':
        'Prefira alimentos leves, hidrate-se bem e evite frituras ou álcool nas próximas 24 horas.',
    'coluna_dor_dorsal':
        'Evite carregar peso, mantenha uma postura ereta e aplique compressas mornas na região dolorida.',
    'membros_superiores':
        'Reduza o esforço repetitivo com o membro afetado e aplique compressa fria por 15 minutos.',
    'membros_inferiores':
        'Eleve o membro afetado, aplique compressa fria e evite esforço físico intenso.',
    'neurologico':
        'Hidrate-se, evite mudanças bruscas de posição e descanse em ambiente calmo.',
    'geniturinario_pelvico':
        'Aumente a ingestão de água e evite segurar a urina por longos períodos.',
    'dermatologico':
        'Evite coçar a área afetada, mantenha a pele limpa e seca, e observe se surgem novos sintomas.',
    'muscular_geral_sistemico':
        'Priorize o descanso, hidrate-se bem e evite esforço físico nas próximas 24 horas.',
    'endocrino_metabolico':
        'Mantenha uma alimentação equilibrada, hidrate-se e monitore os sintomas nos próximos dias.',
    'ansiosa_agitacao':
        'Pratique respiração profunda e reduza estímulos (cafeína, telas) nas próximas horas.',
    'depressiva_desanimo':
        'Tente manter pequenas atividades da rotina e busque contato com pessoas próximas.',
    'estresse_burnout':
        'Reserve pausas curtas ao longo do dia e evite acumular novas demandas hoje.',
    'somatica':
        'Pratique técnicas de relaxamento e observe se os sintomas físicos se intensificam.',
    'sono': 'Mantenha um horário regular para dormir e evite telas antes de deitar.',
    'cognitiva_foco':
        'Faça pausas curtas e frequentes, e evite multitarefas nas próximas horas.',
    'autoestima': 'Pratique autocompaixão e evite se cobrar excessivamente hoje.',
  };

  @override
  Widget build(BuildContext context) {
    Color primaryColor;
    Color bgColor;
    IconData icon;
    String title;
    String description;

    switch (disposition) {
      case CareDisposition.selfCare:
        primaryColor = const Color(0xFF00796B); // Clinical Teal
        bgColor = const Color(0xFFE0F2F1);
        icon = Icons.spa_outlined;
        title = 'Auto-cuidado Monitorado';
        description = _selfCareByCategory[category] ??
            'Repouso, hidratação adequada e acompanhamento dos sintomas nas próximas 24 horas.';
        break;
      case CareDisposition.routineConsultation:
        primaryColor = const Color(0xFF3F51B5); // Soft Indigo
        bgColor = const Color(0xFFE8EAF6);
        icon = Icons.calendar_today_outlined;
        title = 'Consulta de Rotina';
        description =
            'Recomenda-se agendar uma consulta preventiva nos próximos dias com um profissional de saúde.';
        break;
      case CareDisposition.urgentCare:
        primaryColor = const Color(0xFFE65100); // Deep Orange
        bgColor = const Color(0xFFFFF3E0);
        icon = Icons.medical_services_outlined;
        title = 'Pronto Atendimento (24h)';
        description =
            'Recomenda-se buscar avaliação presencial em uma unidade de pronto atendimento em até 24 horas.';
        break;
      case CareDisposition.emergency:
        primaryColor = const Color(0xFFD32F2F); // Emergency Red
        bgColor = const Color(0xFFFFEBEE);
        icon = Icons.emergency_outlined;
        title = 'Atendimento de Emergência';
        description =
            'Seus sintomas exigem atenção médica urgente imediata. Procure um serviço de emergência ou ligue 192.';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recomendação de Cuidado',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
