import { Lang } from '../triage/services/triage-outcome.service';

export interface HouseAdDto {
  id: string;
  brand: string;
  title: string;
  body: string;
  imageUrl?: string;
  /** Image bundled in the app. */
  assetKey?: string;
  url: string;
}

export interface HouseAdsResponseDto {
  ads: HouseAdDto[];
}

type LocalizedAd = Omit<HouseAdDto, 'title' | 'body'> & {
  title: Record<Lang, string>;
  body: Record<Lang, string>;
};

/**
 * Own ads (strategy §14): a static list, identical for every person, that never depends
 * on what anyone recorded. ZOC, WGI and UBO are fictional internal examples (§18, decision 3):
 * replace them with real advertisers or Dualis Premium before launch. No health promises.
 */
const HOUSE_ADS: LocalizedAd[] = [
  {
    id: 'dualis-premium',
    brand: 'Dualis Premium',
    assetKey: 'house_ad_dualis_premium',
    url: 'https://example.com/dualis-premium',
    title: {
      pt: 'Dualis Premium',
      en: 'Dualis Premium',
      es: 'Dualis Premium',
    },
    body: {
      pt: 'Veja seus registros de até 12 meses e escolha fundos personalizados.',
      en: 'See up to 12 months of your entries and choose custom backgrounds.',
      es: 'Mira hasta 12 meses de tus registros y elige fondos personalizados.',
    },
  },
  {
    id: 'zoc',
    brand: 'ZOC',
    assetKey: 'house_ad_zoc',
    url: 'https://example.com/zoc',
    title: {
      pt: 'ZOC: organize sua semana',
      en: 'ZOC: plan your week',
      es: 'ZOC: organiza tu semana',
    },
    body: {
      pt: 'Listas e lembretes simples para o dia a dia. Exemplo de anúncio.',
      en: 'Simple lists and reminders for everyday life. Sample ad.',
      es: 'Listas y recordatorios sencillos para el día a día. Anuncio de ejemplo.',
    },
  },
  {
    id: 'wgi',
    brand: 'WGI',
    assetKey: 'house_ad_wgi',
    url: 'https://example.com/wgi',
    title: {
      pt: 'WGI: garrafas e copos',
      en: 'WGI: bottles and cups',
      es: 'WGI: botellas y vasos',
    },
    body: {
      pt: 'Garrafas reutilizáveis em várias cores. Exemplo de anúncio.',
      en: 'Reusable bottles in many colours. Sample ad.',
      es: 'Botellas reutilizables en varios colores. Anuncio de ejemplo.',
    },
  },
  {
    id: 'ubo',
    brand: 'UBO',
    assetKey: 'house_ad_ubo',
    url: 'https://example.com/ubo',
    title: {
      pt: 'UBO: caminhadas em grupo',
      en: 'UBO: group walks',
      es: 'UBO: caminatas en grupo',
    },
    body: {
      pt: 'Encontre grupos de caminhada perto de você. Exemplo de anúncio.',
      en: 'Find walking groups near you. Sample ad.',
      es: 'Encuentra grupos de caminata cerca de ti. Anuncio de ejemplo.',
    },
  },
];

export function houseAdsFor(lang: Lang): HouseAdsResponseDto {
  return {
    ads: HOUSE_ADS.map(({ title, body, ...ad }) => ({ ...ad, title: title[lang], body: body[lang] })),
  };
}
