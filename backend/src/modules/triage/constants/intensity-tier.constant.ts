/**
 * Display bands for the intensity the person reported themselves (1 to 5).
 * Bands only group the person's own rating for colouring; they are not a clinical
 * scale and carry no judgement. Synchronized with the mobile client's intensity bands.
 */

export enum SelfReportedIntensityBand {
  NONE = 'none',
  MILD = 'mild',
  MODERATE = 'moderate',
  INTENSE = 'intense',
}

export interface SelfReportedIntensityBandMetadata {
  band: SelfReportedIntensityBand;
  label: string;
  minScore: number;
  maxScore: number;
  hexColor: string;
  textColor: string;
  cardBgColor: string;
  borderColor: string;
}

export const SELF_REPORTED_INTENSITY_BANDS: Record<SelfReportedIntensityBand, SelfReportedIntensityBandMetadata> = {
  [SelfReportedIntensityBand.NONE]: {
    band: SelfReportedIntensityBand.NONE,
    label: 'Sem registro',
    minScore: 0,
    maxScore: 0,
    hexColor: '#CFD8DC',
    textColor: '#37474F',
    cardBgColor: '#F5F7F8',
    borderColor: '#CFD8DC',
  },
  [SelfReportedIntensityBand.MILD]: {
    band: SelfReportedIntensityBand.MILD,
    label: 'Leve (1-2)',
    minScore: 1,
    maxScore: 2,
    hexColor: '#FFD54F',
    textColor: '#3E2723',
    cardBgColor: '#FFFDE7',
    borderColor: '#FFE082',
  },
  [SelfReportedIntensityBand.MODERATE]: {
    band: SelfReportedIntensityBand.MODERATE,
    label: 'Moderada (3)',
    minScore: 3,
    maxScore: 3,
    hexColor: '#FF8A65',
    textColor: '#FFFFFF',
    cardBgColor: '#FBE9E7',
    borderColor: '#FFAB91',
  },
  [SelfReportedIntensityBand.INTENSE]: {
    band: SelfReportedIntensityBand.INTENSE,
    label: 'Forte (4-5)',
    minScore: 4,
    maxScore: 5,
    hexColor: '#E53935',
    textColor: '#FFFFFF',
    cardBgColor: '#FFEBEE',
    borderColor: '#EF9A9A',
  },
};

/**
 * Resolves the display band from the reported intensity (0 to 5).
 */
export function getIntensityBand(score: number): SelfReportedIntensityBand {
  if (score <= 0) return SelfReportedIntensityBand.NONE;
  if (score <= 2) return SelfReportedIntensityBand.MILD;
  if (score === 3) return SelfReportedIntensityBand.MODERATE;
  return SelfReportedIntensityBand.INTENSE;
}

/**
 * Returns display metadata for a reported intensity.
 */
export function getIntensityBandMetadata(score: number): SelfReportedIntensityBandMetadata {
  return SELF_REPORTED_INTENSITY_BANDS[getIntensityBand(score)];
}

/**
 * Minimum reported intensity counted as "high" in descriptive journal patterns.
 */
export const HIGH_REPORTED_INTENSITY = 4;
