/**
 * Single Source of Truth for clinical intensity states and tiers across the Dualis backend.
 * Synchronized with mobile client's ClinicalIntensityTier.
 */

export enum ClinicalIntensityTier {
  NONE = 'none',
  MILD = 'mild',
  MODERATE = 'moderate',
  INTENSE = 'intense',
}

export interface ClinicalIntensityTierMetadata {
  tier: ClinicalIntensityTier;
  label: string;
  minScore: number;
  maxScore: number;
  hexColor: string;
  textColor: string;
  cardBgColor: string;
  borderColor: string;
  isCritical: boolean;
}

export const CLINICAL_INTENSITY_TIERS: Record<ClinicalIntensityTier, ClinicalIntensityTierMetadata> = {
  [ClinicalIntensityTier.NONE]: {
    tier: ClinicalIntensityTier.NONE,
    label: 'Sem dor',
    minScore: 0,
    maxScore: 0,
    hexColor: '#CFD8DC',
    textColor: '#37474F',
    cardBgColor: '#F5F7F8',
    borderColor: '#CFD8DC',
    isCritical: false,
  },
  [ClinicalIntensityTier.MILD]: {
    tier: ClinicalIntensityTier.MILD,
    label: 'Leve (1-2)',
    minScore: 1,
    maxScore: 2,
    hexColor: '#FFD54F',
    textColor: '#3E2723',
    cardBgColor: '#FFFDE7',
    borderColor: '#FFE082',
    isCritical: false,
  },
  [ClinicalIntensityTier.MODERATE]: {
    tier: ClinicalIntensityTier.MODERATE,
    label: 'Moderada (3)',
    minScore: 3,
    maxScore: 3,
    hexColor: '#FF8A65',
    textColor: '#FFFFFF',
    cardBgColor: '#FBE9E7',
    borderColor: '#FFAB91',
    isCritical: false,
  },
  [ClinicalIntensityTier.INTENSE]: {
    tier: ClinicalIntensityTier.INTENSE,
    label: 'Intensa (4-5)',
    minScore: 4,
    maxScore: 5,
    hexColor: '#E53935',
    textColor: '#FFFFFF',
    cardBgColor: '#FFEBEE',
    borderColor: '#EF9A9A',
    isCritical: true,
  },
};

/**
 * Resolves the ClinicalIntensityTier from a numerical score (0 to 5).
 */
export function getIntensityTier(score: number): ClinicalIntensityTier {
  if (score <= 0) return ClinicalIntensityTier.NONE;
  if (score <= 2) return ClinicalIntensityTier.MILD;
  if (score === 3) return ClinicalIntensityTier.MODERATE;
  return ClinicalIntensityTier.INTENSE;
}

/**
 * Returns metadata for a numerical intensity score.
 */
export function getIntensityTierMetadata(score: number): ClinicalIntensityTierMetadata {
  const tier = getIntensityTier(score);
  return CLINICAL_INTENSITY_TIERS[tier];
}

/**
 * Returns true if the score is in the critical/acute range (4-5).
 */
export function isCriticalIntensity(score: number): boolean {
  return score >= 4;
}
