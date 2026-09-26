import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/triage_history_models.dart';

class CriticalRecurrenceCard extends StatelessWidget {
  final CriticalRecurrenceItem item;

  const CriticalRecurrenceCard({
    super.key,
    required this.item,
  });

  Future<void> _launchArticle(BuildContext context, String url) async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final fallbackUnavailable = l10n?.errorArticleLinkUnavailable ?? 'Link do artigo não disponível.';
    final fallbackCannotOpen = l10n?.errorUnableToOpenLink ?? 'Não foi possível abrir o link solicitado.';

    final trimmed = url.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(fallbackUnavailable)),
        );
      }
      return;
    }

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        final inAppLaunched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        if (!inAppLaunched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$fallbackCannotOpen: $trimmed')),
          );
        }
      }
    } catch (_) {
      try {
        final basicLaunched = await launchUrl(uri);
        if (!basicLaunched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$fallbackCannotOpen: $trimmed')),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$fallbackCannotOpen: $trimmed')),
          );
        }
      }
    }
  }

  static final Map<String, String> _categoryTranslations = {
    'muscular_geral_sistemico': 'Muscular Geral e Sistêmico',
    'cabeca_pescoco': 'Cabeça e Pescoço',
    'cardiovascular_torax': 'Cardiovascular / Tórax',
    'respiratorio': 'Respiratório',
    'gastrointestinal_abdomen': 'Gastrointestinal / Abdômen',
    'coluna_dorsal': 'Coluna e Dor Dorsal',
    'coluna_dor_dorsal': 'Coluna e Dor Dorsal',
    'coluna_dor_lombar': 'Coluna e Dor Lombar',
    'membros_superiores': 'Membros Superiores',
    'membros_superiores_d': 'Membros Superiores (D)',
    'membros_superiores_e': 'Membros Superiores (E)',
    'membros_inferiores': 'Membros Inferiores',
    'membros_inferiores_d': 'Membros Inferiores (D)',
    'membros_inferiores_e': 'Membros Inferiores (E)',
    'endocrino_metabolico': 'Endócrino / Metabólico',
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

  static String _formatText(String raw) {
    String formatted = raw;
    final sortedKeys = _categoryTranslations.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final key in sortedKeys) {
      formatted = formatted.replaceAll(key, _categoryTranslations[key]!);
    }
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0.5,
      color: const Color(0xFFFFF8E1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFFFE082), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFF57C00),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatText(item.title),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item.frequencyCount}x',
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
              _formatText(item.description),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4E342E),
                height: 1.35,
              ),
            ),
            if (item.recommendedArticleTitle.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _launchArticle(
                    context,
                    item.recommendedArticleUrl,
                  ),
                  icon: const Icon(Icons.menu_book_rounded, size: 16),
                  label: Text(
                    item.recommendedArticleTitle,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE65100),
                    side: const BorderSide(color: Color(0xFFFFB74D)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
