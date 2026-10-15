import { pgTable, uuid, varchar, timestamp, index, pgPolicy } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { users } from './users.schema';
import { profiles } from './profiles.schema';

export const ACCESS_LEVELS = ['VIEW_ONLY', 'CO_MANAGE'] as const;
export type AccessLevel = (typeof ACCESS_LEVELS)[number];

export const GRANT_STATUSES = ['PENDING', 'ACCEPTED', 'REVOKED', 'EXPIRED'] as const;
export type GrantStatus = (typeof GRANT_STATUSES)[number];

export const sharedAccessGrants = pgTable(
  'shared_access_grants',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    granterUserId: uuid('granter_user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    targetProfileId: uuid('target_profile_id')
      .notNull()
      .references(() => profiles.id, { onDelete: 'cascade' }),
    granteeUserId: uuid('grantee_user_id').references(() => users.id, { onDelete: 'cascade' }),
    accessLevel: varchar('access_level', { length: 16 }).$type<AccessLevel>().notNull(),
    inviteCode: varchar('invite_code', { length: 12 }).notNull().unique(),
    status: varchar('status', { length: 16 }).$type<GrantStatus>().default('PENDING').notNull(),
    expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
    acceptedAt: timestamp('accepted_at', { withTimezone: true }),
    revokedAt: timestamp('revoked_at', { withTimezone: true }),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    index('idx_shared_access_grants_granter').on(table.granterUserId),
    index('idx_shared_access_grants_grantee_status').on(table.granteeUserId, table.status),
    index('idx_shared_access_grants_target').on(table.targetProfileId),
    pgPolicy('shared_access_grants_participant_select', {
      for: 'select',
      using: sql`granter_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid OR grantee_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid OR invite_code = NULLIF(current_setting('app.accepting_invite_code', true), '')`,
    }),
    pgPolicy('shared_access_grants_granter_insert', {
      for: 'insert',
      withCheck: sql`granter_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid AND app_owns_profile(target_profile_id)`,
    }),
    pgPolicy('shared_access_grants_participant_update', {
      for: 'update',
      using: sql`granter_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid OR grantee_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid OR (status = 'PENDING' AND invite_code = NULLIF(current_setting('app.accepting_invite_code', true), ''))`,
      withCheck: sql`granter_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid OR grantee_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid OR (status = 'EXPIRED' AND grantee_user_id IS NULL AND invite_code = NULLIF(current_setting('app.accepting_invite_code', true), ''))`,
    }),
  ],
);
