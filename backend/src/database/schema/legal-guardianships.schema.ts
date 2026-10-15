import { pgTable, uuid, varchar, text, timestamp, index, unique, pgPolicy } from 'drizzle-orm/pg-core';
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
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    index('idx_legal_guardianships_guardian').on(table.guardianUserId),
    unique('uq_legal_guardianships_guardian_dependent').on(table.guardianUserId, table.dependentProfileId),
    pgPolicy('legal_guardianships_guardian_isolation', {
      for: 'all',
      using: sql`guardian_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid`,
      withCheck: sql`guardian_user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid AND app_owns_profile(dependent_profile_id)`,
    }),
  ],
);
