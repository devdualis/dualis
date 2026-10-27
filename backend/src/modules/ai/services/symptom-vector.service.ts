import { Inject, Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { sql } from 'drizzle-orm';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { DRIZZLE_DB } from '../../../database/database.service';
import * as schema from '../../../database/schema';
import { ArticleEmbeddingService } from '../../triage/services/article-embedding.service';
import { EntryTagResult } from '../dto/classify-symptom.dto';
import { SYMPTOM_KNOWLEDGE_SEED } from '../data/symptom-knowledge.seed';

const MATCH_SIMILARITY_THRESHOLD = 0.75;

@Injectable()
export class SymptomVectorService implements OnModuleInit {
  private readonly logger = new Logger(SymptomVectorService.name);

  constructor(
    @Inject(DRIZZLE_DB) private readonly db: NodePgDatabase<typeof schema>,
    private readonly embeddingService: ArticleEmbeddingService,
  ) {}

  async onModuleInit(): Promise<void> {
    try {
      await this.ensureSeedSymptoms();
    } catch (err) {
      this.logger.warn(`Failed to seed symptom knowledge on startup: ${(err as Error).message}`);
    }
  }

  async ensureSeedSymptoms(): Promise<void> {
    for (const seed of SYMPTOM_KNOWLEDGE_SEED) {
      if (await this.hasEntry(seed.inputText, seed.systemOrDimension)) {
        continue;
      }
      const embeddingVector = await this.embeddingService.embed(seed.inputText);
      await this.insertEntry({
        inputText: seed.inputText,
        vertical: seed.vertical,
        systemOrDimension: seed.systemOrDimension,
        mappedLayTerm: seed.mappedLayTerm,
        confidence: 0.95,
        source: 'dictionary_fallback',
        embedding: embeddingVector,
      });
    }
  }

  async matchSymptom(text: string): Promise<EntryTagResult | null> {
    const cleanText = text.trim();
    if (cleanText.length === 0) return null;

    try {
      const queryVector = await this.embeddingService.embed(cleanText);
      const vectorString = `[${queryVector.join(',')}]`;

      const queryResult = await this.db.execute(sql`
        SELECT
          vertical,
          system_or_dimension AS "systemOrDimension",
          mapped_lay_term AS "mappedLayTerm",
          1 - (embedding <=> ${vectorString}::vector) AS similarity
        FROM symptom_knowledge
        ORDER BY embedding <=> ${vectorString}::vector ASC
        LIMIT 1
      `);

      const rows = (queryResult as any).rows || queryResult;
      if (!Array.isArray(rows) || rows.length === 0) {
        return null;
      }

      const top = rows[0];
      const similarity = Number(top.similarity ?? 0);
      if (similarity < MATCH_SIMILARITY_THRESHOLD) {
        return null;
      }

      return {
        isOffTopic: false,
        vertical: top.vertical === 'emotional' ? 'emotional' : 'physical',
        bodyAreaOrMood: top.systemOrDimension,
        layTerm: top.mappedLayTerm,
        confidence: Number(similarity.toFixed(2)),
        source: 'vector_match',
        latencyMs: 0,
      };
    } catch (err) {
      this.logger.warn(`Symptom vector match failed: ${(err as Error).message}`);
      return null;
    }
  }

  /**
   * Learns a tag produced by Gemini. symptom_knowledge is shared by every user, so the
   * raw entry text is never stored: only the normalised lay term (input_text = layTerm)
   * and its area/mood key (LGPD Art. 6 III, data minimisation).
   */
  async upsertFromTag(tag: EntryTagResult): Promise<void> {
    const layTerm = tag.layTerm?.trim();
    if (!layTerm || !tag.vertical || !tag.bodyAreaOrMood || tag.isOffTopic) {
      return;
    }
    try {
      if (await this.hasEntry(layTerm, tag.bodyAreaOrMood)) {
        return;
      }
      const embeddingVector = await this.embeddingService.embed(layTerm);
      await this.insertEntry({
        inputText: layTerm,
        vertical: tag.vertical,
        systemOrDimension: tag.bodyAreaOrMood,
        mappedLayTerm: layTerm,
        confidence: tag.confidence,
        source: 'gemini',
        embedding: embeddingVector,
      });
    } catch (err) {
      this.logger.warn(`Failed to persist learned entry tag: ${(err as Error).message}`);
    }
  }

  private async hasEntry(inputText: string, systemOrDimension: string): Promise<boolean> {
    const existing = await this.db.execute(
      sql`SELECT id FROM symptom_knowledge WHERE input_text = ${inputText} AND system_or_dimension = ${systemOrDimension} LIMIT 1`,
    );
    const rows = (existing as any).rows || existing;
    return Array.isArray(rows) && rows.length > 0;
  }

  // Explicit column list: only the tagging columns exist after migration 0015.
  private async insertEntry(entry: {
    inputText: string;
    vertical: string;
    systemOrDimension: string;
    mappedLayTerm: string;
    confidence: number;
    source: string;
    embedding: number[];
  }): Promise<void> {
    const vectorString = `[${entry.embedding.join(',')}]`;
    await this.db.execute(sql`
      INSERT INTO symptom_knowledge
        (input_text, vertical, system_or_dimension, mapped_lay_term, confidence, source, embedding)
      VALUES
        (${entry.inputText}, ${entry.vertical}, ${entry.systemOrDimension}, ${entry.mappedLayTerm},
         ${entry.confidence}, ${entry.source}, ${vectorString}::vector)
    `);
  }
}
