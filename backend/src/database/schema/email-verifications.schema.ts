import { pgTable, uuid, varchar, timestamp, integer, pgPolicy } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { users } from './users.schema';

export const emailVerifications = pgTable(
  'email_verifications',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    email: varchar('email', { length: 255 }).notNull(),
    codeHash: varchar('code_hash', { length: 255 }).notNull(),
    attempts: integer('attempts').default(0).notNull(),
    expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    pgPolicy('email_verifications_isolation', {
      for: 'all',
      using: sql`user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid OR current_setting('app.is_auth_service', true) = 'true'`,
      withCheck: sql`user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid OR current_setting('app.is_auth_service', true) = 'true'`,
    }),
  ],
);
