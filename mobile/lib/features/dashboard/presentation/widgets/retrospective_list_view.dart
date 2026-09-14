import 'package:flutter/material.dart';
import '../../domain/models/triage_history_models.dart';

class RetrospectiveListView extends StatelessWidget {
  final List<TriageHistoryEntry> entries;
  final String verticalFilter;
  final VoidCallback? onRefresh;

  const RetrospectiveListView({
    super.key,
    required this.entries,
    required this.verticalFilter,
    this.onRefresh,
  });

  static Color getIntensityColor(int intensity) {
    if (intensity <= 2) return const Color(0xFFFFA000);
    if (intensity == 3) return const Color(0xFFF4511E);
    return const Color(0xFFC62828);
  }

  static String formatDisposition(String? disposition) {
    switch (disposition) {
      case 'auto_cuidado':
        return 'Autocuidado';
      case 'consulta_rotina':
        return 'Consulta de Rotina';
      case 'pronto_atendimento':
        return 'Pronto Atendimento';
      case 'emergencia':
        return 'Emergência';
      default:
        return 'Acompanhamento';
    }
  }

  static String formatCategory(TriageHistoryEntry entry) {
    if (entry.anatomicalSystem != null) {
      final key = entry.anatomicalSystem!;
      return key.replaceAll('_', ' ').toUpperCase();
    }
    if (entry.emotionalDimension != null) {
      final key = entry.emotionalDimension!;
      return key.replaceAll('_', ' ').toUpperCase();
    }
    return 'GERAL';
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = entries.where((e) {
      if (verticalFilter == 'physical') {
        return e.anatomicalSystem != null;
      } else if (verticalFilter == 'emotional') {
        return e.emotionalDimension != null;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_toggle_off_rounded,
                  size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'Nenhum registro anterior',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Os seus check-ins diários concluídos aparecerão aqui.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = filtered[index];
        final intensityColor = getIntensityColor(entry.intensity);
        final causes = entry.stepAnswers?['causes'] ??
            entry.stepAnswers?['gatilhos'] ??
            entry.stepAnswers?['motivo'];

        return Card(
          margin: EdgeInsets.zero,
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDateTime(entry.recordedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: intensityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Nível ${entry.intensity}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: intensityColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        formatCategory(entry),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (entry.disposition != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00796B).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          formatDisposition(entry.disposition),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF00796B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                if (causes != null && causes.toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Motivo informado: $causes',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
