import { Injectable } from '@nestjs/common';
import { TriageClassificationResult } from '../dto/classify-symptom.dto';

interface IdiomEntry {
  pattern: RegExp;
  vertical: 'physical' | 'emotional';
  systemOrDimension: string;
  urgencyScore: number;
  mappedLayTerm: string;
  clinicalConcept: string;
  isEmergencyCandidate: boolean;
}

@Injectable()
export class IdiomDictionaryService {
  private readonly entries: IdiomEntry[] = [
    {
      pattern: /(dor\s+no\s+peito|peito\s+apertado|press[aã]o\s+no\s+peito|queima[cç][aã]o\s+no\s+peito|dolor\s+en\s+el\s+pecho|chest\s+pain|pressure\s+in\s+chest)/i,
      vertical: 'physical',
      systemOrDimension: 'cardiovascular_chest',
      urgencyScore: 5,
      mappedLayTerm: 'dor / aperto no peito',
      clinicalConcept: 'precordialgia / suspeita de síndrome coronariana aguda',
      isEmergencyCandidate: true,
    },
    {
      pattern: /(cabe[cç]a(\s+\w+)?\s+explodindo|pior\s+dor\s+de\s+cabe[cç]a|trov[aã]o|thunderclap|cabeza(\s+\w+)?\s+explotando|worst\s+headache)/i,
      vertical: 'physical',
      systemOrDimension: 'head_neck',
      urgencyScore: 5,
      mappedLayTerm: 'dor de cabeça súbita e excruciante',
      clinicalConcept: 'cefaleia em trovoada / suspeita de hemorragia subaracnóidea',
      isEmergencyCandidate: true,
    },
    {
      pattern: /(falta\s+de\s+ar|n[aã]o\s+consigo\s+respirar|sufocando|asfixia|dificuldade\s+para\s+respirar|falta\s+de\s+aire|shortness\s+of\s+breath)/i,
      vertical: 'physical',
      systemOrDimension: 'respiratory',
      urgencyScore: 5,
      mappedLayTerm: 'falta de ar aguda',
      clinicalConcept: 'dispneia aguda / insuficiência respiratória',
      isEmergencyCandidate: true,
    },
    {
      pattern: /(boca\s+torta|fraqueza\s+de\s+um\s+lado|bra[cç]o\s+dormente|fala\s+enrolada|boca\s+torcida|facial\s+droop|slurred\s+speech|hemiparesia)/i,
      vertical: 'physical',
      systemOrDimension: 'neurological',
      urgencyScore: 5,
      mappedLayTerm: 'déficit neurológico focal súbito',
      clinicalConcept: 'suspeita de acidente vascular cerebral (AVC)',
      isEmergencyCandidate: true,
    },
    {
      pattern: /(vontade\s+de\s+sumir|n[aã]o\s+quero\s+mais\s+viver|pensando\s+em\s+suic[ií]dio|tirar\s+a\s+pr[oó]pria\s+vida|ganas\s+de\s+morir|want\s+to\s+die|suicid)/i,
      vertical: 'emotional',
      systemOrDimension: 'depressive_hopelessness',
      urgencyScore: 5,
      mappedLayTerm: 'ideação autolesiva / desesperança profunda',
      clinicalConcept: 'crise suicida aguda / risco à integridade física',
      isEmergencyCandidate: true,
    },
    {
      pattern: /(crise\s+de\s+p[aâ]nico|ataque\s+de\s+p[aâ]nico|cora[cç][aã]o\s+disparado\s+de\s+medo|sensa[cç][aã]o\s+de\s+morte|panic\s+attack)/i,
      vertical: 'emotional',
      systemOrDimension: 'anxious_agitation',
      urgencyScore: 4,
      mappedLayTerm: 'crise aguda de pânico',
      clinicalConcept: 'transtorno de ansiedade / crise de pânico paroxística',
      isEmergencyCandidate: true,
    },
    {
      pattern: /(dor\s+de\s+cabe[cç]a|enxaqueca|cefaleia|cabeza|headache|migraine)/i,
      vertical: 'physical',
      systemOrDimension: 'head_neck',
      urgencyScore: 2,
      mappedLayTerm: 'dor de cabeça',
      clinicalConcept: 'cefaleia tensional / migrânea',
      isEmergencyCandidate: false,
    },
    {
      pattern: /(dor\s+nas\s+costas|coluna|lombar|lombalgia|espalda|back\s+pain)/i,
      vertical: 'physical',
      systemOrDimension: 'musculoskeletal_back',
      urgencyScore: 2,
      mappedLayTerm: 'dor nas costas / coluna',
      clinicalConcept: 'lombalgia mecânica / cervicalgia',
      isEmergencyCandidate: false,
    },
    {
      pattern: /(joelho|articula[cç][aã]o|juntas|articulaciones|joint\s+pain|knee|pernas\s+pesadas|incha[cç]o\s+nos\s+tornozelos|calcanhar|panturrilha)/i,
      vertical: 'physical',
      systemOrDimension: 'membros_inferiores',
      urgencyScore: 2,
      mappedLayTerm: 'dor em membros inferiores / articulação',
      clinicalConcept: 'artralgia / dor musculoesquelética de membro inferior',
      isEmergencyCandidate: false,
    },
    {
      pattern: /\b(ombro|bra[cç]o|punho|tendinite|cotovelo)\b/i,
      vertical: 'physical',
      systemOrDimension: 'membros_superiores',
      urgencyScore: 2,
      mappedLayTerm: 'dor em membros superiores / ombro / braço',
      clinicalConcept: 'tendinopatia / dor musculoesquelética de membro superior',
      isEmergencyCandidate: false,
    },
    {
      pattern: /(est[oô]mago|azia|queima[cç][aã]o|barriga|abd[oô]men|gastrite|stomach\s+ache|acid\s+reflux)/i,
      vertical: 'physical',
      systemOrDimension: 'gastrointestinal',
      urgencyScore: 2,
      mappedLayTerm: 'desconforto gástrico / dor abdominal',
      clinicalConcept: 'dispepsia funcional / refluxo gastresofágico',
      isEmergencyCandidate: false,
    },
    {
      pattern: /(tontura|vertigem|labirintite|perda\s+de\s+equil[ií]brio)/i,
      vertical: 'physical',
      systemOrDimension: 'neurological',
      urgencyScore: 2,
      mappedLayTerm: 'tontura / vertigem',
      clinicalConcept: 'vestibulopatia / disfunção vestibular periférica',
      isEmergencyCandidate: false,
    },
    {
      pattern: /(dor\s+ao\s+urinar|ard[eê]ncia\s+ao\s+urinar|c[oó]lica\s+renal|dor\s+p[eé]lvica|baixo\s+ventre)/i,
      vertical: 'physical',
      systemOrDimension: 'geniturinario_pelvico',
      urgencyScore: 2,
      mappedLayTerm: 'desconforto urinário / pélvico',
      clinicalConcept: 'disúria / queixa funcional pélvica',
      isEmergencyCandidate: false,
    },
    {
      pattern: /(coceira|manchas\s+na\s+pele|urtic[aá]ria|alergia\s+na\s+pele|prurido)/i,
      vertical: 'physical',
      systemOrDimension: 'dermatologico',
      urgencyScore: 2,
      mappedLayTerm: 'alergia / lesão de pele',
      clinicalConcept: 'dermatite / reação alérgica cutânea',
      isEmergencyCandidate: false,
    },
    {
      pattern: /(dor\s+no\s+corpo\s+todo|moleza|febre|calafrio|dor\s+nos\s+m[uú]sculos|mialgia)/i,
      vertical: 'physical',
      systemOrDimension: 'muscular_geral_sistemico',
      urgencyScore: 2,
      mappedLayTerm: 'dor muscular / indisposição geral',
      clinicalConcept: 'mialgia difusa / queixa sistêmica',
      isEmergencyCandidate: false,
    },
    {
      pattern: /(sede\s+excessiva|perda\s+de\s+peso\s+repentina|cansa[cç]o\s+extremo)/i,
      vertical: 'physical',
      systemOrDimension: 'endocrino_metabolico',
      urgencyScore: 2,
      mappedLayTerm: 'alteração metabólica / sede excessiva',
      clinicalConcept: 'avaliação metabólica / desgaste energético',
      isEmergencyCandidate: false,
    },
    {
      pattern: /(ansiedade|ansioso|agitado|nervoso|preocupa[cç][aã]o|ansiedad|anxiety|nervous)/i,
      vertical: 'emotional',
      systemOrDimension: 'anxious_agitation',
      urgencyScore: 2,
      mappedLayTerm: 'ansiedade / preocupação',
      clinicalConcept: 'estado ansioso / hiperativação autonômica',
      isEmergencyCandidate: false,
    },
    {
      pattern: /(tristeza|triste|des[aâ]nimo|deprimido|choro|sadness|low\s+mood)/i,
      vertical: 'emotional',
      systemOrDimension: 'depressive_hopelessness',
      urgencyScore: 2,
      mappedLayTerm: 'tristeza / desânimo',
      clinicalConcept: 'rebaixamento de humor / distimia leve',
      isEmergencyCandidate: false,
    },
    {
      pattern: /(estresse|estressado|irritado|irritabilidade|paci[eê]ncia\s+curta|estr[eé]s|stress|burnout)/i,
      vertical: 'emotional',
      systemOrDimension: 'stress_burnout',
      urgencyScore: 2,
      mappedLayTerm: 'estresse / irritabilidade',
      clinicalConcept: 'sobrecarga alostática / esgotamento psicofisiológico',
      isEmergencyCandidate: false,
    },
    {
      pattern: /(n[oó]\s+na\s+garganta|aperto\s+na\s+garganta|gastrite\s+nervosa)/i,
      vertical: 'emotional',
      systemOrDimension: 'somatica',
      urgencyScore: 2,
      mappedLayTerm: 'manifestação psicossomática',
      clinicalConcept: 'somatização de estresse emocional',
      isEmergencyCandidate: false,
    },
    {
      pattern: /(ins[oô]nia|sono\s+ruim|acordo\s+de\s+madrugada|pesadelo|durmo\s+demais)/i,
      vertical: 'emotional',
      systemOrDimension: 'sono',
      urgencyScore: 2,
      mappedLayTerm: 'distúrbio do sono',
      clinicalConcept: 'insônia / alteração do padrão de repouso',
      isEmergencyCandidate: false,
    },
    {
      pattern: /(n[eé]voa\s+mental|brain\s+fog|sem\s+foco|mente\s+lerda|cansa[cç]o\s+mental|fadiga\s+mental|mente\s+pesada|mental\s+fatigue)/i,
      vertical: 'emotional',
      systemOrDimension: 'cognitiva_foco',
      urgencyScore: 2,
      mappedLayTerm: 'cansaço mental / névoa mental',
      clinicalConcept: 'fadiga cognitiva / sobrecarga atencional',
      isEmergencyCandidate: false,
    },
    {
      pattern: /(culpa|incapaz|me\s+sinto\s+um\s+lixo|autocr[ií]tica)/i,
      vertical: 'emotional',
      systemOrDimension: 'autoestima',
      urgencyScore: 2,
      mappedLayTerm: 'autocrítica severa / sentimento de culpa',
      clinicalConcept: 'autoimagem fragilizada / distorção de autoeficácia',
      isEmergencyCandidate: false,
    },
  ];

  match(text: string): TriageClassificationResult | null {
    const start = performance.now();
    const clean = text.trim();

    for (const entry of this.entries) {
      if (entry.pattern.test(clean)) {
        return {
          primaryVertical: entry.vertical,
          systemOrDimension: entry.systemOrDimension,
          urgencyScore: entry.urgencyScore,
          mappedLayTerm: entry.mappedLayTerm,
          clinicalConcept: entry.clinicalConcept,
          isEmergencyCandidate: entry.isEmergencyCandidate,
          confidence: 0.95,
          source: 'dictionary_fallback',
          latencyMs: Math.round(performance.now() - start),
        };
      }
    }

    return null;
  }
}
