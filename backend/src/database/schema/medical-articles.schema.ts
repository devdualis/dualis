import { pgTable, varchar, text, integer, timestamp, vector, index } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';

export const medicalArticles = pgTable(
  'medical_articles',
  {
    id: varchar('id', { length: 64 }).primaryKey(),
    language: varchar('language', { length: 10 }).default('pt').notNull(),
    title: text('title').notNull(),
    category: varchar('category', { length: 64 }).notNull(),
    somaticSystem: varchar('somatic_system', { length: 64 }),
    author: text('author').notNull(),
    authorRole: text('author_role').notNull(),
    readTimeMinutes: integer('read_time_minutes').default(4).notNull(),
    summary: text('summary').notNull(),
    contentMarkdown: text('content_markdown').notNull(),
    keywords: text('keywords').array().notNull(),
    url: text('url').notNull(),
    embedding: vector('embedding', { dimensions: 768 }),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    index('idx_medical_articles_category').on(table.category),
    index('idx_medical_articles_language').on(table.language),
    index('idx_medical_articles_category_lang').on(table.category, table.language),
    index('idx_medical_articles_embedding').using('hnsw', table.embedding.op('vector_cosine_ops')),
  ],
);

export type MedicalArticle = typeof medicalArticles.$inferSelect;
export type NewMedicalArticle = typeof medicalArticles.$inferInsert;
