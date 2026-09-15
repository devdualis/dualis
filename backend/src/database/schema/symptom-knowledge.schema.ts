import { pgTable, uuid, varchar, text, integer, real, boolean, timestamp, vector, index } from 'drizzle-orm/pg-core';

export const symptomKnowledge = pgTable(
  'symptom_knowledge',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    inputText: text('input_text').notNull(),
    vertical: varchar('vertical', { length: 16 }).notNull(),
    systemOrDimension: varchar('system_or_dimension', { length: 64 }).notNull(),
    urgencyScore: integer('urgency_score').notNull(),
    mappedLayTerm: text('mapped_lay_term').notNull(),
    clinicalConcept: text('clinical_concept').notNull(),
    isEmergencyCandidate: boolean('is_emergency_candidate').notNull().default(false),
    confidence: real('confidence').notNull(),
    source: varchar('source', { length: 32 }).notNull(),
    embedding: vector('embedding', { dimensions: 768 }),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    index('idx_symptom_knowledge_system').on(table.systemOrDimension),
    index('idx_symptom_knowledge_embedding').using('hnsw', table.embedding.op('vector_cosine_ops')),
  ],
);

export type SymptomKnowledge = typeof symptomKnowledge.$inferSelect;
export type NewSymptomKnowledge = typeof symptomKnowledge.$inferInsert;
