import { pgTable, uuid, text, integer, timestamp, pgPolicy, index } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { users } from './users.schema';

export const waterIntakeLogs = pgTable(
  'water_intake_logs',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    amountMl: integer('amount_ml').notNull(),
    source: text('source').default('manual').notNull(),
    recordedAt: timestamp('recorded_at', { withTimezone: true }).defaultNow().notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    index('idx_water_intake_logs_user_recorded').on(table.userId, table.recordedAt.desc()),
    pgPolicy('water_intake_logs_patient_isolation', {
      for: 'all',
      using: sql`user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid`,
      withCheck: sql`user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid`,
    }),
  ],
);
