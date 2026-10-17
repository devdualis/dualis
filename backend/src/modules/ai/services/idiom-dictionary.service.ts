import { Injectable } from '@nestjs/common';
import { EntryTagResult } from '../dto/classify-symptom.dto';

// Content-safety net (not an assessment): the text mentions wanting to hurt oneself
// or die. Checked on every entry, independently of which idiom matched first.
const SELF_HARM_PATTERN =
  /(vontade\s+de\s+sumir|n[aã]o\s+quero\s+mais\s+viver|quero\s+morrer|pensando\s+em\s+suic[ií]dio|tirar\s+a\s+pr[oó]pria\s+vida|me\s+machucar|me\s+ferir|ganas\s+de\s+morir|quiero\s+morir|quitarme\s+la\s+vida|want\s+to\s+die|kill\s+myself|hurt\s+myself|self[-\s]harm|suicid)/i;

interface IdiomEntry {
  pattern: RegExp;
  vertical: 'physical' | 'emotional';
  systemOrDimension: string;
  mappedLayTerm: string;
}

@Injectable()
export class IdiomDictionaryService {
  private readonly entries: IdiomEntry[] = [
    {
      pattern: /(dor(\s+\w+)?\s+no\s+peito|aperto(\s+\w+)?\s+no\s+peito|peito(\s+\w+)?\s+apertado|press[aã]o\s+no\s+peito|queima[cç][aã]o\s+no\s+peito|dolor\s+en\s+el\s+pecho|chest\s+pain|pressure\s+in\s+chest|precordialgia)/i,
      vertical: 'physical',
      systemOrDimension: 'cardiovascular_chest',
      mappedLayTerm: 'dor / aperto no peito',
    },
    {
      pattern: /(cabe[cç]a(\s+\w+)?\s+explodindo|pior\s+dor\s+de\s+cabe[cç]a|trov[aã]o|thunderclap|cabeza(\s+\w+)?\s+explotando|worst\s+headache)/i,
      vertical: 'physical',
      systemOrDimension: 'head_neck',
      mappedLayTerm: 'dor de cabeça muito forte e repentina',
    },
    {
      pattern: /(falta\s+de\s+ar|n[aã]o\s+consigo\s+respirar|sufocando|asfixia|dificuldade\s+para\s+respirar|falta\s+de\s+aire|shortness\s+of\s+breath)/i,
      vertical: 'physical',
      systemOrDimension: 'respiratory',
      mappedLayTerm: 'falta de ar',
    },
    {
      pattern: /(boca\s+torta|fraqueza\s+de\s+um\s+lado|bra[cç]o\s+dormente|fala\s+enrolada|boca\s+torcida|facial\s+droop|slurred\s+speech|hemiparesia)/i,
      vertical: 'physical',
      systemOrDimension: 'neurological',
      mappedLayTerm: 'fraqueza de um lado / fala enrolada',
    },
    {
      pattern: /(vontade\s+de\s+sumir|n[aã]o\s+quero\s+mais\s+viver|pensando\s+em\s+suic[ií]dio|tirar\s+a\s+pr[oó]pria\s+vida|ganas\s+de\s+morir|want\s+to\s+die|suicid)/i,
      vertical: 'emotional',
      systemOrDimension: 'depressive_hopelessness',
      mappedLayTerm: 'vontade de se ferir / desesperança',
    },
    {
      pattern: /(crise\s+de\s+p[aâ]nico|ataque\s+de\s+p[aâ]nico|cora[cç][aã]o\s+disparado|sensa[cç][aã]o\s+de\s+morte|medo\s+s[uú]bito\s+de\s+morrer|panic\s+attack)/i,
      vertical: 'emotional',
      systemOrDimension: 'anxious_agitation',
      mappedLayTerm: 'crise de pânico',
    },
    {
      pattern: /(dor\s+de\s+cabe[cç]a|enxaqueca|cefaleia|cabeza|headache|migraine)/i,
      vertical: 'physical',
      systemOrDimension: 'head_neck',
      mappedLayTerm: 'dor de cabeça',
    },
    {
      pattern: /(c[oó]lica\s+renal|c[aá]lculo\s+renal|pedra\s+nos\s+rins|virilha\s+ao\s+urinar|desce\s+para\s+a\s+virilha)/i,
      vertical: 'physical',
      systemOrDimension: 'geniturinario_pelvico',
      mappedLayTerm: 'cólica / dor na região dos rins',
    },
    {
      pattern: /(dor(\s+\w+)?\s+nas\s+costas|dor\s+muscular\s+nas\s+costas|coluna|lombar|lombalgia|espalda|back\s+pain)/i,
      vertical: 'physical',
      systemOrDimension: 'musculoskeletal_back',
      mappedLayTerm: 'dor nas costas / coluna',
    },
    {
      pattern: /(joelho|articula[cç][aã]o|juntas|articulaciones|joint\s+pain|knee|pernas\s+pesadas|incha[cç]o\s+nos\s+tornozelos|calcanhar|panturrilha)/i,
      vertical: 'physical',
      systemOrDimension: 'membros_inferiores',
      mappedLayTerm: 'dor nas pernas / articulações',
    },
    {
      pattern: /\b(ombro|bra[cç]o|punho|tendinite|cotovelo)\b/i,
      vertical: 'physical',
      systemOrDimension: 'membros_superiores',
      mappedLayTerm: 'dor no ombro / braço',
    },
    {
      pattern: /(est[oô]mago|azia|queima[cç][aã]o|barriga|abd[oô]men|gastrite|stomach\s+ache|acid\s+reflux)/i,
      vertical: 'physical',
      systemOrDimension: 'gastrointestinal',
      mappedLayTerm: 'desconforto no estômago / barriga',
    },
    {
      pattern: /(tontura|vertigem|labirintite|perda\s+de\s+equil[ií]brio)/i,
      vertical: 'physical',
      systemOrDimension: 'neurological',
      mappedLayTerm: 'tontura / vertigem',
    },
    {
      pattern: /(dor\s+ao\s+urinar|ard[eê]ncia\s+ao\s+urinar|c[oó]lica\s+renal|dor\s+p[eé]lvica|baixo\s+ventre)/i,
      vertical: 'physical',
      systemOrDimension: 'geniturinario_pelvico',
      mappedLayTerm: 'desconforto ao urinar / baixo ventre',
    },
    {
      pattern: /(coceira|manchas\s+na\s+pele|urtic[aá]ria|alergia\s+na\s+pele|prurido)/i,
      vertical: 'physical',
      systemOrDimension: 'dermatologico',
      mappedLayTerm: 'coceira / manchas na pele',
    },
    {
      pattern: /(dor\s+no\s+corpo\s+todo|moleza|febre|calafrio|dor\s+nos\s+m[uú]sculos|mialgia)/i,
      vertical: 'physical',
      systemOrDimension: 'muscular_geral_sistemico',
      mappedLayTerm: 'dor muscular / indisposição geral',
    },
    {
      pattern: /(sede\s+excessiva|perda\s+de\s+peso\s+repentina|cansa[cç]o\s+extremo)/i,
      vertical: 'physical',
      systemOrDimension: 'endocrino_metabolico',
      mappedLayTerm: 'muita sede / cansaço extremo',
    },
    {
      pattern: /(ansiedade|ansioso|agitado|nervoso|preocupa[cç][aã]o|ansiedad|anxiety|nervous)/i,
      vertical: 'emotional',
      systemOrDimension: 'anxious_agitation',
      mappedLayTerm: 'ansiedade / preocupação',
    },
    {
      pattern: /(tristeza|triste|des[aâ]nimo|deprimido|choro|sadness|low\s+mood)/i,
      vertical: 'emotional',
      systemOrDimension: 'depressive_hopelessness',
      mappedLayTerm: 'tristeza / desânimo',
    },
    {
      pattern: /(estresse|estressado|irritado|irritabilidade|paci[eê]ncia\s+curta|estr[eé]s|stress|burnout)/i,
      vertical: 'emotional',
      systemOrDimension: 'stress_burnout',
      mappedLayTerm: 'estresse / irritabilidade',
    },
    {
      pattern: /(n[oó]\s+na\s+garganta|aperto\s+na\s+garganta|gastrite\s+nervosa)/i,
      vertical: 'emotional',
      systemOrDimension: 'somatica',
      mappedLayTerm: 'nó na garganta',
    },
    {
      pattern: /(ins[oô]nia|sono\s+ruim|acordo\s+de\s+madrugada|pesadelo|durmo\s+demais|pegar\s+no\s+sono|dificuldade\s+para\s+.*sono)/i,
      vertical: 'emotional',
      systemOrDimension: 'sono',
      mappedLayTerm: 'sono ruim',
    },
    {
      pattern: /(n[eé]voa\s+mental|brain\s+fog|sem\s+foco|mente\s+lerda|cansa[cç]o\s+mental|fadiga\s+mental|mente\s+pesada|mental\s+fatigue)/i,
      vertical: 'emotional',
      systemOrDimension: 'cognitiva_foco',
      mappedLayTerm: 'cansaço mental / névoa mental',
    },
    {
      pattern: /(culpa|incapaz|me\s+sinto\s+um\s+lixo|autocr[ií]tica)/i,
      vertical: 'emotional',
      systemOrDimension: 'autoestima',
      mappedLayTerm: 'autocrítica / sentimento de culpa',
    },
  ];

  mentionsSelfHarm(text: string): boolean {
    return SELF_HARM_PATTERN.test(text);
  }

  match(text: string): EntryTagResult | null {
    const start = performance.now();
    const clean = text.trim();

    for (const entry of this.entries) {
      if (entry.pattern.test(clean)) {
        return {
          isOffTopic: false,
          vertical: entry.vertical,
          bodyAreaOrMood: entry.systemOrDimension,
          layTerm: entry.mappedLayTerm,
          mentionsSelfHarm: this.mentionsSelfHarm(clean),
          confidence: 0.95,
          source: 'dictionary_fallback',
          latencyMs: Math.round(performance.now() - start),
        };
      }
    }

    return null;
  }
}
