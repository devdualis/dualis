import { pgTable, uuid, varchar, date, text, timestamp, index, pgPolicy } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { users } from './users.schema';

export const PROFILE_TYPES = ['primary', 'dependent_minor', 'dependent_adult'] as const;
export type ProfileType = (typeof PROFILE_TYPES)[number];

export const profiles = pgTable(
  'profiles',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    accountOwnerId: uuid('account_owner_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    profileType: varchar('profile_type', { length: 32 }).$type<ProfileType>().notNull(),
    name: varchar('name', { length: 255 }).notNull(),
    dateOfBirth: date('date_of_birth'),
    gender: varchar('gender', { length: 50 }),
    avatarUrl: text('avatar_url'),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    index('idx_profiles_account_owner').on(table.accountOwnerId),
    pgPolicy('profiles_owner_all', {
      for: 'all',
      using: sql`account_owner_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid`,
      withCheck: sql`account_owner_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid`,
    }),
    pgPolicy('profiles_grantee_select', {
      for: 'select',
      using: sql`app_has_profile_grant(id, false)`,
    }),
    pgPolicy('profiles_grantee_update', {
      for: 'update',
      using: sql`app_has_profile_grant(id, true)`,
      withCheck: sql`app_has_profile_grant(id, true)`,
    }),
    pgPolicy('profiles_owner_immutable', {
      as: 'restrictive',
      for: 'update',
      using: sql`true`,
      withCheck: sql`account_owner_id = app_profile_owner_id(id)`,
    }),
  ],
);
