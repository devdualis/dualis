import { Inject, Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { sql } from 'drizzle-orm';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { DRIZZLE_DB } from '../../../database/database.service';
import * as schema from '../../../database/schema';
import { ArticleEmbeddingService } from '../../triage/services/article-embedding.service';
import { TriageClassificationResult } from '../dto/classify-symptom.dto';
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
      const existing = await this.db.execute(
        sql`SELECT id FROM symptom_knowledge WHERE input_text = ${seed.inputText} LIMIT 1`,
      );
      const rows = (existing as any).rows || existing;
      if (Array.isArray(rows) && rows.length > 0) {
        continue;
      }

      const embeddingVector = await this.embeddingService.embed(seed.inputText);
      await this.db.insert(schema.symptomKnowledge).values({
        inputText: seed.inputText,
        vertical: seed.vertical,
        systemOrDimension: seed.systemOrDimension,
        urgencyScore: seed.urgencyScore,
        mappedLayTerm: seed.mappedLayTerm,
        clinicalConcept: seed.clinicalConcept,
        isEmergencyCandidate: seed.isEmergencyCandidate,
        confidence: 0.95,
        source: 'dictionary_fallback',
        embedding: embeddingVector,
      });
    }
  }

  async matchSymptom(text: string): Promise<TriageClassificationResult | null> {
    const cleanText = text.trim();
    if (cleanText.length === 0) return null;

    try {
      const queryVector = await this.embeddingService.embed(cleanText);
      const vectorString = `[${queryVector.join(',')}]`;

      const queryResult = await this.db.execute(sql`
        SELECT
          vertical,
          system_or_dimension AS "systemOrDimension",
          urgency_score AS "urgencyScore",
          mapped_lay_term AS "mappedLayTerm",
          clinical_concept AS "clinicalConcept",
          is_emergency_candidate AS "isEmergencyCandidate",
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
        primaryVertical: top.vertical === 'emotional' ? 'emotional' : 'physical',
        systemOrDimension: top.systemOrDimension,
        urgencyScore: Number(top.urgencyScore),
        mappedLayTerm: top.mappedLayTerm,
        clinicalConcept: top.clinicalConcept,
        isEmergencyCandidate: Boolean(top.isEmergencyCandidate),
        confidence: Number(similarity.toFixed(2)),
        source: 'vector_match',
        latencyMs: 0,
      };
    } catch (err) {
      this.logger.warn(`Symptom vector match failed: ${(err as Error).message}`);
      return null;
    }
  }

  async upsertFromClassification(text: string, result: TriageClassificationResult): Promise<void> {
    try {
      const embeddingVector = await this.embeddingService.embed(text.trim());
      await this.db.insert(schema.symptomKnowledge).values({
        inputText: text.trim(),
        vertical: result.primaryVertical,
        systemOrDimension: result.systemOrDimension,
        urgencyScore: result.urgencyScore,
        mappedLayTerm: result.mappedLayTerm,
        clinicalConcept: result.clinicalConcept,
        isEmergencyCandidate: result.isEmergencyCandidate,
        confidence: result.confidence,
        source: 'gemini',
        embedding: embeddingVector,
      });
    } catch (err) {
      this.logger.warn(`Failed to persist learned symptom classification: ${(err as Error).message}`);
    }
  }
}
