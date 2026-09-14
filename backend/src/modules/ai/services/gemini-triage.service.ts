import { Inject, Injectable, Logger, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenAI } from '@google/genai';
import { ClassifySymptomDto, TriageClassificationResult } from '../dto/classify-symptom.dto';
import { IdiomDictionaryService } from './idiom-dictionary.service';

@Injectable()
export class GeminiTriageService {
  private readonly logger = new Logger(GeminiTriageService.name);
  private readonly client: GoogleGenAI | null = null;
  private readonly cache = new Map<string, TriageClassificationResult>();
  private readonly idiomDict: IdiomDictionaryService;

  constructor(
    @Optional() @Inject(ConfigService) private readonly configService?: ConfigService,
    @Optional() @Inject(IdiomDictionaryService) idiomDictionary?: IdiomDictionaryService,
  ) {
    this.idiomDict = idiomDictionary ?? new IdiomDictionaryService();
    const apiKey = this.configService?.get<string>('GEMINI_API_KEY');
    if (apiKey && apiKey !== 'mock-gemini-key') {
      try {
        this.client = new GoogleGenAI({ apiKey });
        this.logger.log('Gemini 1.5 Flash client initialized successfully');
      } catch (err) {
        this.logger.warn(`Failed to initialize GoogleGenAI client: ${(err as Error).message}`);
      }
    } else {
      this.logger.log('GEMINI_API_KEY not provided or mock; operating with deterministic clinical dictionary engine');
    }
  }

  async classify(dto: ClassifySymptomDto): Promise<TriageClassificationResult> {
    const startTime = performance.now();
    const cacheKey = dto.text.trim().toLowerCase();

    // 1. Check in-memory semantic cache (<1ms)
    if (this.cache.has(cacheKey)) {
      const cached = this.cache.get(cacheKey)!;
      return {
        ...cached,
        source: 'idiom_cache',
        latencyMs: Math.round(performance.now() - startTime),
      };
    }

    // 2. Deterministic Idiom Dictionary fast-path (<2ms)
    const idiomMatch = this.idiomDict.match(dto.text);
    if (idiomMatch) {
      this.cache.set(cacheKey, idiomMatch);
      return {
        ...idiomMatch,
        latencyMs: Math.round(performance.now() - startTime),
      };
    }

    // 3. Gemini 1.5 Flash structured output
    if (this.client) {
      try {
        const response = await this.client.models.generateContent({
          model: 'gemini-1.5-flash',
          contents: [
            {
              role: 'user',
              parts: [
                {
                  text: `Você é o motor de triagem médica preventiva do DualisCheckUp. Classifique a seguinte descrição clínica do usuário: "${dto.text}". Retorne em JSON estrito com:
                  - vertical: "physical" ou "emotional"
                  - systemOrDimension: chave do sistema anatômico ou dimensão emocional
                  - urgencyScore: número inteiro de 1 a 5
                  - mappedLayTerm: termo leigo identificado
                  - clinicalConcept: conceito médico formal correspondente
                  - isEmergencyCandidate: booleano indicando se preenche critérios Manchester/ESI nível 1-2`,
                },
              ],
            },
          ],
          config: {
            responseMimeType: 'application/json',
          },
        });

        const rawText = response.text || '{}';
        const parsed = JSON.parse(rawText);

        const result: TriageClassificationResult = {
          primaryVertical: parsed.vertical === 'emotional' ? 'emotional' : 'physical',
          systemOrDimension: parsed.systemOrDimension || 'general_somatic',
          urgencyScore: typeof parsed.urgencyScore === 'number' ? parsed.urgencyScore : 2,
          mappedLayTerm: parsed.mappedLayTerm || dto.text,
          clinicalConcept: parsed.clinicalConcept || 'sintoma inespecífico',
          isEmergencyCandidate: parsed.isEmergencyCandidate === true,
          confidence: 0.90,
          source: 'gemini_flash',
          latencyMs: Math.round(performance.now() - startTime),
        };

        this.cache.set(cacheKey, result);
        return result;
      } catch (err) {
        this.logger.warn(`Gemini inference failed, falling back: ${(err as Error).message}`);
      }
    }

    // 4. Heuristic Fallback (<2ms)
    const fallback: TriageClassificationResult = {
      primaryVertical: 'physical',
      systemOrDimension: 'general_somatic',
      urgencyScore: 2,
      mappedLayTerm: dto.text,
      clinicalConcept: 'sintoma geral a investigar',
      isEmergencyCandidate: false,
      confidence: 0.70,
      source: 'dictionary_fallback',
      latencyMs: Math.round(performance.now() - startTime),
    };

    this.cache.set(cacheKey, fallback);
    return fallback;
  }
}
