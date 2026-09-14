import { pgTable, uuid, varchar, timestamp, pgPolicy } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { users } from './users.schema';

export const userDisclaimerConsents = pgTable(
  'user_disclaimer_consents',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    disclaimerVersion: varchar('disclaimer_version', { length: 20 }).notNull(),
    acceptedAt: timestamp('accepted_at', { withTimezone: true }).defaultNow().notNull(),
    ipAddressHash: varchar('ip_address_hash', { length: 64 }).notNull(), // SHA-256 hashed IP
    userAgent: varchar('user_agent', { length: 255 }),
  },
  (table) => [
    pgPolicy('user_disclaimer_consents_patient_isolation', {
      for: 'all',
      using: sql`user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid`,
      withCheck: sql`user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid`,
    }),
  ],
);
