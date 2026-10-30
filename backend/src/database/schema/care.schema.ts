import { pgTable, uuid, text, integer, timestamp, pgPolicy, index, uniqueIndex, customType, check, type AnyPgColumn } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { users } from './users.schema';
import { profiles } from './profiles.schema';

/**
 * Premium "Meus cuidados" (migration 0021). Stores what the person entered or confirmed;
 * the app never interprets it. `data` is AES-256-GCM ciphertext of a JSON object whose
 * shape depends on `kind` (see modules/care/care.types.ts); `file` is encrypted bytes.
 */

const bytea = customType<{ data: Buffer; driverData: Buffer }>({
  dataType: () => 'bytea',
});

export const CARE_RECORD_KINDS = ['vaccine_dose', 'allergy', 'medication', 'medication_intake', 'appointment'] as const;
export type CareRecordKind = (typeof CARE_RECORD_KINDS)[number];

export const CARE_DOCUMENT_KINDS = ['lab', 'prescription', 'other'] as const;
export type CareDocumentKind = (typeof CARE_DOCUMENT_KINDS)[number];

export const CARE_DOCUMENT_STATUSES = ['archived', 'processing', 'review', 'ready', 'failed'] as const;
export type CareDocumentStatus = (typeof CARE_DOCUMENT_STATUSES)[number];

const profilePolicies = (table: string) => [
  pgPolicy(`${table}_profile_select`, { for: 'select', using: sql`app_can_read_profile(profile_id)` }),
  pgPolicy(`${table}_profile_insert`, {
    for: 'insert',
    withCheck: sql`app_can_write_profile(profile_id) AND user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid`,
  }),
  pgPolicy(`${table}_profile_update`, {
    for: 'update',
    using: sql`app_can_write_profile(profile_id)`,
    withCheck: sql`app_can_write_profile(profile_id)`,
  }),
  pgPolicy(`${table}_profile_delete`, { for: 'delete', using: sql`app_can_write_profile(profile_id)` }),
];

export const careRecords = pgTable(
  'care_records',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    /** Author; NULL once the author deletes their account (the record stays with the profile). */
    userId: uuid('user_id').references(() => users.id, { onDelete: 'set null' }),
    profileId: uuid('profile_id').notNull().references(() => profiles.id, { onDelete: 'cascade' }), // subject
    kind: text('kind').$type<CareRecordKind>().notNull(),
    /** medication_intake -> its medication. */
    parentId: uuid('parent_id').references((): AnyPgColumn => careRecords.id, { onDelete: 'cascade' }),
    /** Sort/filter date: dose applied, appointment start, intake time, allergy informed. */
    occursAt: timestamp('occurs_at', { withTimezone: true }),
    data: text('data').notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    index('idx_care_records_profile_kind').on(table.profileId, table.kind, table.occursAt.desc()),
    index('idx_care_records_parent').on(table.parentId),
    check('care_records_kind_check', sql`kind IN ('vaccine_dose', 'allergy', 'medication', 'medication_intake', 'appointment')`),
    ...profilePolicies('care_records'),
  ],
);

export const careDocuments = pgTable(
  'care_documents',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id').references(() => users.id, { onDelete: 'set null' }), // author, as in care_records
    profileId: uuid('profile_id').notNull().references(() => profiles.id, { onDelete: 'cascade' }),
    kind: text('kind').$type<CareDocumentKind>().notNull(),
    mime: text('mime').notNull(),
    sizeBytes: integer('size_bytes').notNull(),
    file: bytea('file').notNull(),
    /** Keyed HMAC of the plain file (migration 0022): the same file is stored and read once per profile. */
    fileHmac: text('file_hmac'),
    status: text('status').$type<CareDocumentStatus>().notNull(),
    data: text('data'),
    error: text('error'),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    index('idx_care_documents_profile_created').on(table.profileId, table.createdAt.desc()),
    uniqueIndex('uq_care_documents_profile_file_hmac').on(table.profileId, table.fileHmac),
    check('care_documents_kind_check', sql`kind IN ('lab', 'prescription', 'other')`),
    check('care_documents_status_check', sql`status IN ('archived', 'processing', 'review', 'ready', 'failed')`),
    ...profilePolicies('care_documents'),
  ],
);

/** The caller's own rows (requests are counted per author, not per profile). */
const ownRow = sql`user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid`;

/**
 * One row per document upload or re-read (migration 0023), counted for the daily limit
 * in CareService. Append-only: deleting a document does not give its request back.
 */
export const careDocumentRequests = pgTable(
  'care_document_requests',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    index('idx_care_document_requests_user_created').on(table.userId, table.createdAt.desc()),
    pgPolicy('care_document_requests_own_select', { for: 'select', using: ownRow }),
    pgPolicy('care_document_requests_own_insert', { for: 'insert', withCheck: ownRow }),
  ],
);
