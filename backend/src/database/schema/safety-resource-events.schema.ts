import { pgTable, uuid, text, timestamp, pgPolicy, index, check } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { users } from './users.schema';
import { profiles } from './profiles.schema';

export const SAFETY_RESOURCE_ACTIONS = ['opened_resources', 'call_started'] as const;
export type SafetyResourceAction = (typeof SAFETY_RESOURCE_ACTIONS)[number];

/**
 * Minimal audit of the static help resources: someone opened them or started a call.
 * Holds no symptom, severity or category data (LGPD Art. 6 III).
 */
export const safetyResourceEvents = pgTable(
  'safety_resource_events',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }),
    // Subject profile. NULL only for anonymous (unauthenticated) events, where user_id is NULL too.
    profileId: uuid('profile_id').references(() => profiles.id, { onDelete: 'cascade' }),
    action: text('action').$type<SafetyResourceAction>().notNull(),
    channel: text('channel'),
    clientTimestamp: timestamp('client_timestamp', { withTimezone: true }).notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    index('idx_safety_resource_events_user_id').on(table.userId),
    index('idx_safety_resource_events_profile_created').on(table.profileId, table.createdAt.desc()),
    check('safety_resource_events_action_check', sql`action IN ('opened_resources', 'call_started')`),
    check('safety_resource_events_profile_required', sql`user_id IS NULL OR profile_id IS NOT NULL`),
    pgPolicy('safety_resource_events_profile_select', {
      for: 'select',
      using: sql`app_can_read_profile(profile_id)`,
    }),
    // Read access is enough: reaching the help resources must never be blocked by a permission level.
    pgPolicy('safety_resource_events_profile_insert', {
      for: 'insert',
      withCheck: sql`(app_can_read_profile(profile_id) AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid) OR (user_id IS NULL AND profile_id IS NULL)`,
    }),
    pgPolicy('safety_resource_events_profile_update', {
      for: 'update',
      using: sql`app_can_write_profile(profile_id)`,
      withCheck: sql`app_can_write_profile(profile_id)`,
    }),
    pgPolicy('safety_resource_events_profile_delete', {
      for: 'delete',
      using: sql`app_can_write_profile(profile_id)`,
    }),
  ],
);

export type SafetyResourceEvent = typeof safetyResourceEvents.$inferSelect;
export type NewSafetyResourceEvent = typeof safetyResourceEvents.$inferInsert;
