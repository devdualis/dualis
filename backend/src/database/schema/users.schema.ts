import { pgTable, uuid, varchar, timestamp, pgPolicy } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';

export const users = pgTable(
  'users',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    email: varchar('email', { length: 255 }).notNull().unique(),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    pgPolicy('users_patient_isolation', {
      for: 'all',
      using: sql`id = NULLIF(current_setting('app.current_user_id', true), '')::uuid`,
      withCheck: sql`id = NULLIF(current_setting('app.current_user_id', true), '')::uuid`,
    }),
  ],
);
