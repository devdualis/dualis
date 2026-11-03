import { pgTable, uuid, text, smallint, timestamp, pgPolicy, index, check, unique } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { users } from './users.schema';
import { profiles } from './profiles.schema';

/**
 * Journal v2 (docs/bienestar/CONTRATO-JOURNAL-V2.md). Stores what the person chose
 * (option keys) or wrote (custom labels), never a translation of it.
 * Free text (note, trigger_note, custom_label, label) is AES-256-GCM ciphertext.
 */

export const userConditions = pgTable(
  'user_conditions',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id').references(() => users.id, { onDelete: 'set null' }), // author (the caller); NULL once they delete their account
    profileId: uuid('profile_id')
      .notNull()
      .references(() => profiles.id, { onDelete: 'cascade' }), // subject
    label: text('label').notNull(), // encrypted, the person's own words (max 40 chars)
    // Readings the person chose to note for this condition (v2.4): blood_pressure, glucose, weight.
    // Set only by the person, never derived from the label.
    tracking: text('tracking').array().default(sql`'{}'::text[]`).notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
    archivedAt: timestamp('archived_at', { withTimezone: true }),
  },
  (table) => [
    index('idx_user_conditions_profile_created').on(table.profileId, table.createdAt),
    check('user_conditions_tracking_check', sql`${table.tracking} <@ ARRAY['blood_pressure', 'glucose', 'weight']::text[]`),
    pgPolicy('user_conditions_profile_select', {
      for: 'select',
      using: sql`app_can_read_profile_category(profile_id, 'conditions')`,
    }),
    pgPolicy('user_conditions_profile_insert', {
      for: 'insert',
      withCheck: sql`app_can_write_profile_category(profile_id, 'conditions') AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid`,
    }),
    pgPolicy('user_conditions_profile_update', {
      for: 'update',
      using: sql`app_can_write_profile_category(profile_id, 'conditions')`,
      withCheck: sql`app_can_write_profile_category(profile_id, 'conditions')`,
    }),
    pgPolicy('user_conditions_profile_delete', {
      for: 'delete',
      using: sql`app_can_write_profile_category(profile_id, 'conditions')`,
    }),
  ],
);

export const journalEntries = pgTable(
  'journal_entries',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id').references(() => users.id, { onDelete: 'set null' }), // author (the caller); NULL once they delete their account
    profileId: uuid('profile_id')
      .notNull()
      .references(() => profiles.id, { onDelete: 'cascade' }), // subject
    recordedAt: timestamp('recorded_at', { withTimezone: true }).notNull(),
    mood: text('mood').notNull(),
    area: text('area'), // 'emotional' | 'physical'; null on entries saved before v2.1
    coping: text('coping'),
    helpers: text('helpers').array().default(sql`'{}'::text[]`).notNull(),
    triggers: text('triggers').array().default(sql`'{}'::text[]`).notNull(),
    triggerNote: text('trigger_note'), // encrypted
    note: text('note'), // encrypted
    transitionVariantIds: text('transition_variant_ids').array().default(sql`'{}'::text[]`).notNull(), // UX analytics only
    clientId: text('client_id').notNull(), // outbox idempotency, unique per profile
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    index('idx_journal_entries_profile_recorded').on(table.profileId, table.recordedAt.desc()),
    unique('journal_entries_profile_client_id_unique').on(table.profileId, table.clientId),
    check('journal_entries_coping_check', sql`${table.coping} IS NULL OR ${table.coping} IN ('consegui', 'esperei', 'dificil')`),
    check('journal_entries_mood_check', sql`${table.mood} IN ('bem', 'normal', 'nao_tao_bem')`),
    check('journal_entries_area_check', sql`${table.area} IS NULL OR ${table.area} IN ('emotional', 'physical')`),
    pgPolicy('journal_entries_profile_select', {
      for: 'select',
      using: sql`app_can_read_profile_category(profile_id, app_journal_area_category(area))`,
    }),
    pgPolicy('journal_entries_profile_insert', {
      for: 'insert',
      withCheck: sql`app_can_write_profile_category(profile_id, app_journal_area_category(area)) AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid`,
    }),
    pgPolicy('journal_entries_profile_update', {
      for: 'update',
      using: sql`app_can_write_profile_category(profile_id, app_journal_area_category(area))`,
      withCheck: sql`app_can_write_profile_category(profile_id, app_journal_area_category(area))`,
    }),
    pgPolicy('journal_entries_profile_delete', {
      for: 'delete',
      using: sql`app_can_write_profile_category(profile_id, app_journal_area_category(area))`,
    }),
  ],
);

export const journalItems = pgTable(
  'journal_items',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    entryId: uuid('entry_id')
      .notNull()
      .references(() => journalEntries.id, { onDelete: 'cascade' }),
    kind: text('kind').notNull(),
    optionKey: text('option_key'),
    customLabel: text('custom_label'), // encrypted (max 80 chars before encryption)
    conditionId: uuid('condition_id').references(() => userConditions.id, { onDelete: 'cascade' }),
    bodySide: text('body_side'),
    sensation: text('sensation'), // 'dor' | 'incomodo', physical items only
    persistence: text('persistence'),
    intensity: smallint('intensity'),
  },
  (table) => [
    index('idx_journal_items_entry').on(table.entryId),
    index('idx_journal_items_condition').on(table.conditionId),
    check('journal_items_kind_check', sql`${table.kind} IN ('emotional', 'physical', 'condition', 'positive')`),
    check(
      'journal_items_shape_check',
      sql`(${table.kind} = 'condition' AND ${table.conditionId} IS NOT NULL AND ${table.optionKey} IS NULL AND ${table.customLabel} IS NULL)
        OR (${table.kind} IN ('emotional', 'physical', 'positive') AND ${table.optionKey} IS NOT NULL AND ${table.conditionId} IS NULL)`,
    ),
    check('journal_items_positive_check', sql`${table.kind} <> 'positive' OR (${table.intensity} IS NULL AND ${table.persistence} IS NULL AND ${table.bodySide} IS NULL AND ${table.sensation} IS NULL)`),
    check('journal_items_body_side_check', sql`${table.bodySide} IS NULL OR ${table.bodySide} IN ('front', 'back')`),
    check(
      'journal_items_sensation_check',
      sql`${table.sensation} IS NULL OR (${table.sensation} IN ('dor', 'incomodo') AND ${table.kind} = 'physical')`,
    ),
    check(
      'journal_items_persistence_check',
      sql`${table.persistence} IS NULL OR ${table.persistence} IN ('hoje', 'dias_semanas', 'meses_anos')`,
    ),
    check('journal_items_intensity_check', sql`${table.intensity} IS NULL OR ${table.intensity} BETWEEN 1 AND 5`),
    pgPolicy('journal_items_profile_select', {
      for: 'select',
      using: sql`EXISTS (SELECT 1 FROM journal_entries e WHERE e.id = entry_id AND app_can_read_profile_category(e.profile_id, app_journal_area_category(e.area)))`,
    }),
    pgPolicy('journal_items_profile_insert', {
      for: 'insert',
      withCheck: sql`EXISTS (SELECT 1 FROM journal_entries e WHERE e.id = entry_id AND app_can_write_profile_category(e.profile_id, app_journal_area_category(e.area)))
        AND (condition_id IS NULL OR EXISTS (
          SELECT 1 FROM user_conditions c JOIN journal_entries e ON e.id = entry_id
          WHERE c.id = condition_id AND c.profile_id = e.profile_id))`,
    }),
    pgPolicy('journal_items_profile_update', {
      for: 'update',
      using: sql`EXISTS (SELECT 1 FROM journal_entries e WHERE e.id = entry_id AND app_can_write_profile_category(e.profile_id, app_journal_area_category(e.area)))`,
      withCheck: sql`EXISTS (SELECT 1 FROM journal_entries e WHERE e.id = entry_id AND app_can_write_profile_category(e.profile_id, app_journal_area_category(e.area)))
        AND (condition_id IS NULL OR EXISTS (
          SELECT 1 FROM user_conditions c JOIN journal_entries e ON e.id = entry_id
          WHERE c.id = condition_id AND c.profile_id = e.profile_id))`,
    }),
    pgPolicy('journal_items_profile_delete', {
      for: 'delete',
      using: sql`EXISTS (SELECT 1 FROM journal_entries e WHERE e.id = entry_id AND app_can_write_profile_category(e.profile_id, app_journal_area_category(e.area)))`,
    }),
  ],
);

/**
 * Self-reported readings on a condition item (v2.4): one row per reading, each with its own
 * time. `data` is AES-256-GCM ciphertext of the JSON values of that kind
 * (blood_pressure: systolic, diastolic, pulse?; glucose: mgdl, moment; weight: kg).
 * Stored as typed, never compared, labelled or averaged.
 */
export const conditionReadings = pgTable(
  'condition_readings',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id').references(() => users.id, { onDelete: 'set null' }), // author (the caller); NULL once they delete their account
    profileId: uuid('profile_id')
      .notNull()
      .references(() => profiles.id, { onDelete: 'cascade' }), // subject
    entryId: uuid('entry_id')
      .notNull()
      .references(() => journalEntries.id, { onDelete: 'cascade' }),
    conditionId: uuid('condition_id')
      .notNull()
      .references(() => userConditions.id, { onDelete: 'cascade' }),
    kind: text('kind').notNull(),
    measuredAt: timestamp('measured_at', { withTimezone: true }).notNull(),
    data: text('data').notNull(), // encrypted JSON of the values
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    index('idx_condition_readings_condition_measured').on(table.profileId, table.conditionId, table.measuredAt.desc()),
    index('idx_condition_readings_entry').on(table.entryId),
    check('condition_readings_kind_check', sql`${table.kind} IN ('blood_pressure', 'glucose', 'weight')`),
    pgPolicy('condition_readings_profile_select', {
      for: 'select',
      using: sql`app_can_read_profile_category(profile_id, 'conditions')`,
    }),
    pgPolicy('condition_readings_profile_insert', {
      for: 'insert',
      withCheck: sql`app_can_write_profile_category(profile_id, 'conditions') AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
        AND EXISTS (SELECT 1 FROM journal_entries e WHERE e.id = condition_readings.entry_id AND e.profile_id = condition_readings.profile_id)
        AND EXISTS (SELECT 1 FROM user_conditions c WHERE c.id = condition_readings.condition_id AND c.profile_id = condition_readings.profile_id)`,
    }),
    pgPolicy('condition_readings_profile_update', {
      for: 'update',
      using: sql`app_can_write_profile_category(profile_id, 'conditions')`,
      withCheck: sql`app_can_write_profile_category(profile_id, 'conditions')
        AND EXISTS (SELECT 1 FROM journal_entries e WHERE e.id = condition_readings.entry_id AND e.profile_id = condition_readings.profile_id)
        AND EXISTS (SELECT 1 FROM user_conditions c WHERE c.id = condition_readings.condition_id AND c.profile_id = condition_readings.profile_id)`,
    }),
    pgPolicy('condition_readings_profile_delete', {
      for: 'delete',
      using: sql`app_can_write_profile_category(profile_id, 'conditions')`,
    }),
  ],
);
