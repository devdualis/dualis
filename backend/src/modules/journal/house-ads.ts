import { Lang } from '../../common/i18n/lang';

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
 * on what anyone recorded. Our own apps, alpha test list (2026-10-30). The app draws each
 * brand's card from `assetKey`. No health promises.
 */
const HOUSE_ADS: LocalizedAd[] = [
  {
    id: 'dualis-premium',
    brand: 'Dualis Premium',
    assetKey: 'house_ad_dualis_premium',
    url: 'https://dualischeckup.com/#pricing',
    title: {
      pt: 'Meus cuidados, organizados num só lugar',
      en: 'My care, organised in one place',
      es: 'Mis cuidados, organizados en un solo lugar',
    },
    body: {
      pt: 'Vacinas, alergias, lembretes de medicamentos, consultas e exames. Sem anúncios.',
      en: 'Vaccines, allergies, medication reminders, appointments and exams. No ads.',
      es: 'Vacunas, alergias, recordatorios de medicamentos, citas y exámenes. Sin anuncios.',
    },
  },
  {
    id: 'zoc',
    brand: 'ZOC',
    assetKey: 'house_ad_zoc',
    url: 'https://www.zoctec.com',
    title: {
      pt: 'Cada hora da equipe, no projeto certo',
      en: 'Every team hour, on the right project',
      es: 'Cada hora del equipo, en el proyecto correcto',
    },
    body: {
      pt: 'Apontamento de horas por cliente, projeto e tarefa, com painel de orçamento e produtividade para gestores.',
      en: 'Time tracking by client, project and task, with a budget and productivity dashboard for managers.',
      es: 'Registro de horas por cliente, proyecto y tarea, con panel de presupuesto y productividad para gestores.',
    },
  },
  {
    id: 'ebef',
    brand: 'e-BEF',
    assetKey: 'house_ad_ebef',
    url: 'https://e-bef.com.br',
    title: {
      pt: 'Beneficiário final (UBO) com evidência, sem planilhas',
      en: 'Ultimate beneficial owner (UBO) with evidence, no spreadsheets',
      es: 'Beneficiario final (UBO) con evidencia, sin hojas de cálculo',
    },
    body: {
      pt: 'Documentos societários viram um grafo de poder rastreável, pronto para a IN RFB nº 2.119/2022.',
      en: 'Corporate documents become a traceable power graph, ready for RFB Normative Instruction 2,119/2022.',
      es: 'Los documentos societarios se vuelven un grafo de poder rastreable, listo para la IN RFB n.º 2.119/2022.',
    },
  },
];

export function houseAdsFor(lang: Lang): HouseAdsResponseDto {
  return {
    ads: HOUSE_ADS.map(({ title, body, ...ad }) => ({ ...ad, title: title[lang], body: body[lang] })),
  };
}
