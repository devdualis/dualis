import { pgTable, uuid, varchar, text, timestamp, index, unique, uniqueIndex, pgPolicy } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { users } from './users.schema';
import { profiles } from './profiles.schema';

export const RELATIONSHIP_TYPES = ['parent', 'legal_guardian', 'curator'] as const;
export type RelationshipType = (typeof RELATIONSHIP_TYPES)[number];

export const legalGuardianships = pgTable(
  'legal_guardianships',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    guardianUserId: uuid('guardian_user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    dependentProfileId: uuid('dependent_profile_id')
      .notNull()
      .references(() => profiles.id, { onDelete: 'cascade' }),
    relationshipType: varchar('relationship_type', { length: 32 }).$type<RelationshipType>().notNull(),
    lgpdConsentRecordedAt: timestamp('lgpd_consent_recorded_at', { withTimezone: true }).notNull(),
    lgpdLegalBasisNotes: text('lgpd_legal_basis_notes'),
    // Hand-over at 18 (0028, D3): claim code opened by the guardian, then the closed row
    // is kept for audit.
    handoverCode: varchar('handover_code', { length: 12 }),
    handoverCodeExpiresAt: timestamp('handover_code_expires_at', { withTimezone: true }),
    handoverNotifiedAt: timestamp('handover_notified_at', { withTimezone: true }),
    closedAt: timestamp('closed_at', { withTimezone: true }),
    closedReason: varchar('closed_reason', { length: 32 }),
    handedOverToUserId: uuid('handed_over_to_user_id').references(() => users.id, { onDelete: 'set null' }),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    index('idx_legal_guardianships_guardian').on(table.guardianUserId),
    unique('uq_legal_guardianships_guardian_dependent').on(table.guardianUserId, table.dependentProfileId),
    uniqueIndex('uq_legal_guardianships_handover_code')
      .on(table.handoverCode)
      .where(sql`${table.handoverCode} IS NOT NULL`),
    pgPolicy('legal_guardianships_guardian_isolation', {
      for: 'all',
      using: sql`guardian_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid`,
      withCheck: sql`guardian_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid AND app_owns_profile(dependent_profile_id)`,
    }),
    pgPolicy('legal_guardianships_claim_select', {
      for: 'select',
      using: sql`handover_code = NULLIF(current_setting('app.claiming_code', true), '') AND app_in_claim_function()`,
    }),
    pgPolicy('legal_guardianships_claim_update', {
      for: 'update',
      using: sql`handover_code = NULLIF(current_setting('app.claiming_code', true), '') AND app_in_claim_function()`,
      withCheck: sql`closed_at IS NOT NULL AND handed_over_to_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid AND handover_code = NULLIF(current_setting('app.claiming_code', true), '')`,
    }),
    pgPolicy('legal_guardianships_closed_keep', {
      as: 'restrictive',
      for: 'delete',
      using: sql`closed_at IS NULL`,
    }),
  ],
);
