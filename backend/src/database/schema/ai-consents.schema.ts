import { index, pgPolicy, pgTable, timestamp, uniqueIndex, uuid, varchar } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { users } from './users.schema';

/**
 * LGPD Art. 11, I consent for sending de-identified journal text to the AI provider.
 * Grants are append-only; revoking sets revoked_at and keeps the row as history.
 * Hand-written migration: 0030_ai_processing_consents.sql.
 */
export const userAiConsents = pgTable(
  'user_ai_consents',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    purpose: varchar('purpose', { length: 40 }).notNull(),
    consentVersion: varchar('consent_version', { length: 20 }).notNull(),
    grantedAt: timestamp('granted_at', { withTimezone: true }).defaultNow().notNull(),
    revokedAt: timestamp('revoked_at', { withTimezone: true }),
    ipAddressHash: varchar('ip_address_hash', { length: 64 }).notNull(), // HMAC-SHA256 of the IP (EncryptionService.hashIp)
    userAgent: varchar('user_agent', { length: 255 }),
  },
  (table) => [
    uniqueIndex('user_ai_consents_one_active')
      .on(table.userId, table.purpose)
      .where(sql`revoked_at IS NULL`),
    index('user_ai_consents_user_idx').on(table.userId),
    pgPolicy('user_ai_consents_owner_isolation', {
      for: 'all',
      using: sql`user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid`,
      withCheck: sql`user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid`,
    }),
  ],
);
