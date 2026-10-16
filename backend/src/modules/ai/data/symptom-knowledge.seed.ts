export interface SeedSymptomDefinition {
  id: string;
  inputText: string;
  vertical: 'physical' | 'emotional';
  systemOrDimension: string;
  mappedLayTerm: string;
}

// Seeded from the deterministic entries in IdiomDictionaryService so the vector
// store starts warm with the same lay vocabulary the regex fast-path already covers.
// Only canonical phrases live here; raw user text is never stored in this shared table.
export const SYMPTOM_KNOWLEDGE_SEED: SeedSymptomDefinition[] = [
  {
    id: 'symp-peito-01',
    inputText: 'dor no peito, peito apertado, pressão no peito',
    vertical: 'physical',
    systemOrDimension: 'cardiovascular_chest',
    mappedLayTerm: 'dor / aperto no peito',
  },
  {
    id: 'symp-cabeca-explodindo-01',
    inputText: 'cabeça explodindo, pior dor de cabeça da minha vida, trovão',
    vertical: 'physical',
    systemOrDimension: 'head_neck',
    mappedLayTerm: 'dor de cabeça muito forte e repentina',
  },
  {
    id: 'symp-falta-de-ar-01',
    inputText: 'falta de ar, não consigo respirar, sufocando, asfixia',
    vertical: 'physical',
    systemOrDimension: 'respiratory',
    mappedLayTerm: 'falta de ar',
  },
  {
    id: 'symp-avc-01',
    inputText: 'boca torta, fraqueza de um lado, braço dormente, fala enrolada',
    vertical: 'physical',
    systemOrDimension: 'neurological',
    mappedLayTerm: 'fraqueza de um lado / fala enrolada',
  },
  {
    id: 'symp-ideacao-suicida-01',
    inputText: 'vontade de sumir, não quero mais viver, pensando em suicídio',
    vertical: 'emotional',
    systemOrDimension: 'depressive_hopelessness',
    mappedLayTerm: 'vontade de se ferir / desesperança',
  },
  {
    id: 'symp-panico-01',
    inputText: 'crise de pânico, ataque de pânico, coração disparado de medo',
    vertical: 'emotional',
    systemOrDimension: 'anxious_agitation',
    mappedLayTerm: 'crise de pânico',
  },
  {
    id: 'symp-cefaleia-01',
    inputText: 'dor de cabeça, enxaqueca, cefaleia',
    vertical: 'physical',
    systemOrDimension: 'head_neck',
    mappedLayTerm: 'dor de cabeça',
  },
  {
    id: 'symp-costas-01',
    inputText: 'dor nas costas, coluna, lombar, lombalgia',
    vertical: 'physical',
    systemOrDimension: 'musculoskeletal_back',
    mappedLayTerm: 'dor nas costas / coluna',
  },
  {
    id: 'symp-joelho-01',
    inputText: 'joelho, articulação, juntas, dor nas pernas, tornozelo inchado',
    vertical: 'physical',
    systemOrDimension: 'membros_inferiores',
    mappedLayTerm: 'dor nas pernas / articulações',
  },
  {
    id: 'symp-ombro-01',
    inputText: 'ombro, braço, punho, tendinite, cotovelo',
    vertical: 'physical',
    systemOrDimension: 'membros_superiores',
    mappedLayTerm: 'dor no ombro / braço',
  },
  {
    id: 'symp-estomago-01',
    inputText: 'estômago, azia, queimação, barriga, gastrite',
    vertical: 'physical',
    systemOrDimension: 'gastrointestinal',
    mappedLayTerm: 'desconforto no estômago / barriga',
  },
  {
    id: 'symp-tontura-01',
    inputText: 'tontura, vertigem, labirintite, perda de equilíbrio',
    vertical: 'physical',
    systemOrDimension: 'neurological',
    mappedLayTerm: 'tontura / vertigem',
  },
  {
    id: 'symp-urinario-01',
    inputText: 'dor ao urinar, ardência ao urinar, cólica renal, dor pélvica',
    vertical: 'physical',
    systemOrDimension: 'geniturinario_pelvico',
    mappedLayTerm: 'desconforto ao urinar / baixo ventre',
  },
  {
    id: 'symp-pele-01',
    inputText: 'coceira, manchas na pele, urticária, alergia na pele, prurido',
    vertical: 'physical',
    systemOrDimension: 'dermatologico',
    mappedLayTerm: 'coceira / manchas na pele',
  },
  {
    id: 'symp-corpo-todo-01',
    inputText: 'dor no corpo todo, moleza, febre, calafrio, mialgia',
    vertical: 'physical',
    systemOrDimension: 'muscular_geral_sistemico',
    mappedLayTerm: 'dor muscular / indisposição geral',
  },
  {
    id: 'symp-metabolico-01',
    inputText: 'sede excessiva, perda de peso repentina, cansaço extremo',
    vertical: 'physical',
    systemOrDimension: 'endocrino_metabolico',
    mappedLayTerm: 'muita sede / cansaço extremo',
  },
  {
    id: 'symp-ansiedade-01',
    inputText: 'ansiedade, ansioso, agitado, nervoso, preocupação',
    vertical: 'emotional',
    systemOrDimension: 'anxious_agitation',
    mappedLayTerm: 'ansiedade / preocupação',
  },
  {
    id: 'symp-tristeza-01',
    inputText: 'tristeza, triste, desânimo, deprimido, choro',
    vertical: 'emotional',
    systemOrDimension: 'depressive_hopelessness',
    mappedLayTerm: 'tristeza / desânimo',
  },
  {
    id: 'symp-estresse-01',
    inputText: 'estresse, estressado, irritado, irritabilidade, paciência curta',
    vertical: 'emotional',
    systemOrDimension: 'stress_burnout',
    mappedLayTerm: 'estresse / irritabilidade',
  },
  {
    id: 'symp-somatico-01',
    inputText: 'nó na garganta, aperto na garganta, gastrite nervosa',
    vertical: 'emotional',
    systemOrDimension: 'somatica',
    mappedLayTerm: 'nó na garganta',
  },
  {
    id: 'symp-sono-01',
    inputText: 'insônia, sono ruim, acordo de madrugada, pesadelo',
    vertical: 'emotional',
    systemOrDimension: 'sono',
    mappedLayTerm: 'sono ruim',
  },
  {
    id: 'symp-nevoa-mental-01',
    inputText: 'névoa mental, sem foco, mente lerda, cansaço mental, esgotado',
    vertical: 'emotional',
    systemOrDimension: 'cognitiva_foco',
    mappedLayTerm: 'cansaço mental / névoa mental',
  },
  {
    id: 'symp-autoestima-01',
    inputText: 'culpa, incapaz, me sinto um lixo, autocrítica',
    vertical: 'emotional',
    systemOrDimension: 'autoestima',
    mappedLayTerm: 'autocrítica / sentimento de culpa',
  },
];
