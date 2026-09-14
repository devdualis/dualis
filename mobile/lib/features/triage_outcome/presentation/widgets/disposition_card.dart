import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/triage_outcome_models.dart';

class DispositionCard extends StatelessWidget {
  final CareDisposition disposition;

  const DispositionCard({
    super.key,
    required this.disposition,
  });

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
        description =
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
