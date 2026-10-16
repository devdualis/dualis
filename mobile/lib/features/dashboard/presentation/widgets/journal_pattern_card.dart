import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/triage_history_models.dart';

class JournalPatternCard extends StatelessWidget {
  final JournalPatternItem item;

  const JournalPatternCard({
    super.key,
    required this.item,
  });

  static final Map<String, String> _categoryLabels = {
    'muscular_geral_sistemico': 'Corpo todo / cansaço',
    'cabeca_pescoco': 'Cabeça e pescoço',
    'cardiovascular_torax': 'Peito',
    'respiratorio': 'Respiração',
    'gastrointestinal_abdomen': 'Barriga',
    'coluna_dorsal': 'Costas',
    'coluna_dor_dorsal': 'Costas',
    'coluna_dor_lombar': 'Costas',
    'membros_superiores': 'Braços',
    'membros_inferiores': 'Pernas',
    'dermatologico': 'Pele',
    'geral_fisico': 'Corpo',
    'ansiosa_agitacao': 'Agitação',
    'depressiva_desanimo': 'Pra baixo',
    'estresse_burnout': 'Esgotado(a)',
    'somatica': 'Tensão no corpo',
    'sono': 'Sono',
    'cognitiva_foco': 'Foco',
    'autoestima': 'Autoestima',
    'geral_emocional': 'Emoções',
    'geral': 'Registros',
  };

  String _categoryLabel(String raw) => _categoryLabels[raw] ?? raw.replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = _categoryLabel(item.category);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0.5,
      color: const Color(0xFFF3F6F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  item.vertical == 'emotional' ? Icons.psychology_outlined : Icons.accessibility_new_rounded,
                  color: const Color(0xFF455A64),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.journalPatternTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF37474F),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF546E7A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item.count}x',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.journalPatternDescription(
                label,
                item.count,
                item.windowDays,
              ),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF455A64),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
