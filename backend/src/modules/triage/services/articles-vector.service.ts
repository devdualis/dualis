import { Inject, Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { sql } from 'drizzle-orm';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { DRIZZLE_DB } from '../../../database/database.service';
import * as schema from '../../../database/schema';
import { RecommendedArticleDto } from '../dto/triage-outcome.dto';
import { ArticleEmbeddingService } from './article-embedding.service';

export interface SeedArticleDefinition {
  id: string;
  title: string;
  category: string;
  somaticSystem?: string;
  author: string;
  authorRole: string;
  readTimeMinutes: number;
  summary: string;
  contentMarkdown: string;
  keywords: string[];
  url: string;
}

@Injectable()
export class ArticlesVectorService implements OnModuleInit {
  private readonly logger = new Logger(ArticlesVectorService.name);
  private readonly semanticCache = new Map<string, RecommendedArticleDto[]>();

  public readonly seedArticles: SeedArticleDefinition[] = [
    {
      id: 'art-coluna-01',
      title: 'Ergonomia no Trabalho e Prevenção de Dores Lombares e Cervicais',
      category: 'coluna_dor_dorsal',
      somaticSystem: 'musculoesqueletico',
      author: 'Dr. Marcelo Mendes',
      authorRole: 'Ortopedista e Traumatologista (HCFMUSP / CRM-SP 128.450)',
      readTimeMinutes: 5,
      summary:
        'Posturas preventivas, pausas ativas a cada 50 minutos e exercícios de descompressão da coluna lombar.',
      contentMarkdown:
        'A dor nas costas e coluna lombar é uma das queixas musculoesqueléticas mais frequentes no trabalho diário...',
      keywords: ['costas', 'coluna', 'lombar', 'dor lombar', 'cervical', 'postura', 'ergonomia', 'coluna dorsal'],
      url: 'https://dualis.health/artigos/ergonomia-postura-coluna',
    },
    {
      id: 'art-cardio-01',
      title: 'Compreendendo as Palpitações e Quando Procurar um Cardiologista',
      category: 'cardiovascular_torax',
      somaticSystem: 'cardiovascular',
      author: 'Dra. Beatriz Silva',
      authorRole: 'Cardiologista (InCor / CRM-SP 142.890)',
      readTimeMinutes: 4,
      summary:
        'Guia clínico sobre diferenciação de palpitações benignas por estresse e arritmias que requerem eletrocardiograma imediato.',
      contentMarkdown:
        'Palpitações torácicas e sensação de coração acelerado podem derivar de sobrecarga adrenérgica...',
      keywords: ['peito', 'coracao', 'palpitacao', 'torax', 'taquicardia', 'aperto', 'cardiaco'],
      url: 'https://dualis.health/artigos/palpitacoes-e-cuidados-cardiacos',
    },
    {
      id: 'art-cabeca-01',
      title: 'Cefaleia Tensional vs. Enxaqueca: Como Identificar os Primeiros Sinais',
      category: 'cabeca_pescoco',
      somaticSystem: 'neurologico',
      author: 'Dr. Thiago Albuquerque',
      authorRole: 'Neurologista Clínico (UNIFESP / CRM-SP 156.702)',
      readTimeMinutes: 4,
      summary:
        'Diferenciação prática entre dores de cabeça causadas por tensão muscular e crises de enxaqueca pulsátil.',
      contentMarkdown:
        'Cefaleias tensionais afetam a faixa muscular da fronte e nuca, enquanto enxaquecas tendem a ser unilaterais...',
      keywords: ['cabeca', 'enxaqueca', 'cefaleia', 'pescoco', 'pulsatil', 'tensao craniana'],
      url: 'https://dualis.health/artigos/cefaleia-e-enxaqueca',
    },
    {
      id: 'art-gastro-01',
      title: 'O Eixo Intestino-Cérebro: Como o Estresse Afeta Sua Digestão',
      category: 'gastrointestinal_abdomen',
      somaticSystem: 'digestivo',
      author: 'Dra. Fernanda Toledo',
      authorRole: 'Gastroenterologista (FBG / CRM-SP 139.112)',
      readTimeMinutes: 5,
      summary:
        'Mecanismos neuroquímicos da dispepsia funcional, gastrite nervosa e estratégias de modulação alimentar.',
      contentMarkdown:
        'O trato gastrointestinal contém uma extensa rede de neurônios diretamente conectada ao sistema nervoso central...',
      keywords: ['estomago', 'abdomen', 'digestao', 'gastrite', 'refluxo', 'queimacao', 'colica'],
      url: 'https://dualis.health/artigos/eixo-intestino-cerebro',
    },
    {
      id: 'art-respiratorio-01',
      title: 'Manejo Preventivo da Respiração Curta e Alergias Respiratórias',
      category: 'respiratorio_pulmao',
      somaticSystem: 'respiratorio',
      author: 'Dr. Paulo Sampaio',
      authorRole: 'Pneumologista (SBPT / CRM-SP 151.290)',
      readTimeMinutes: 4,
      summary:
        'Dicas para melhorar a capacidade ventilatória e identificar precocemente desconfortos broncopulmonares.',
      contentMarkdown:
        'Dificuldades ventilatórias leves podem ser amenizadas com controle ambiental e hidratação das vias aéreas...',
      keywords: ['respiracao', 'pulmao', 'falta de ar', 'tosse', 'peito cheio', 'chiado'],
      url: 'https://dualis.health/artigos/prevencao-respiratoria',
    },
    {
      id: 'art-ansiedade-01',
      title: 'Manejo da Ansiedade Aguda com Respiração Diafragmática',
      category: 'ansiosa_agitacao',
      somaticSystem: 'emocional',
      author: 'Dra. Camila Prado',
      authorRole: 'Psiquiatra Clínica (ABP / CRM-SP 165.340)',
      readTimeMinutes: 4,
      summary:
        'Exercício guiado 4-7-8 para desaceleração do sistema simpático e restabelecimento do equilíbrio vagal em minutos.',
      contentMarkdown:
        'A respiração diafragmática ativa o nervo vago e induz uma resposta parassimpática quase imediata...',
      keywords: ['ansiedade', 'agitacao', 'nervosismo', 'inquietacao', 'panico', 'angustia', 'medo'],
      url: 'https://dualis.health/artigos/respiracao-diafragmatica-ansiedade',
    },
    {
      id: 'art-desanimo-01',
      title: 'Ativação Comportamental: Passos para Romper o Ciclo do Desânimo',
      category: 'depressiva_desanimo',
      somaticSystem: 'emocional',
      author: 'Dr. Rafael Nogueira',
      authorRole: 'Psiquiatra e Psicoterapeuta (CRM-SP 148.910)',
      readTimeMinutes: 5,
      summary:
        'Estratégias práticas para reengajar em pequenas atividades diárias e restaurar gradualmente a motivação.',
      contentMarkdown:
        'A inatividade reforça sentimentos de tristeza e desânimo. A ativação gradual reabre os circuitos de recompensa...',
      keywords: ['tristeza', 'desanimo', 'depressao', 'apatia', 'desmotivacao', 'baixa energia'],
      url: 'https://dualis.health/artigos/ativacao-comportamental-desanimo',
    },
    {
      id: 'art-burnout-01',
      title: 'Prevenção da Exaustão Mental e Sobrecarga Emocional',
      category: 'estresse_burnout',
      somaticSystem: 'emocional',
      author: 'Dr. Lucas Rossi',
      authorRole: 'Psicólogo Clínico (CRP-06/123456)',
      readTimeMinutes: 5,
      summary:
        'Sinais precoces de esgotamento pelo trabalho e métodos de reestruturação de rotina para restauração cognitiva.',
      contentMarkdown:
        'O esgotamento mental progride silenciosamente em fases: idealismo, estagnação, frustração e apatia...',
      keywords: ['estresse', 'burnout', 'sobrecarga', 'cansaco mental', 'exaustao', 'pressao'],
      url: 'https://dualis.health/artigos/prevencao-esgotamento-burnout',
    },
    {
      id: 'art-sono-01',
      title: 'Higiene do Sono: 7 Hábitos Essenciais para uma Noite Reparadora',
      category: 'sono',
      somaticSystem: 'emocional',
      author: 'Dra. Helena Vasconcelos',
      authorRole: 'Especialista em Medicina do Sono (ABMS / CRM-SP 153.220)',
      readTimeMinutes: 4,
      summary:
        'Protocolo de descompressão antes de deitar, controle da exposição à luz azul e ambiente ideal para repouso.',
      contentMarkdown:
        'Dormir adequadamente restaura o sistema glinfático cerebral e equilibra a produção hormonal...',
      keywords: ['sono', 'insonia', 'dormir', 'acordar cansado', 'descanso', 'pesadelos'],
      url: 'https://dualis.health/artigos/higiene-do-sono',
    },
    {
      id: 'art-somatica-01',
      title: 'Manifestações Psicossomáticas: Quando o Corpo Reage às Emoções',
      category: 'somatica',
      somaticSystem: 'emocional',
      author: 'Dra. Juliana Guimarães',
      authorRole: 'Médica de Família e Comunidade (SBMFC / CRM-SP 171.045)',
      readTimeMinutes: 4,
      summary:
        'Como entender o nó na garganta e a tensão torácica emocional, garantindo sempre a prioridade clínica orgânica.',
      contentMarkdown:
        'O organismo humano opera de forma integrada. Manifestações físicas de estresse demandam sempre avaliação médica prévia...',
      keywords: ['somatico', 'psicossomatico', 'no na garganta', 'tensao corporal', 'aperto no peito'],
      url: 'https://dualis.health/artigos/sintomas-psicossomaticos-e-corpo',
    },
    {
      id: 'art-geral-01',
      title: 'Guia de Auto-Cuidado Preventivo e Bem-Estar Diário',
      category: 'geral',
      somaticSystem: 'geral',
      author: 'Dr. André Cavalcanti',
      authorRole: 'Clínico Geral (SBCM / CRM-SP 134.800)',
      readTimeMinutes: 3,
      summary:
        'Práticas fundamentais de hidratação, sono adequado e monitoramento preventivo de sinais e sintomas.',
      contentMarkdown:
        'Ações preventivas consistentes formam a base para uma saúde integral e sustentável ao longo do tempo...',
      keywords: ['geral', 'autocuidado', 'hidratacao', 'bem-estar', 'prevencao'],
      url: 'https://dualis.health/artigos/autocuidado-preventivo',
    },
  ];

  constructor(
    @Inject(DRIZZLE_DB) private readonly db: NodePgDatabase<typeof schema>,
    private readonly embeddingService: ArticleEmbeddingService,
  ) {}

  async onModuleInit(): Promise<void> {
    try {
      await this.ensureSeedArticles();
    } catch (err) {
      this.logger.warn(`Failed to seed vector articles on startup: ${(err as Error).message}`);
    }
  }

  async ensureSeedArticles(): Promise<void> {
    const existing = await this.db.select({ id: schema.medicalArticles.id }).from(schema.medicalArticles).limit(1);
    if (existing.length > 0) {
      return;
    }

    for (const article of this.seedArticles) {
      const textToEmbed = `${article.title} ${article.category} ${article.keywords.join(' ')} ${article.summary}`;
      const embeddingVector = await this.embeddingService.embed(textToEmbed);

      await this.db
        .insert(schema.medicalArticles)
        .values({
          id: article.id,
          title: article.title,
          category: article.category,
          somaticSystem: article.somaticSystem ?? null,
          author: article.author,
          authorRole: article.authorRole,
          readTimeMinutes: article.readTimeMinutes,
          summary: article.summary,
          contentMarkdown: article.contentMarkdown,
          keywords: article.keywords,
          url: article.url,
          embedding: embeddingVector,
        })
        .onConflictDoNothing();
    }
  }

  async searchArticles(params: {
    queryText?: string;
    category: string;
    vertical: string;
    limit?: number;
  }): Promise<RecommendedArticleDto[]> {
    const limit = params.limit ?? 2;
    const sanitizedNarrative = (params.queryText || '').trim().toLowerCase();
    const cacheKey = `${params.vertical}:${params.category}:${sanitizedNarrative}`;

    if (this.semanticCache.has(cacheKey)) {
      return this.semanticCache.get(cacheKey)!;
    }

    let results: RecommendedArticleDto[] = [];

    if (sanitizedNarrative.length > 0) {
      try {
        const queryVector = await this.embeddingService.embed(sanitizedNarrative);
        const vectorString = `[${queryVector.join(',')}]`;

        const queryResult = await this.db.execute(sql`
          SELECT 
            id, 
            title, 
            category, 
            author, 
            author_role AS "authorRole", 
            read_time_minutes AS "readTimeMinutes", 
            summary, 
            url,
            1 - (embedding <=> ${vectorString}::vector) AS similarity
          FROM medical_articles
          ORDER BY embedding <=> ${vectorString}::vector ASC
          LIMIT ${limit}
        `);

        const rows = (queryResult as any).rows || queryResult;
        if (Array.isArray(rows) && rows.length > 0) {
          const topSimilarity = Number(rows[0].similarity ?? 0);
          if (topSimilarity >= 0.60) {
            results = rows.map((r: any) => ({
              id: r.id,
              title: r.title,
              category: r.category,
              author: r.author,
              authorRole: r.authorRole,
              readTimeMinutes: Number(r.readTimeMinutes),
              summary: r.summary,
              url: r.url,
            }));
          }
        }
      } catch (err) {
        this.logger.warn(`Vector search failed, falling back to category match: ${(err as Error).message}`);
      }
    }

    if (results.length === 0) {
      const categoryRows = await this.db.execute(sql`
        SELECT 
          id, title, category, author, author_role AS "authorRole",
          read_time_minutes AS "readTimeMinutes", summary, url
        FROM medical_articles
        WHERE category = ${params.category}
        LIMIT ${limit}
      `);

      const rows = (categoryRows as any).rows || categoryRows;
      if (Array.isArray(rows) && rows.length > 0) {
        results = rows.map((r: any) => ({
          id: r.id,
          title: r.title,
          category: r.category,
          author: r.author,
          authorRole: r.authorRole,
          readTimeMinutes: Number(r.readTimeMinutes),
          summary: r.summary,
          url: r.url,
        }));
      }
    }

    if (results.length === 0) {
      const matched = this.seedArticles.filter((a) => a.category === params.category);
      if (matched.length > 0) {
        results = matched.slice(0, limit).map((a) => ({
          id: a.id,
          title: a.title,
          category: a.category,
          author: a.author,
          authorRole: a.authorRole,
          readTimeMinutes: a.readTimeMinutes,
          summary: a.summary,
          url: a.url,
        }));
      } else {
        const general = this.seedArticles.find((a) => a.id === 'art-geral-01') || this.seedArticles[0];
        results = [
          {
            id: general.id,
            title: general.title,
            category: general.category,
            author: general.author,
            authorRole: general.authorRole,
            readTimeMinutes: general.readTimeMinutes,
            summary: general.summary,
            url: general.url,
          },
        ];
      }
    }

    this.semanticCache.set(cacheKey, results);
    return results;
  }
}
