import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/triage_history_models.dart';

class RetrospectiveListView extends StatelessWidget {
  final List<TriageHistoryEntry> entries;
  final String verticalFilter;
  final VoidCallback? onRefresh;
  final Future<bool> Function(String id)? onDeleteEntry;

  const RetrospectiveListView({
    super.key,
    required this.entries,
    required this.verticalFilter,
    this.onRefresh,
    this.onDeleteEntry,
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

  static final Map<String, String> _categoryLabels = {
    'cabeca_pescoco': 'Cabeça e Pescoço',
    'cardiovascular_torax': 'Cardiovascular / Tórax',
    'respiratorio': 'Respiratório',
    'gastrointestinal_abdomen': 'Gastrointestinal / Abdômen',
    'coluna_dorsal': 'Coluna Dorsal',
    'coluna_dor_dorsal': 'Coluna Dorsal',
    'coluna_dor_lombar': 'Coluna Lombar',
    'membros_superiores_d': 'Membros Superiores (D)',
    'membros_superiores_e': 'Membros Superiores (E)',
    'membros_inferiores_d': 'Membros Inferiores (D)',
    'membros_inferiores_e': 'Membros Inferiores (E)',
    'neurologico': 'Neurológico',
    'geniturinario_pelvico': 'Geniturinário / Pélvico',
    'dermatologico': 'Dermatológico',
    'geral_fisico': 'Saúde Física Geral',
    'ansiosa_agitacao': 'Ansiosa / Agitação',
    'depressiva_desanimo': 'Depressiva / Desânimo',
    'estresse_burnout': 'Estresse / Burnout',
    'somatica': 'Somática (Psicossomática)',
    'sono': 'Sono e Ritmo Circadiano',
    'cognitiva_foco': 'Cognitiva / Foco',
    'autoestima': 'Autoestima / Autoimagem',
    'geral_emocional': 'Saúde Emocional Geral',
    'geral': 'Saúde Geral e Bem-Estar',
  };

  static String _formatCategoryKey(String key) {
    if (_categoryLabels.containsKey(key)) {
      return _categoryLabels[key]!.toUpperCase();
    }
    return key.replaceAll('_', ' ').toUpperCase();
  }

  static String formatCategory(TriageHistoryEntry entry, [String? verticalFilter]) {
    if (verticalFilter == 'emotional' && entry.emotionalDimension != null) {
      return _formatCategoryKey(entry.emotionalDimension!);
    }
    if (verticalFilter == 'physical' && entry.anatomicalSystem != null) {
      return _formatCategoryKey(entry.anatomicalSystem!);
    }
    if (entry.anatomicalSystem != null) {
      return _formatCategoryKey(entry.anatomicalSystem!);
    }
    if (entry.emotionalDimension != null) {
      return _formatCategoryKey(entry.emotionalDimension!);
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

  Future<void> _confirmAndDelete(BuildContext context, String id) async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.emergencyCrimson,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n?.deleteHistoryItemTitle ?? 'Descartar registro do histórico',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          l10n?.deleteHistoryItemConfirm ??
              'Tem certeza de que deseja descartar este registro de triagem do seu histórico? Esta ação é irreversível.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n?.cancel ?? 'Cancelar'),
          ),
          FilledButton(
            key: const Key('confirm_delete_history_item_button'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emergencyCrimson,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n?.deleteAction ?? 'Descartar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted && onDeleteEntry != null) {
      final success = await onDeleteEntry!(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? (l10n?.deleteHistoryItemSuccess ?? 'Registro removido com sucesso.')
                  : (l10n?.deleteHistoryItemError ?? 'Não foi possível remover o registro.'),
            ),
            backgroundColor:
                success ? AppColors.clinicalTeal : AppColors.emergencyCrimson,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                        if (onDeleteEntry != null) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            key: Key('delete_history_item_${entry.id}'),
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: Colors.grey.shade500,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            splashRadius: 18,
                            tooltip: l10n?.deleteHistoryItemTitle ?? 'Descartar registro',
                            onPressed: () => _confirmAndDelete(context, entry.id),
                          ),
                        ],
                      ],
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
                        formatCategory(entry, verticalFilter),
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
