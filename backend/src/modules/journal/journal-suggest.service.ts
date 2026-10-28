import { Inject, Injectable, Optional } from '@nestjs/common';
import { GeminiService } from '../../common/ai/gemini.service';
import {
  EMOTIONAL_OPTION_KEYS,
  PHYSICAL_OPTION_KEYS,
  isCustomOptionKey,
} from './constants/journal-keys.constant';

const NONE = 'none';

/** Catalog chips only (no `.custom` keys). */
export function catalogKeys(kind: 'emotional' | 'physical'): string[] {
  const source = kind === 'physical' ? PHYSICAL_OPTION_KEYS : EMOTIONAL_OPTION_KEYS;
  return source.filter((key) => !isCustomOptionKey(key));
}

/**
 * Maps a short free-text phrase onto one existing journal chip, or none.
 * Never invents keys. Never names conditions. The person must confirm in the app.
 */
@Injectable()
export class JournalSuggestService {
  constructor(@Optional() @Inject(GeminiService) private readonly gemini?: GeminiService) {}

  async suggest(text: string, kind: 'emotional' | 'physical'): Promise<{ optionKey: string | null }> {
    const allowed = catalogKeys(kind);
    const clean = text.trim();
    if (!clean || !this.gemini?.isAvailable) return { optionKey: null };

    try {
      const parsed = await this.gemini.generateJson<{ optionKey?: string }>({
        systemInstruction:
          'You map a short everyday phrase onto one existing diary chip. ' +
          'Return that chip key, or none. Do not invent keys. Do not assess health. ' +
          'Do not name disorders. The chip is only a filing shortcut the person will confirm.',
        prompt: `Kind: ${kind}\nAllowed keys:\n${allowed.join('\n')}\n\nPhrase:\n${clean}`,
        schema: {
          type: 'object',
          additionalProperties: false,
          properties: {
            optionKey: { type: 'string', enum: [...allowed, NONE] },
          },
          required: ['optionKey'],
        },
        temperature: 0,
      });
      const key = parsed.optionKey === NONE ? null : parsed.optionKey ?? null;
      return { optionKey: key && allowed.includes(key) ? key : null };
    } catch {
      return { optionKey: null };
    }
  }
}
