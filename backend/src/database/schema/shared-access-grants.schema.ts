import { pgTable, uuid, varchar, text, timestamp, index, pgPolicy, check } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { users } from './users.schema';
import { profiles } from './profiles.schema';

export const ACCESS_LEVELS = ['VIEW_ONLY', 'CO_MANAGE'] as const;
export type AccessLevel = (typeof ACCESS_LEVELS)[number];

export const GRANT_STATUSES = ['PENDING', 'ACCEPTED', 'REVOKED', 'EXPIRED'] as const;
export type GrantStatus = (typeof GRANT_STATUSES)[number];

/**
 * Data categories a grant opens (Phase 11.1, D2). Enforced by RLS through
 * app_can_read_profile_category / app_can_write_profile_category (migration 0028).
 * emotional_journal is always opt-in. Safety events are never shared.
 */
export const SHARE_CATEGORIES = ['habits', 'physical_journal', 'emotional_journal', 'conditions', 'care'] as const;
export type ShareCategory = (typeof SHARE_CATEGORIES)[number];

/** Who the grantee is to the owner (Phase 11.1, gap 7). NULL on legacy grants ("não informado"). */
export const GRANT_RELATIONSHIPS = [
  'spouse_partner',
  'sibling',
  'parent',
  'child',
  'other_family',
  'caregiver',
  'friend',
  'other',
] as const;
export type GrantRelationship = (typeof GRANT_RELATIONSHIPS)[number];

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
    categories: text('categories').array().$type<ShareCategory[]>().default(sql`ARRAY['habits']::text[]`).notNull(),
    relationship: varchar('relationship', { length: 32 }).$type<GrantRelationship>(),
    /** When the owner confirmed sharing a dependent's data; required by RLS for non-primary targets (gap 9). */
    dependentShareConfirmedAt: timestamp('dependent_share_confirmed_at', { withTimezone: true }),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    index('idx_shared_access_grants_granter').on(table.granterUserId),
    index('idx_shared_access_grants_grantee_status').on(table.granteeUserId, table.status),
    index('idx_shared_access_grants_target').on(table.targetProfileId),
    check(
      'shared_access_grants_categories_check',
      sql`${table.categories} <@ ARRAY['habits', 'physical_journal', 'emotional_journal', 'conditions', 'care']::text[]`,
    ),
    check(
      'shared_access_grants_relationship_check',
      sql`${table.relationship} IS NULL OR ${table.relationship} IN ('spouse_partner', 'sibling', 'parent', 'child', 'other_family', 'caregiver', 'friend', 'other')`,
    ),
    pgPolicy('shared_access_grants_participant_select', {
      for: 'select',
      using: sql`granter_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid OR grantee_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid OR invite_code = NULLIF(current_setting('app.accepting_invite_code', true), '')`,
    }),
    pgPolicy('shared_access_grants_granter_insert', {
      for: 'insert',
      withCheck: sql`granter_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid AND app_owns_profile(target_profile_id)
        AND (app_profile_type(target_profile_id) = 'primary' OR dependent_share_confirmed_at IS NOT NULL)`,
    }),
    pgPolicy('shared_access_grants_participant_update', {
      for: 'update',
      using: sql`granter_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid OR grantee_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid OR (status = 'PENDING' AND invite_code = NULLIF(current_setting('app.accepting_invite_code', true), ''))`,
      withCheck: sql`granter_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid OR grantee_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid OR (status = 'EXPIRED' AND grantee_user_id IS NULL AND invite_code = NULLIF(current_setting('app.accepting_invite_code', true), ''))`,
    }),
  ],
);
