import { pgTable, uuid, text, integer, timestamp, pgPolicy } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { users } from './users.schema';

export const triageEmergencyEvents = pgTable(
  'triage_emergency_events',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }),
    triggerCategory: text('trigger_category').notNull(),
    severityLevel: integer('severity_level').notNull(),
    sourceVertical: text('source_vertical').notNull(),
    actionTaken: text('action_taken'),
    reportedAt: timestamp('reported_at', { withTimezone: true }).notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    pgPolicy('triage_emergency_events_isolation', {
      for: 'all',
      using: sql`user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid`,
      withCheck: sql`user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid OR user_id IS NULL`,
    }),
  ],
);

export type TriageEmergencyEvent = typeof triageEmergencyEvents.$inferSelect;
export type NewTriageEmergencyEvent = typeof triageEmergencyEvents.$inferInsert;
