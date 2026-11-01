import { sql } from 'drizzle-orm';
import { boolean, check, date, index, pgPolicy, pgTable, text, timestamp, unique, uuid } from 'drizzle-orm/pg-core';
import { users } from './users.schema';
import { profiles } from './profiles.schema';

export const dailyHabits = pgTable('daily_habits', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'set null' }),
  profileId: uuid('profile_id').notNull().references(() => profiles.id, { onDelete: 'cascade' }),
  day: date('day').notNull(),
  sleepQuality: text('sleep_quality'),
  sleepHours: text('sleep_hours'),
  moved: boolean('moved'),
  movementMinutes: text('movement_minutes'),
  period: boolean('period'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  unique('daily_habits_profile_day_unique').on(table.profileId, table.day),
  index('idx_daily_habits_profile_day').on(table.profileId, table.day.desc()),
  check('daily_habits_sleep_quality_check', sql`${table.sleepQuality} IN ('bem', 'regular', 'mal')`),
  check('daily_habits_sleep_hours_check', sql`${table.sleepHours} IN ('menos_5', '5_6', '7_8', '9_mais')`),
  check('daily_habits_movement_minutes_check', sql`${table.movementMinutes} IN ('ate_15', '15_30', '30_60', 'mais_60')`),
  check('daily_habits_movement_check', sql`${table.movementMinutes} IS NULL OR ${table.moved} IS TRUE`),
  pgPolicy('daily_habits_profile_select', { for: 'select', using: sql`app_can_read_profile(profile_id)` }),
  pgPolicy('daily_habits_profile_insert', {
    for: 'insert',
    withCheck: sql`app_can_write_profile(profile_id) AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid`,
  }),
  pgPolicy('daily_habits_profile_update', {
    for: 'update', using: sql`app_can_write_profile(profile_id)`, withCheck: sql`app_can_write_profile(profile_id)`,
  }),
  pgPolicy('daily_habits_profile_delete', { for: 'delete', using: sql`app_can_write_profile(profile_id)` }),
]);
