import { pgTable, uuid, text, integer, timestamp, pgPolicy, index, check } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { users } from './users.schema';
import { profiles } from './profiles.schema';

export const triageEmergencyEvents = pgTable(
  'triage_emergency_events',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }),
    // Subject profile. NULL only for anonymous (unauthenticated) events, where user_id is NULL too.
    profileId: uuid('profile_id').references(() => profiles.id, { onDelete: 'cascade' }),
    triggerCategory: text('trigger_category').notNull(),
    severityLevel: integer('severity_level').notNull(),
    sourceVertical: text('source_vertical').notNull(),
    actionTaken: text('action_taken'),
    reportedAt: timestamp('reported_at', { withTimezone: true }).notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    index('idx_triage_emergency_events_user_id').on(table.userId),
    index('idx_triage_emergency_events_reported_at').on(table.reportedAt),
    check('triage_emergency_events_profile_required', sql`user_id IS NULL OR profile_id IS NOT NULL`),
    index('idx_triage_emergency_events_profile_reported').on(table.profileId, table.reportedAt.desc()),
    pgPolicy('triage_emergency_events_profile_select', {
      for: 'select',
      using: sql`app_can_read_profile(profile_id)`,
    }),
    // Read access is enough: an emergency must never be blocked by a permission level.
    pgPolicy('triage_emergency_events_profile_insert', {
      for: 'insert',
      withCheck: sql`(app_can_read_profile(profile_id) AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid) OR (user_id IS NULL AND profile_id IS NULL)`,
    }),
    pgPolicy('triage_emergency_events_profile_update', {
      for: 'update',
      using: sql`app_can_write_profile(profile_id)`,
      withCheck: sql`app_can_write_profile(profile_id)`,
    }),
    pgPolicy('triage_emergency_events_profile_delete', {
      for: 'delete',
      using: sql`app_can_write_profile(profile_id)`,
    }),
  ],
);

export type TriageEmergencyEvent = typeof triageEmergencyEvents.$inferSelect;
export type NewTriageEmergencyEvent = typeof triageEmergencyEvents.$inferInsert;
