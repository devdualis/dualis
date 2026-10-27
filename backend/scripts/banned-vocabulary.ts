/**
 * Banned vocabulary for user-facing output and the journal v2 contract
 * (plan PLAN-TECNICO-BIENESTAR.md §2 and strategy ESTRATEGIA-MEJORAS-DUALIS-FREE.md §15).
 * Plain strings match as case-insensitive substrings; short acronyms match as whole
 * uppercase words so ordinary words ("tocar", "etiqueta") are not flagged.
 */
export const BANNED_VOCABULARY: ReadonlyArray<string | RegExp> = [
  // Plan §2
  'triagem',
  'triaje',
  'triage',
  'diagnóstico',
  'diagnostico',
  'prontuário',
  'prontuario',
  'clínico',
  'clinico',
  'clínica',
  'clinica',
  'paciente',
  'manchester',
  'esi',
  'samd',
  'rdc 657',
  'cfm 2.314',
  'concordância clínica',
  'concordancia clinica',
  'precisas',
  // Strategy §15
  'transtorno',
  /\bTAG\b/,
  /\bTOC\b/,
  /\bTEPT\b/,
  'bipolar',
  'ciclotim',
  'borderline',
  'grupo clínico',
  'grupo clinico',
  'sintoma estruturado',
  'esfera',
  'vertical de tratamento',
  'anedonia',
  'radiculopatia',
  'costocondrite',
  'isquemia',
  '☠️',
  '☠',
];

export function findBannedVocabulary(text: string | null | undefined): string[] {
  if (!text) return [];
  const normalized = text.toLowerCase();
  return BANNED_VOCABULARY.filter((term) =>
    typeof term === 'string' ? normalized.includes(term) : term.test(text),
  ).map((term) => (typeof term === 'string' ? term : term.source));
}
