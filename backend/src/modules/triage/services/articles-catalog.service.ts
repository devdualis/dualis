import { Injectable } from '@nestjs/common';
import { RecommendedArticleDto } from '../dto/triage-outcome.dto';

@Injectable()
export class ArticlesCatalogService {
  private readonly articles: RecommendedArticleDto[] = [
    {
      id: 'art-cardio-01',
      title: 'Compreendendo as Palpitações e Quando Procurar um Cardiologista',
      category: 'cardiovascular_torax',
      author: 'Dra. Beatriz Silva',
      authorRole: 'Cardiologista (InCor / CRM-SP 142.890)',
      readTimeMinutes: 4,
      summary:
        'Guia clínico sobre diferenciação de palpitações benignas por estresse e arritmias que requerem eletrocardiograma imediato.',
      url: 'https://dualis.health/artigos/palpitacoes-e-cuidados-cardiacos',
    },
    {
      id: 'art-coluna-01',
      title: 'Ergonomia no Trabalho e Prevenção de Dores Lombares e Cervicais',
      category: 'coluna_dor_dorsal',
      author: 'Dr. Marcelo Mendes',
      authorRole: 'Ortopedista e Traumatologista (HCFMUSP / CRM-SP 128.450)',
      readTimeMinutes: 5,
      summary:
        'Posturas preventivas, pausas ativas a cada 50 minutos e exercícios de descompressão da coluna lombar.',
      url: 'https://dualis.health/artigos/ergonomia-postura-coluna',
    },
    {
      id: 'art-cabeca-01',
      title: 'Cefaleia Tensional vs. Enxaqueca: Como Identificar os Primeiros Sinais',
      category: 'cabeca_pescoco',
      author: 'Dr. Thiago Albuquerque',
      authorRole: 'Neurologista Clínico (UNIFESP / CRM-SP 156.702)',
      readTimeMinutes: 4,
      summary:
        'Diferenciação prática entre dores de cabeça causadas por tensão muscular e crises de enxaqueca pulsátil.',
      url: 'https://dualis.health/artigos/cefaleia-e-enxaqueca',
    },
    {
      id: 'art-gastro-01',
      title: 'O Eixo Intestino-Cérebro: Como o Estresse Afeta Sua Digestão',
      category: 'gastrointestinal_abdomen',
      author: 'Dra. Fernanda Toledo',
      authorRole: 'Gastroenterologista (FBG / CRM-SP 139.112)',
      readTimeMinutes: 5,
      summary:
        'Mecanismos neuroquímicos da dispepsia funcional, gastrite nervosa e estratégias de modulação alimentar.',
      url: 'https://dualis.health/artigos/eixo-intestino-cerebro',
    },
    {
      id: 'art-ansiedade-01',
      title: 'Manejo da Ansiedade Aguda com Respiração Diafragmática',
      category: 'ansiosa_agitacao',
      author: 'Dra. Camila Prado',
      authorRole: 'Psiquiatra Clínica (ABP / CRM-SP 165.340)',
      readTimeMinutes: 4,
      summary:
        'Exercício guiado 4-7-8 para desaceleração do sistema simpático e restabelecimento do equilíbrio vagal em minutos.',
      url: 'https://dualis.health/artigos/respiracao-diafragmatica-ansiedade',
    },
    {
      id: 'art-desanimo-01',
      title: 'Ativação Comportamental: Passos para Romper o Ciclo do Desânimo',
      category: 'depressiva_desanimo',
      author: 'Dr. Rafael Nogueira',
      authorRole: 'Psiquiatra e Psicoterapeuta (CRM-SP 148.910)',
      readTimeMinutes: 5,
      summary:
        'Estratégias práticas para reengajar em pequenas atividades diárias e restaurar gradualmente a motivação.',
      url: 'https://dualis.health/artigos/ativacao-comportamental-desanimo',
    },
    {
      id: 'art-burnout-01',
      title: 'Prevenção da Exaustão Mental e Sobrecarga Emocional',
      category: 'estresse_burnout',
      author: 'Dr. Lucas Rossi',
      authorRole: 'Psicólogo Clínico (CRP-06/123456)',
      readTimeMinutes: 5,
      summary:
        'Sinais precoces de esgotamento pelo trabalho e métodos de reestruturação de rotina para restauração cognitiva.',
      url: 'https://dualis.health/artigos/prevencao-esgotamento-burnout',
    },
    {
      id: 'art-sono-01',
      title: 'Higiene do Sono: 7 Hábitos Essenciais para uma Noite Reparadora',
      category: 'sono',
      author: 'Dra. Helena Vasconcelos',
      authorRole: 'Especialista em Medicina do Sono (ABMS / CRM-SP 153.220)',
      readTimeMinutes: 4,
      summary:
        'Protocolo de descompressão antes de deitar, controle da exposição à luz azul e ambiente ideal para repouso.',
      url: 'https://dualis.health/artigos/higiene-do-sono',
    },
    {
      id: 'art-somatica-01',
      title: 'Manifestações Psicossomáticas: Quando o Corpo Reage às Emoções',
      category: 'somatica',
      author: 'Dra. Juliana Guimarães',
      authorRole: 'Médica de Família e Comunidade (SBMFC / CRM-SP 171.045)',
      readTimeMinutes: 4,
      summary:
        'Como entender o nó na garganta e a tensão torácica emocional, garantindo sempre a prioridade clínica orgânica.',
      url: 'https://dualis.health/artigos/sintomas-psicossomaticos-e-corpo',
    },
    {
      id: 'art-geral-01',
      title: 'Guia de Auto-Cuidado Preventivo e Bem-Estar Diário',
      category: 'geral',
      author: 'Dr. André Cavalcanti',
      authorRole: 'Clínico Geral (SBCM / CRM-SP 134.800)',
      readTimeMinutes: 3,
      summary:
        'Práticas fundamentais de hidratação, sono adequado e monitoramento preventivo de sinais e sintomas.',
      url: 'https://dualis.health/artigos/autocuidado-preventivo',
    },
  ];

  getArticlesForCategory(category: string): RecommendedArticleDto[] {
    const matched = this.articles.filter((a) => a.category === category);
    if (matched.length > 0) {
      const general = this.articles.find((a) => a.category === 'geral');
      return general && !matched.includes(general) ? [...matched, general] : matched;
    }

    return this.articles.slice(0, 2);
  }
}
