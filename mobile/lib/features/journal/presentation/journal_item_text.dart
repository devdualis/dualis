import '../../../l10n/app_localizations.dart';
import '../domain/journal_keys.dart';
import '../domain/journal_models.dart';
import 'journal_labels.dart';

/// Emoji shown next to a key (strategy sections 5, 8 and 18.1). Graphic only.
const Map<String, String> journalEmojis = {
  'bem': '😊',
  'normal': '🙂',
  'nao_tao_bem': '😕',
  'passado': '⏳',
  'presente': '📍',
  'futuro': '🚀',
  'passado.tristeza': '🍂',
  'passado.memoria': '🔁',
  'presente.energia': '🔋',
  'presente.sobrecarga': '⚡',
  'futuro.mente': '💬',
  'futuro.medo': '🚨',
  'passado.tristeza.culpa': '🛑',
  'passado.tristeza.saudade': '⏳',
  'passado.memoria.lembranca': '⚠️',
  'passado.memoria.magoa': '🔄',
  'presente.energia.corpo': '🪫',
  'presente.energia.desligado': '🌫️',
  'presente.sobrecarga.paciencia': '💥',
  'presente.sobrecarga.aperto': '🌪️',
  'futuro.mente.antecipar': '🧠',
  'futuro.mente.cobranca': '🏋️',
  'futuro.medo.julgamento': '👥',
  'futuro.medo.desanimo': '📉',
  'hoje': '⏱️',
  'dias_semanas': '⏳',
  'meses_anos': '🔄',
  'trabalho': '💼',
  'familia': '👨‍👩‍👧',
  'sono': '😴',
  'alimentacao': '🍽️',
  'esforco': '🏃',
  'queda': '🤕',
  'medicamento': '💊',
  'clima': '🌦️',
  'nao_sei': '🤷',
  'outro': '✏️',
  'emotional': '💭',
  'physical': '🧍',
  'condition': '📝',
};

/// What the user chose or wrote for this item, in their language.
String journalItemText(AppLocalizations l10n, JournalItem item) {
  if (item.kind == JournalKeys.kindCondition) return item.conditionLabel ?? '';
  if (item.customLabel != null && item.customLabel!.isNotEmpty) {
    return item.customLabel!;
  }
  if (item.optionKey != null) return JournalLabels.option(l10n, item.optionKey!);
  return item.legacyLabel ?? '';
}

/// Row title: physical items are prefixed with the body region
/// ("Cabeça e pescoço · Dor ou pressão nas têmporas ou testa").
String journalItemTitle(AppLocalizations l10n, JournalItem item) {
  final text = journalItemText(l10n, item);
  if (item.kind == JournalKeys.kindPhysical && item.optionKey != null) {
    final region = JournalLabels.root(l10n, JournalKeys.rootOf(item.optionKey!));
    return '$region · $text';
  }
  return text;
}
