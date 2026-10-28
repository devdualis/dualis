export type Lang = 'pt' | 'en' | 'es';
export type Localized = Record<Lang, string>;

/** pt (default), en or es from a language code or an Accept-Language header. */
export function resolveLang(language?: string): Lang {
  const lang = (language || 'pt').toLowerCase();
  if (lang.startsWith('es')) return 'es';
  if (lang.startsWith('en')) return 'en';
  return 'pt';
}
