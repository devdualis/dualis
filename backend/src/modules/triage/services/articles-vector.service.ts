import { Inject, Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { sql } from 'drizzle-orm';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { DRIZZLE_DB } from '../../../database/database.service';
import * as schema from '../../../database/schema';
import { RecommendedArticleDto } from '../dto/triage-outcome.dto';
import { ArticleEmbeddingService } from './article-embedding.service';

import { SeedArticleDefinition, MEDICAL_ARTICLES_SEED } from '../data/medical-articles.seed';
export { SeedArticleDefinition };

@Injectable()
export class ArticlesVectorService implements OnModuleInit {
  private readonly logger = new Logger(ArticlesVectorService.name);
  private readonly semanticCache = new Map<string, RecommendedArticleDto[]>();

  public readonly seedArticles: SeedArticleDefinition[] = MEDICAL_ARTICLES_SEED;

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
    const existing = await this.db.select({ id: schema.medicalArticles.id }).from(schema.medicalArticles);
    const existingIds = new Set(existing.map((e) => e.id));

    for (const article of this.seedArticles) {
      if (existingIds.has(article.id)) {
        continue;
      }

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
          WHERE category = ${params.category}
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
