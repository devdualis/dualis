import { SeedArticleDefinition, MEDICAL_ARTICLES_PT_SEED } from './medical-articles.seed.pt';
import { MEDICAL_ARTICLES_ES_SEED } from './medical-articles.seed.es';
import { MEDICAL_ARTICLES_EN_SEED } from './medical-articles.seed.en';

export { SeedArticleDefinition };
export { MEDICAL_ARTICLES_PT_SEED };
export { MEDICAL_ARTICLES_ES_SEED };
export { MEDICAL_ARTICLES_EN_SEED };

export const MEDICAL_ARTICLES_SEED: SeedArticleDefinition[] = [
  ...MEDICAL_ARTICLES_PT_SEED,
  ...MEDICAL_ARTICLES_ES_SEED,
  ...MEDICAL_ARTICLES_EN_SEED,
];
