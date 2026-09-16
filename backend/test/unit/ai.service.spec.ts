import { describe, it, expect, beforeEach } from 'vitest';
import { ConfigService } from '@nestjs/config';
import { IdiomDictionaryService } from '../../src/modules/ai/services/idiom-dictionary.service';
import { AiTriageService } from '../../src/modules/ai/services/ai-triage.service';

describe('AI Classification Engine (TRG-02 / I18N-02 / RNF-002)', () => {
  let idiomService: IdiomDictionaryService;
  let aiTriageService: AiTriageService;

  beforeEach(() => {
    idiomService = new IdiomDictionaryService();
    const configService = {
      get: (key: string) => (key === 'OPENAI_KEY' ? 'mock-openai-key' : null),
    } as unknown as ConfigService;
    aiTriageService = new AiTriageService(configService, idiomService);
  });

  describe('IdiomDictionaryService', () => {
    it('1. Correctly classifies physical emergency red-flags (e.g. chest pain)', () => {
      const match = idiomService.match('Estou com uma dor no peito muito forte');
      expect(match).not.toBeNull();
      expect(match?.primaryVertical).toBe('physical');
      expect(match?.systemOrDimension).toBe('cardiovascular_chest');
      expect(match?.urgencyScore).toBe(5);
      expect(match?.isEmergencyCandidate).toBe(true);
      expect(match?.latencyMs).toBeLessThan(10);
    });

    it('2. Correctly classifies thunderclap headache emergency', () => {
      const match = idiomService.match('Minha cabeça está explodindo, parece um trovão');
      expect(match).not.toBeNull();
      expect(match?.primaryVertical).toBe('physical');
      expect(match?.systemOrDimension).toBe('head_neck');
      expect(match?.urgencyScore).toBe(5);
      expect(match?.isEmergencyCandidate).toBe(true);
    });

    it('3. Correctly classifies acute respiratory emergency', () => {
      const match = idiomService.match('Estou com muita falta de ar e me sinto sufocando');
      expect(match).not.toBeNull();
      expect(match?.primaryVertical).toBe('physical');
      expect(match?.systemOrDimension).toBe('respiratory');
      expect(match?.urgencyScore).toBe(5);
      expect(match?.isEmergencyCandidate).toBe(true);
    });

    it('4. Correctly classifies emotional suicidal crisis emergency', () => {
      const match = idiomService.match('Estou com vontade de sumir, não aguento mais viver');
      expect(match).not.toBeNull();
      expect(match?.primaryVertical).toBe('emotional');
      expect(match?.systemOrDimension).toBe('depressive_hopelessness');
      expect(match?.urgencyScore).toBe(5);
      expect(match?.isEmergencyCandidate).toBe(true);
    });

    it('5. Correctly classifies panic attack paroxysm', () => {
      const match = idiomService.match('Acho que estou tendo uma crise de pânico agora');
      expect(match).not.toBeNull();
      expect(match?.primaryVertical).toBe('emotional');
      expect(match?.systemOrDimension).toBe('anxious_agitation');
      expect(match?.urgencyScore).toBe(4);
      expect(match?.isEmergencyCandidate).toBe(true);
    });

    it('6. Correctly maps non-emergency somatic complaint (dor de cabeça leve)', () => {
      const match = idiomService.match('Acordei hoje com dor de cabeça');
      expect(match).not.toBeNull();
      expect(match?.primaryVertical).toBe('physical');
      expect(match?.systemOrDimension).toBe('head_neck');
      expect(match?.isEmergencyCandidate).toBe(false);
    });

    it('7. Correctly maps Spanish and English colloquial inputs', () => {
      const esMatch = idiomService.match('Tengo dolor en el pecho');
      expect(esMatch?.primaryVertical).toBe('physical');
      expect(esMatch?.systemOrDimension).toBe('cardiovascular_chest');
      expect(esMatch?.isEmergencyCandidate).toBe(true);

      const enMatch = idiomService.match('I am having severe chest pain');
      expect(enMatch?.primaryVertical).toBe('physical');
      expect(enMatch?.systemOrDimension).toBe('cardiovascular_chest');
      expect(enMatch?.isEmergencyCandidate).toBe(true);
    });
  });

  describe('AiTriageService & SLA Benchmark', () => {
    it('8. Serves query with sub-2s latency SLA (RNF-002)', async () => {
      const result = await aiTriageService.classify({
        text: 'Estou com muita dor de cabeça e enxaqueca',
      });

      expect(result).toBeDefined();
      expect(result.primaryVertical).toBe('physical');
      expect(result.systemOrDimension).toBe('head_neck');
      expect(result.latencyMs).toBeLessThan(2000);
    });

    it('9. Caches repeated queries and returns from memory cache', async () => {
      const query = { text: 'Estresse e cansaço mental do trabalho' };
      const first = await aiTriageService.classify(query);
      expect(first.source).toBe('dictionary_fallback');

      const second = await aiTriageService.classify(query);
      expect(second.source).toBe('idiom_cache');
      expect(second.latencyMs).toBeLessThan(5);
    });

    it('10. Handles unfamiliar input via fallback with zero crash', async () => {
      const result = await aiTriageService.classify({
        text: 'xyz123 algo completamente atípico e sem padrão conhecido',
      });

      expect(result).toBeDefined();
      expect(result.urgencyScore).toBe(2);
      expect(result.isEmergencyCandidate).toBe(false);
      expect(result.latencyMs).toBeLessThan(2000);
    });
  });
});
