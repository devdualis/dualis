import { pgTable, uuid, text, integer, timestamp, pgPolicy, boolean, index, uniqueIndex } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { users } from './users.schema';
import { profiles } from './profiles.schema';

export const symptomLogs = pgTable(
  'symptom_logs',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }), // author (always the caller)
    profileId: uuid('profile_id')
      .notNull()
      .references(() => profiles.id, { onDelete: 'cascade' }), // subject (whose health data)
    encryptedNarrative: text('encrypted_narrative'), // AES-256-GCM ciphertext
    intensity: integer('intensity').notNull(),
    anatomicalSystem: text('anatomical_system'),
    emotionalDimension: text('emotional_dimension'),
    disposition: text('disposition'),
    organicPrimacyApplied: boolean('organic_primacy_applied').default(false).notNull(),
    stepAnswers: text('step_answers'),
    clientSessionId: text('client_session_id'),
    recordedAt: timestamp('recorded_at', { withTimezone: true }).defaultNow().notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    index('idx_symptom_logs_user_recorded').on(table.userId, table.recordedAt.desc()),
    uniqueIndex('idx_symptom_logs_user_client_session').on(table.userId, table.clientSessionId),
    index('idx_symptom_logs_profile_recorded').on(table.profileId, table.recordedAt.desc()),
    // Per-row category (Phase 11.1, A1): emotional_dimension needs emotional_journal;
    // anatomical_system, or neither column, needs physical_journal.
    pgPolicy('symptom_logs_profile_select', {
      for: 'select',
      using: sql`(emotional_dimension IS NULL OR app_can_read_profile_category(profile_id, 'emotional_journal'))
        AND ((anatomical_system IS NULL AND emotional_dimension IS NOT NULL) OR app_can_read_profile_category(profile_id, 'physical_journal'))`,
    }),
    pgPolicy('symptom_logs_profile_insert', {
      for: 'insert',
      withCheck: sql`(emotional_dimension IS NULL OR app_can_write_profile_category(profile_id, 'emotional_journal'))
        AND ((anatomical_system IS NULL AND emotional_dimension IS NOT NULL) OR app_can_write_profile_category(profile_id, 'physical_journal'))
        AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid`,
    }),
    pgPolicy('symptom_logs_profile_update', {
      for: 'update',
      using: sql`(emotional_dimension IS NULL OR app_can_write_profile_category(profile_id, 'emotional_journal'))
        AND ((anatomical_system IS NULL AND emotional_dimension IS NOT NULL) OR app_can_write_profile_category(profile_id, 'physical_journal'))`,
      withCheck: sql`(emotional_dimension IS NULL OR app_can_write_profile_category(profile_id, 'emotional_journal'))
        AND ((anatomical_system IS NULL AND emotional_dimension IS NOT NULL) OR app_can_write_profile_category(profile_id, 'physical_journal'))`,
    }),
    pgPolicy('symptom_logs_profile_delete', {
      for: 'delete',
      using: sql`(emotional_dimension IS NULL OR app_can_write_profile_category(profile_id, 'emotional_journal'))
        AND ((anatomical_system IS NULL AND emotional_dimension IS NOT NULL) OR app_can_write_profile_category(profile_id, 'physical_journal'))`,
    }),
  ],
);
