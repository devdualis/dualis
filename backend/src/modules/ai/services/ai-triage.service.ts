import { Inject, Injectable, Logger, Optional } from '@nestjs/common';
import { GeminiService } from '../../../common/ai/gemini.service';
import { ClassifySymptomDto, TriageClassificationResult } from '../dto/classify-symptom.dto';
import { IdiomDictionaryService } from './idiom-dictionary.service';
import { SymptomVectorService } from './symptom-vector.service';

// Canonical systemOrDimension keys (must match idiom-dictionary.service.ts and the
// mobile app's triage question bank / wizard category aliases). Gemini is constrained
// to this vocabulary so free-form output doesn't produce keys the app can't route on.
const PHYSICAL_SYSTEMS = [
  'cardiovascular_chest',
  'head_neck',
  'respiratory',
  'neurological',
  'musculoskeletal_back',
  'membros_superiores',
  'membros_inferiores',
  'gastrointestinal',
  'geniturinario_pelvico',
  'dermatologico',
  'muscular_geral_sistemico',
  'endocrino_metabolico',
];
const EMOTIONAL_SYSTEMS = [
  'depressive_hopelessness',
  'anxious_agitation',
  'stress_burnout',
  'somatica',
  'sono',
  'cognitiva_foco',
  'autoestima',
];

const CLASSIFICATION_SCHEMA = {
  type: 'object',
  properties: {
    isOffTopic: { type: 'boolean' },
    vertical: { type: 'string', enum: ['physical', 'emotional'] },
    systemOrDimension: { type: 'string', enum: [...PHYSICAL_SYSTEMS, ...EMOTIONAL_SYSTEMS] },
    urgencyScore: { type: 'integer', minimum: 1, maximum: 5 },
    mappedLayTerm: { type: 'string' },
    clinicalConcept: { type: 'string' },
    isEmergencyCandidate: { type: 'boolean' },
  },
  required: [
    'isOffTopic',
    'vertical',
    'systemOrDimension',
    'urgencyScore',
    'mappedLayTerm',
    'clinicalConcept',
    'isEmergencyCandidate',
  ],
};

@Injectable()
export class AiTriageService {
  private readonly logger = new Logger(AiTriageService.name);
  private readonly cache = new Map<string, TriageClassificationResult>();
  private readonly idiomDict: IdiomDictionaryService;

  constructor(
    @Optional() @Inject(GeminiService) private readonly gemini?: GeminiService,
    @Optional() @Inject(IdiomDictionaryService) idiomDictionary?: IdiomDictionaryService,
    @Optional() @Inject(SymptomVectorService) private readonly symptomVector?: SymptomVectorService,
  ) {
    this.idiomDict = idiomDictionary ?? new IdiomDictionaryService();
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

    // 3. Symptom vector DB match (semantic, learns over time from Gemini classifications)
    if (this.symptomVector) {
      const vectorMatch = await this.symptomVector.matchSymptom(dto.text);
      if (vectorMatch) {
        this.cache.set(cacheKey, vectorMatch);
        return {
          ...vectorMatch,
          latencyMs: Math.round(performance.now() - startTime),
        };
      }
    }

    // 4. Gemini structured output
    if (this.gemini?.isAvailable) {
      try {
        const parsed = await this.gemini.generateJson<Record<string, any>>({
          schema: CLASSIFICATION_SCHEMA,
          prompt: `Você é o motor de triagem médica preventiva do DualisCheckUp. Classifique a seguinte descrição do usuário: "${dto.text}". Retorne em JSON estrito com:
              - isOffTopic: booleano indicando se o texto NÃO descreve um sintoma físico ou emocional real (ex.: piadas, textos aleatórios, spam, pedidos não relacionados à saúde). Se true, ainda assim preencha os demais campos com os valores mais neutros/plausíveis abaixo.
              - vertical: "physical" ou "emotional"
              - systemOrDimension: escolha EXATAMENTE uma destas chaves, de acordo com o "vertical" escolhido (nunca invente uma chave nova):
                se vertical = "physical": ${PHYSICAL_SYSTEMS.join(', ')}
                se vertical = "emotional": ${EMOTIONAL_SYSTEMS.join(', ')}
              - urgencyScore: número inteiro de 1 a 5
              - mappedLayTerm: termo leigo identificado, refletindo o sintoma relatado (ex.: coceira, tontura, dor) e não assumindo que é dor quando não for
              - clinicalConcept: conceito médico formal correspondente
              - isEmergencyCandidate: booleano indicando se preenche critérios Manchester/ESI nível 1-2`,
        });

        const primaryVertical = parsed.vertical === 'emotional' ? 'emotional' : 'physical';
        const validSystems = primaryVertical === 'emotional' ? EMOTIONAL_SYSTEMS : PHYSICAL_SYSTEMS;
        const systemOrDimension = validSystems.includes(parsed.systemOrDimension)
          ? parsed.systemOrDimension
          : primaryVertical === 'emotional'
            ? 'cognitiva_foco'
            : 'general_somatic';

        const result: TriageClassificationResult = {
          primaryVertical,
          systemOrDimension,
          urgencyScore: typeof parsed.urgencyScore === 'number' ? parsed.urgencyScore : 2,
          mappedLayTerm: parsed.mappedLayTerm || dto.text,
          clinicalConcept: parsed.clinicalConcept || 'sintoma inespecífico',
          isEmergencyCandidate: parsed.isEmergencyCandidate === true,
          isOffTopic: parsed.isOffTopic === true,
          confidence: 0.90,
          source: 'gemini',
          latencyMs: Math.round(performance.now() - startTime),
        };

        this.cache.set(cacheKey, result);
        if (!result.isOffTopic) {
          this.symptomVector?.upsertFromClassification(dto.text, result).catch(() => {});
        }
        return result;
      } catch (err) {
        this.logger.warn(`Gemini inference failed, falling back: ${(err as Error).message}`);
      }
    }

    // 5. Heuristic Fallback (<2ms)
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
