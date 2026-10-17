import { pgTable, uuid, text, integer, timestamp, pgPolicy, index } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { users } from './users.schema';
import { profiles } from './profiles.schema';

export const waterIntakeLogs = pgTable(
  'water_intake_logs',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }), // author (always the caller)
    profileId: uuid('profile_id')
      .notNull()
      .references(() => profiles.id, { onDelete: 'cascade' }), // subject (whose health data)
    amountMl: integer('amount_ml').notNull(),
    source: text('source').default('manual').notNull(),
    recordedAt: timestamp('recorded_at', { withTimezone: true }).defaultNow().notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    index('idx_water_intake_logs_user_recorded').on(table.userId, table.recordedAt.desc()),
    index('idx_water_intake_logs_profile_recorded').on(table.profileId, table.recordedAt.desc()),
    pgPolicy('water_intake_logs_profile_select', {
      for: 'select',
      using: sql`app_can_read_profile(profile_id)`,
    }),
    pgPolicy('water_intake_logs_profile_insert', {
      for: 'insert',
      withCheck: sql`app_can_write_profile(profile_id) AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid`,
    }),
    pgPolicy('water_intake_logs_profile_update', {
      for: 'update',
      using: sql`app_can_write_profile(profile_id)`,
      withCheck: sql`app_can_write_profile(profile_id)`,
    }),
    pgPolicy('water_intake_logs_profile_delete', {
      for: 'delete',
      using: sql`app_can_write_profile(profile_id)`,
    }),
  ],
);
