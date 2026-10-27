import { describe, it, expect, beforeEach } from 'vitest';
import { ConfigService } from '@nestjs/config';
import { GeminiService } from '../../src/common/ai/gemini.service';
import { IdiomDictionaryService } from '../../src/modules/ai/services/idiom-dictionary.service';
import { AiTaggingService } from '../../src/modules/ai/services/ai-tagging.service';

describe('AI journal tagging engine (I18N-02 / RNF-002)', () => {
  let idiomService: IdiomDictionaryService;
  let aiTaggingService: AiTaggingService;

  beforeEach(() => {
    idiomService = new IdiomDictionaryService();
    const configService = {
      get: (key: string) => (key === 'GEMINI_API_KEY' ? 'mock-gemini-key' : null),
    } as unknown as ConfigService;
    aiTaggingService = new AiTaggingService(new GeminiService(configService), idiomService);
  });

  describe('IdiomDictionaryService', () => {
    const cases: Array<[string, string, string, string]> = [
      ['Estou com uma dor no peito muito forte', 'physical', 'cardiovascular_chest', 'dor / aperto no peito'],
      ['Minha cabeça está explodindo, parece um trovão', 'physical', 'head_neck', 'dor de cabeça muito forte e repentina'],
      ['Estou com muita falta de ar e me sinto sufocando', 'physical', 'respiratory', 'falta de ar'],
      ['Acho que estou tendo uma crise de pânico agora', 'emotional', 'anxious_agitation', 'crise de pânico'],
      ['Acordei hoje com dor de cabeça', 'physical', 'head_neck', 'dor de cabeça'],
      ['Tengo dolor en el pecho', 'physical', 'cardiovascular_chest', 'dor / aperto no peito'],
      ['I am having severe chest pain', 'physical', 'cardiovascular_chest', 'dor / aperto no peito'],
    ];

    it.each(cases)('1. tags "%s" with area/mood and lay term only', (text, vertical, area, layTerm) => {
      const match = idiomService.match(text);
      expect(match).toMatchObject({ isOffTopic: false, vertical, bodyAreaOrMood: area, layTerm });
      expect(match).not.toHaveProperty('mentionsSelfHarm');
      expect(match?.latencyMs).toBeLessThan(10);
    });

    it('2. tags a mention of wanting to disappear like any other entry: no content flag', () => {
      const match = idiomService.match('Estou com vontade de sumir, não aguento mais viver');
      expect(match).toMatchObject({ vertical: 'emotional', bodyAreaOrMood: 'depressive_hopelessness' });
      expect(match).not.toHaveProperty('mentionsSelfHarm');
    });

    it('4. never names a condition in lay terms', () => {
      for (const [text] of cases) {
        expect(idiomService.match(text)?.layTerm).not.toMatch(/suspeita|AVC|síndrome|coronari|hemorragia|insufici|déficit|transtorno/i);
      }
    });
  });

  describe('AiTaggingService & SLA Benchmark', () => {
    it('5. serves a tag with sub-2s latency SLA (RNF-002)', async () => {
      const result = await aiTaggingService.tagWithMetadata({
        text: 'Estou com muita dor de cabeça e enxaqueca',
      });

      expect(result.vertical).toBe('physical');
      expect(result.bodyAreaOrMood).toBe('head_neck');
      expect(result.latencyMs).toBeLessThan(2000);
    });

    it('6. caches repeated queries and returns from memory cache', async () => {
      const query = { text: 'Estresse e cansaço mental do trabalho' };
      const first = await aiTaggingService.tagWithMetadata(query);
      expect(first.source).toBe('dictionary_fallback');

      const second = await aiTaggingService.tagWithMetadata(query);
      expect(second.source).toBe('idiom_cache');
      expect(second.latencyMs).toBeLessThan(5);
    });

    it('7. leaves unfamiliar input untagged instead of guessing, with zero crash', async () => {
      const result = await aiTaggingService.tagEntry({
        text: 'xyz123 algo completamente atípico e sem padrão conhecido',
      });

      expect(result).toEqual({
        isOffTopic: false,
        vertical: null,
        bodyAreaOrMood: null,
        layTerm: null,
      });
    });
  });
});
